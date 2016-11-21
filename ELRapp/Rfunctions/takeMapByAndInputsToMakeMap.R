takeMapByAndInputsToMakeMap <- function(tab, mapByInput, mapByProductInput, productInputVector = NULL) {
  #########################################
  # tab <- 'com'
  # mapByInput <- 'Sales Territory'
  # mapByProductInput <- 'Pouches'
  # productInputVector <- c('ME','BCID')
  ###########################################
  
  ag.arg.0 <- switch(tab,
                     'com' = 'cbind(Qty, Count)',
                     'sale' = 'cbind(Qty, Count, ItemsShipped)'
                    )
  
  ag.arg.1 <- switch(mapByInput,
                     'Sales Territory' = 'TerritoryGroup',
                     'Customer Type' = 'CustomerType'
                     )
  
  if(mapByProductInput == 'All Products') {
    ag.string <- paste(ag.arg.0, paste(ag.arg.1,'Region','StateName',sep='+'), sep='~')
  } else {
    ag.string <- paste(ag.arg.0, paste(ag.arg.1,'Region','StateName','Product',sep='+'), sep='~')
  }


  uc.agg <- switch(tab,
                   'com' = with(complaints.us, aggregate(as.formula(ag.string), FUN=sum)),
                   'sale' = with(sales.map, aggregate(as.formula(ag.string), FUN=sum)))
  
  if(!mapByProductInput == 'All Products') {
    if (is.null(productInputVector)){
      if(tab=='com') {
        uc.agg$Rate <- 0
      }
      uc.agg <- uc.agg[uc.agg[,'Product'] %in% productInputVector, ]
    } else {
      uc.agg <- uc.agg[uc.agg[,'Product'] %in% productInputVector, ]
      uc.agg <- with(uc.agg, aggregate(as.formula(paste(ag.arg.0, paste('Region','StateName', sep='+'),sep='~')), FUN=sum))
      if(tab=='com'){
        denom <- mapDenom[mapDenom[,'Product'] %in% productInputVector, ]
        denom <- with(denom, aggregate(QtyShipped~State, FUN=sum))
        uc.agg <- merge(uc.agg, denom, by.x='Region', by.y='State')
        uc.agg$Rate <- uc.agg$Qty / uc.agg$QtyShipped
      }
     # print(uc.agg[1:10,])
    }
  } else {
    uc.agg <- with(uc.agg, aggregate(as.formula(paste(ag.arg.0, paste('Region','StateName', sep='+'),sep='~')), FUN=sum))
    if(tab=='com') {
      denom <- mapDenom
      denom <- with(denom, aggregate(QtyShipped~State, FUN=sum))
      uc.agg <- merge(uc.agg, denom, by.x='Region', by.y='State')
      uc.agg$Rate <- uc.agg$Qty / uc.agg$QtyShipped
    }
  }
  
  colnames(uc.agg)[grep('StateName', colnames(uc.agg))] <- 'NAME'
  return(uc.agg)
}
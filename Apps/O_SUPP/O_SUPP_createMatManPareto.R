createMatManPareto <- function(paretoType, paretoFilterType, paretoFilterValue, dateStart, dateEnd, rate = FALSE, supplierFault = FALSE) {
  
  # first, the NCR data should be trimmed down to only include tickets in the date range
  ncr.df <- switch(paretoType,
                   
                   'Defects' = defects.date[defects.date$Date >= dateStart & defects.date$Date <= dateEnd, ],
                   'Parts Affected' = affParts.date[affParts.date$Date >= dateStart & affParts.date$Date <= dateEnd, ],
                   'Supplier Performance - Best' = affParts.date[affParts.date$Date >= dateStart & affParts.date$Date <= dateEnd, ],
                   'Supplier Performance - Worst' = affParts.date[affParts.date$Date >= dateStart & affParts.date$Date <= dateEnd, ],
                   'Vendor NCR Summary' = affParts.date[affParts.date$Date >= dateStart & affParts.date$Date <= dateEnd, ]
  )
  
  # if the user only wants to see data where the supplier is at fault, filter down the data
  if(supplierFault) {
    
    ncr.df <- merge(filters.df[filters.df$SupplierAtFault == 1, c('TicketId','Type','SCAR','Vendor')], ncr.df, by='TicketId')
  } else {
    
    ncr.df <- merge(filters.df[, c('TicketId','Type','SCAR','Vendor')], ncr.df, by='TicketId')
  }
  
  # now apply the paretoFilterType and paretoFilterValue to trim the data set
  ncr.trim <- switch(paretoFilterType,
                     
                     'NCR Type' = ncr.df[ncr.df$Type == paretoFilterValue, ],
                     'Item Class' = merge(ncr.df, smi.df[smi.df$ItemClass == paretoFilterValue, c('ItemID','ItemClass')], by.x='PartNumber', by.y='ItemID'),
                     'SCAR' = ncr.df[ncr.df$SCAR == paretoFilterValue, ],
                     'SMI' = merge(ncr.df, smi.df[smi.df$SMI == paretoFilterValue, c('ItemID','SMI')], by.x='PartNumber', by.y='ItemID'),
                     'Vendor Name' = ncr.df[as.character(ncr.df$Vendor) == paretoFilterValue, ]
                     )

  if(length(ncr.trim[,1])==0) {
    
    p <- ggplot(ncr.trim) + geom_blank() + theme(panel.background=element_rect(fill='white', color='white'), text=element_text(size=20, face='bold'), axis.text=element_text(size=18, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title = 'No Data Available with Current Input Parameters')
    return(p)
  }
  
  # if the pareto is supposed to show a rate, then calculate the rate
  if(rate) {
    
    num.ncr <- with(ncr.trim, aggregate(Record~Vendor, FUN=sum))
    num.receipt <- receipts.df[receipts.df$Date >= dateStart & receipts.df$Date <= dateEnd, c('VendName','PartNumber','RcvQty')]
    num.receipt <- with(num.receipt, aggregate(RcvQty~VendName, FUN=sum))
    denom.receipt <- with(receipts.df, aggregate(RcvQty~VendName, FUN=sum))
    rate.df <- merge(merge(num.ncr, num.receipt, by.x='Vendor', by.y='VendName'), denom.receipt, by.x='Vendor', by.y='VendName')
    colnames(rate.df ) <- c('Vendor','QtyNCR','QtyRcv','QtyRcvTotal')
    rate.df$Rate <- with(rate.df, (QtyRcv - QtyNCR)/QtyRcv)
    vendors <- as.character(unique(rate.df$Vendor))
    
    if(paretoType == 'Supplier Performance - Best') {
      
      rate.df <- rate.df[with(rate.df, order(Rate)), ]
      ncr.trim <- rate.df[rate.df$Rate >= quantile(rate.df$Rate, probs = 0.9), ]
      if(length(ncr.trim$Vendor) <= 10) {
        
        ncr.trim <- rate.df[rate.df$Rate >= quantile(rate.df$Rate, probs = 0.5), ]
      }
      
    } else {
      
      rate.df <- rate.df[with(rate.df, order(Rate, decreasing = TRUE)), ]
      ncr.trim <- rate.df[rate.df$Rate <= quantile(rate.df$Rate, probs = 0.1), ]
      if(length(ncr.trim$Vendor) <= 10) {
        
        ncr.trim <- rate.df[rate.df$Rate <= quantile(rate.df$Rate, probs = 0.5), ]
      }
    }
    
    ncr.trim <- ncr.trim[,c('Vendor','Rate')]
    colnames(ncr.trim) <- c('Category','Record')
  } else {
    
    ncr.trim <- switch(paretoType,
                       
                       'Parts Affected' = with(ncr.trim, aggregate(Record~PartNumber, FUN=sum)),
                       'Defects' = with(ncr.trim, aggregate(Record~Order, FUN=sum)),
                       'Vendor NCR Summary' = with(ncr.trim, aggregate(Record~PartNumber, FUN=sum))
    )
    
    colnames(ncr.trim) <- c('Category','Record')
    
    if(paretoType=='Vendor NCR Summary') {
      
      ncr.trim <- ncr.trim
    } else if(length(ncr.trim$Category) > 10) {
      
      ncr.trim <- ncr.trim[ncr.trim$Record >= quantile(ncr.trim$Record, 0.9), ]
    }
  }
  
  ncr.trim <- ncr.trim[ncr.trim$Record >= 0, ]
  
  if(length(ncr.trim[,1]) == 0) {
    
    p <- ggplot(ncr.trim) + geom_blank() + theme(panel.background=element_rect(fill='white', color='white'), text=element_text(size=20, face='bold'), axis.text=element_text(size=18, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title = 'No Data Available with Current Input Parameters')
  } else {
    
    ncr.trim$Name <- factor(ncr.trim$Category, levels = ncr.trim[with(ncr.trim, order(Record, decreasing = TRUE)), 'Category'])
    
    if(paretoType %in% c('Supplier Performance - Best','Supplier Performance - Worst')) {
      
      p <- ggplot(ncr.trim, aes(x=Name, y=Record, fill='filling')) + geom_bar(stat='identity') + scale_fill_manual(values='orange', guide=FALSE) + theme(panel.background=element_rect(fill='white', color='white'), text=element_text(size=20, face='bold'), axis.text=element_text(size=18, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1)) + scale_y_continuous(labels=percent) + coord_cartesian(ylim=c(min(ncr.trim$Record)-0.1, 1)) + labs(x='', y='Percent of Supplier Receipts Accepted', title=paste(paretoType, 'where', paretoFilterType,'=',paretoFilterValue, sep=' '))
    } else {
      
      p <- ggplot(ncr.trim, aes(x=Name, y=Record, fill='filling')) + geom_bar(stat='identity') + scale_fill_manual(values='orange', guide=FALSE) + theme(panel.background=element_rect(fill='white', color='white'), text=element_text(size=20, face='bold'), axis.text=element_text(size=18, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1)) + labs(x='',y='NCR Quantity or Count', title=paste(paretoType, 'where', paretoFilterType,'=',paretoFilterValue, sep=' '))
    }
    
  }
  
  return(p)
}
takeMapByAndInputsToMakeTable <- function(tab, mapByInput, mapByProductInput, productInputVector = NULL) {
  #########################################
  # tab <- 'com'
  # mapByInput <- 'Sales Territory'
  # mapByProductInput <- 'All Products'
  # productInputVector <- c('FA1.5')
  # productInputVector <- c('RP', 'GI')
  # 
  # mapByInput <- 'Customer Type'
  # mapByProductInput <- 'All Products'
  
  ###########################################
  
  arg.0 <- switch(tab,
                     'com' = 'cbind(Qty, Count)',
                     'sale' = 'cbind(Qty, Count, ItemsShipped)'
                  )

  arg.1 <- switch(mapByInput,
                     'Sales Territory' = 'TerritoryGroup',
                     'Customer Type' = 'CustomerType'
  )

  if(mapByProductInput == 'All Products') {
    ag.string <- paste(arg.0, paste(arg.1,'Region','lng','lat',sep='+'), sep='~')
  } else {
    ag.string <- paste(arg.0, paste(arg.1,'Product','Region','lng','lat',sep='+'), sep='~')
  }

  filteredData <- switch(tab,
                         'com' = with(complaints.us, aggregate(as.formula(ag.string), FUN=sum)),
                         'sale' = with(sales.map, aggregate(as.formula(ag.string), FUN=sum))
                         )
  
  
  if(!mapByProductInput == 'All Products') {
    
    filteredData <- filteredData[filteredData[,'Product'] %in% productInputVector, ]
  }

  count.col <- switch(mapByInput,
                    'Sales Territory' = with(filteredData, aggregate(Count~TerritoryGroup, FUN=sum)),
                    'Customer Type' = with(filteredData, aggregate(Count~CustomerType, FUN=sum)))

  qty.col <- switch(mapByInput,
                    'Sales Territory' = with(filteredData, aggregate(Qty~TerritoryGroup, FUN=sum)),
                    'Customer Type' = with(filteredData, aggregate(Qty~CustomerType, FUN=sum)))
  if(tab=='sale') {
    items.col <- switch(mapByInput,
                        'Sales Territory' = with(filteredData, aggregate(ItemsShipped~TerritoryGroup, FUN=sum)),
                        'Customer Type' = with(filteredData, aggregate(ItemsShipped~CustomerType, FUN=sum)))
  } else if(tab=='com') {
    filteredData.denom <- with(sales.map, aggregate(as.formula(ag.string), FUN=sum))
    if(!mapByProductInput == 'All Products') {
      
      filteredData.denom <- filteredData.denom[filteredData.denom[,'Product'] %in% productInputVector, ]
    }
    denom.col <- switch(mapByInput,
                        'Sales Territory' = with(filteredData.denom, aggregate(Count~TerritoryGroup, FUN=sum)),
                        'Customer Type' = with(filteredData.denom, aggregate(Count~CustomerType, FUN=sum)))
    rate.col <- switch(mapByInput,
                       'Sales Territory' = merge(denom.col, count.col, by='TerritoryGroup'),
                       'Customer Type' = merge(denom.col, count.col, by='CustomerType')
                      )
    rate.col$Rate <- rate.col$Count.y / rate.col$Count.x
  }
  # US Sales Table
  if (tab == 'sale') {
    table <- tags$table(class = "table",
                        tags$thead(tags$tr(
                          tags$th(
                            switch(mapByInput,
                                   'Sales Territory' = 'Sales Territory',
                                   'Customer Type' = 'Customer Type')
                          ),
                          tags$th(
                            "Number of Units Shipped"
                          ),
                          tags$th(
                            "Quantity of Items Sold"
                          ),
                          tags$th(
                            "Revenue"
                        )),
                        tags$tbody(
                          tags$tr(
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = 'Central',
                                     'Customer Type' = 'Small Clinical Hospital')
                            ),
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = format(items.col$ItemsShipped[items.col$TerritoryGroup == 'Central'],big.mark=",", scientific = FALSE, digits=0),
                                     'Customer Type' = format(items.col$ItemsShipped[items.col$CustomerType == 'Small Clinical Hospital'],big.mark=",", scientific = FALSE,digits=0))
                            ),
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = format(count.col$Count[count.col$TerritoryGroup == 'Central'],big.mark=",",scientific = FALSE, digits=0),
                                     'Customer Type' = format(count.col$Count[count.col$CustomerType == 'Small Clinical Hospital'],big.mark=",",scientific = FALSE, digits=0))
                            ),
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = paste('$',format(qty.col$Qty[qty.col$TerritoryGroup == 'Central'],big.mark=","),sep=""),
                                     'Customer Type' = paste('$', format(qty.col$Qty[qty.col$CustomerType == 'Small Clinical Hospital'],big.mark=","), sep=""))
                            )),
                          tags$tr(
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = 'Great Lakes',
                                     'Customer Type' = 'Medium Clinical Hospital')
                            ),
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = format(items.col$ItemsShipped[items.col$TerritoryGroup == 'Great Lakes'],big.mark=",",scientific = FALSE, digits=0),
                                     'Customer Type' = format(items.col$ItemsShipped[items.col$CustomerType == 'Medium Clinical Hospital'], big.mark=",",scientific = FALSE,digits=0))
                            ),
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = format(count.col$Count[count.col$TerritoryGroup == 'Great Lakes'],big.mark=",",scientific = FALSE, digits=0),
                                     'Customer Type' = format(count.col$Count[count.col$CustomerType == 'Medium Clinical Hospital'], big.mark=",",scientific = FALSE,digits=0))
                            ),
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = paste('$', format(qty.col$Qty[qty.col$TerritoryGroup == 'Great Lakes'], big.mark=","), sep=""),
                                     'Customer Type' = paste('$', format(qty.col$Qty[qty.col$CustomerType == 'Medium Clinical Hospital'], big.mark=","), sep=""))
                            )),
                          tags$tr(
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = 'North East',
                                     'Customer Type' = 'Large Clinical Hospital')
                            ),
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = format(items.col$ItemsShipped[items.col$TerritoryGroup == 'North East'], big.mark=",",scientific = FALSE,digits=0),
                                     'Customer Type' = format(items.col$ItemsShipped[items.col$CustomerType == 'Large Clinical Hospital'], big.mark=",",scientific = FALSE,digits=0))
                            ),
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = format(count.col$Count[count.col$TerritoryGroup == 'North East'], big.mark=",",scientific = FALSE,digits=0),
                                     'Customer Type' = format(count.col$Count[count.col$CustomerType == 'Large Clinical Hospital'], big.mark=",",scientific = FALSE,digits=0))
                            ),
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = paste('$', format(qty.col$Qty[qty.col$TerritoryGroup == 'North East'], big.mark=","), sep=""),
                                     'Customer Type' = paste('$', format(qty.col$Qty[qty.col$CustomerType == 'Large Clinical Hospital'], big.mark=","), sep=""))
                            )),
                          tags$tr(
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = 'South East',
                                     'Customer Type' = 'Laboratory')
                            ),
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = format(items.col$ItemsShipped[items.col$TerritoryGroup == 'South East'], big.mark=",",scientific = FALSE,digits=0),
                                     'Customer Type' = format(items.col$ItemsShipped[items.col$CustomerType == 'Laboratory'], big.mark=",",scientific = FALSE,digits=0))
                            ),
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = format(count.col$Count[count.col$TerritoryGroup == 'South East'], big.mark=",",scientific = FALSE,digits=0),
                                     'Customer Type' = format(count.col$Count[count.col$CustomerType == 'Laboratory'], big.mark=",",scientific = FALSE,digits=0))
                            ),
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = paste('$', format(qty.col$Qty[qty.col$TerritoryGroup == 'South East'], big.mark=","), sep=""),
                                     'Customer Type' = paste('$', format(qty.col$Qty[qty.col$CustomerType == 'Laboratory'], big.mark=","), sep=""))
                            )),
                          tags$tr(
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = 'West',
                                     'Customer Type' = 'Military')
                            ),
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = format(items.col$ItemsShipped[items.col$TerritoryGroup == 'West'], big.mark=",",scientific = FALSE,digits=0),
                                     'Customer Type' = format(items.col$ItemsShipped[items.col$CustomerType == 'Military'], big.mark=",",scientific = FALSE,digits=0))
                            ),
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = format(count.col$Count[count.col$TerritoryGroup == 'West'], big.mark=",",scientific = FALSE,digits=0),
                                     'Customer Type' = format(count.col$Count[count.col$CustomerType == 'Military'], big.mark=",",scientific = FALSE,digits=0))
                            ),
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = paste('$', format(qty.col$Qty[qty.col$TerritoryGroup == 'West'], big.mark=","), sep=""),
                                     'Customer Type' = paste('$', format(qty.col$Qty[qty.col$CustomerType == 'Military'], big.mark = ","), sep=""))
                            )),
                          tags$tr(
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = ' ',
                                     'Customer Type' = 'Other')
                            ),
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = '',
                                     'Customer Type' = format(items.col$ItemsShipped[items.col$CustomerType == 'Other'], big.mark=",",scientific = FALSE,digits=0))
                            ),
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = '',
                                     'Customer Type' = format(count.col$Count[count.col$CustomerType == 'Other'], big.mark=",",scientific = FALSE,digits=0))
                            ),
                            tags$td(
                              switch(mapByInput,
                                     'Sales Territory' = '',
                                     'Customer Type' = paste('$', format(qty.col$Qty[qty.col$CustomerType == 'Other'], big.mark=","), sep=""))
                            )))))
    
  } else {
  # US Complaints tables
  table <- tags$table(class = "table",
             tags$thead(tags$tr(
               tags$th(
                 switch(mapByInput,
                        'Sales Territory' = 'Sales Territory',
                        'Customer Type' = 'Customer Type')
               ),
               tags$th(
                 switch(tab,
                        'com' = "Count of Complaints"
                        )
                 ),
               tags$th(
                 switch(tab,
                        'com' = "Quantity of Product Affected"
               )),
               tags$th(
                 switch(tab,
                        'com' = "Complaints per Product Shipped"
               )
             ))),
             tags$tbody(
               tags$tr(
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = 'Central',
                          'Customer Type' = 'Small Clinical Hospital')
                 ),
                 tags$td(
                    switch(mapByInput,
                          'Sales Territory' = count.col$Count[count.col$TerritoryGroup == 'Central'],
                          'Customer Type' = count.col$Count[count.col$CustomerType == 'Small Clinical Hospital'])
                 ),
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = qty.col$Qty[qty.col$TerritoryGroup == 'Central'],
                          'Customer Type' = qty.col$Qty[qty.col$CustomerType == 'Small Clinical Hospital'])
                 ),
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = format(rate.col$Rate[rate.col$TerritoryGroup == 'Central'], digits=2),
                          'Customer Type' = format(rate.col$Rate[rate.col$CustomerType == 'Small Clinical Hospital'], digits=2))
                 )),
                 
               tags$tr(
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = 'Great Lakes',
                          'Customer Type' = 'Medium Clinical Hospital')
                 ),
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = count.col$Count[count.col$TerritoryGroup == 'Great Lakes'],
                          'Customer Type' = count.col$Count[count.col$CustomerType == 'Medium Clinical Hospital'])
                 ),
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = qty.col$Qty[qty.col$TerritoryGroup == 'Great Lakes'],
                          'Customer Type' = qty.col$Qty[qty.col$CustomerType == 'Medium Clinical Hospital'])
                 ),
                 tags$td(
                   switch(mapByInput,
                        'Sales Territory' = format(rate.col$Rate[rate.col$TerritoryGroup == 'Great Lakes'], digits=2),
                        'Customer Type' = format(rate.col$Rate[rate.col$CustomerType == 'Medium Clinical Hospital'], digits=2))
                 )),
               tags$tr(
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = 'North East',
                          'Customer Type' = 'Large Clinical Hospital')
                 ),
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = count.col$Count[count.col$TerritoryGroup == 'North East'],
                          'Customer Type' = count.col$Count[count.col$CustomerType == 'Large Clinical Hospital'])
                 ),
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = qty.col$Qty[qty.col$TerritoryGroup == 'North East'],
                          'Customer Type' = qty.col$Qty[qty.col$CustomerType == 'Large Clinical Hospital'])
                 ),
                 tags$td(
                   switch(mapByInput,
                        'Sales Territory' = format(rate.col$Rate[rate.col$TerritoryGroup == 'North East'], digits=2),
                        'Customer Type' = format(rate.col$Rate[rate.col$CustomerType == 'Large Clinical Hospital'], digits=2))
                 )),
               tags$tr(
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = 'South East',
                          'Customer Type' = 'Laboratory')
                 ),
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = count.col$Count[count.col$TerritoryGroup == 'South East'],
                          'Customer Type' = count.col$Count[count.col$CustomerType == 'Laboratory'])
                 ),
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = qty.col$Qty[qty.col$TerritoryGroup == 'South East'],
                          'Customer Type' = qty.col$Qty[qty.col$CustomerType == 'Laboratory'])
                 ),
                tags$td(
                  switch(mapByInput,
                        'Sales Territory' = format(rate.col$Rate[rate.col$TerritoryGroup == 'South East'], digits=2),
                        'Customer Type' = format(rate.col$Rate[rate.col$CustomerType == 'Laboratory'], digits=2))
                )),
               tags$tr(
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = 'West',
                          'Customer Type' = 'Military')
                 ),
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = count.col$Count[count.col$TerritoryGroup == 'West'],
                          'Customer Type' = count.col$Count[count.col$CustomerType == 'Military'])
                 ),
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = qty.col$Qty[qty.col$TerritoryGroup == 'West'],
                          'Customer Type' = qty.col$Qty[qty.col$CustomerType == 'Military'])
                 ),
                 tags$td(
                   switch(mapByInput,
                        'Sales Territory' = format(rate.col$Rate[rate.col$TerritoryGroup == 'West'], digits=2),
                        'Customer Type' = format(rate.col$Rate[rate.col$CustomerType == 'Military'], digits=2))
                 )),
               tags$tr(
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = 'Defense',
                          'Customer Type' = 'Other')
                 ),
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = count.col$Count[count.col$TerritoryGroup == 'Defense'],
                          'Customer Type' = count.col$Count[count.col$CustomerType == 'Other'])
                 ),
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = qty.col$Qty[qty.col$TerritoryGroup == 'Defense'],
                          'Customer Type' = qty.col$Qty[qty.col$CustomerType == 'Other'])
                 )),
               tags$tr(
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = 'House',
                          'Customer Type' = '')
                 ),
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = count.col$Count[count.col$TerritoryGroup == 'House'],
                          'Customer Type' = '')),
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = qty.col$Qty[qty.col$TerritoryGroup == 'House'],
                          'Customer Type' = '')
                 )),
               tags$tr(
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = 'Other',
                          'Customer Type' = '')
                 ),
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = count.col$Count[count.col$TerritoryGroup == 'Other'],
                          'Customer Type' = '')),
                 tags$td(
                   switch(mapByInput,
                          'Sales Territory' = qty.col$Qty[qty.col$TerritoryGroup == 'Other'],
                          'Customer Type' = '')
               ))))
  }

  return(table)
}
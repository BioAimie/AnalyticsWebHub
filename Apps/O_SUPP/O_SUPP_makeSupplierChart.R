#make chart for Supplier Performance 
makeSupplierChart <- function(ncrType, vendName, supplierAtFault, timeStart = NULL, timeEnd = NULL) {
  #######################################
  # ncrType <- 'Raw Material'
  # vendName <- 'Intertech Medical Inc'
  # timeStart <- '2015-05-17'
  # timeEnd <- '2016-05-16'
  ##########################################
  if(is.null(vendName)) {
    return(0)
  }
  
  #all <- c('Raw Material','Instrument Production WIP','BioReagents', 'HTFA Instrument WIP', 'FA2.0 Instrument WIP','FA1.5 Instrument WIP')
  #iNcrType <- c('Instrument Production WIP','HTFA Instrument WIP', 'FA2.0 Instrument WIP','FA1.5 Instrument WIP')
  if(supplierAtFault) {
    
    ncrParts.sum <- subset(ncrParts.df, SupplierAtFault=='Yes')
  } else {
    
    ncrParts.sum <- ncrParts.df
  }
  
  if(ncrType=='All NCRs') {
    filteredData <- subset(ncrParts.sum, Type %in% all & VendName == vendName)
  } else if(ncrType == 'Instrument') {
    filteredData <- subset(ncrParts.sum, Type %in% iNcrType & VendName == vendName)
  } else {
    filteredData <- subset(ncrParts.sum, Type == ncrType & VendName == vendName)
  }
  
  colnames(filteredData)[colnames(filteredData) == 'Qty'] <- 'Record'
  
  suppReceipts <- subset(receipts.df, VendName == vendName)
  colnames(suppReceipts)[colnames(suppReceipts) == 'RcvQty'] <- 'Record'
  
  if(nrow(suppReceipts)==0 || nrow(filteredData)==0){
    return(0)
  } 
  
  startYear <- year(min(suppReceipts$Date[!(is.na(suppReceipts$Date))]))
  startWeek <- suppReceipts$Week[suppReceipts$Date == min(suppReceipts$Date[!(is.na(suppReceipts$Date))])]
  startDate <- ifelse(startWeek < 10,
                      paste(startYear, paste('0', startWeek, sep=''), sep='-'),
                      paste(startYear, startWeek, sep='-'))
  
  #make dategroups
  filteredData <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', filteredData, 'VendName', startDate, 'Record', 'sum', 0)
  filteredData <- filteredData[with(filteredData, order(DateGroup)),]
  filteredData <- with(filteredData, aggregate(Record~DateGroup, FUN=sum))
  colnames(filteredData)[colnames(filteredData) == 'Record'] <- 'NCRQty'
  filteredData$NCRsum <- with(filteredData, cumsum(NCRQty))
  
  suppReceipts <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', suppReceipts, 'VendName', startDate, 'Record', 'sum', 0)
  suppReceipts <- suppReceipts[with(suppReceipts, order(DateGroup)),]
  suppReceipts <- with(suppReceipts, aggregate(Record~DateGroup, FUN=sum))
  colnames(suppReceipts)[colnames(suppReceipts) == 'Record'] <- 'TotalQty'
  suppReceipts$Totalsum <- with(suppReceipts, cumsum(TotalQty))
  
  #Acceptance Rate
  supp.part <- merge(filteredData,suppReceipts, by='DateGroup')
  supp.part$RejectionRate <- supp.part$NCRsum / supp.part$Totalsum
  supp.part$ARate <- ifelse(supp.part$RejectionRate < 1, 1-supp.part$RejectionRate, 0)
  
  
  #Dates
  start <- calendar.week[calendar.week$Date == timeStart, 'DateGroup']
  
  end <- calendar.week[calendar.week$Date == timeEnd, 'DateGroup']

  # # Fail if below 90% acceptance rate
  # supp.part$Review <- 'Pass'
  # for(i in 1:length(supp.part$ARate)) {
  #   if(supp.part$ARate[i] < 0.9) {
  #     supp.part$Review[i] <- 'Fail'
  #   }
  # }
  # 
  # reviewColors <- c('red','blue')
  # names(reviewColors) <- c('Fail','Pass')
  
  p.chart <- ggplot(subset(supp.part, as.character(supp.part$DateGroup) >= start & as.character(supp.part$DateGroup) <= end), aes(x=DateGroup, y=ARate, group=1)) + 
    geom_line() + geom_point(size=1.5) + xlab('Date\n(Year-Week)') + ylab('Vendor Acceptance Rate') + 
    theme(text=element_text(size=18), axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=14),
          axis.text.y=element_text(hjust=1, color='black', size=14),legend.position='none') + ggtitle(paste('Acceptance Rate of Supplier\n', vendName)) + 
    scale_y_continuous(labels=percent,breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30), limits=c(0,1)) + 
    geom_hline(yintercept=.9, linetype='dashed', color = 'blue')
  
  return(p.chart)
}

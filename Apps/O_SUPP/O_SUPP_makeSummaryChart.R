#make chart for Supplier Performance 
makeSummaryChart <- function(ncrType, vendName, receiptLag, supplierAtFault=FALSE) {
  #######################################
  # ncrType <- 'All NCRs'
  # vendName <- 'McMaster Carr Supply Co.'
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
  
  if(receiptLag == '1 Year') {
    
    suppReceipts <- suppReceipts[suppReceipts$Date >= Sys.Date()-365, ]
  } else {
    
    suppReceipts <- suppReceipts[suppReceipts$Date >= Sys.Date()-730, ]
  }
  
  colnames(suppReceipts)[colnames(suppReceipts) == 'RcvQty'] <- 'Record'
  
  if(nrow(suppReceipts)==0 || nrow(filteredData)==0){
    return(0)
  }
  
  startYear <- year(min(suppReceipts$Date[!(is.na(suppReceipts$Date))]))
  startMonth <- month(min(suppReceipts$Date[!(is.na(suppReceipts$Date))]))
  startDate <- ifelse(startMonth < 10,
                      paste(startYear, paste('0', startMonth, sep=''), sep='-'),
                      paste(startYear, startMonth, sep='-'))

  #numerator
  filteredData <- aggregateAndFillDateGroupGaps(calendar, 'Month', filteredData, 'PartNumber', startDate, 'Record', 'sum', 0)
  colnames(filteredData)[colnames(filteredData) == 'Record'] <- 'NCRQty'
  
  #Quarters
  filteredData$Quarter <- 0
  for (i in 1:length(filteredData$DateGroup)) {
    if(as.numeric(substr(filteredData$DateGroup[i],6,7)) >= 1 & as.numeric(substr(filteredData$DateGroup[i],6,7)) < 4) {
      filteredData$Quarter[i] <- '01'
    } else if (as.numeric(substr(filteredData$DateGroup[i],6,7)) >= 4 & as.numeric(substr(filteredData$DateGroup[i],6,7)) < 7) {
      filteredData$Quarter[i] <- '02'
    } else if (as.numeric(substr(filteredData$DateGroup[i],6,7)) >= 7 & as.numeric(substr(filteredData$DateGroup[i],6,7)) < 10) {
      filteredData$Quarter[i] <- '03'
    } else {
      filteredData$Quarter[i] <- '04'
    }
  }
  
  #Year
  filteredData$Year <- 0
  for (i in 1:length(filteredData$DateGroup)) {
    filteredData$Year[i] <- substr(filteredData$DateGroup[i],1,4)
  }
  
  #DateGroup by Quarter
  filteredData$QuarterGroup <- 0
  for (i in 1:length(filteredData$DateGroup)) {
    filteredData$QuarterGroup[i] <- paste(filteredData$Year[i],filteredData$Quarter[i], sep='-')
  }
  
  #Aggregate by Quarter and part
  filteredData <- with(filteredData, aggregate(NCRQty~QuarterGroup+PartNumber, FUN=sum))
  
  #Cumulative sum of NCRs per part
  # num <- c()
  # 
  # for(i in unique(filteredData$PartNumber)) {
  #   s <- subset(filteredData, PartNumber==i)
  #   s <- s[with(s, order(QuarterGroup)),]
  #   s$NCRsum <- with(s, cumsum(NCRQty))
  #   num <- rbind(num, s)
  # }

  
  #denominator
  suppReceipts <- aggregateAndFillDateGroupGaps(calendar, 'Month', suppReceipts, 'VendName', startDate, 'Record', 'sum', 0)
  suppReceipts <- with(suppReceipts, aggregate(Record~DateGroup, FUN=sum))
  colnames(suppReceipts)[colnames(suppReceipts) == 'Record'] <- 'TotalQty'
  
  #Quarters
  suppReceipts$Quarter <- 0
  for (i in 1:length(suppReceipts$DateGroup)) {
    if(as.numeric(substr(suppReceipts$DateGroup[i],6,7)) >= 1 & as.numeric(substr(suppReceipts$DateGroup[i],6,7)) < 4) {
      suppReceipts$Quarter[i] <- '01'
    } else if (as.numeric(substr(suppReceipts$DateGroup[i],6,7)) >= 4 & as.numeric(substr(suppReceipts$DateGroup[i],6,7)) < 7) {
      suppReceipts$Quarter[i] <- '02'
    } else if (as.numeric(substr(suppReceipts$DateGroup[i],6,7)) >= 7 & as.numeric(substr(suppReceipts$DateGroup[i],6,7)) < 10) {
      suppReceipts$Quarter[i] <- '03'
    } else {
      suppReceipts$Quarter[i] <- '04'
    }
  }
  
  #Year
  suppReceipts$Year <- 0
  for (i in 1:length(suppReceipts$DateGroup)) {
    suppReceipts$Year[i] <- substr(suppReceipts$DateGroup[i],1,4)
  }
  
  #DateGroup by Quarter
  suppReceipts$QuarterGroup <- 0
  for (i in 1:length(suppReceipts$DateGroup)) {
    suppReceipts$QuarterGroup[i] <- paste(suppReceipts$Year[i],suppReceipts$Quarter[i], sep='-')
  }
  
  #Aggregate by Quarter
  # suppReceipts <- with(suppReceipts, aggregate(TotalQty~QuarterGroup, FUN=sum))
  # suppReceipts$Totalsum <- with(suppReceipts, cumsum(TotalQty))
  suppReceipts <- data.frame(QuarterGroup = suppReceipts$QuarterGroup, Totalsum = sum(suppReceipts$TotalQty))
  suppReceipts <- unique(suppReceipts[,c('QuarterGroup','Totalsum')])
  
  # supp.part <- merge(num,suppReceipts, by='QuarterGroup', all=TRUE)
  
  supp.part <- merge(filteredData,suppReceipts, by='QuarterGroup', all=TRUE)
  
  #Acceptance Rate per Quarter
  supp.part$RejectionRate <- supp.part$NCRQty / supp.part$Totalsum
  for(i in 1:length(supp.part$RejectionRate)) {
    if(supp.part$RejectionRate[i] < 0) {
      supp.part$RejectionRate[i] <- 0
    }
  }
  #supp.part$RejectionRate <- supp.part$NCRsum / supp.part$Totalsum
  #supp.part$ARate <- ifelse(supp.part$RejectionRate < 1, 1-supp.part$RejectionRate, 0)
  
  #Show last 8 quarters
  if(month(Sys.Date()) >= 1 & month(Sys.Date()) < 4) {
    currQuarter <- '01'
  } else if (month(Sys.Date()) >= 4 & month(Sys.Date()) < 7) {
    currQuarter <- '02'
  } else if (month(Sys.Date()) >= 7 & month(Sys.Date()) < 10) {
    currQuarter <- '03'
  } else {
    currQuarter <- '04'
  }
  
  start <- paste(year(Sys.Date()) - 2, currQuarter, sep='-')

  #Percent complete with current quarter
  currentWeek <- week(Sys.Date())
  currentYear <- year(Sys.Date())
  if(currentWeek <= 13){
    weeksIn <- currentWeek - 1
  } else if(currentWeek <= 26){
    weeksIn <- currentWeek - 14
  } else if(currentWeek <= 39){
    weeksIn <- currentWeek - 27
  } else if(currentWeek <= 53){
    weeksIn <- currentWeek - 40
  }
  percentIn <- round(100*(weeksIn/13), 0)
  note <- paste0('Current quarter\n',percentIn,'% complete')
  lastLev <- paste(year(Sys.Date()), currQuarter, sep='-')
  
  #Order df so that colors line up 
  supp.part <- supp.part[with(supp.part, order(PartNumber)),]
  
  #number <- length(unique(supp.part$PartNumber))
  #pal <- createPaletteOfVariableLength(supp.part, 'PartNumber')
  
  p.chart <- ggplot(subset(supp.part, as.character(supp.part$QuarterGroup) >= start), aes(x=QuarterGroup, y=RejectionRate, fill=PartNumber)) + 
    geom_bar(stat='identity') + xlab('Date\n(Year-Quarter)') + ylab('Percent Parts Rejected') + 
    theme(text=element_text(size=18), axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=14),
          axis.text.y=element_text(hjust=1, color='black', size=14)) + ggtitle(paste('Supplier Reliability\n',vendName)) + 
    scale_y_continuous(labels=percent,breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30)) +
    annotate("text",x=lastLev,y=0,label=note, size=3) + scale_fill_hue(name='Part Number') 
  # + scale_fill_manual(name = 'Part Number')
  
  return(p.chart)
}

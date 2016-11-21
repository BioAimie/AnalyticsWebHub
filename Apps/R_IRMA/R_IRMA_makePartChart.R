makePartChart <- function(partFrame, dateRange, partDescrip) {
  
  # take the code description and format it to act as the title for the plot
  partText <- strsplit(partDescrip, ': ')[[1]][2]
  titleString <- paste(partText,'Replacement Rate (4-week rolling average)')
  
  # transform the dateRange input to make it meaningful for partsReplaced.mrg
  if(dateRange == '52 weeks') {
    maxDate <- with(partFrame, max(as.character(DateGroup)))
    year <- strsplit(maxDate,'-')[[1]][1]
    week <- strsplit(maxDate,'-')[[1]][2]
    priorYear <- as.character(as.numeric(year) - 1)
    mark <- paste(priorYear,week,sep='-')
    subFrame <- partFrame[as.character(partFrame[,'DateGroup']) >= mark, ]
  }
  else {
    indices <- grep(dateRange, partFrame[,'DateGroup'])
    subFrame <- partFrame[indices, ]
  }
  
  # transform the code description into the integer that matches it in the serviceCodes.mrg dataframe and subset
  partNumber <- getPartNumber(partDescrip)
  sub <- subFrame[subFrame[,'Key']==partNumber, ]
  
  # create the plot
  if(length(sub[,1]) == 0) {
    return(plot(x=1:10, type='n', axes=F, xlab='',ylab='',main='No Data Available'))
  } else {
    p <- ggplot(sub, aes(x=DateGroup, y=RollingRate, group='black')) + geom_point() + geom_line() + theme(axis.text.x = element_text(angle=90, hjust=1)) + labs(title = titleString, x='Date', y='Parts Replaced per RMAs Shipped')  
    return(p)
  }
}

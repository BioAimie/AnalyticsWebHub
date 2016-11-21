makeCodeChart <- function(codeFrame, dateRange, codeDescrip) {
  
  # take the code description and format it to act as the title for the plot
  codeText <- strsplit(codeDescrip, '- ')[[1]][2]
  titleString <- paste(codeText,'Occurrence Rate (4-week rolling average)')
  
  # transform the dateRange input to make it meaningful for serviceCodes.mrg
  if(dateRange == '52 weeks') {
    maxDate <- with(codeFrame, max(as.character(DateGroup)))
    year <- strsplit(maxDate,'-')[[1]][1]
    week <- strsplit(maxDate,'-')[[1]][2]
    priorYear <- as.character(as.numeric(year) - 1)
    mark <- paste(priorYear,week,sep='-')
    subFrame <- codeFrame[as.character(codeFrame[,'DateGroup']) >= mark, ]
  }
  else {
    indices <- grep(dateRange, codeFrame[,'DateGroup'])
    subFrame <- codeFrame[indices, ]
  }
  
  # transform the code description into the integer that matches it in the serviceCodes.mrg dataframe and subset
  intCode <- getCodeFromDescrip(codeDescrip)
  sub <- subFrame[subFrame[,'Key']==intCode, ]
  
  # create the plot
  if(length(sub[,1]) == 0) {
    return(plot(x=1:10, type='n', axes=F, xlab='',ylab='',main='No Data Available'))
  } else {
    p <- ggplot(sub, aes(x=DateGroup, y=RollingRate, group='black')) + geom_point() + geom_line() + theme(axis.text.x = element_text(angle=90, hjust=1)) + labs(title = titleString, x='Date', y='Code Occurence per RMAs Shipped')  
    return(p)
  }  
}

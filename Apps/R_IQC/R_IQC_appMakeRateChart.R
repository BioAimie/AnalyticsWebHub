appMakeRateChart <- function(variableName, dateRange) {
  
  dateFlag <- ifelse(dateRange == '52 weeks', 'thisYear', 'Year')
  
  dataFrame <- passRate(data, c(variableName))
  
  rateData <- cbind(data[ ,dateFlag], dataFrame)
  colnames(rateData)[1] <- c('flag')
  
  rateData$flag <- ifelse(rateData$flag == 1, '52 weeks', rateData$flag)
  
  point <- paste(variableName,'rate',sep='_')
  avgAll <- paste(variableName,'mean',sep='_')
  sdAll <- paste(variableName,'sdev',sep='_')

  a <- rateData[rateData$flag==dateRange, c('DateGroup','Key','Version',point,avgAll,sdAll)]
  colnames(a) <- c('DateGroup','Key','Version','Point','avgAll','sdAll')
  
#   a$Colors <- with(a, ifelse(Point > avgAll+sdAll | Point < avgAll-sdAll, 'review','pass'))
  a$Colors <- 'pass'
  
  if(sum(!is.na(unique(a[,'Colors'])))==2) {
    p <- ggplot(a, aes(x=DateGroup, y=Point, group=Key, color=Key)) + geom_line() + facet_wrap(~Version, nrow=2) + geom_point(aes(x=DateGroup, y=Point, color=Colors)) + scale_color_manual(values=c('#CFCFCF','#000000','#FF0000','#0000FF'), breaks=c('Production','Service')) + theme(axis.text.x = element_text(angle=90, hjust=1), legend.title = element_blank()) + labs(title=variableName, x='Date', y='Rate')
    return(p)
  }
  else {
    p <- ggplot(a, aes(x=DateGroup, y=Point, group=Key, color=Key)) + geom_line() + facet_wrap(~Version, nrow=2) + geom_point(aes(x=DateGroup, y=Point, color=Colors)) + scale_color_manual(values=c('#CFCFCF','#000000','#0000FF'), breaks=c('Production','Service')) + theme(axis.text.x = element_text(angle=90, hjust=1), legend.title = element_blank()) + labs(title=variableName, x='Date', y='Rate')
    return(p)
  }
  
}

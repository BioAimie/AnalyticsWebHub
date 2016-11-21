passRate <- function(dataFrame, listOfParameters) {
  
  outData <- dataFrame[ , c('DateGroup','Key','Version',listOfParameters)]
  base <- outData
  
  for (i in seq_along(listOfParameters)) {
    
    a <- dataFrame[ , c('DateGroup','Key','Version','Record',listOfParameters[i])]
    colnames(a) <- c('DateGroup','Key','Version','Record','Parameter')
    
    a$Review <- with(a, ifelse(Parameter=='Review',1,0))
    x <- aggregate(a$Record~a$Key+a$Version,FUN=sum)
    colnames(x) <- c('Key','Version','Total')
    y <- aggregate(a$Review~a$Key+a$Version,FUN=sum)
    colnames(y) <- c('Key','Version','Sum')
    z <- merge(x,y,by=c('Key','Version'))
    z$mean <- z$Sum/z$Total

    stats <- z[ ,c('Key','Version','mean')]
   
    sumByKeys <- aggregate(a$Record ~ a$DateGroup+a$Key+a$Version, FUN=sum, na.action=na.omit)
    sumByResult <- aggregate(a$Record ~ a$DateGroup+a$Key+a$Version+a$Parameter, FUN=sum, na.action=na.omit)
    
    temp <- merge(sumByResult, sumByKeys, by = c('a$DateGroup','a$Key','a$Version'))
    colnames(temp) <- c('DateGroup','Key','Version','Result','sum','total')
    
    rate <- temp[with(temp, order(DateGroup,Key,Version)), ]
    rate$reviewRate <- ifelse(rate$Result=='Pass',1-rate$sum/rate$total,rate$sum/rate$total)

    m <- rate[rate[,'Result']=='Review', ]
    sdev <- with(m, aggregate(reviewRate~Key+Version, FUN=sd))
    
    stats <- merge(stats, sdev, by=c('Key','Version'), all=TRUE)
    colnames(stats) <- c('Key','Version','mean','sdev')
    stats[is.na(stats[,'sdev']),'sdev'] <- 0
    
    c <- merge(rate, stats, by = c('Key','Version'))
    
    name1 <- listOfParameters[i]
    name2 <- paste(listOfParameters[i],'rate',sep='_')
    name3 <- paste(listOfParameters[i],'mean',sep='_')
    name4 <- paste(listOfParameters[i],'sdev',sep='_')
    
    colnames(c) <- c('Key','Version','DateGroup', name1,'sum','total', name2, name3, name4)
    
    d <- merge(base, c, by = c('DateGroup','Key','Version',listOfParameters[i]))
    f <- d[with(d, order(DateGroup,Key,Version)), ]
    
    end <- length(f)
    start <- end - 2
    
    outData <- cbind(outData, f[ ,start:end])
    
  }
  
  return(outData)
  
}

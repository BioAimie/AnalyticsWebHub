averageOfParameters <- function(dataFrame, listOfParameters) {
  
  outData <- dataFrame[ , c('Year','DateGroup','thisYear','Key','Version','Record')]
  
  for (i in seq_along(listOfParameters)) {
    
    a <- dataFrame[ , c('DateGroup','Key','Version',listOfParameters[i])]
    colnames(a) <- c('DateGroup','Key','Version','Parameter')
    
    averageParameter <- aggregate(a$Parameter ~ a$DateGroup+a$Key+a$Version, FUN=mean, na.action=na.omit)
    
    m <- merge(aggregate(a$Parameter ~ a$Key+a$Version, FUN=mean, na.action=na.omit),
               aggregate(a$Parameter ~ a$Key+a$Version, FUN=sd, na.action=na.omit),
               by = c('a$Key','a$Version'))
    
    b <- merge(a, averageParameter, by.x = c('DateGroup','Key','Version'), by.y = c('a$DateGroup','a$Key','a$Version'), all=T)    
    
    name1 <- listOfParameters[i]
    name2 <- paste(listOfParameters[i],'avg',sep='_')
    name3 <- paste(listOfParameters[i],'mean',sep='_')
    name4 <- paste(listOfParameters[i],'sdev',sep='_')
    
    colnames(b) <- c('DateGroup','Key','Version', name1, name2)    
    colnames(m) <- c('Key','Version', name3, name4)    
    
    c <- merge(b, m, by = c('Key','Version'))
    d <- c[with(c, order(DateGroup,Key,Version)), ]
    
    outData <- cbind(outData, d[ ,c(4:7)])
     
  }
  
    return(outData)
  
}

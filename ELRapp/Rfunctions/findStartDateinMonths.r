findStartDateinMonths <- function(dataFrame, bigGroup, subGroup, timeFrame, forPareto=FALSE) {
  
  if(forPareto) {
    
    big <- max(dataFrame[,bigGroup])
    sub <- as.numeric(max(dataFrame[dataFrame[,bigGroup]==big, subGroup])) - 15
    
    if(sub < 1) {
      
      big <- big - 1
      sub <- 53 - abs(sub)
      startGroup <- ifelse(sub < 10, paste(big, sub, sep='-0'), paste(big, sub, sep='-'))
    }
    else {
      
      startGroup <- ifelse(sub < 10, paste(big, sub, sep='-0'), paste(big, sub, sep='-'))
    }
  }
  
  else {
    
    if (timeFrame == 'OneYear') {
      
      big <- as.numeric(max(dataFrame[,bigGroup]))
      sub <- as.numeric(max(dataFrame[dataFrame[,bigGroup]==big, subGroup])) - 4
      
      if(sub < 1) {
        
        big <- big - 2
        sub <- 12 - abs(sub) 
        startGroup <- ifelse(sub < 10, paste(big, sub, sep='-0'), paste(big, sub, sep='-'))
      }
      else {
        
        big <- big - 1
        startGroup <- ifelse(sub < 10, paste(big, sub, sep='-0'), paste(big, sub, sep='-'))
      }
      
    }
    else {  
      
      big <- min(dataFrame[,bigGroup])
      sub <- min(dataFrame[dataFrame[,bigGroup]==big, subGroup])
      startGroup <- ifelse(sub < 10, paste(big, sub, sep='-0'), paste(big, sub, sep='-'))
    }
  }
  
  return(startGroup)
}

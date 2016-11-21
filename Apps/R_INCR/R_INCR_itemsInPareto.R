itemsInPareto <- function(dataFrame, category, percent = 0.8) {
  
  aggString <- paste('Record',category,sep='~')
  temp <- with(dataFrame, aggregate(as.formula(aggString), FUN=sum))
  temp <- temp[with(temp, order(-Record)), ]
  temp$cumSum <- with(temp, sapply(1:length(temp[,1]), function(x) sum(temp[1:x,'Record'])))
  allRecords <- sum(temp[,'Record'])
  indexToKeep <- which(abs(temp[,'cumSum'] - percent*allRecords) %in% min(abs(temp[,'cumSum'] - percent*allRecords)))
  
  if(indexToKeep < 10 & length(temp[,1]) < 10) {
     return(as.character(temp[1:length(temp[,1]),category]))
  }
  else if(indexToKeep < 10 & length(temp[,1]) >= 10) {
    return(as.character(temp[1:10,category]))
  }
  else {
    return(as.character(temp[1:indexToKeep,category]))
  }
  
}

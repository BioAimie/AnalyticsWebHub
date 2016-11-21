makeRootCausePareto <- function(highLevel, filterCategory, lowLevel, timeFrame, topPercent = 0.8) {
  
  dataFrame <- subsetBasedOnTimeFrame(timeFrame)
  
  bigCat <- switch(highLevel,
                   'Where Found' = 'WhereFound',
                   'Problem Area' = 'ProblemArea',
                   'Failed Part' = 'FailCat',
                   'Suspected Failure Mode' = 'SubFailCat'
                   )
  
  subCat <- switch(lowLevel,
                   'Where Found' = 'WhereFound',
                   'Problem Area' = 'ProblemArea',
                   'Failed Part' = 'FailCat',
                   'Suspected Failure Mode' = 'SubFailCat'
                   )
  
  if(bigCat == subCat) {
    
    keepCats <- itemsInPareto(dataFrame,subCat,topPercent)
    aggString <- paste('Record',subCat,sep='~')
    temp <- with(dataFrame[dataFrame[,subCat] %in% keepCats, ], aggregate(as.formula(aggString), FUN=sum))
    colnames(temp) <- c('Category','Record')
    p <- ggplot(temp, aes(x=reorder(Category,-Record), y=Record)) + geom_bar(stat='identity') + labs(title = highLevel, x = lowLevel, y = paste('Occurrences in ',timeFrame)) + theme(axis.text.x = element_text(angle=90, hjust=1), text = element_text(size=16))
    
    return(p)
  }

  else {
    
    keepCats <- itemsInPareto(dataFrame[dataFrame[,bigCat] == filterCategory, ],subCat,topPercent)
    aggString <- paste('Record',subCat,sep='~')
    temp <- with(dataFrame[dataFrame[,subCat] %in% keepCats, ], aggregate(as.formula(aggString),FUN=sum))
    colnames(temp) <- c('Category','Record')
    p <- ggplot(temp, aes(x=reorder(Category,-Record), y=Record)) + geom_bar(stat='identity') + labs(title = paste(highLevel,' = ',filterCategory), x = lowLevel, y = paste('Occurrences in ',timeFrame)) + theme(axis.text.x = element_text(angle=45, hjust=1), text = element_text(size=16))
    
    return(p)
  }
  
#   if(highLevel == 'Where Found') {
#     
#     keepCats <- itemsInPareto(dataFrame[dataFrame[,'WhereFound'] == filterCategory, ],subCat,topPercent)
#     aggString <- paste('Record',subCat,sep='~')
#     temp <- with(dataFrame[dataFrame[,subCat] %in% keepCats, ], aggregate(as.formula(aggString),FUN=sum))
#     colnames(temp) <- c('Category','Record')
#     p <- ggplot(temp, aes(x=reorder(Category,-Record), y=Record)) + geom_bar(stat='identity') + labs(title = paste(highLevel,' = ',filterCategory), x = lowLevel, y = paste('Occurrences in ',timeFrame)) + theme(axis.text.x = element_text(angle=90, hjust=1), text = element_text(size=16))
#     
#     return(p)
#   }
#   
#   else if(highLevel == 'Problem Area') {
#     
#     keepCats <- itemsInPareto(dataFrame[dataFrame[,'ProblemArea'] == filterCategory, ],subCat,topPercent)
#     aggString <- paste('Record',subCat,sep='~')
#     temp <- with(dataFrame[dataFrame[,subCat] %in% keepCats, ], aggregate(as.formula(aggString),FUN=sum))
#     colnames(temp) <- c('Category','Record')
#     p <- ggplot(temp, aes(x=reorder(Category,-Record), y=Record)) + geom_bar(stat='identity') + labs(title = paste(highLevel,' = ',filterCategory), x = lowLevel, y = paste('Occurrences in ',timeFrame)) + theme(axis.text.x = element_text(angle=90, hjust=1), text = element_text(size=16))
#     
#     return(p)
#   }
#   
#   else if (highLevel == 'Failed Part') {
#     
#     keepCats <- itemsInPareto(dataFrame[dataFrame[,'FailCat'] == filterCategory, ],subCat,topPercent)
#     aggString <- paste('Record',subCat,sep='~')
#     temp <- with(dataFrame[dataFrame[,subCat] %in% keepCats, ], aggregate(as.formula(aggString),FUN=sum))
#     colnames(temp) <- c('Category','Record')
#     p <- ggplot(temp, aes(x=reorder(Category,-Record), y=Record)) + geom_bar(stat='identity') + labs(title = paste(highLevel,' = ',filterCategory), x = lowLevel, y = paste('Occurrences in ',timeFrame)) + theme(axis.text.x = element_text(angle=90, hjust=1), text = element_text(size=16))
#     
#     return(p)
#   }
#   
#   else if (highLevel == lowLevel) {
#     
#     keepCats <- itemsInPareto(dataFrame[dataFrame[,]])
#     
#   }
  
  
}

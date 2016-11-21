makeRootCausePareto <- function(highLevel, filterCategory, lowLevel, timeFrame, earlyFailOnly, topPercent = 0.8) {
  
  dataFrame <- subsetBasedOnTimeFrame(timeFrame)
  
  if(earlyFailOnly) {
    
    dataFrame <- dataFrame[dataFrame[,'FailType'] %in% c('DOA','ELF','SDOA','SELF'), ]
  }
  
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
  
  if(earlyFailOnly) {
    aggString <- paste('Record',paste(subCat,'FailType',sep='+'),sep='~')
  }
  else {
    aggString <- paste('Record',subCat,sep='~')
  }
  
  if(bigCat == subCat) {
    
    keepCats <- itemsInPareto(dataFrame,subCat,topPercent)
    temp <- with(dataFrame[dataFrame[,subCat] %in% keepCats, ], aggregate(as.formula(aggString), FUN=sum))
    colnames(temp)[1] <- 'Category'
    plotTitle <- highLevel
  }

  else {
    
    keepCats <- itemsInPareto(dataFrame[dataFrame[,bigCat] == filterCategory, ],subCat,topPercent)
    temp <- with(dataFrame[dataFrame[,subCat] %in% keepCats, ], aggregate(as.formula(aggString),FUN=sum))
    colnames(temp)[1] <- 'Category'
    plotTitle <- paste(highLevel,' = ',filterCategory)
  }
  
  if(length(temp[,1])==0) {
    return(plot(x=1:10, type='n', axes=F, xlab='',ylab='',main='No Data Available'))
  }
  else {
    
    if(earlyFailOnly) {
      temp <- merge(temp, with(temp, aggregate(Record~Category, FUN=sum)), by='Category')
      colnames(temp) <- c('Category','FailType','Record','Total')
      p <- ggplot(temp, aes(x=reorder(Category,-Total), y=Record, fill=FailType, order=FailType)) + geom_bar(stat='identity') + labs(title = plotTitle, x = lowLevel, y = paste('Occurrences in ',timeFrame)) + theme(axis.text.x = element_text(angle=90, hjust=1), text = element_text(size=18)) + scale_fill_manual(values=c('darkgreen','darkseagreen','dodgerblue','lightskyblue'))
    }
    else {
      p <- ggplot(temp, aes(x=reorder(Category,-Record), y=Record)) + geom_bar(stat='identity') + labs(title = plotTitle, x = lowLevel, y = paste('Occurrences in ',timeFrame)) + theme(axis.text.x = element_text(angle=90, hjust=1), text = element_text(size=18))
    }
    return(p)
  }
  
}

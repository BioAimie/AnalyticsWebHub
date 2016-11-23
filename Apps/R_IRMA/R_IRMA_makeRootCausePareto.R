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
  } else {
    
    aggString <- paste('Record',subCat,sep='~')
  }
  
  if(bigCat == subCat) {
    
    keepCats <- itemsInPareto(dataFrame,subCat,topPercent)
    temp <- with(dataFrame[dataFrame[,subCat] %in% keepCats, ], aggregate(as.formula(aggString), FUN=sum))
    colnames(temp)[1] <- 'Category'
    plotTitle <- highLevel
  } else {
    
    keepCats <- itemsInPareto(dataFrame[dataFrame[,bigCat] == filterCategory, ], subCat, topPercent)
    temp <- with(dataFrame[dataFrame[,subCat] %in% keepCats, ], aggregate(as.formula(aggString),FUN=sum))
    colnames(temp)[1] <- 'Category'
    plotTitle <- paste(highLevel,' = ',filterCategory)
  }
  
  if(length(temp[,1])==0) {
    
    return(plot(x=1:10, type='n', axes=F, xlab='',ylab='',main='No Data Available'))
  } else {
    
    if(earlyFailOnly) {
      temp <- merge(temp, with(temp, aggregate(Record~Category, FUN=sum)), by='Category')
      colnames(temp) <- c('Category','FailType','Record','Total')
      temp$CatLevel <- factor(temp$Category, levels = temp[with(temp, order(Total, decreasing = TRUE)), 'Category'])
  
      p <- ggplot(temp[with(temp, order(FailType)), ], aes(x=CatLevel, y=Record, fill=FailType)) + geom_bar(stat='identity') + labs(title = plotTitle, x = lowLevel, y = 'Occurrences') + theme(text = element_text(size=20, face='bold'), axis.text=element_text(size=18, color='black'), axis.text.x = element_text(angle=90, hjust=1), panel.background=element_rect(fill='white', color='white')) + scale_fill_manual(values=createPaletteOfVariableLength(temp, 'FailType'), name='')
    } else {
      
      p <- ggplot(temp, aes(x=reorder(Category,-Record), y=Record, fill='empty')) + geom_bar(stat='identity') + labs(title = plotTitle, x = lowLevel, y = 'Occurrences') + theme(text = element_text(size=20, face='bold'), axis.text=element_text(size=18, color='black'), axis.text.x = element_text(angle=90, hjust=1), panel.background=element_rect(fill='white', color='white')) + scale_fill_manual(values=createPaletteOfVariableLength(data.frame(Category='Category', Fill='empty'), 'Fill'), guide=FALSE)
    }
    return(p)
  }
  
}

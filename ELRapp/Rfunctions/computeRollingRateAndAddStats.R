# ASSUMES THAT DENOM AND NUM FRAMES ARE FORMATTED SIMILARLY (i.e. DATEGROUP, VERSION, KEY, RECORDEDVALUE, RECORD), 
# THOUGH THE VERSION AND RECORDEDVALUE FIELDS ARE OPTIONAL --- RECORD IS ALWAYS THE ONE TO AGGREGATE
computeRollingRateAndAddStats <- function(denomFrame, numFrame, denomAggCols, numAggCols, joinCols, rollPeriods, lagEnd, startDate, review=TRUE) {
  
  # if the value is a review/pass, then use the actual denomFrame, otherwise craft a new one so that NA values don't skew the average
  if(review==FALSE) {
    denomFrame <- numFrame
    denomFrame[,'Record'] <- with(denomFrame, ifelse(is.na(Record), 0, 1))
  }
  
  # use the input parameters to create the correct input for the aggregate function
  agg.denom.string <- paste('Record', paste(denomAggCols, collapse='+'), sep='~')
  agg.num.string <- paste('Record', paste(numAggCols, collapse='+'), sep='~')
  
  # find the sum of Records in each combo for the numerator and denominator
  denom.agg <- with(denomFrame, aggregate(as.formula(agg.denom.string), FUN=sum))
  num.agg <- with(numFrame, aggregate(as.formula(agg.num.string), FUN=sum))
  
  # use joinCols to merge the denominator and numerator, then merge and find a rate
  agg.sum <- merge(denom.agg, num.agg, by=joinCols, all.x=TRUE)
  colnames(agg.sum)[grep('Record\\.', colnames(agg.sum))] <- c('denomRecord','numRecord')
  
  # decide which columns and rows to keep 
  colNames <- colnames(agg.sum)[grep(paste(numAggCols, collapse='|'), colnames(agg.sum))]
  colNames <- colNames[!(colNames %in% colNames[grep('\\.x', colNames)])]
  keepCols <- c(colNames, 'denomRecord','numRecord')
  agg.sum <- agg.sum[as.character(agg.sum[,'DateGroup']) >= startDate, keepCols] 

  if(length(keepCols[grep('\\.y', keepCols)]) > 0) {
    fixedNames <- sapply(1:length(strsplit(keepCols[grep('\\.y', keepCols)],'\\.')), function(x) strsplit(keepCols[grep('\\.y', keepCols)],'\\.')[[x]][1]) 
    colnames(agg.sum)[grep('\\.y', colnames(agg.sum))] <- fixedNames
  }
  
  # make sure the data are ordered correctly and then find the rolling average, though this must be done for each combo in the data
  rolledFrame <- as.data.frame(NULL)
  agg.sum <- agg.sum[with(agg.sum, order(DateGroup)), ]
  partitionVec <- colnames(agg.sum)[!(colnames(agg.sum) %in% c('DateGroup','denomRecord','numRecord'))]
  
  if(length(partitionVec) == 3) {
    levelOne <- partitionVec[1]
    levelOneCategories <- as.character(unique(agg.sum[,levelOne]))
    
    for (i in 1:length(levelOneCategories)) {
      
      levelOneFrame <- agg.sum[agg.sum[,levelOne]==levelOneCategories[i], ]
      levelTwo <- partitionVec[2]
      levelTwoCategories <- as.character(unique(levelOneFrame[,levelTwo]))
      
      for (j in 1:length(levelTwoCategories)) {
        
        levelTwoFrame <- levelOneFrame[levelOneFrame[,levelTwo]==levelTwoCategories[j], ]
        if(length(levelTwoFrame[,1]) < rollPeriods) { next() }
        levelThree <- partitionVec[3]
        levelThreeCategories <- as.character(unique(levelTwoFrame[,levelThree]))
        
        for (k in 1:length(levelThreeCategories)) {
          
          levelThreeFrame <- levelTwoFrame[levelTwoFrame[,levelThree]==levelThreeCategories[k], ]
          if(length(levelThreeFrame[,1]) < rollPeriods) { next() }
          rolledRecords <- as.data.frame(cbind(with(levelThreeFrame, rollapply(denomRecord, rollPeriods, FUN=sum, na.rm=TRUE)),with(levelThreeFrame, rollapply(numRecord, rollPeriods, FUN=sum, na.rm=TRUE))))
          colnames(rolledRecords) <- c('denomRecord','numRecord')
          temp <- cbind(levelThreeFrame[rollPeriods:length(levelThreeFrame[,'DateGroup']), c('DateGroup',partitionVec[1],partitionVec[2],partitionVec[3])], rolledRecords)
          temp[,'RollingRate'] <- with(temp, numRecord/denomRecord)
          avg <- with(temp[as.character(temp[,'DateGroup']) <= lagEnd, ], mean(RollingRate, na.rm = TRUE))
          sdv <- with(temp[as.character(temp[,'DateGroup']) <= lagEnd, ], sd(RollingRate, na.rm = TRUE))
          temp[,'average'] <- avg
          temp[,'sdev'] <- sdv
          temp <- temp[,c('DateGroup',partitionVec[1],partitionVec[2],partitionVec[3],'RollingRate','average','sdev')]
          rolledFrame <- rbind(rolledFrame, temp)
        }
      }
    }
    
    return(rolledFrame)
  }
  
  else if(length(partitionVec) == 2) {
    levelOne <- partitionVec[1]
    levelOneCategories <- as.character(unique(agg.sum[,levelOne]))
    
    for (i in 1:length(levelOneCategories)) {
      
      levelOneFrame <- agg.sum[agg.sum[,levelOne]==levelOneCategories[i], ]
      levelTwo <- partitionVec[2]
      levelTwoCategories <- as.character(unique(levelOneFrame[,levelTwo]))
      
      for (j in 1:length(levelTwoCategories)) {
                  
        levelTwoFrame <- levelOneFrame[levelOneFrame[,levelTwo]==levelTwoCategories[j], ]
        rolledRecords <- as.data.frame(cbind(with(levelTwoFrame, rollapply(denomRecord, rollPeriods, FUN=sum, na.rm=TRUE)),with(levelTwoFrame, rollapply(numRecord, rollPeriods, FUN=sum, na.rm=TRUE))))
        colnames(rolledRecords) <- c('denomRecord','numRecord')
        temp <- cbind(levelTwoFrame[rollPeriods:length(levelTwoFrame[,'DateGroup']), c('DateGroup',partitionVec[1],partitionVec[2])], rolledRecords)
        temp[,'RollingRate'] <- with(temp, numRecord/denomRecord)
        avg <- with(temp[as.character(temp[,'DateGroup']) <= lagEnd, ], mean(RollingRate, na.rm = TRUE))
        sdv <- with(temp[as.character(temp[,'DateGroup']) <= lagEnd, ], sd(RollingRate, na.rm = TRUE))
        temp[,'average'] <- avg
        temp[,'sdev'] <- sdv
        temp <- temp[,c('DateGroup',partitionVec[1],partitionVec[2],'RollingRate','average','sdev')]
        rolledFrame <- rbind(rolledFrame, temp)
      }
    }
    
    return(rolledFrame)
  }
  
  else if(length(partitionVec) == 1) {
    
    levelOne <- partitionVec[1]
    levelOneCategories <- as.character(unique(agg.sum[,levelOne]))
    
    for (i in 1:length(levelOneCategories)) {
      
      levelOneFrame <- agg.sum[agg.sum[,levelOne]==levelOneCategories[i], ]
      rolledRecords <- as.data.frame(cbind(with(levelOneFrame, rollapply(denomRecord, rollPeriods, FUN=sum, na.rm=TRUE)),with(levelOneFrame, rollapply(numRecord, rollPeriods, FUN=sum, na.rm=TRUE))))
      colnames(rolledRecords) <- c('denomRecord','numRecord')
      temp <- cbind(levelOneFrame[rollPeriods:length(levelOneFrame[,'DateGroup']), c('DateGroup',partitionVec[1])], rolledRecords)
      temp[,'RollingRate'] <- with(temp, numRecord/denomRecord)
      avg <- with(temp[as.character(temp[,'DateGroup']) <= lagEnd, ], mean(RollingRate, na.rm = TRUE))
      sdv <- with(temp[as.character(temp[,'DateGroup']) <= lagEnd, ], sd(RollingRate, na.rm = TRUE))
      temp[,'average'] <- avg
      temp[,'sdev'] <- sdv
      temp <- temp[,c('DateGroup',partitionVec[1],'RollingRate','average','sdev')]
      rolledFrame <- rbind(rolledFrame, temp)
    }
    
    return(rolledFrame)
  }
  
  else {
    stop('The function is not written to accomodate data of this structure yet. Please update the function as neccessary to make it more robust!')
  }
}
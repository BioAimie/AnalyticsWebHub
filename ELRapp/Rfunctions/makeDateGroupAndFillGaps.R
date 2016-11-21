#  VERY IMPORTANT: DATAFRAMES SHOULD BE FORMATTED AS - YEAR, MONTH, WEEK, VERSION, KEY, RECORDEDVALUE, RECORD
#  THE partitionVec PARAMETER SHOULD ALWAYS GO FROM LEAST TO MOST SPECIFIC (i.e. VERSION-KEY-RECORDEDVALUE) 

makeDateGroupAndFillGaps <- function(calendarFrame, dataFrame, bigGroup, subGroup, partitionVec, startString) {
  
  # the time periods that are used to make date groups
  big <- bigGroup
  small <- subGroup
  
  # format the date groups correctly and make sure that none are repeated, also, choose a starting point
  base <- ifelse(calendarFrame[ ,small] < 10, paste(calendarFrame[ ,big],'-0',calendarFrame[ ,small],sep=''), 
                 paste(calendarFrame[ ,big],'-',calendarFrame[ ,small],sep=''))
  base <- as.data.frame(unique(base[base>=startString]))  
  colnames(base) <- 'DateGroup'
  
  # if the time periods do not exist in the input data frame, then do not continue, otherwise make date groups
  possibleErrorBig <- tryCatch(dataFrame[,big], error=function(e) e)
  possibleErrorSmall <- tryCatch(dataFrame[,small], error=function(e) e)
  
  if(inherits(possibleErrorBig,'error') & inherits(possibleErrorSmall,'error')) {
    stop("Either the data frame is incorrectly formatted, or the bigGroup/smallGroup parameters are incorrectly specified")
  }
  else {
    dataFrame$DateGroup <- ifelse(dataFrame[ ,small] < 10, paste(dataFrame[ ,big],'-0',dataFrame[ ,small],sep=''), 
                                  paste(dataFrame[ ,big],'-',dataFrame[ ,small],sep=''))    
  }
  
  # create an empty data frame to use for output
  out <- as.data.frame(NULL)
  
  # if there are three levels in the partition vector (i.e. Version, Key, RecordedValue)
  if(length(partitionVec)==3) {
    # the top level is Version, get all versions
    topCol <- partitionVec[1]
    topVars <- as.character(unique(dataFrame[ ,topCol]))
    
    for (i in 1:length(topVars)) {
      # for each version, make a sub-frame of each key
      top <- dataFrame[dataFrame[,topCol]==topVars[i] & as.character(dataFrame[,'DateGroup'])>=startString, ]
      midCol <- partitionVec[2]
      midVars <- as.character(unique(dataFrame[ ,midCol]))
      
      for (j in 1:length(midVars)) {
        # for each key, make a sub-frame of each recorded value
        mid <- top[top[,midCol]==midVars[j], ]
        botCol <- partitionVec[3]
        botVars <- as.character(unique(top[,botCol]))
        
        for (k in 1:length(botVars)) {
          # iterate for the unique combo of Version+Key+RecordedValue and fill in date gaps
          bot <- mid[mid[,botCol]==botVars[k], ]
          temp <- merge(base, bot, by='DateGroup', all=TRUE)
          temp <- temp[ , c('DateGroup',partitionVec[1],partitionVec[2],partitionVec[3],'Record')]
          temp[is.na(temp[,partitionVec[1]]),partitionVec[1]] <- topVars[i]
          temp[is.na(temp[,partitionVec[2]]),partitionVec[2]] <- midVars[j]
          temp[is.na(temp[,partitionVec[3]]),partitionVec[3]] <- botVars[k]
          temp[is.na(temp[,'Record']),'Record'] <- 0
          temp <- temp[!is.na(temp[,'DateGroup']), ]
          # keep binding on to the output frame such that each unique combo gets all dates filled in
          out <- rbind(out, temp)
        }      
      }
    }
    return(out)
  }
  # do the same thing as the if statement above, but only for two levels, not three
  else if(length(partitionVec)==2) {
    topCol <- partitionVec[1]
    topVars <- as.character(unique(dataFrame[ ,topCol]))
    
    for (i in 1:length(topVars)) {
      top <- dataFrame[dataFrame[,topCol]==topVars[i] & as.character(dataFrame[,'DateGroup'])>=startString, ]
      midCol <- partitionVec[2]
      midVars <- as.character(unique(dataFrame[ ,midCol]))
      
      for (j in 1:length(midVars)) {
        mid <- top[top[,midCol]==midVars[j], ]
        temp <- merge(base, mid, by='DateGroup', all=TRUE)
        temp <- temp[ , c('DateGroup',partitionVec[1],partitionVec[2],'Record')]
        temp[is.na(temp[,partitionVec[1]]),partitionVec[1]] <- topVars[i]
        temp[is.na(temp[,partitionVec[2]]),partitionVec[2]] <- midVars[j]
        temp[is.na(temp[,'Record']),'Record'] <- 0
        temp <- temp[!is.na(temp[,'DateGroup']), ]
        out <- rbind(out, temp)     
      }
    }
    return(out)
  }
  # do the same thing as above, but for only one level
  else if(length(partitionVec)==1) {
    topCol <- partitionVec[1]
    topVars <- as.character(unique(dataFrame[ ,topCol]))
    
    for (i in 1:length(topVars)) {
      top <- dataFrame[dataFrame[,topCol]==topVars[i] & as.character(dataFrame[,'DateGroup'])>=startString, ]
      temp <- merge(base, top, by='DateGroup', all=TRUE)
      temp <- temp[ , c('DateGroup',partitionVec[1],'Record')]
      temp[is.na(temp[,partitionVec[1]]),partitionVec[1]] <- topVars[i]
      temp[is.na(temp[,'Record']),'Record'] <- 0
      temp <- temp[!is.na(temp[,'DateGroup']), ]
      out <- rbind(out, temp)     
    }
    return(out)
  }
  # error catch
  else {
    stop('The partitionVec parameter is not correctly specified... check the function!')
  }
}
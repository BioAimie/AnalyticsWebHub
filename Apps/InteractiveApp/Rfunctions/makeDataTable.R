makeDataTable <- function(dataSetName, startDate, endDate, dateType, partNum = NULL, ncrType = NULL, whereType = NULL, problemType = NULL, failType = NULL) {
  #################################################
  # dataSetName = 'NCRParts'
  # startDate = '2015-09-01'
  # endDate = '2016-08-31'
  # dateType = 'Year-Week'
  # partNum = ''
  # ncrType = c('BioReagents', "Cal/PM", "FA1.5 Instrument WIP", "FA2.0 Instrument WIP", "HTFA Instrument WIP", "Torch Instrument WIP", "Instrument Production WIP", "Raw Material")
  # whereType = NULL
  ###############################################

  #get correct data set based on dateType
  dataSet <- get(paste0(dataSetName, '.df'))
  #get start and end week or month or quarter based on input date range and input dateType
  if(dateType == 'Year-Week') {
    dataSet$DateGroup <- ifelse(dataSet$Week < 10, paste(dataSet$Year, paste0('0', dataSet$Week), sep='-'), paste(dataSet$Year, dataSet$Week, sep='-'))
    start <- calendar.week[calendar.week$Date == startDate, 'DateGroup']
    end <- calendar.week[calendar.week$Date == endDate, 'DateGroup']
  } else if(dateType == 'Year-Month') {
    start <- calendar.month[calendar.month$Date == startDate, 'DateGroup']
    end <- calendar.month[calendar.month$Date == endDate, 'DateGroup']
  } else if(dateType == 'Year-Quarter') {
    start <- calendar.quarter[calendar.quarter$Date == startDate, 'DateGroup']
    end <- calendar.quarter[calendar.quarter$Date == endDate, 'DateGroup']
  }
  
  #subset the data based on date range
  dataSubSet <- subset(dataSet, as.character(DateGroup) >= start & as.character(DateGroup) <= end) 
  
  #if NCR type is not null, subset based on NCR type
  if(!is.null(ncrType)){
    dataSubSet <- subset(dataSubSet, Type %in% ncrType)
  } 
  
  #if parts dataframe, subset based on part numbers input or top 10 parts affected as default
  if(dataSetName == 'NCRParts') {
    if(is.null(partNum)) {
      topParts <- with(dataSubSet, aggregate(Record~PartAffected, FUN=sum))
      topParts <- topParts[with(topParts, order(-Record)),]
      top10 <- as.character(head(topParts, 10)[,'PartAffected'])
      #subset data
      dataSubSet <- subset(dataSubSet, PartAffected %in% top10)
    } else if(partNum == '') {
      topParts <- with(dataSubSet, aggregate(Record~PartAffected, FUN=sum))
      topParts <- topParts[with(topParts, order(-Record)),]
      top10 <- as.character(head(topParts, 10)[,'PartAffected'])
      #subset data
      dataSubSet <- subset(dataSubSet, PartAffected %in% top10)
    } else {
      #split comma separated list into multiple strings
      partSeparated <- unlist(strsplit(partNum, split=','))
      #remove any spaces
      partSeparated <- gsub(' ','',partSeparated)
      #make it uppercase
      partSeparated <- toupper(partSeparated)
      #subset data
      dataSubSet <- subset(dataSubSet, PartAffected %in% partSeparated)
    }
  }
  
  #subset by where found for whereType and failType for Fail cat
  if(dataSetName == 'NCRWhereProblem' | dataSetName == 'NCRFail') {
    if(!is.null(whereType)) {
      if(whereType != 'All') 
        dataSubSet <- subset(dataSubSet, as.character(WhereFound) == whereType)
    }
    
    if(dataSetName == 'NCRFail') {
      dataSubSet <- subset(dataSubSet, as.character(ProblemArea) == problemType)
      
      if(failType != 'All') {
        dataSubSet <- subset(dataSubSet, as.character(FailureCategory) == failType)   
      }
    }
  }
  
  return(dataSubSet)
}
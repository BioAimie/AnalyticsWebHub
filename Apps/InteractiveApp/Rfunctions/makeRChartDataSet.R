makeRChartDataSet <- function(dataSetName, startDate, endDate, chartType, dateType, groupBy = NULL, partNum = NULL, 
                       ncrType = NULL, whereType = NULL, problemType = NULL, failType = NULL, currWhere = NULL) {
  
  # dataSetName = 'NCRFail'
  # startDate = '2014-08-01'
  # endDate = '2016-11-09'
  # chartType = 'Bar'
  # dateType = 'Year-Week'
  # groupBy = 'FailureCategory'
  # partNum = NULL
  # ncrType = c("BioReagents","Cal/PM","FA1.5 Instrument WIP","FA2.0 Instrument WIP","HTFA Instrument WIP","Torch Instrument WIP","Instrument Production WIP","Raw Material")
  # whereType = 'All'
  # problemType = 'Fails QC Analysis'
  # failType = 'All'
  # currWhere = 'All Where Found Categories'

  #------Prep the data-------------------------------------------------------------------------------------------------------------------------
  
  #get correct data set based on dateType
  #get start and end week or month or quarter based on input date range and input dateType
  if(dateType == 'Year-Week') {
    dataSet <- get(paste0(dataSetName, '.week'))
    start <- calendar.week[calendar.week$Date == startDate, 'DateGroup']
    end <- calendar.week[calendar.week$Date == endDate, 'DateGroup']
    cal <- with(subset(calendar.week, as.character(DateGroup) >= start & as.character(DateGroup) <= end), aggregate(Date~DateGroup, FUN=max))
    cal$Date <- (cal$Date + 1)
  } else if(dateType == 'Year-Month') {
    dataSet <- get(paste0(dataSetName, '.month'))
    start <- calendar.month[calendar.month$Date == startDate, 'DateGroup']
    end <- calendar.month[calendar.month$Date == endDate, 'DateGroup']
    cal <- with(subset(calendar.month, as.character(DateGroup) >= start & as.character(DateGroup) <= end), aggregate(Date~DateGroup, FUN=max))
  } else if(dateType == 'Year-Quarter') {
    dataSet <- get(paste0(dataSetName, '.quarter'))
    start <- calendar.quarter[calendar.quarter$Date == startDate, 'DateGroup']
    end <- calendar.quarter[calendar.quarter$Date == endDate, 'DateGroup']
    cal <- with(subset(calendar.quarter, as.character(DateGroup) >= start & as.character(DateGroup) <= end), aggregate(Date~DateGroup, FUN=max))
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
      if(!('All' %in% whereType)) {
        dataSubSet <- subset(dataSubSet, as.character(WhereFound) %in% whereType)
      } else {
        if(currWhere == 'Current Where Found Categories') {
          currentWhereFoundCats <- c('Array Manufacture', 'Customer', 'Engineering', 'Final QC', 'Formulation', 'Functional Testing', 'Incoming Inspection',
                                     'Instrument Service', 'Oligo Manufacture', 'Outgoing Inspection', 'Pouch Manufacture', 'SMI: Quality Inspection',
                                     'Sniffing/Packaging', 'Tooling: WIP', 'Warehouse Receiving')
          dataSubSet <- subset(dataSubSet, as.character(WhereFound) %in% currentWhereFoundCats)
        }
      }
    }
    
    if(!is.null(problemType)) {
      if(!('All' %in% problemType)) 
        dataSubSet <- subset(dataSubSet, as.character(ProblemArea) %in% problemType)
    }
    
    if(dataSetName == 'NCRFail') {
      if(!('All' %in% failType)) {
        dataSubSet <- subset(dataSubSet, as.character(FailureCategory) == failType)   
      }
    }
  }
  
  #if dataset is empty
  if(nrow(dataSubSet) < 1) {
    if(chartType == 'Bar') {
      emptyData <- data.frame(DateGroup = 'No Data Found', Record = 0)
    } else if(chartType == 'Line' || chartType == 'Area'){
      emptyData <- data.frame(Date = '2000-01-01', Record = 0)
    }
    return(emptyData)
  }
  
  #aggregate data based on groupBy variable
  if(!is.null(groupBy)) {
    dataSubSet.agg <- with(dataSubSet, aggregate(Record~DateGroup+dataSubSet[, groupBy], FUN=sum))
    colnames(dataSubSet.agg)[grepl('groupBy', colnames(dataSubSet.agg))] <- groupBy
    
    #get rid of any categories that are all zero
    cats <- unique(as.character(dataSubSet.agg[, groupBy]))
    keepCat <- c()
    for(i in 1:length(cats)) {
      temp <- subset(dataSubSet.agg, dataSubSet.agg[, groupBy] == cats[i])
      checkSum <- sum(temp$Record)
      if(checkSum > 0) {
        keepCat <- c(keepCat, cats[i])
      }
    }
    dataSubSet.agg <- subset(dataSubSet.agg, dataSubSet.agg[, groupBy] %in% keepCat)
    
  } else {
    dataSubSet.agg <- with(dataSubSet, aggregate(Record~DateGroup, FUN=sum))
  }
  
  if(chartType=='Line' || chartType=='Area') {
    #make frame with first date of week and dategroup
    dataSubSet.agg <- merge(dataSubSet.agg, cal)
    #change date to date format 
    dataSubSet.agg$Date <- as.Date(dataSubSet.agg$Date)
  }
  
  return(dataSubSet.agg)
}
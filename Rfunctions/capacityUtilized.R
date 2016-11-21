capacityUtilized <- function(dataFrame, workDay=14, byDay=TRUE) {
  
  # get rid of instrument QC runs and service runs as best as possible (also burn ins and engineering runs as much as possible)
#   instQC.toRemove <- dataFrame[grep('^FA|NewBuild|PostRepair|Service|service', dataFrame[,'SampleId']),'PouchSerialNumber']
#   dataFrame <- dataFrame[!(dataFrame[,'PouchSerialNumber'] %in% instQC.toRemove),]
#   dataFrame[,'Record'] <- 1
  
  # most runs to keep is 180 days
  dataFrame[,'Date'] <- as.Date(dataFrame[,'StartTime'], tz = 'MST')
  dataFrame <- dataFrame[dataFrame[,'Date'] > Sys.Date() - 180, ]
  
  # remove serial numbers where there is a low average run count per week
#   sumRuns <- with(dataFrame, aggregate(Record~InstrumentSerialNumber+Week, FUN=sum))
#   avgRuns <- with(sumRuns, aggregate(Record~InstrumentSerialNumber, FUN=mean))
#   keepInsts <- avgRuns[avgRuns$Record > 5, 'InstrumentSerialNumber']
  
#   dataFrame <- dataFrame[dataFrame[,'RunStatus']=='Completed' & dataFrame[,'InstrumentSerialNumber'] %in% keepInsts, 
#                          c('InstrumentSerialNumber','Year','Week','SampleId','StartTime','MinutesRun')]
  dungeon <- dataFrame[dataFrame[,'RunStatus']=='Completed' & dataFrame[,'InstrumentSerialNumber'] %in% dungInsts$Instrument, 
                         c('InstrumentSerialNumber','Week','SampleId','StartTime','MinutesRun','Date')]
  pouchqc <- dataFrame[grep('^QC_|PouchQC',dataFrame[,'SampleId']), 
                       c('InstrumentSerialNumber','Week','SampleId','StartTime','MinutesRun','RunStatus','Date')]
  pouchqc <- pouchqc[pouchqc$RunStatus=='Completed', c('InstrumentSerialNumber','Week','SampleId','StartTime','MinutesRun','Date')]
  dataFrame <- rbind(dungeon, pouchqc)  
  dataFrame[,'Key'] <- NA
  dataFrame[grep('^QC_|PouchQC',dataFrame[,'SampleId']), 'Key'] <- 'PouchQC'
  dataFrame[is.na(dataFrame[,'Key']),'Key'] <- 'Dungeon'
  dataFrame[,'Record'] <- 1
  
  if(byDay) {
    
    subFrame <- dataFrame
    
    # for each week, look at how many unique instruments are running
    instByDate <- unique(subFrame[,c('InstrumentSerialNumber','Week','Key')])
    instByDate$Record <- 1
    instByDate <- with(instByDate, aggregate(Record~Week+Key, FUN=sum))
    colnames(instByDate) <- c('Week','Key','InstsRunning')
    
    # assume a mean run time determined by the runs.df table (completed runs only) and a 1.1 factor for time between runs
    avgRunDurationHours <- 1.1*mean(dataFrame[,'MinutesRun'], na.rm=TRUE)/60
    theoreticalRunLoad <- workDay/avgRunDurationHours
    
    # for each day, determine the theoretical maximum capacity for the instruments
    instByDate$TheoreticalCapacity <- theoreticalRunLoad*instByDate$InstsRunning
    
    # take the data and aggregate the number of runs by date, multiply by the average run time
    totalRuns <- with(subFrame, aggregate(Record~Date+Week+Key, FUN=sum))
    totalRuns$ActualRunHours <- totalRuns$Record*avgRunDurationHours
    
    # merge the data to get a "% capacity utilized"
    out <- merge(totalRuns, instByDate, by=c('Week','Key'))
    out$CapacityUtilized <- out$ActualRunHours/out$TheoreticalCapacity
    
    # take a 5-period rolling average (work week)... do not fill in data gaps since I don't want zeroes in the data
    # do this for both dungeon and qc keys
    dungeon <- out[out$Key=='Dungeon', ]
    dungeon <- dungeon[with(dungeon, order(Date)), ]
    dungeon <- cbind(dungeon[5:length(dungeon$Date), ], rollapply(dungeon$CapacityUtilized, 5, FUN=mean))
    colnames(dungeon)[length(colnames(dungeon))] <- 'RollingRate'
    pouchqc <- out[out$Key=='PouchQC', ]
    pouchqc <- pouchqc[with(pouchqc, order(Date)), ]
    pouchqc <- cbind(pouchqc[5:length(pouchqc$Date), ], rollapply(pouchqc$CapacityUtilized, 5, FUN=mean))
    colnames(pouchqc)[length(colnames(pouchqc))] <- 'RollingRate'
    
    out <- rbind(dungeon, pouchqc)
  }
  
  # if it's not by day, assume it's by hour... then take the last three weeks of data and plot by day
  else {
    
    subFrame <- dataFrame[dataFrame[,'Date'] > Sys.Date() - 21, ]
    
    # for each week, look at how many unique instruments are running
    instByDate <- unique(subFrame[,c('InstrumentSerialNumber','Week','Key')])
    instByDate$Record <- 1
    instByDate <- with(instByDate, aggregate(Record~Week+Key, FUN=sum))
    colnames(instByDate) <- c('Week','Key','InstsAbleToRun')
    
    # for each hour, look at how many insturments are running
    subFrame$Hour <- hour(subFrame$StartTime)
    instByHour <- unique(subFrame[,c('Key','Date','Week','Hour','InstrumentSerialNumber')])
    instByHour$Record <- 1
    instByHour <- with(instByHour, aggregate(Record~Key+Date+Week+Hour, FUN=sum))
    colnames(instByHour) <- c('Key','Date','Week','Hour','InstRunningInHour')
    
    # combine the data, then find a capacility utlized by hour by dividing the number of instruments run in the hour
    # by the total instruments available that day (week).
    out <- merge(instByHour, instByDate, by=c('Key','Week'))
    out$CapacityUtilized <- with(out, InstRunningInHour/InstsAbleToRun)
    
    # take an average for hourly capacity utilized rate
    out <- with(out, aggregate(CapacityUtilized~Key+Hour, FUN=mean))
  }
  
  return(out)
}

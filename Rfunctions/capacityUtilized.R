capacityUtilized <- function(dataFrame, workDay=14, byDay=TRUE, byVersion=FALSE) {
  
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
  
  # remove new build and service runs
  serv.build <- dataFrame[grep('Service|NewBuild', dataFrame$SampleId), 'PouchSerialNumber']
  dataFrame <- dataFrame[!(dataFrame[,'PouchSerialNumber'] %in% serv.build), ]
  
  dungeon <- dataFrame[dataFrame[,'RunStatus']=='Completed' & dataFrame[,'InstrumentSerialNumber'] %in% dungInsts$Instrument, 
                         c('InstrumentSerialNumber','Week','SampleId','StartTime','InstrumentProtocolVersion','MinutesRun','Date')]
  pouchqc <- dataFrame[grep('^QC_|PouchQC',dataFrame[,'SampleId']), 
                       c('InstrumentSerialNumber','Week','SampleId','StartTime','InstrumentProtocolVersion','MinutesRun','RunStatus','Date')]
  pouchqc <- pouchqc[pouchqc$RunStatus=='Completed', c('InstrumentSerialNumber','Week','SampleId','StartTime','InstrumentProtocolVersion','MinutesRun','Date')]
  dataFrame <- rbind(dungeon, pouchqc)
  dataFrame[,'Key'] <- NA
  dataFrame[grep('^QC_|PouchQC',dataFrame[,'SampleId']), 'Key'] <- 'PouchQC'
  dataFrame[is.na(dataFrame[,'Key']),'Key'] <- 'Dungeon'
  dataFrame[,'Record'] <- 1
  
  if(byDay==TRUE & byVersion==FALSE) {
    
    subFrame <- dataFrame
    
    # for each week, look at how many unique instruments are running
    instByDate <- unique(subFrame[,c('InstrumentSerialNumber','Week','Key')])
    instByDate$Record <- 1
    instByDate <- with(instByDate, aggregate(Record~Week+Key, FUN=sum))
    colnames(instByDate) <- c('Week','Key','InstsRunning')
    
    # assume a mean run time determined by the runs.df table (completed runs only) and a 1.15 factor for time between runs
    avgRunDurationHours <- 1.15*mean(dataFrame[,'MinutesRun'], na.rm=TRUE)/60
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
  
  # if it's by version, that's for the dungeon and it should be handled differently
  else if(byVersion) {
    
    dataFrame <- dataFrame[dataFrame[,'Date'] >= Sys.Date() - 30 & dataFrame$Key=='Dungeon', ]

    # how many working days are there in the last 30 days?
    dataFrame$WeekDay <- weekdays(dataFrame$Date, TRUE)
    off.fri <- with(dataFrame[dataFrame$Date %in% unique(dataFrame[dataFrame$WeekDay=='Fri', 'Date']),], aggregate(Record~Date, FUN=sum))
    on.fri <- off.fri[off.fri$Record > median(off.fri$Record), 'Date']
    subFrame <- dataFrame[dataFrame$WeekDay %in% c('Mon','Tue','Wed','Thu') | dataFrame$Date %in% on.fri, ]
    working.days <- length(unique(subFrame$Date))
    
    # how many runs can be done on an average day?
    avg.run.time <- mean(subFrame$MinutesRun)/60
    hours.per.day <- 9
    runs.per.day <- hours.per.day/(avg.run.time*1.15)
    
    # how many instruments are running during the thirty day period (do some tricks to make it more accurate!)
    work.dates <- unique(subFrame$Date)[order(unique(subFrame$Date))]
    inst.dates <- work.dates[seq(3, length(work.dates), 3)]
    if(max(work.dates) > max(inst.dates)) {
      inst.dates[length(inst.dates)] <- max(work.dates)
    }
    subFrame$index <- cut(subFrame$Date, breaks = inst.dates, right = TRUE, left = TRUE, labels = seq(1, length(inst.dates)-1, 1))
    subFrame$index <- as.numeric(as.character(subFrame$index))
    subFrame[is.na(subFrame$index), 'index'] <- 0
    subFrame$Version <- ifelse(subFrame$InstrumentProtocolVersion==2, 'FA1.5', ifelse(substring(subFrame$InstrumentSerialNumber, 1, 2) %in% c('FA','2F'), 'FA2.0', 'Torch'))
    inst.versions.running <- do.call(rbind, lapply(1:length(unique(subFrame$index)), function(x) with(with(unique(subFrame[subFrame$index==(x-1), c('Date','Version','InstrumentSerialNumber','Record'), ]), aggregate(Record~Date+Version, FUN=sum)), aggregate(Record~Version, FUN=mean))))
    inst.versions.running <- with(inst.versions.running, aggregate(Record~Version, FUN=median))
    
    # using the inst.versions.running, the runs.per.day, and working.days, find the theoretical capacity
    theoretical.capacity <- data.frame(inst.versions.running, RunsPerDay = runs.per.day, WorkingDays = working.days)
    theoretical.capacity$TheoreticalCapacity <- with(theoretical.capacity, round(Record, 0)*RunsPerDay*WorkingDays)
    
    # calcualte the total number of runs actually performed in the same period
    actual.runs <- with(subFrame, aggregate(Record~Version, FUN=sum))
    
    # now get the end product... WHAT IS THE END CHART SUPPOSED TO LOOK LIKE????
    return(merge(theoretical.capacity, actual.runs, by='Version'))
    # if b is what is returned on the above line, then the code below will make a chart
    # ggplot(b, aes(x=Version, y=Record.y/TheoreticalCapacity)) + geom_bar(stat='identity') + scale_y_continuous(label=percent) + geom_text(aes(x=Version, y=Record.y/TheoreticalCapacity+0.05, label=paste(round(100*Record.y/TheoreticalCapacity, 0), '%', sep='')))
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

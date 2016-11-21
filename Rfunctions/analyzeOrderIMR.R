analyzeOrderIMR <- function(dataFrame, variableToPlot, dateToAnalyze, entriesToChart, thresholdParam, equipColName, byEquipment=TRUE, returnClean = FALSE) {
  
  # perform some cleaning of the dataFrame by removing NAs in the variableToPlot
  dataFrame <- dataFrame[!(is.na(dataFrame[,variableToPlot])), ]
  
  # if the variableToPlot is not numeric, convert it to numeric value... make sure to do a double cleaning of NAs after conversion
  if(!(is.numeric(dataFrame[,variableToPlot]))) {
    
    dataFrame[,variableToPlot] <- as.numeric(as.character(dataFrame[,variableToPlot]))
    dataFrame <- dataFrame[!(is.na(dataFrame[,variableToPlot])), ]
  }
  
  # take only the columns of interest in the data frame, and rename the variableToPlot column as 'Result'
  dataFrame <- dataFrame[,c('LotNumber','TestNumber', equipColName, dateToAnalyze, variableToPlot)]
  colnames(dataFrame) <- c('LotNumber','TestNumber', 'Equipment', dateToAnalyze, 'Result')
  
  # remove data points that are throw aways... this is done by taking the lower 10% and upper 10% of points, then, the spread between these quantiles
  # is multiplied by the "thresholdParam" parameter supplied in the inputs is substracted/added to the respective quantiles. 
  # based on feedback from the teams, the lower limit should be zero, so hard code that
  q <- quantile(dataFrame[,'Result'], probs=c(0.10,0.90))
  # minTrash <- q[1] - thresholdParam*(q[2] - q[1])
  minTrash <- 0
  maxTrash <- q[2] + thresholdParam*(q[2] - q[1])
  dataFrame <- dataFrame[dataFrame[,'Result'] >= minTrash & dataFrame[,'Result'] <= maxTrash, ]
  
  # replace a POSIX type date with a "normal" date assuming a Mountain Standard Time for all tests
  dataFrame[,'Date'] <- as.character(as.Date(dataFrame[,dateToAnalyze], tz = 'MST'))
  dataFrame[,'Hour'] <- hour(dataFrame[,dateToAnalyze])
  dataFrame[,'Minute'] <- minute(dataFrame[,dateToAnalyze])
  dataFrame[,'Second'] <- second(dataFrame[,dateToAnalyze])
  
  # if the "returnClean" parameter is true, return the clean data frame
  if(returnClean) { return(dataFrame) }
    
  # reorder the data frame in order of most recent to oldest entries, then number the top "entriesToChart" from highest to lowest
  # then re-sort by observation number (these are the entries to chart individually on the charts)
  dataFrame <- dataFrame[with(dataFrame, order(Date, Hour, Minute, Second, TestNumber, decreasing = TRUE)), ]
  if(entriesToChart > length(dataFrame[,1])) {
    entriesToChart <- length(dataFrame[,1])
  }
  keepEntries <- dataFrame[1:entriesToChart, ]
  Observation <- seq(entriesToChart, 1, -1)
  keepEntries <- cbind(keepEntries, Observation)
  keepEntries <- keepEntries[with(keepEntries, order(Observation)), ]
  
  # for IMR, both the individual result and the range must be calculated, BUT the team wants things grouped by Equipment, so add this as an option
  if(byEquipment) {
    
    I <- keepEntries[,c('LotNumber','TestNumber','Equipment','DateOpened','Observation','Result')]
    I$Key <- 'Individual Value'
    equips <- unique(as.character(I[,'Equipment']))
    l <- length(equips)
    I.equip <- c()
    MR.equip <- c()
    
    # loop through each piece of equipment so that these can be viewed by equipment line in the correct observation order
    for(i in 1:l) {
      # Create a data set for the Individual Values
      temp <- I[I[,'Equipment'] == equips[i], ]
      temp <- temp[with(temp, order(Observation)), ]
      temp[,'Observation'] <- seq(1, length(temp[,'Observation']), 1)
      
      # if there are fewer than 12 measurements, then skip that piece of equipment because there is not enough data 
      if(length(temp[,1]) < 12) {
        next()
      }
      # bind the data for each equipment into one data frame
      I.equip <- rbind(I.equip, temp)
    }
  
    for(i in 1:l) {
      # create a data set for the Range values
      temp <- I.equip[I.equip[,'Equipment'] == equips[i], ]
      
      if(length(temp[,1]) < 12) {
        next()
      }
      Result <- sapply(2:length(temp[,'Observation']), function(x) abs(temp[x,'Result'] - temp[x-1,'Result']))
      Result <- c(NA, Result)
      temp <- cbind(temp[,c('LotNumber','TestNumber','Equipment','DateOpened','Observation')], Result)
      temp$Key <- 'Moving Range'
      # bind the data for each equipment into one data frame
      MR.equip <- rbind(MR.equip, temp)
    }
    
    # some equipment will not have enough data to be considered, so trim that out
    equips <- as.character(unique(I.equip[,'Equipment']))
    l <- length(equips)
  
    I <- c()
    MR <- c()
    for(i in 1:l) {
      
      # add the limits to the data frames... the limits should include all the data available, not just the last 24 hours (by equipment)
      I.equip.lim <- dataFrame[dataFrame[,'Equipment'] == equips[i], ]
      MR.equip.lim <- I.equip.lim
      Result <- sapply(2:length(MR.equip.lim[,'Result']), function(x) abs(MR.equip.lim[x,'Result'] - MR.equip.lim[x-1,'Result']))
      x.Bar.equip <- mean(I.equip.lim[,'Result'], na.rm=TRUE)
      r.Bar.equip <- mean(Result, na.rm=TRUE)
      
      # divide the I.equip and MR.equip into their respective equipment groups and add the limits using the results from the total equipment
      # data set
      I.temp <- I.equip[I.equip[,'Equipment'] == equips[i], ]
      MR.temp <- MR.equip[MR.equip[,'Equipment'] == equips[i], ]
      I.temp[,'Average'] <- x.Bar.equip
      I.temp[,'LCL'] <- x.Bar.equip - 3*r.Bar.equip/1.128
      I.temp[,'UCL'] <- x.Bar.equip + 3*r.Bar.equip/1.128
      MR.temp[,'Average'] <- r.Bar.equip
      MR.temp[,'LCL'] <- 0
      MR.temp[,'UCL'] <- 3.267*r.Bar.equip
      
      # Bind the data for each equipment into one data frame
      I <- rbind(I, I.temp)
      MR <- rbind(MR, MR.temp)
    }
  } else {  
  
    # Create a data set for the Individual Values
    I <- keepEntries[,c('LotNumber','TestNumber','Equipment','DateOpened','Observation','Result')]
    I$Key <- 'Individual Value'
    
    # Create a data set for the Range values
    Result <- sapply(2:entriesToChart, function(x) abs(keepEntries[x,'Result'] - keepEntries[x-1,'Result']))
    Result <- c(NA, Result)
    MR <- cbind(I[,c('LotNumber','TestNumber','Equipment','DateOpened','Observation')], Result)
    MR$Key <- 'Moving Range'
    
    # The upper and lower control limits should now be added, BUT these limits should be over all time not just the IncludeInIMR data points
    # (the coefficients used are taken from http://sixsigmacharts.blogspot.com/2010/02/understand-i-mr-chart.html)
    I.lim <- dataFrame
    MR.lim <- I.lim
    Result <- sapply(2:length(MR.lim[,'Result']), function(x) abs(MR.lim[x,'Result'] - MR.lim[x-1,'Result']))
    x.Bar <- mean(I.lim[,'Result'])
    r.Bar <- mean(Result)
    I[,'Average'] <- x.Bar
    I[,'LCL'] <- x.Bar - 3*r.Bar/1.128
    I[,'UCL'] <- x.Bar + 3*r.Bar/1.128
    MR[,'Average'] <- r.Bar
    MR[,'LCL'] <- 0
    MR[,'UCL'] <- 3.267*r.Bar
  }
  
  # rbind these sets together and return the property formatted data frame
  IMR <- rbind(I, MR)
  return(IMR)
}
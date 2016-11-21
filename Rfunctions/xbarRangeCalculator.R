xbarRangeCalculator <- function(dataFrame, groupSize=6) {
  
  lot.size <- with(data.frame(dataFrame, Record=1), aggregate(Record~LotNumber+Date, FUN=sum))
  lots <- as.character(unique(lot.size[with(lot.size, order(Date)),'LotNumber']))
  
  # table of constants for determining upper and lower limits of xBar and Range 
  # (https://www.spcforexcel.com/knowledge/variable-control-charts/xbar-r-charts-part-1)
  constants.xbarR <- data.frame(n = c(2, 3, 4, 5, 6), A2=c(1.880, 1.023, 0.729, 0.577, 0.483), D3=c(0, 0, 0, 0, 0), D4 = c(3.267, 2.574, 2.282, 2.114, 2.004))
  D3 <- 0
  D4.3 <- 2.574
  D4.6 <- 2.004
  
  outFrame <- c()
  for(i in 1:length(lots)) {
    
    lotFrame <- dataFrame[dataFrame[,'LotNumber']==lots[i], ]
    entries <- lot.size[lot.size[,'LotNumber']==lots[i],'Record']
    bins <- ceiling(entries/groupSize)
    lotFrame[,'Bin'] <- do.call(rbind, lapply(1:bins, function(x) data.frame(Bin = rep(x, groupSize))))[1:entries, ]
  
    xBarR <- do.call(rbind, lapply(1:length(unique(lotFrame$Bin)), function(x) data.frame(LotNumber = unique(lotFrame$LotNumber), Bin = unique(lotFrame$Bin)[x], Xbar = mean(lotFrame[lotFrame$Bin==unique(lotFrame$Bin)[x], 'Result']), Range = (range(lotFrame[lotFrame$Bin==unique(lotFrame$Bin)[x], 'Result'])[2]-range(lotFrame[lotFrame$Bin==unique(lotFrame$Bin)[x], 'Result'])[1]), n = length(lotFrame[lotFrame$Bin==unique(lotFrame$Bin)[x],'LotNumber']))))
    
    outFrame <- rbind(outFrame, xBarR)
  }
  
  outFrame$XbarAvg <- mean(outFrame$Xbar)
  outFrame$Rbar <- mean(outFrame$Range) 
  outFrame$UCLx <- outFrame$XbarAvg + constants.xbarR[constants.xbarR$n==groupSize, 'A2']*outFrame$Rbar
  outFrame$LCLx <- outFrame$XbarAvg - constants.xbarR[constants.xbarR$n==groupSize, 'A2']*outFrame$Rbar
  outFrame$UCLr <- constants.xbarR[constants.xbarR$n==groupSize, 'D4']*outFrame$Rbar
  outFrame$LCLr <- constants.xbarR[constants.xbarR$n==groupSize, 'D3']*outFrame$Rbar
  
  outFrame <- outFrame[,c('LotNumber','Bin','Xbar','Range','XbarAvg','Rbar','UCLx','LCLx','UCLr','LCLr')]
  outFrame <- merge(outFrame, unique(dataFrame[,c('LotNumber','Date')]), by='LotNumber')
  outFrame <- outFrame[with(outFrame, order(Date, LotNumber, Bin)), ]
  outFrame[,'Observation'] <- seq(1, length(outFrame$LotNumber), 1)
  
  # because the data frame is in the format where the Xbar and Range are not in key-value pairs, that makes it hard to do a facet wrap, so reformat
  xbar <- data.frame(LotNumber = outFrame$LotNumber, Observation = outFrame$Observation, Key = 'Xbar', Value = outFrame$Xbar, Avg = outFrame$XbarAvg, UCL = outFrame$UCLx, LCL = outFrame$LCLx)
  R <- data.frame(LotNumber = outFrame$LotNumber, Observation = outFrame$Observation, Key = 'Range', Value = outFrame$Range, Avg = outFrame$Rbar, UCL = outFrame$UCLr, LCL = outFrame$LCLr)
  xBarR.df <- rbind(xbar, R)
  
  return(xBarR.df)
}
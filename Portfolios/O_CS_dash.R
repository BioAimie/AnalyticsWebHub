workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_CustomerSupport'
pdfDir <- '~/WebHub/pdfs/'

setwd(workDir)

# Load needed libraries
library(ggplot2)
library(scales)
library(zoo)
library(lubridate)
library(dateManip)
library(gtable)
library(grid)

# load the data from SQL
source('Portfolios/O_CS_load.R')

source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/makeTimeStamp.R')

calendar.week <- createCalendarLikeMicrosoft(year(Sys.Date())-2, 'Week')
startString.week <- findStartDate(calendar.week, 'Week', 54, 4)
calendar.month <- createCalendarLikeMicrosoft(2013, 'Month')
startString.month <- findStartDate(calendar.month, 'Month', 13, 0)
startString.month3yr <- findStartDate(calendar.month, 'Month', 36, 0)
seqBreak <- 12
dateBreaks <- as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= startString.week,'DateGroup']))[order(as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= startString.week,'DateGroup'])))][seq(4,length(as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= startString.week,'DateGroup']))), seqBreak)]
fontSize <- 20
fontFace <- 'bold'
currentMonth <- ifelse(month(Sys.Date()) < 10, paste0(year(Sys.Date()),'-','0',month(Sys.Date())), paste0(year(Sys.Date()),'-',month(Sys.Date())))

# Reburb Inventory Stock Levels
refurbStock <- subset(stockInv.df, grepl('R$',ItemID))

#add all ItemIDs to be sure there is at least one row for each
refurbStock$ItemID <- as.character(refurbStock$ItemID)
refurbStock <- rbind(refurbStock, c('HTFA-ASY-0001R', 0), c('HTFA-ASY-0003R', 0))
refurbStock$Record <- as.numeric(refurbStock$Record)
refurbStock$ItemID <- as.factor(refurbStock$ItemID)

refurbStock.agg <- with(refurbStock, aggregate(Record~ItemID, FUN=sum))

refurbStock.agg$Key <- ' '

p.RefurbStockInventory <- ggplot(refurbStock.agg, aes(x=Key, y=Record)) + geom_bar(stat='identity', width = 0.5) + xlab(' ') + ylab('Inventory') + facet_wrap(~ItemID, scales='free_y', strip.position = 'bottom') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20), strip.background = element_blank(), strip.placement = 'outside', plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + ggtitle('Refurbished Stock Inventory Levels') + scale_y_continuous(breaks=pretty_breaks(n=10))

# Quantity of refurb parts shipped per week and moving average
#---FLM1-ASY-0001R
ship15 <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', subset(refurbShip.df, Product == 'FA1.5R'), c('Product'), startString.week, 'Record', 'sum', 0)

#4 week moving avg
l <- length(ship15$DateGroup)
ship15 <- cbind(ship15[4:l,], sapply(4:l, function(x) mean(ship15[(x-3):x,'Record'])))
colnames(ship15)[4] <- 'RollingAvg'

p.Refurb1.5Shipments <- ggplot(ship15, aes(x=DateGroup, y=Record)) + geom_bar(stat='identity', fill='cornflowerblue') + geom_line(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + geom_point(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Refurbished FA 1.5 Shipments', subtitle = '4 Week Moving Average', x = 'Date\n(Year-Week)', y ='Shipments') + scale_x_discrete(breaks=dateBreaks)
  
#---FLM2-ASY-0002R
ship20 <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', subset(refurbShip.df, Product == 'FA2.0R'), c('Product'), startString.week, 'Record', 'sum', 0)

#4 week moving avg
l <- length(ship20$DateGroup)
ship20 <- cbind(ship20[4:l,], sapply(4:l, function(x) mean(ship20[(x-3):x,'Record'])))
colnames(ship20)[4] <- 'RollingAvg'

p.Refurb2.0Shipments <- ggplot(ship20, aes(x=DateGroup, y=Record)) + geom_bar(stat='identity', fill='cornflowerblue') + geom_line(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + geom_point(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Refurbished FA 2.0 Shipments', subtitle = '4 Week Moving Average', x = 'Date\n(Year-Week)', y ='Shipments') + scale_x_discrete(breaks=dateBreaks)

#---HTFA-ASY-0001R
if(nrow(subset(refurbShip.df, Product == 'Torch Base R')) > 0) {
  shipBase <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', subset(refurbShip.df, Product == 'Torch Base R'), c('Product'), startString.week, 'Record', 'sum', 0)
  
  #4 week moving avg
  l <- length(shipBase$DateGroup)
  shipBase <- cbind(shipBase[4:l,], sapply(4:l, function(x) mean(shipBase[(x-3):x,'Record'])))
  colnames(shipBase)[4] <- 'RollingAvg'
  
  p.RefurbTorchBaseShipments <- ggplot(shipBase, aes(x=DateGroup, y=Record)) + geom_bar(stat='identity', fill='cornflowerblue') + geom_line(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + geom_point(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Refurbished Torch Base Shipments', subtitle = '4 Week Moving Average', x = 'Date\n(Year-Week)', y ='Shipments') + scale_x_discrete(breaks=dateBreaks)
} else {
  shipBase <- data.frame(DateGroup = unique(ship20$DateGroup), Record = 0)
  p.RefurbTorchBaseShipments <- ggplot(shipBase, aes(x=DateGroup, y=Record)) + geom_bar(stat='identity', fill='cornflowerblue') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Refurbished Torch Base Shipments', subtitle = '4 Week Moving Average', x = 'Date\n(Year-Week)', y ='Shipments') + scale_x_discrete(breaks=dateBreaks) + scale_y_continuous(limits = c(0,1))
}

#---HTFA-ASY-0003R
shipTorch <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', subset(refurbShip.df, Product == 'Torch Module R'), c('Product'), startString.week, 'Record', 'sum', 0)

#4 week moving avg
l <- length(shipTorch$DateGroup)
shipTorch <- cbind(shipTorch[4:l,], sapply(4:l, function(x) mean(shipTorch[(x-3):x,'Record'])))
colnames(shipTorch)[4] <- 'RollingAvg'

p.RefurbTorchModuleShipments <- ggplot(shipTorch, aes(x=DateGroup, y=Record)) + geom_bar(stat='identity', fill='cornflowerblue') + geom_line(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + geom_point(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Refurbished Torch Module Shipments', subtitle = '4 Week Moving Average', x = 'Date\n(Year-Week)', y ='Shipments') + scale_x_discrete(breaks=dateBreaks)

#---COMP-SUB-0016R
shipComp <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', subset(refurbShip.df, Product == 'Computer'), c('Product'), startString.week, 'Record', 'sum', 0)

#4 week moving avg
l <- length(shipComp$DateGroup)
shipComp <- cbind(shipComp[4:l,], sapply(4:l, function(x) mean(shipComp[(x-3):x,'Record'])))
colnames(shipComp)[4] <- 'RollingAvg'

p.RefurbComputerShipments <- ggplot(shipComp, aes(x=DateGroup, y=Record)) + geom_bar(stat='identity', fill='cornflowerblue') + geom_line(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + geom_point(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Refurbished Computer Shipments', subtitle = '4 Week Moving Average', x = 'Date\n(Year-Week)', y ='Shipments') + scale_x_discrete(breaks=dateBreaks)

# Sales Source of Refurb Shipments by month !!!Need to choose which chart to show
refurbSource <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', refurbShip.df, c('Product', 'SalesSource', 'SalesType'), startString.month, 'Record', 'sum', 0)

p.RefurbSalesSource <- ggplot(refurbSource, aes(x=DateGroup, y=Record, fill=SalesSource)) + geom_bar(stat='identity') + scale_fill_manual(name='Sales Source ID', values = createPaletteOfVariableLength(refurbSource, 'SalesSource')) + facet_wrap(~Product, scales = 'free_y') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Sales Source of Refurbished Shipments', x = 'Date\n(Year-Month)', y ='Shipments')

p.RefurbSalesType <- ggplot(refurbSource, aes(x=DateGroup, y=Record, fill=SalesType)) + geom_bar(stat='identity') + scale_fill_manual(name='Sales Source', values = createPaletteOfVariableLength(refurbSource, 'SalesType')) + facet_wrap(~Product, scales = 'free_y') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Sales Source of Refurbished Shipments', x = 'Date\n(Year-Month)', y ='Shipments')

# New Inventory Stock Levels 
newStock <- subset(stockInv.df, !(grepl('R$',ItemID)))

#add all ItemIDs to be sure there is at least one row for each
newStock$ItemID <- as.character(newStock$ItemID)
newStock <- rbind(newStock, c('HTFA-ASY-0001', 0), c('HTFA-ASY-0003', 0))
newStock$Record <- as.numeric(newStock$Record)
newStock$ItemID <- as.factor(newStock$ItemID)

newStock.agg <- with(newStock, aggregate(Record~ItemID, FUN=sum))

newStock.agg$Key <- ' '

p.NewStockInventory <- ggplot(newStock.agg, aes(x=Key, y=Record)) + geom_bar(stat='identity', width = 0.5) + xlab(' ') + ylab('Inventory') + facet_wrap(~ItemID, scales='free_y', strip.position = 'bottom') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20), strip.background = element_blank(), strip.placement = 'outside', plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + ggtitle('New Stock Inventory Levels') + scale_y_continuous(breaks=pretty_breaks(n=10))

# Service Tiers
#---by RMA type
tier.type <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', tier.df, c('Type', 'ServiceTier'), startString.week, 'Record', 'sum', 0)
p.ServiceTiersbyType <- ggplot(tier.type, aes(x=DateGroup, y=Record, fill=ServiceTier)) + geom_bar(stat='identity') + scale_fill_manual(name='Service Tier', values = createPaletteOfVariableLength(tier.type, 'ServiceTier')) + facet_wrap(~Type, scales = 'free_y', ncol=1) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Service Tier Repairs of FA 1.5, FA 2.0, and Torch', x = 'Date\n(Year-Week)', y ='Repairs') + scale_x_discrete(breaks=dateBreaks)
#---by version
tier.version <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', tier.df, c('Version', 'ServiceTier'), startString.week, 'Record', 'sum', 0)
p.ServiceTiersbyVersion <- ggplot(tier.version, aes(x=DateGroup, y=Record, fill=ServiceTier)) + geom_bar(stat='identity') + scale_fill_manual(name='Service Tier', values = createPaletteOfVariableLength(tier.version, 'ServiceTier')) + facet_wrap(~Version, scales = 'free_y', ncol=1) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Service Tier Repairs of Customer RMAs', x = 'Date\n(Year-Week)', y ='Repairs') + scale_x_discrete(breaks=dateBreaks)

# Current Open Complaints
OpenComplaints <- with(subset(complaints.df, Status == 'Open'), aggregate(Record~Key, FUN=sum))
OpenComplaints$Key <- factor(OpenComplaints$Key, levels = c('0 - 30', '31 - 60', '61 - 90', '91 - 120', '121+'))
p.CurrentOpenComplaints <- ggplot(OpenComplaints, aes(x=Key, y=Record)) + geom_bar(stat='identity', fill='midnightblue') + geom_text(aes(label=Record), vjust=-1, fontface=fontFace, size = 5) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Aging Open Complaints - Days Open', subtitle = paste('Current Open Complaints:', sum(OpenComplaints$Record)), x = 'Days Open', y ='Number of Complaints')

# Complaints Open by month
OpenDate <- subset(complaints.df, select = c('YearOpen', 'MonthOpen', 'Record'))
colnames(OpenDate)[colnames(OpenDate)=='YearOpen'] <- 'Year'
colnames(OpenDate)[colnames(OpenDate)=='MonthOpen'] <- 'Month'
OpenDate$Key <- 'Opened Complaints'
OpenDate <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', OpenDate, 'Key', startString.month3yr, 'Record', 'sum', 0)
OpenedComplaints <- subset(OpenDate, DateGroup == currentMonth)[,'Record']
p.ComplaintsOpened <- ggplot(OpenDate, aes(x=as.numeric(as.factor(DateGroup)), y=Record, fill=Key)) + geom_area(stat='identity', position='stack') + scale_x_continuous(labels=sort(as.character(unique(OpenDate$DateGroup))), breaks = 1:length(as.character(unique(OpenDate$DateGroup)))) + scale_fill_manual(values = 'midnightblue') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle=90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5), legend.position = 'none') + labs(title = 'Complaints Received', subtitle = paste('Complaints Opened in', format(Sys.Date(), '%B'),':', OpenedComplaints), x = 'Date\n(Year-Month)', y ='Number of Complaints')

# RMAs closed in current month by type (part)
closedRMA <- subset(rmas.df, Status == 'Closed', select = c('YearClose', 'MonthClose', 'Part', 'Type', 'Record'))
colnames(closedRMA)[colnames(closedRMA)=='YearClose'] <- 'Year'
colnames(closedRMA)[colnames(closedRMA)=='MonthClose'] <- 'Month'
closedRMA <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', closedRMA, c('Part', 'Type'), startString.month3yr, 'Record', 'sum', 0)
currentClosedRMA <- with(subset(closedRMA, DateGroup == currentMonth), aggregate(Record~Part, FUN=sum))
currentClosedRMA$Part <- factor(currentClosedRMA$Part, levels = as.character(unique(currentClosedRMA[with(currentClosedRMA, order(Record, decreasing=TRUE)),'Part'])))
p.CurrentClosedRMA <- ggplot(currentClosedRMA, aes(x=Part, y=Record)) + geom_bar(stat='identity', fill='midnightblue') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5)) + labs(title = paste('RMAs Closed in', format(Sys.Date(), '%B')), x = 'RMA Type', y ='Number of RMAs') + geom_text(aes(label=Record), vjust = -0.75, size = 5)

# RMAs closed over time by month
p.AllClosedRMA <- ggplot(closedRMA, aes(DateGroup, y=Record, fill=Part)) + geom_bar(stat='identity') + scale_fill_manual(name='RMA Type', values = createPaletteOfVariableLength(closedRMA, 'Part')) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5)) + labs(title = 'Closed RMAs', x = 'Date\n(Year-Month)', y ='Number of RMAs') 

# RMA TAT for all service centers
rmaTAT <- subset(rmas.df, Disposition == 'Return to Customer' & Part == 'Instrument', select = c('YearShip', 'MonthShip', 'ServiceCenter', 'DaysInReceiving', 'DaysInQuarantine/Decon', 'DaysInService', 'DaysInQC', 'DaysToSalesOrder', 'DaysToShip', 'Record'))
rmaTAT$DateGroup <- with(rmaTAT, ifelse(MonthShip < 10, paste0(YearShip,'-0',MonthShip), paste0(YearShip,'-',MonthShip)))
rmaTAT <- subset(rmaTAT, DateGroup >= startString.month3yr)
dateGroups <- sort(as.character(unique(rmaTAT$DateGroup)))
avgDaysperPhase <- c()
for(i in 1:length(dateGroups)) {
  temp <- subset(rmaTAT, DateGroup == dateGroups[i])
  avgDaysInReceiving <- data.frame(DateGroup = dateGroups[i], Key = 'Days In Receiving', Record = mean(temp$DaysInReceiving, na.rm=TRUE))
  avgDaysInQuarantineDecon <- data.frame(DateGroup = dateGroups[i], Key = 'Days In Quarantine/Decon', Record = mean(temp$'DaysInQuarantine/Decon', na.rm=TRUE))
  avgDaysInService <- data.frame(DateGroup=dateGroups[i], Key = 'Days In Service', Record = mean(temp$DaysInService, na.rm=TRUE))
  avgDaysInQC <- data.frame(DateGroup = dateGroups[i], Key = 'Days In QC', Record = mean(temp$DaysInQC, na.rm=TRUE))
  avgDaysToSalesOrder <- data.frame(DateGroup = dateGroups[i], Key = 'Days To Sales Order', Record = mean(temp$DaysToSalesOrder, na.rm=TRUE))
  avgDaysToShip <- data.frame(DateGroup = dateGroups[i], Key = 'Days To Ship', Record = mean(temp$DaysToShip, na.rm=TRUE))
  avgDaysperPhase <- rbind(avgDaysperPhase, avgDaysInReceiving, avgDaysInQuarantineDecon, avgDaysInService, avgDaysInQC, avgDaysToSalesOrder, avgDaysToShip)
}
p.RMATaT <- ggplot(avgDaysperPhase, aes(x=DateGroup, y=Record, fill=Key)) + geom_bar(stat='identity') + scale_fill_manual(name='', values = createPaletteOfVariableLength(avgDaysperPhase, 'Key')) + geom_hline(aes(yintercept = 14), lty='dashed', color = 'midnightblue') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5), legend.position = 'bottom') + labs(title = 'Days Per RMA Process', subtitle = 'Goal = 14 days', x = 'Shipping Date\n(Year-Month)', y ='Average Days')  

# RMA TAT for SL service center
rmaTAT.SL <- subset(rmaTAT, ServiceCenter == 'Salt Lake')
dateGroups <- sort(as.character(unique(rmaTAT.SL$DateGroup)))
avgDaysperPhase.SL <- c()
for(i in 1:length(dateGroups)) {
  temp <- subset(rmaTAT.SL, DateGroup == dateGroups[i])
  avgDaysInReceiving <- data.frame(DateGroup = dateGroups[i], Key = 'Days In Receiving', Record = mean(temp$DaysInReceiving, na.rm=TRUE))
  avgDaysInQuarantineDecon <- data.frame(DateGroup = dateGroups[i], Key = 'Days In Quarantine/Decon', Record = mean(temp$'DaysInQuarantine/Decon', na.rm=TRUE))
  avgDaysInService <- data.frame(DateGroup=dateGroups[i], Key = 'Days In Service', Record = mean(temp$DaysInService, na.rm=TRUE))
  avgDaysInQC <- data.frame(DateGroup = dateGroups[i], Key = 'Days In QC', Record = mean(temp$DaysInQC, na.rm=TRUE))
  avgDaysToSalesOrder <- data.frame(DateGroup = dateGroups[i], Key = 'Days To Sales Order', Record = mean(temp$DaysToSalesOrder, na.rm=TRUE))
  avgDaysToShip <- data.frame(DateGroup = dateGroups[i], Key = 'Days To Ship', Record = mean(temp$DaysToShip, na.rm=TRUE))
  avgDaysperPhase.SL <- rbind(avgDaysperPhase.SL, avgDaysInReceiving, avgDaysInQuarantineDecon, avgDaysInService, avgDaysInQC, avgDaysToSalesOrder, avgDaysToShip)
}
p.RMATaT.SaltLake <- ggplot(avgDaysperPhase.SL, aes(x=DateGroup, y=Record, fill=Key)) + geom_bar(stat='identity') + scale_fill_manual(name='', values = createPaletteOfVariableLength(avgDaysperPhase, 'Key')) + geom_hline(aes(yintercept = 14), lty='dashed', color = 'midnightblue') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5), legend.position = 'bottom') + labs(title = 'Days Per RMA Process for Salt Lake Service Center', subtitle = 'Goal = 14 days', x = 'Shipping Date\n(Year-Month)', y ='Average Days')  

# RMA TAT for Florence service center
rmaTAT.FL <- subset(rmaTAT, ServiceCenter == 'Florence')
dateGroups <- sort(as.character(unique(rmaTAT.FL$DateGroup)))
avgDaysperPhase.FL <- c()
for(i in 1:length(dateGroups)) {
  temp <- subset(rmaTAT.FL, DateGroup == dateGroups[i])
  avgDaysInReceiving <- data.frame(DateGroup = dateGroups[i], Key = 'Days In Receiving', Record = mean(temp$DaysInReceiving, na.rm=TRUE))
  avgDaysInQuarantineDecon <- data.frame(DateGroup = dateGroups[i], Key = 'Days In Quarantine/Decon', Record = mean(temp$'DaysInQuarantine/Decon', na.rm=TRUE))
  avgDaysInService <- data.frame(DateGroup=dateGroups[i], Key = 'Days In Service', Record = mean(temp$DaysInService, na.rm=TRUE))
  avgDaysInQC <- data.frame(DateGroup = dateGroups[i], Key = 'Days In QC', Record = mean(temp$DaysInQC, na.rm=TRUE))
  avgDaysToSalesOrder <- data.frame(DateGroup = dateGroups[i], Key = 'Days To Sales Order', Record = mean(temp$DaysToSalesOrder, na.rm=TRUE))
  avgDaysToShip <- data.frame(DateGroup = dateGroups[i], Key = 'Days To Ship', Record = mean(temp$DaysToShip, na.rm=TRUE))
  avgDaysperPhase.FL <- rbind(avgDaysperPhase.FL, avgDaysInReceiving, avgDaysInQuarantineDecon, avgDaysInService, avgDaysInQC, avgDaysToSalesOrder, avgDaysToShip)
}
p.RMATaT.Florence <- ggplot(avgDaysperPhase.FL, aes(x=DateGroup, y=Record, fill=Key)) + geom_bar(stat='identity') + scale_fill_manual(name='', values = createPaletteOfVariableLength(avgDaysperPhase, 'Key')) + geom_hline(aes(yintercept = 14), lty='dashed', color = 'midnightblue') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5), legend.position = 'bottom') + labs(title = 'Days Per RMA Process for Florence Service Center', subtitle = 'Goal = 14 days', x = 'Shipping Date\n(Year-Month)', y ='Average Days')  


# All RMAs opened by type (part) 
openedRMA <- subset(rmas.df, select = c('YearOpen', 'MonthOpen', 'Part', 'Type', 'Record'))
colnames(openedRMA)[colnames(openedRMA)=='YearOpen'] <- 'Year'
colnames(openedRMA)[colnames(openedRMA)=='MonthOpen'] <- 'Month'
openedRMA <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', openedRMA, c('Part', 'Type'), startString.month3yr, 'Record', 'sum', 0)
p.AllOpenedRMA <- ggplot(openedRMA, aes(DateGroup, y=Record, fill=Part)) + geom_bar(stat='identity') + scale_fill_manual(name='RMA Type', values = createPaletteOfVariableLength(openedRMA, 'Part')) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5)) + labs(title = 'Opened RMAs', x = 'Date\n(Year-Month)', y ='Number of RMAs') 

# Customer RMAs opened by type (part)
subset(openedRMA, Type == 'Customer - Failure' | Type == 'Customer - No failure')
p.CustomerOpenedRMA <- ggplot(subset(openedRMA, Type == 'Customer - Failure' | Type == 'Customer - No failure'), aes(DateGroup, y=Record, fill=Part)) + geom_bar(stat='identity') + scale_fill_manual(name='RMA Type', values = createPaletteOfVariableLength(openedRMA, 'Part')) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5)) + labs(title = 'Opened Customer RMAs', x = 'Date\n(Year-Month)', y ='Number of RMAs') 

# Complaints Closed and Average Days Open to Close - Print this separately
CloseDate <- subset(complaints.df, select = c('YearClosed', 'MonthClosed', 'Record'), Status == 'Closed')
colnames(CloseDate)[colnames(CloseDate)=='YearClosed'] <- 'Year'
colnames(CloseDate)[colnames(CloseDate)=='MonthClosed'] <- 'Month'
CloseDate$Key <- 'Closed Complaints'
CloseDate <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', CloseDate, c('Key'), startString.month3yr, 'Record', 'sum', 0)
ClosedComplaints <- sum(subset(CloseDate, DateGroup == currentMonth)[,'Record'])
#---Avg days open to close
avgDays <- subset(complaints.df, Status == 'Closed', select = c('YearClosed', 'MonthClosed', 'DaysOpen', 'Record'))
avgDays$DateGroup <- with(avgDays, ifelse(MonthClosed < 10, paste0(YearClosed,'-0',MonthClosed), paste0(YearClosed,'-',MonthClosed)))
avgDays <- subset(avgDays, DateGroup >= startString.month3yr)
avgDays.agg <- c()
Dates <- sort(as.character(unique(avgDays$DateGroup)))
for(i in 1:length(Dates)) {
  temp <- subset(avgDays, DateGroup == Dates[i])
  avg <- round(mean(temp$DaysOpen), 2)
  avgDays.agg <- rbind(avgDays.agg, data.frame(DateGroup = Dates[i], DaysOpen = avg, Record = 1))
}
p1 <- ggplot(CloseDate, aes(x=DateGroup, y=Record)) + geom_bar(stat='identity', fill='cornflowerblue') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle=90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Complaints Closed - Average Days Open', subtitle = paste('Complaints Closed in', format(Sys.Date(), '%B'),':', ClosedComplaints,'\nAverage Days Open in',format(Sys.Date(), '%B'),':',subset(avgDays.agg, DateGroup == currentMonth)[,'DaysOpen'],' Goal = 30 days'), x = 'Date\n(Year-Month)', y ='Number of Complaints')
p2 <- ggplot(avgDays.agg, aes(x=DateGroup, y=DaysOpen, group=1)) + geom_line(color='midnightblue', size = 1.5) + theme(panel.background = element_blank(),panel.grid.major = element_blank(), panel.grid.minor = element_blank(),panel.grid.major.x = element_blank(), text=element_text(size=20, face='bold'), axis.text.x=element_blank(), axis.title.x=element_blank(), axis.ticks.x = element_blank(), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(x='', y ='Average Days Open') + scale_y_continuous(position = 'right', limits = c(0,60)) + geom_hline(aes(yintercept=30), color='forestgreen', lty='dashed', size=1.5)
g1 <- ggplotGrob(p1)
g2 <- ggplotGrob(p2)
pp <- c(subset(g1$layout, name == 'panel', se = t:r))
g1 <- gtable_add_grob(g1, g2$grobs[[which(g2$layout$name == 'panel')]], pp$t, pp$l, pp$b, pp$r)
index2 <- which(g2$layout$name == "ylab-r")
yaxislab <- g2$grobs[[index2]]
g1 <- gtable_add_cols(g1, g2$widths[g2$layout[index2, ]$l], pp$r)
g1 <- gtable_add_grob(g1, yaxislab, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "ylab-r")
index <- which(g2$layout$name == "axis-r")
yaxis <- g2$grobs[[index]]
g1 <- gtable_add_cols(g1, g2$widths[g2$layout[index, ]$l], pp$r)
g1 <- gtable_add_grob(g1, yaxis, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "axis-r")

# Export Images for the Web Hub
setwd(imgDir)
plots <- ls()[grep('^p\\.', ls())]
for(i in 1:length(plots)) {
  imgName <- paste(substring(plots[i],3),'.png',sep='')
  
  png(file=imgName, width=1200, height=800, units='px')
  print(get(plots[i]))
  makeTimeStamp(author='Data Science')
  dev.off()
}
png(file='ComplaintsClosedAvgDaysOpen.png', width=1200, height=800, units='px')
grid.draw(g1)
makeTimeStamp(timeStamp = Sys.time(), author='Data Science')
dev.off()

# Export PDF for the Web Hub
setwd(pdfDir)
pdf("CustomerSupport.pdf", width = 11, height = 8)
for(i in 1:length(plots)) {
  print(get(plots[i]))
}
grid.draw(g1)
dev.off()

rm(list = ls())

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

calendar.week <- createCalendarLikeMicrosoft(year(Sys.Date())-3, 'Week')
startString.week <- findStartDate(calendar.week, 'Week', 54, 4)
calendar.month <- createCalendarLikeMicrosoft(2013, 'Month')
startString.month <- findStartDate(calendar.month, 'Month', 13, 0)
startString.monthRoll <- findStartDate(calendar.month, 'Month', 12, 4)
startString.month3yr <- findStartDate(calendar.month, 'Month', 36, 0)
startString.month3yr.rolling <- findStartDate(calendar.month, 'Month', 36, 4)
seqBreak <- 12
dateBreaks <- as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= startString.week,'DateGroup']))[order(as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= startString.week,'DateGroup'])))][seq(4,length(as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= startString.week,'DateGroup']))), seqBreak)]
fontSize <- 20
fontFace <- 'bold'
currentMonth <- ifelse(month(Sys.Date()) < 10, paste0(year(Sys.Date()),'-','0',month(Sys.Date())), paste0(year(Sys.Date()),'-',month(Sys.Date())))
lm <- month(Sys.Date()) -1
lastMonth <- ifelse(lm < 10, paste0(year(Sys.Date()),'-','0',lm), paste0(year(Sys.Date()),'-',lm))

# Reburb Inventory Stock Levels
refurbStock <- subset(stockInv.df, grepl('R$',ItemID))

#add all ItemIDs to be sure there is at least one row for each
refurbStock$ItemID <- as.character(refurbStock$ItemID)
refurbStock <- rbind(refurbStock, c('HTFA-ASY-0001R', 0), c('HTFA-ASY-0003R', 0))
refurbStock$ItemID[which(grepl("COMP-SUB-0016R", refurbStock$ItemID))] <-  "Laptop - COMP-SUB-0016R"
refurbStock$ItemID[which(grepl("FLM1-ASY-0001R", refurbStock$ItemID))] <-  "FA 1.5 - FLM1-ASY-0001R"
refurbStock$ItemID[which(grepl("FLM2-ASY-0001R", refurbStock$ItemID))] <-  "FA 2.0 - FLM2-ASY-0001R"
refurbStock$ItemID[which(grepl("HTFA-ASY-0001R", refurbStock$ItemID))] <-  "Torch Base - HTFA-ASY-0001R"
refurbStock$ItemID[which(grepl("HTFA-ASY-0003R", refurbStock$ItemID))] <-  "Torch Module - HTFA-ASY-0003R"
refurbStock$Record <- as.numeric(refurbStock$Record)
refurbStock$ItemID <- as.factor(refurbStock$ItemID)
refurbStock.agg <- with(refurbStock, aggregate(Record~ItemID, FUN=sum))
refurbStock.agg$Key <- ' '
## make a new column for the staftey stock lines 
saftey.stock <- rep(NA, nrow(refurbStock.agg))
saftey.stock[which(refurbStock.agg$ItemID == "FA 1.5 - FLM1-ASY-0001R")] <- 35
saftey.stock[which(refurbStock.agg$ItemID == "FA 2.0 - FLM2-ASY-0001R")] <- 30
refurbStock.agg$SafteyStock <- saftey.stock
p.RefurbStockInventory <- ggplot(refurbStock.agg, aes(x=Key, y=Record)) + geom_bar(stat='identity', width = 0.5) + geom_hline(data=refurbStock.agg, aes(yintercept=SafteyStock), size=1, colour="#0C13A8", linetype=2 ) + facet_wrap(~ItemID, scales='free_y', strip.position = 'bottom')+ theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20), strip.background = element_blank(), strip.placement = 'outside', plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + scale_y_continuous(breaks=pretty_breaks(n=10)) + labs(title='Refurbished Stock Inventory Levels', subtitle='Blue Line = Safety Stock Level', x='', y='Inventory')

# Quantity of refurb parts shipped per week and moving average
refurbShip.df$Key <- rep(NA, nrow(refurbShip.df))
refurbShip.df$Key[which(refurbShip.df$SalesType == "Loaner")] <- "Loaner"
refurbShip.df$Key[which(refurbShip.df$SalesType == "Replacements")] <- "Replacements"
refurbShip.df$Key[which(is.na(refurbShip.df$Key))] <- "Other"
shipLevels <- c('Other','Replacements','Loaner')
#---FLM1-ASY-0001R
ship15 <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', subset(refurbShip.df, Product == 'FA1.5R'), c('Product', 'Key'), startString.week, 'Record', 'sum', 0)
ship15 <- ship15[order(ship15$DateGroup), ]
#4 week moving avg
temp.agg <- with(ship15, aggregate(Record~DateGroup, FUN=sum))
l <- length(temp.agg$DateGroup)
temp.agg <- cbind(temp.agg[4:l,], sapply(4:l, function(x) mean(temp.agg[(x-3):x,'Record'])))
colnames(temp.agg)[3] <- 'RollingAvg'
ship15 <- merge(ship15, subset(temp.agg, select=c('DateGroup', 'RollingAvg')))
ship15$Key <- factor(ship15$Key, levels=shipLevels)
p.Refurb1.5Shipments <- ggplot(ship15, aes(x=DateGroup, y=Record, fill=Key)) + geom_bar(stat='identity') + scale_fill_manual(name='Shipment Type', values=createPaletteOfVariableLength(ship15, 'Key')) + geom_line(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + geom_point(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Refurbished FA 1.5 Shipments', subtitle = '4 Week Moving Average', x = 'Date\n(Year-Week)', y ='Shipments') + scale_x_discrete(breaks=dateBreaks)

#---FLM2-ASY-0002R
ship20 <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', subset(refurbShip.df, Product == 'FA2.0R'), c('Product', 'Key'), startString.week, 'Record', 'sum', 0)
ship20 <- ship20[order(ship20$DateGroup), ]
#4 week moving avg
temp.agg <- with(ship20, aggregate(Record~DateGroup, FUN=sum))
l <- length(temp.agg$DateGroup)
temp.agg <- cbind(temp.agg[4:l,], sapply(4:l, function(x) mean(temp.agg[(x-3):x,'Record'])))
colnames(temp.agg)[3] <- 'RollingAvg'
ship20 <- merge(ship20, subset(temp.agg, select=c('DateGroup', 'RollingAvg')))
ship20$Key <- factor(ship20$Key, levels=shipLevels)
p.Refurb2.0Shipments <- ggplot(ship20, aes(x=DateGroup, y=Record, fill=Key)) + geom_bar(stat='identity') + scale_fill_manual(name='Shipment Type', values=createPaletteOfVariableLength(ship20, 'Key')) + geom_line(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + geom_point(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Refurbished FA 2.0 Shipments', subtitle = '4 Week Moving Average', x = 'Date\n(Year-Week)', y ='Shipments') + scale_x_discrete(breaks=dateBreaks)

#---HTFA-ASY-0001R
if(nrow(subset(refurbShip.df, Product == 'Torch Base R')) > 0) {
  shipBase <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', subset(refurbShip.df, Product == 'Torch Base R'), c('Product', 'Key'), startString.week, 'Record', 'sum', 0)
  shipBase <- shipBase[order(shipBase$DateGroup), ]
  #4 week moving avg
  temp.agg <- with(shipBase, aggregate(Record~DateGroup, FUN=sum))
  l <- length(temp.agg$DateGroup)
  temp.agg <- cbind(temp.agg[4:l,], sapply(4:l, function(x) mean(temp.agg[(x-3):x,'Record'])))
  colnames(temp.agg)[3] <- 'RollingAvg'
  shipBase <- merge(shipBase, subset(temp.agg, select=c('DateGroup', 'RollingAvg')))
  shipBase$Key <- factor(shipBase$Key, levels=shipLevels)
  p.RefurbTorchBaseShipments <- ggplot(shipBase, aes(x=DateGroup, y=Record, fill=Key)) + geom_bar(stat='identity') + scale_fill_manual(name='Shipment Type', values=createPaletteOfVariableLength(shipBase, 'Key')) + geom_line(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + geom_point(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Refurbished Torch Base Shipments', subtitle = '4 Week Moving Average', x = 'Date\n(Year-Week)', y ='Shipments') + scale_x_discrete(breaks=dateBreaks)
} else {
  shipBase <- data.frame(DateGroup = unique(ship20$DateGroup), Record = 0)
  p.RefurbTorchBaseShipments <- ggplot(shipBase, aes(x=DateGroup, y=Record)) + geom_bar(stat='identity') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Refurbished Torch Base Shipments', subtitle = '4 Week Moving Average', x = 'Date\n(Year-Week)', y ='Shipments') + scale_x_discrete(breaks=dateBreaks) + scale_y_continuous(limits = c(0,1))
}

#---HTFA-ASY-0003R
shipTorch <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', subset(refurbShip.df, Product == 'Torch Module R'), c('Product', 'Key'), startString.week, 'Record', 'sum', 0)
shipTorch<- shipTorch[order(shipTorch$DateGroup), ]
#4 week moving avg
temp.agg <- with(shipTorch, aggregate(Record~DateGroup, FUN=sum))
l <- length(temp.agg$DateGroup)
temp.agg <- cbind(temp.agg[4:l,], sapply(4:l, function(x) mean(temp.agg[(x-3):x,'Record'])))
colnames(temp.agg)[3] <- 'RollingAvg'
shipTorch <- merge(shipTorch, subset(temp.agg, select=c('DateGroup', 'RollingAvg')))
shipTorch$Key <- factor(shipTorch$Key, levels=shipLevels)
p.RefurbTorchModuleShipments <- ggplot(shipTorch, aes(x=DateGroup, y=Record, fill=Key)) + geom_bar(stat='identity') + scale_fill_manual(name='Shipment Type', values=createPaletteOfVariableLength(shipTorch, 'Key')) + geom_line(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + geom_point(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Refurbished Torch Module Shipments', subtitle = '4 Week Moving Average', x = 'Date\n(Year-Week)', y ='Shipments') + scale_x_discrete(breaks=dateBreaks)

#---COMP-SUB-0016R
shipComp <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', subset(refurbShip.df, Product == 'Computer'), c('Product', 'Key'), startString.week, 'Record', 'sum', 0)
shipComp <- shipComp[order(shipComp$DateGroup), ]
#4 week moving avg
temp.agg <- with(shipComp, aggregate(Record~DateGroup, FUN=sum))
l <- length(temp.agg$DateGroup)
temp.agg <- cbind(temp.agg[4:l,], sapply(4:l, function(x) mean(temp.agg[(x-3):x,'Record'])))
colnames(temp.agg)[3] <- 'RollingAvg'
shipComp <- merge(shipComp, subset(temp.agg, select=c('DateGroup', 'RollingAvg')))
shipComp$Key <- factor(shipComp$Key, levels=shipLevels)
p.RefurbComputerShipments <- ggplot(shipComp, aes(x=DateGroup, y=Record, fill=Key)) + geom_bar(stat='identity') + scale_fill_manual(name='Shipment Type', values=createPaletteOfVariableLength(shipComp, 'Key')) + geom_line(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + geom_point(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Refurbished Computer Shipments', subtitle = '4 Week Moving Average', x = 'Date\n(Year-Week)', y ='Shipments') + scale_x_discrete(breaks=dateBreaks)

# Sales Source of Refurb Shipments by month 
refurbSource <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', refurbShip.df, c('Product', 'SalesSource', 'SalesType'), startString.month, 'Record', 'sum', 0)
p.RefurbSalesType <- ggplot(refurbSource, aes(x=DateGroup, y=Record, fill=SalesType)) + geom_bar(stat='identity') + scale_fill_manual(name='Sales Source', values = createPaletteOfVariableLength(refurbSource, 'SalesType')) + facet_wrap(~Product, scales = 'free_y') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Sales Source of Refurbished Shipments', x = 'Date\n(Year-Month)', y ='Shipments')

# New Inventory Stock Levels 
newStock <- subset(stockInv.df, !(grepl('R$',ItemID)))
#add all ItemIDs to be sure there is at least one row for each
newStock$ItemID <- as.character(newStock$ItemID)
newStock <- rbind(newStock, c('HTFA-ASY-0001', 0), c('HTFA-ASY-0003', 0))
newStock$ItemID[which(grepl("COMP-SUB-0016", newStock$ItemID))] <-  "Laptop - COMP-SUB-0016"
newStock$ItemID[which(grepl("FLM1-ASY-0001", newStock$ItemID))] <-  "FA 1.5 - FLM1-ASY-0001"
newStock$ItemID[which(grepl("FLM2-ASY-0001", newStock$ItemID))] <-  "FA 2.0 - FLM2-ASY-0001"
newStock$ItemID[which(grepl("HTFA-ASY-0001", newStock$ItemID))] <-  "Torch Base - HTFA-ASY-0001"
newStock$ItemID[which(grepl("HTFA-ASY-0003", newStock$ItemID))] <-  "Torch Module - HTFA-ASY-0003"
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
#---by Tier
#calendar.week.all <- createCalendarLikeMicrosoft('2014', 'Week')
startDate.Tier <- paste('2014', as.character(min(tier.df$Week[which(tier.df$Year == '2014')])), sep='-')
tier.all <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', tier.df, c('ServiceTier'), startDate.Tier, 'Record', 'sum', 0)
tier.counts <- data.frame(matrix(nrow=3, ncol=2))
colnames(tier.counts) <- c('Tier', 'Percent') 
tier.counts$Tier <- c('Tier 1', 'Tier 2', 'Tier 3')
tier.counts$Percent <- c(sum(tier.all$Record[which(tier.all$ServiceTier == "Tier 1")], na.rm=TRUE), sum(tier.all$Record[which(tier.all$ServiceTier == "Tier 2")], na.rm=TRUE), sum(tier.all$Record[which(tier.all$ServiceTier == "Tier 3")], na.rm=TRUE))
tier.counts$Percent <- (tier.counts$Percent/sum(tier.counts$Percent))*100
tier.counts$labels <- paste0(as.character(round(tier.counts$Percent, 1)), '%')
p.AllTiers <- ggplot(tier.counts, aes(x=Tier, y=Percent)) + geom_bar(stat='identity', fill='cornflowerblue') + ylim(c(0, 100)) + geom_text(aes(label=labels), position=position_dodge(width=0.9), vjust=-.8, size=6) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Service Tier Repairs of Customer RMAs since 11/2014', x="", y ='Percent of Repairs')
#---by tier and version
tier.version.all <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', tier.df, c('ServiceTier', 'Version'), startDate.Tier, 'Record', 'sum', 0)
tier.version.counts <- data.frame(matrix(ncol=3))
colnames(tier.version.counts) <- c('Tier', 'Version', 'Percent') 
for( t in unique(tier.version.all$ServiceTier)){
  for (v in unique(tier.version.all$Version)){
    tier.version.counts <- rbind(tier.version.counts, list("Tier"= t, "Version"=v, "Percent"=sum(tier.version.all$Record[which(tier.version.all$ServiceTier == t & tier.version.all$Version == v)], na.rm=TRUE)))
  }
}
for (v in unique(tier.version.all$Version)){
  tier.version.counts$Percent[which(tier.version.counts$Version == v)] <- (tier.version.counts$Percent[which(tier.version.counts$Version == v)]/sum(tier.version.counts$Percent[which(tier.version.counts$Version == v)], na.rm=TRUE))*100
}
tier.version.counts <- tier.version.counts[-1, ]
tier.version.counts$Tier <- factor(tier.version.counts$Tier, levels=c('Tier 3', 'Tier 2', 'Tier 1'))
tier.version.counts$labels <- paste0(as.character(round(tier.version.counts$Percent, 1)), '%')
p.AllTiersVersions <- ggplot(tier.version.counts, aes(x=Version, y=Percent, fill=Tier)) + coord_flip() + geom_bar(stat='identity') + geom_text(aes(label=labels), position=position_stack(vjust=0.5), size=5) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Service Tier Repairs of Customer RMAs since 11/2014', x="", y ='Percent of Repairs')

# Current Open Complaints
OpenComplaints <- with(subset(complaints.df, Status == 'Open'), aggregate(Record~Key, FUN=sum))
OpenComplaints$Key <- factor(OpenComplaints$Key, levels = c('0 - 30', '31 - 60', '61 - 90', '91 - 120', '121+'))
p.CurrentOpenComplaints <- ggplot(OpenComplaints, aes(x=Key, y=Record)) + geom_bar(stat='identity', fill='midnightblue') + geom_text(aes(label=Record), vjust=-1, fontface=fontFace, size = 5) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Aging Open Complaints - Days Open', subtitle = paste('Current Open Complaints:', sum(OpenComplaints$Record)), x = 'Days Open', y ='Number of Complaints')

# Complaints Open by month
OpenDate <- subset(complaints.df, select = c('YearOpen', 'MonthOpen', 'Record'))
colnames(OpenDate)[colnames(OpenDate)=='YearOpen'] <- 'Year'
colnames(OpenDate)[colnames(OpenDate)=='MonthOpen'] <- 'Month'
OpenDate$Key <- 'Opened Complaints'
OpenDate <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', OpenDate, 'Key', startString.month3yr.rolling, 'Record', 'sum', 0)
l <- length(OpenDate$DateGroup)
OpenDate <- cbind(OpenDate[4:l,], sapply(4:l, function(x) mean(OpenDate[(x-3):x,'Record'])))
colnames(OpenDate)[4] <- 'RollingAvg'
OpenedComplaints <- subset(OpenDate, DateGroup == currentMonth)[,'Record']
p.ComplaintsOpened <- ggplot(OpenDate, aes(x=DateGroup, y=Record)) + geom_bar(stat='identity', fill="cornflowerblue") + geom_line(aes(x=DateGroup, y=RollingAvg, group=1), color="black") + geom_point(aes(x=DateGroup, y=RollingAvg)) + geom_text(aes(label=Record), position=position_dodge(width=0.9), vjust=-.8, size=5) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle=90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Complaints Received', subtitle = paste('Complaints Opened in', format(Sys.Date(), '%B'),':', OpenedComplaints), x = 'Date\n(Year-Month)', y ='Number of Complaints\n(4 month rolling average)') + scale_y_continuous(limits = c(0,max(OpenDate$Record)+20))

# Complaints opened / number of customer accounts per month
acct.denom <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', acct.df, 'Key', startString.month3yr, 'Record', 'sum', 0)
acct.denom$CumSum <- cumsum(acct.denom$Record)
complaintsOpen.rate <- mergeCalSparseFrames(OpenDate, acct.denom, 'DateGroup', 'DateGroup', 'Record', 'CumSum', 0, 0)
p.CompOpen.CustAccounts.hist <- ggplot(complaintsOpen.rate, aes(x=DateGroup, y=Rate, group=1)) + geom_line() + geom_point() + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Complaints Opened Per Number of Customer Accounts', subtitle='Historic View', x = 'Date\n(Year-Month)', y ='Complaints Opened / Customer Accounts') 
p.ComplaintsOpened.CustAccounts <- ggplot(subset(complaintsOpen.rate, DateGroup >= startString.month), aes(x=DateGroup, y=Rate, group=1)) + geom_line() + geom_point() + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5)) + labs(title = 'Complaints Opened Per Number of Customer Accounts', x = 'Date\n(Year-Month)', y ='Complaints Opened / Customer Accounts') 

# RMAs closed in current month by type (part)
closedRMA <- subset(rmas.df, Status == 'Closed', select = c('YearClose', 'MonthClose', 'Part', 'Type', 'Record'))
colnames(closedRMA)[colnames(closedRMA)=='YearClose'] <- 'Year'
colnames(closedRMA)[colnames(closedRMA)=='MonthClose'] <- 'Month'
closedRMA <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', closedRMA, c('Part', 'Type'), startString.month3yr, 'Record', 'sum', 0)
currentClosedRMA <- with(subset(closedRMA, DateGroup == currentMonth), aggregate(Record~Part, FUN=sum))
lastMonthClosedRMA <- with(subset(closedRMA, DateGroup == lastMonth), aggregate(Record~Part, FUN=sum))
currentClosedRMA$Part <- factor(currentClosedRMA$Part, levels = as.character(unique(currentClosedRMA[with(currentClosedRMA, order(Record, decreasing=TRUE)),'Part'])))
lastMonthClosedRMA$Part <- factor(lastMonthClosedRMA$Part, levels = as.character(unique(lastMonthClosedRMA[with(lastMonthClosedRMA, order(Record, decreasing=TRUE)),'Part'])))
p.CurrentClosedRMA <- ggplot(currentClosedRMA, aes(x=Part, y=Record)) + geom_bar(stat='identity', fill='midnightblue') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5)) + labs(title = paste('RMAs Closed in', format(Sys.Date(), '%B')), x = 'RMA Type', y ='Number of RMAs') + geom_text(aes(label=Record), vjust = -0.75, size = 5)
p.LastMonthClosedRMA <- ggplot(lastMonthClosedRMA, aes(x=Part, y=Record)) + geom_bar(stat='identity', fill='midnightblue') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5)) + labs(title = paste('RMAs Closed in', format(Sys.Date() - months(1), '%B')), x = 'RMA Type', y ='Number of RMAs') + geom_text(aes(label=Record), vjust = -0.75, size = 5)

# RMAs closed over time by month
p.AllClosedRMA <- ggplot(closedRMA, aes(DateGroup, y=Record, fill=Part)) + geom_bar(stat='identity') + scale_fill_manual(name='RMA Type', values = createPaletteOfVariableLength(closedRMA, 'Part')) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5)) + labs(title = 'Closed RMAs', x = 'Date\n(Year-Month)', y ='Number of RMAs') 

# RMA TAT for all service centers
rmaTAT.levels <- c('Days To Ship','Days To Sales Order','Days In Loaner RMA','Days In QC','Days In Service','Days In Quarantine/Decon','Days In Receiving')
rmaTAT <- subset(rmas.df, Disposition == 'Return to Customer' & Part == 'Instrument', select = c('YearShip', 'MonthShip', 'ServiceCenter', 'DaysInReceiving', 'DaysInQuarantine/Decon', 'DaysInService', 'DaysInQC', 'DaysInLoanerRMA', 'DaysToSalesOrder', 'DaysToShip', 'Record'))
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
  avgDaysInLoanerRMA <- data.frame(DateGroup = dateGroups[i], Key = 'Days In Loaner RMA', Record = mean(temp$DaysInLoanerRMA, na.rm=TRUE))
  avgDaysToSalesOrder <- data.frame(DateGroup = dateGroups[i], Key = 'Days To Sales Order', Record = mean(temp$DaysToSalesOrder, na.rm=TRUE))
  avgDaysToShip <- data.frame(DateGroup = dateGroups[i], Key = 'Days To Ship', Record = mean(temp$DaysToShip, na.rm=TRUE))
  avgDaysperPhase <- rbind(avgDaysperPhase, avgDaysInReceiving, avgDaysInQuarantineDecon, avgDaysInService, avgDaysInQC, avgDaysInLoanerRMA, avgDaysToSalesOrder, avgDaysToShip)
}
avgDaysperPhase$Key <- factor(avgDaysperPhase$Key, levels = rmaTAT.levels)
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
  avgDaysInLoanerRMA <- data.frame(DateGroup = dateGroups[i], Key = 'Days In Loaner RMA', Record = mean(temp$DaysInLoanerRMA, na.rm=TRUE))
  avgDaysToSalesOrder <- data.frame(DateGroup = dateGroups[i], Key = 'Days To Sales Order', Record = mean(temp$DaysToSalesOrder, na.rm=TRUE))
  avgDaysToShip <- data.frame(DateGroup = dateGroups[i], Key = 'Days To Ship', Record = mean(temp$DaysToShip, na.rm=TRUE))
  avgDaysperPhase.SL <- rbind(avgDaysperPhase.SL, avgDaysInReceiving, avgDaysInQuarantineDecon, avgDaysInService, avgDaysInQC, avgDaysInLoanerRMA, avgDaysToSalesOrder, avgDaysToShip)
}
avgDaysperPhase.SL$Key <- factor(avgDaysperPhase.SL$Key, levels = rmaTAT.levels)
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
  avgDaysInLoanerRMA <- data.frame(DateGroup = dateGroups[i], Key = 'Days In Loaner RMA', Record = mean(temp$DaysInLoanerRMA, na.rm=TRUE))
  avgDaysToSalesOrder <- data.frame(DateGroup = dateGroups[i], Key = 'Days To Sales Order', Record = mean(temp$DaysToSalesOrder, na.rm=TRUE))
  avgDaysToShip <- data.frame(DateGroup = dateGroups[i], Key = 'Days To Ship', Record = mean(temp$DaysToShip, na.rm=TRUE))
  avgDaysperPhase.FL <- rbind(avgDaysperPhase.FL, avgDaysInReceiving, avgDaysInQuarantineDecon, avgDaysInService, avgDaysInQC, avgDaysInLoanerRMA, avgDaysToSalesOrder, avgDaysToShip)
}
avgDaysperPhase.FL$Key <- factor(avgDaysperPhase.FL$Key, levels = rmaTAT.levels)
p.RMATaT.Florence <- ggplot(avgDaysperPhase.FL, aes(x=DateGroup, y=Record, fill=Key)) + geom_bar(stat='identity') + scale_fill_manual(name='', values = createPaletteOfVariableLength(avgDaysperPhase, 'Key')) + geom_hline(aes(yintercept = 14), lty='dashed', color = 'midnightblue') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5), legend.position = 'bottom') + labs(title = 'Days Per RMA Process for Florence Service Center', subtitle = 'Goal = 14 days', x = 'Shipping Date\n(Year-Month)', y ='Average Days')  

#--- plots of the average days it takes for an rma'd instrument to get to a service center
serviceCenter.df$DateGroup <- with(serviceCenter.df, ifelse(Month < 10, paste0(Year,'-0', Month), paste0(Year,'-',Month)))
serviceCenter.dateGroups <- unique(serviceCenter.df$DateGroup)
allServiceCenters.df <- data.frame(matrix(ncol=2, nrow=length(serviceCenter.dateGroups)))
colnames(allServiceCenters.df) <- c("DateGroup", "AvgDaysToReceived")
allServiceCenters.df$DateGroup <- serviceCenter.dateGroups
allServiceCenters.df$AvgDaysToReceived <- unlist(lapply(unique(serviceCenter.df$DateGroup), function(d)mean(serviceCenter.df$DaysToReceived[which(serviceCenter.df$DateGroup == d)], na.rm=TRUE)))
# remove the first row with data from 2014-04 
allServiceCenters.df <- allServiceCenters.df[-1, ]
p.AllServiceCenters.hist <- ggplot(allServiceCenters.df, aes(x=DateGroup, y=AvgDaysToReceived)) +geom_bar(stat='identity', fill="cornflowerblue") + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle=90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Average Days for a Customer RMA to be Received', subtitle='Historic View', x = 'Date\n(Year-Month)', y ='Average Days')
p.AllServiceCenters <- ggplot(subset(allServiceCenters.df, DateGroup >= startString.month), aes(x=DateGroup, y=AvgDaysToReceived)) +geom_bar(stat='identity', fill="cornflowerblue") + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle=90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Average Days for a Customer RMA to be Received', x = 'Date\n(Year-Month)', y ='Average Days')
serviceCenter.df$ServiceCenterAgg <- rep(NA, nrow(serviceCenter.df))
serviceCenter.df$ServiceCenterAgg[which(serviceCenter.df$ServiceCenter == "Salt Lake" & serviceCenter.df$CustomerType == "US")] <- "Salt Lake - US Customers"
serviceCenter.df$ServiceCenterAgg[which(serviceCenter.df$ServiceCenter == "Salt Lake" & serviceCenter.df$CustomerType == "BMX")] <- "Salt Lake - BMX Customers"
serviceCenter.df$ServiceCenterAgg[which(serviceCenter.df$ServiceCenter == "Florence")] <- "Florence - All Customers"
aggregateDaysToReceived <- aggregateAndFillDateGroupGaps(calendar.month, "Month", serviceCenter.df, c("ServiceCenterAgg"), "2014-11", 'DaysToReceived', 'mean', NA)
aggregateDaysToReceived$ServiceCenterAgg <- factor(aggregateDaysToReceived$ServiceCenterAgg, levels = c('Salt Lake - US Customers', 'Salt Lake - BMX Customers', 'Florence - All Customers'))
p.AggregateServiceCenters <- ggplot(aggregateDaysToReceived, aes(x=DateGroup, y=DaysToReceived)) + geom_bar(stat="identity", fill="cornflowerblue") + facet_wrap(~ServiceCenterAgg, scales="free_y", nrow=3) +theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle=90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Average Days for Customer RMA to be Received By Service Center', x = 'Date\n(Year-Month)', y ='Average Days')

# All RMAs opened by type (part) 
openedRMA <- subset(rmas.df, select = c('YearOpen', 'MonthOpen', 'Part', 'Type', 'Record'))
colnames(openedRMA)[colnames(openedRMA)=='YearOpen'] <- 'Year'
colnames(openedRMA)[colnames(openedRMA)=='MonthOpen'] <- 'Month'
openedRMA <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', openedRMA, c('Part', 'Type'), startString.month3yr, 'Record', 'sum', 0)
p.AllOpenedRMA <- ggplot(openedRMA, aes(DateGroup, y=Record, fill=Part)) + geom_bar(stat='identity') + scale_fill_manual(name='RMA Type', values = createPaletteOfVariableLength(openedRMA, 'Part')) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5)) + labs(title = 'Opened RMAs', x = 'Date\n(Year-Month)', y ='Number of RMAs') 

# Customer RMAs opened by type (part)
p.CustomerOpenedRMA <- ggplot(subset(openedRMA, Type == 'Customer - Failure' | Type == 'Customer - No failure'), aes(DateGroup, y=Record, fill=Part)) + geom_bar(stat='identity') + scale_fill_manual(name='RMA Type', values = createPaletteOfVariableLength(openedRMA, 'Part')) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5)) + labs(title = 'Opened Customer RMAs', x = 'Date\n(Year-Month)', y ='Number of RMAs') 

# Rate of Loaner RMA acceptance / all US customer RMAs
# loaner.yes <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', subset(loaners.df, Loaner == 'Yes'), 'Key', startString.monthRoll, 'Record', 'sum', 0) 
# allcustRMA <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', loaners.df, 'Key', startString.monthRoll, 'Record', 'sum', 1)
# loaner.rate <- mergeCalSparseFrames(loaner.yes, allcustRMA, c('DateGroup', 'Key'), c('DateGroup', 'Key'), 'Record', 'Record', 0, 4)
loaner.yes <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', subset(loaners.df, Loaner == 'Yes'), 'Key', startString.month3yr, 'Record', 'sum', 0) 
allcustRMA <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', loaners.df, 'Key', startString.month3yr, 'Record', 'sum', 1)
loaner.rate <- mergeCalSparseFrames(loaner.yes, allcustRMA, c('DateGroup', 'Key'), c('DateGroup', 'Key'), 'Record', 'Record', 0, 4)
p.LoanerAcceptance <- ggplot(subset(loaner.rate, DateGroup >= '2015-01'), aes(x=DateGroup, y=Rate, group=1)) + geom_line() + geom_point() + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle = 90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5)) + labs(title = 'Acceptance Rate of Loaners in US Customer Instrument RMAs', x = 'Date\n(Year-Month)', y ='Loaners Accepted / Customer RMAs\n(4 Month Rolling Average)') 

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
p1 <- ggplot(CloseDate, aes(x=DateGroup, y=Record)) + geom_bar(stat='identity', fill='cornflowerblue') + geom_text(aes(label=Record), position = position_stack(vjust = 0.25), size = 5) + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20, angle=90), axis.text.y=element_text(hjust=1, color='black', size=20), plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) + labs(title = 'Complaints Closed - Average Days Open', subtitle = paste('Complaints Closed in', format(Sys.Date(), '%B'),':', ClosedComplaints,'\nAverage Days Open in',format(Sys.Date(), '%B'),':',subset(avgDays.agg, DateGroup == currentMonth)[,'DaysOpen'],' Goal = 30 days'), x = 'Date\n(Year-Month)', y ='Number of Complaints')
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

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
library(gridExtra)

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
theme_set(theme_grey()+theme(plot.title=element_text(hjust=0.5), plot.subtitle=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(color='black',size=fontSize,face=fontFace)))

currentMonth <- ifelse(month(Sys.Date()) < 10, paste0(year(Sys.Date()),'-','0',month(Sys.Date())), paste0(year(Sys.Date()),'-',month(Sys.Date())))
curMonthName <- month.name[month(Sys.Date())]
lm <- ifelse(month(Sys.Date()) == 1, 12, month(Sys.Date()) -1)
ly <- ifelse(month(Sys.Date()) == 1, year(Sys.Date())-1, year(Sys.Date()))
lastMonth <- ifelse(lm < 10, paste0(ly,'-0',lm), paste0(ly,'-',lm))
prevMonthName <- ifelse(month(Sys.Date()) == 1, 'December', month.name[month(Sys.Date())-1])

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
p.RefurbStockInventory <- ggplot(refurbStock.agg, aes(x=Key, y=Record)) + geom_bar(stat='identity', width = 0.5) + geom_hline(data=refurbStock.agg, aes(yintercept=SafteyStock), size=1, colour="#0C13A8", linetype=2 ) + facet_wrap(~ItemID, scales='free_y', strip.position = 'bottom')+ theme(strip.background = element_blank(), strip.placement = 'outside') + scale_y_continuous(breaks=pretty_breaks(n=10)) + labs(title='Refurbished Stock Inventory Levels', subtitle='Blue Line = Safety Stock Level', x='', y='Inventory') + geom_text(aes(label=Record), color='lightgrey', vjust = 1.5, size=5, fontface='bold')

# Quantity of refurb parts shipped per week and moving average
refurbShip.df$Key <- rep(NA, nrow(refurbShip.df))
refurbShip.df$Key[which(refurbShip.df$SalesType == "Loaner")] <- "Loaner"
refurbShip.df$Key[which(refurbShip.df$SalesType == "Replacements")] <- "Replacements"
refurbShip.df$Key[which(is.na(refurbShip.df$Key))] <- "Other"
shipLevels <- c('Other','Replacements','Loaner')
#---FLM1-ASY-0001R - by month
ship15 <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', subset(refurbShip.df, Product == 'FA1.5R'), c('Product', 'Key'), startString.monthRoll, 'Record', 'sum', 0)
ship15 <- ship15[order(ship15$DateGroup), ]
# 4 month moving avg
temp.agg <- with(ship15, aggregate(Record~DateGroup, FUN=sum))
l <- length(temp.agg$DateGroup)
temp.agg <- cbind(temp.agg[4:l,], sapply(4:l, function(x) mean(temp.agg[(x-3):x,'Record'])))
colnames(temp.agg)[3] <- 'RollingAvg'
ship15 <- merge(ship15, subset(temp.agg, select=c('DateGroup', 'RollingAvg')))
ship15$Key <- factor(ship15$Key, levels=shipLevels)
p.Refurb1.5Shipments <- ggplot(ship15, aes(x=DateGroup, y=Record, fill=Key)) + geom_bar(stat='identity') + scale_fill_manual(name='Shipment Type', values=createPaletteOfVariableLength(ship15, 'Key')) + geom_line(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + geom_point(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + theme(axis.text.x=element_text(angle = 90)) + labs(title = 'Refurbished FA 1.5 Shipments', subtitle = paste('Rolling Average for', curMonthName, ': ', format(unique(subset(ship15, DateGroup == currentMonth)[,'RollingAvg']),digits=3)), x = 'Date\n(Year-Month)', y ='Shipments\n4 Month Rolling Average Line') 

#---FLM2-ASY-0002R - by month
ship20 <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', subset(refurbShip.df, Product == 'FA2.0R'), c('Product', 'Key'), startString.monthRoll, 'Record', 'sum', 0)
ship20 <- ship20[order(ship20$DateGroup), ]
# 4 month moving avg
temp.agg <- with(ship20, aggregate(Record~DateGroup, FUN=sum))
l <- length(temp.agg$DateGroup)
temp.agg <- cbind(temp.agg[4:l,], sapply(4:l, function(x) mean(temp.agg[(x-3):x,'Record'])))
colnames(temp.agg)[3] <- 'RollingAvg'
ship20 <- merge(ship20, subset(temp.agg, select=c('DateGroup', 'RollingAvg')))
ship20$Key <- factor(ship20$Key, levels=shipLevels)
p.Refurb2.0Shipments <- ggplot(ship20, aes(x=DateGroup, y=Record, fill=Key)) + geom_bar(stat='identity') + scale_fill_manual(name='Shipment Type', values=createPaletteOfVariableLength(ship20, 'Key')) + geom_line(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + geom_point(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + theme(axis.text.x=element_text(angle = 90)) + labs(title = 'Refurbished FA 2.0 Shipments', subtitle = paste('Rolling Average for', curMonthName, ': ', format(unique(subset(ship20, DateGroup == currentMonth)[,'RollingAvg']),digits=3)), x = 'Date\n(Year-Month)', y ='Shipments\n4 Month Rolling Average Line') 

#---HTFA-ASY-0001R - by week
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
  p.RefurbTorchBaseShipments <- ggplot(shipBase, aes(x=DateGroup, y=Record, fill=Key)) + geom_bar(stat='identity') + scale_fill_manual(name='Shipment Type', values=createPaletteOfVariableLength(shipBase, 'Key')) + geom_line(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + geom_point(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + theme(axis.text.x=element_text(angle = 90)) + labs(title = 'Refurbished Torch Base Shipments', subtitle = paste('Rolling Average for Week', tail(shipBase,1)[,'DateGroup'], ': ', format(tail(shipBase,1)[,'RollingAvg'],digits=3)), x = 'Date\n(Year-Week)', y ='Shipments\n4 Week Moving Average Line') + scale_x_discrete(breaks=dateBreaks) 
} else {
  shipBase <- data.frame(DateGroup = unique(ship20$DateGroup), Record = 0)
  p.RefurbTorchBaseShipments <- ggplot(shipBase, aes(x=DateGroup, y=Record)) + geom_bar(stat='identity') + theme(axis.text.x=element_text(angle = 90)) + labs(title = 'Refurbished Torch Base Shipments', x = 'Date\n(Year-Week)', y ='Shipments\n4 Week Moving Average Line') + scale_x_discrete(breaks=dateBreaks) + scale_y_continuous(limits = c(0,1))
}

#---HTFA-ASY-0003R - by week
shipTorch <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', subset(refurbShip.df, Product == 'Torch Module R'), c('Product', 'Key'), startString.week, 'Record', 'sum', 0)
shipTorch<- shipTorch[order(shipTorch$DateGroup), ]
#4 week moving avg
temp.agg <- with(shipTorch, aggregate(Record~DateGroup, FUN=sum))
l <- length(temp.agg$DateGroup)
temp.agg <- cbind(temp.agg[4:l,], sapply(4:l, function(x) mean(temp.agg[(x-3):x,'Record'])))
colnames(temp.agg)[3] <- 'RollingAvg'
shipTorch <- merge(shipTorch, subset(temp.agg, select=c('DateGroup', 'RollingAvg')))
shipTorch$Key <- factor(shipTorch$Key, levels=shipLevels)
p.RefurbTorchModuleShipments <- ggplot(shipTorch, aes(x=DateGroup, y=Record, fill=Key)) + geom_bar(stat='identity') + scale_fill_manual(name='Shipment Type', values=createPaletteOfVariableLength(shipTorch, 'Key')) + geom_line(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + geom_point(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + theme(axis.text.x=element_text(angle = 90)) + labs(title = 'Refurbished Torch Module Shipments', subtitle = paste('Rolling Average for Week', tail(shipTorch,1)[,'DateGroup'], ': ', format(tail(shipTorch,1)[,'RollingAvg'],digits=3)), x = 'Date\n(Year-Week)', y ='Shipments\n4 Week Moving Average Line') + scale_x_discrete(breaks=dateBreaks) 

#---COMP-SUB-0016R - by week
shipComp <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', subset(refurbShip.df, Product == 'Computer'), c('Product', 'Key'), startString.week, 'Record', 'sum', 0)
shipComp <- shipComp[order(shipComp$DateGroup), ]
#4 week moving avg
temp.agg <- with(shipComp, aggregate(Record~DateGroup, FUN=sum))
l <- length(temp.agg$DateGroup)
temp.agg <- cbind(temp.agg[4:l,], sapply(4:l, function(x) mean(temp.agg[(x-3):x,'Record'])))
colnames(temp.agg)[3] <- 'RollingAvg'
shipComp <- merge(shipComp, subset(temp.agg, select=c('DateGroup', 'RollingAvg')))
shipComp$Key <- factor(shipComp$Key, levels=shipLevels)
p.RefurbComputerShipments <- ggplot(shipComp, aes(x=DateGroup, y=Record, fill=Key)) + geom_bar(stat='identity') + scale_fill_manual(name='Shipment Type', values=createPaletteOfVariableLength(shipComp, 'Key')) + geom_line(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + geom_point(inherit.aes = FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + theme(axis.text.x=element_text(angle = 90)) + labs(title = 'Refurbished Computer Shipments', subtitle = paste('Rolling Average for Week', tail(shipComp,1)[,'DateGroup'], ': ', format(tail(shipComp,1)[,'RollingAvg'],digits=3)), x = 'Date\n(Year-Week)', y ='Shipments') + scale_x_discrete(breaks=dateBreaks) 

# Sales Source of Refurb Shipments by month 
refurbSource <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', refurbShip.df, c('Product', 'SalesSource', 'SalesType'), startString.month, 'Record', 'sum', 0)
p.RefurbSalesType <- ggplot(refurbSource, aes(x=DateGroup, y=Record, fill=SalesType)) + geom_bar(stat='identity') + scale_fill_manual(name='Sales Source', values = createPaletteOfVariableLength(refurbSource, 'SalesType')) + facet_wrap(~Product, scales = 'free_y') + theme(axis.text.x=element_text(angle = 90)) + labs(title = 'Sales Source of Refurbished Shipments', x = 'Date\n(Year-Month)', y ='Shipments') + geom_text(data = with(refurbSource, aggregate(Record~DateGroup+Product, FUN=sum)), inherit.aes=FALSE, aes(x=DateGroup, y=Record, label=Record), size=4, fontface='bold', vjust = -0.5)

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
p.NewStockInventory <- ggplot(newStock.agg, aes(x=Key, y=Record)) + geom_bar(stat='identity', width = 0.5) + xlab(' ') + ylab('Inventory') + facet_wrap(~ItemID, scales='free_y', strip.position = 'bottom') + theme(strip.background = element_blank(), strip.placement = 'outside') + ggtitle('New Stock Inventory Levels') + scale_y_continuous(breaks=pretty_breaks(n=10)) + geom_text(aes(label=Record), color='lightgrey', size = 5, vjust = 1.5, fontface='bold')

# Service Tiers
#---by RMA type
tier.type <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', tier.df, c('Type', 'ServiceTier'), startString.week, 'Record', 'sum', 0)
p.ServiceTiersbyType <- ggplot(tier.type, aes(x=DateGroup, y=Record, fill=ServiceTier)) + geom_bar(stat='identity') + scale_fill_manual(name='Service Tier', values = createPaletteOfVariableLength(tier.type, 'ServiceTier')) + facet_wrap(~Type, scales = 'free_y', ncol=1) + theme(axis.text.x=element_text(angle = 90)) + labs(title = 'Service Tier Repairs of FA 1.5, FA 2.0, and Torch', x = 'Date\n(Year-Week)', y ='Repairs') + scale_x_discrete(breaks=dateBreaks)
#---by version
tier.version <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', tier.df, c('Version', 'ServiceTier'), startString.week, 'Record', 'sum', 0)
p.ServiceTiersbyVersion <- ggplot(tier.version, aes(x=DateGroup, y=Record, fill=ServiceTier)) + geom_bar(stat='identity') + scale_fill_manual(name='Service Tier', values = createPaletteOfVariableLength(tier.version, 'ServiceTier')) + facet_wrap(~Version, scales = 'free_y', ncol=1) + theme(axis.text.x=element_text(angle = 90)) + labs(title = 'Service Tier Repairs of Customer RMAs', x = 'Date\n(Year-Week)', y ='Repairs') + scale_x_discrete(breaks=dateBreaks)
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
p.AllTiers <- ggplot(tier.counts, aes(x=Tier, y=Percent)) + geom_bar(stat='identity', fill='cornflowerblue') + ylim(c(0, 100)) + geom_text(aes(label=labels), position=position_dodge(width=0.9), vjust=-.8, size=6) + labs(title = 'Service Tier Repairs of Customer RMAs since 11/2014', x="", y ='Percent of Repairs')
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
p.AllTiersVersions <- ggplot(tier.version.counts, aes(x=Version, y=Percent, fill=Tier)) + coord_flip() + geom_bar(stat='identity') + geom_text(aes(label=labels), position=position_stack(vjust=0.5), size=5) + labs(title = 'Service Tier Repairs of Customer RMAs since 11/2014', x="", y ='Percent of Repairs')

# Current Open Complaints
OpenComplaints <- with(subset(complaints.df, Status == 'Open'), aggregate(Record~Key, FUN=sum))
OpenComplaints$Key <- factor(OpenComplaints$Key, levels = c('0 - 30', '31 - 60', '61 - 90', '91 - 120', '121+'))
p.CurrentOpenComplaints <- ggplot(OpenComplaints, aes(x=Key, y=Record)) + geom_bar(stat='identity', fill='midnightblue') + geom_text(aes(label=Record), vjust=-1, fontface=fontFace, size = 5) + labs(title = 'Aging Open Complaints - Days Open', subtitle = paste('Current Open Complaints:', sum(OpenComplaints$Record)), x = 'Days Open', y ='Number of Complaints')
#previous month freeze
complaints.df$DateMonthOpen <- with(complaints.df, ifelse(MonthOpen < 10, paste0(YearOpen,'-0', MonthOpen), paste0(YearOpen,'-', MonthOpen)))
prevopen <- with(subset(complaints.df, Status == 'Open' & DateMonthOpen <= lastMonth), aggregate(Record~Key, FUN=sum))
prevopen$Key <- factor(prevopen$Key, levels = c('0 - 30', '31 - 60', '61 - 90', '91 - 120', '121+'))
p.PrevOpenComplaints <- ggplot(prevopen, aes(x=Key, y=Record)) + geom_bar(stat='identity', fill='midnightblue') + geom_text(aes(label=Record), vjust=-1, fontface=fontFace, size = 5) + labs(title = 'Aging Open Complaints - Days Open', subtitle = paste('Open Complaints as of', tail(subset(calendar.month, DateGroup == lastMonth), 1)[,'Date'], ':', sum(prevopen$Record)), x = 'Days Open', y ='Number of Complaints')

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
p.ComplaintsOpened <- ggplot(OpenDate, aes(x=DateGroup, y=Record)) + geom_bar(stat='identity', fill="forestgreen") + geom_line(aes(x=DateGroup, y=RollingAvg, group=1), color="black") + geom_point(aes(x=DateGroup, y=RollingAvg)) + geom_text(aes(label=Record), position=position_dodge(width=0.9), vjust=-.5, size=5) + theme(axis.text.x=element_text(angle=90)) + labs(title = 'Complaints Received', subtitle = paste('Complaints Opened in', curMonthName,':', OpenedComplaints, '\nRolling Average for', curMonthName, ':', format(subset(OpenDate, DateGroup == currentMonth)[,'RollingAvg'], digits=3)), x = 'Date\n(Year-Month)', y ='Number of Complaints\n(4 month rolling average)')
#previous month freeze
p.ComplaintsOpened.Prev <- ggplot(subset(OpenDate, DateGroup <= lastMonth), aes(x=DateGroup, y=Record)) + geom_bar(stat='identity', fill="forestgreen") + geom_line(aes(x=DateGroup, y=RollingAvg, group=1), color="black") + geom_point(aes(x=DateGroup, y=RollingAvg)) + geom_text(aes(label=Record), position=position_dodge(width=0.9), vjust=-.5, size=5) + theme(axis.text.x=element_text(angle=90)) + labs(title = 'Complaints Received', subtitle = paste('Complaints Opened in', prevMonthName,':', subset(OpenDate, DateGroup == lastMonth)[,'Record'], '\nRolling Average for', prevMonthName, ':', format(subset(OpenDate, DateGroup == lastMonth)[,'RollingAvg'], digits=3)), x = 'Date\n(Year-Month)', y ='Number of Complaints\n(4 month rolling average)')

# Complaints opened / number of customer accounts per month
acct.denom <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', acct.df, 'Key', startString.month3yr, 'Record', 'sum', 0)
acct.denom$CumSum <- cumsum(acct.denom$Record)
complaintsOpen.rate <- mergeCalSparseFrames(OpenDate, acct.denom, 'DateGroup', 'DateGroup', 'Record', 'CumSum', 0, 0)
p.CompOpen.CustAccounts.hist <- ggplot(complaintsOpen.rate, aes(x=DateGroup, y=Rate, group=1)) + geom_line() + geom_point() + theme(axis.text.x=element_text(angle = 90)) + labs(title = 'Complaints Opened Per Number of Customer Accounts', subtitle='Historic View', x = 'Date\n(Year-Month)', y ='Complaints Opened / Customer Accounts') 

# RMAs closed in current month by type (part)
closedRMA <- subset(rmas.df, Status == 'Closed', select = c('YearClose', 'MonthClose', 'Part', 'Type', 'Record'))
colnames(closedRMA)[colnames(closedRMA)=='YearClose'] <- 'Year'
colnames(closedRMA)[colnames(closedRMA)=='MonthClose'] <- 'Month'
closedRMA <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', closedRMA, c('Part', 'Type'), startString.month3yr, 'Record', 'sum', 0)
currentClosedRMA <- with(subset(closedRMA, DateGroup == currentMonth), aggregate(Record~Part, FUN=sum))
lastMonthClosedRMA <- with(subset(closedRMA, DateGroup == lastMonth), aggregate(Record~Part, FUN=sum))
currentClosedRMA$Part <- factor(currentClosedRMA$Part, levels = as.character(unique(currentClosedRMA[with(currentClosedRMA, order(Record, decreasing=TRUE)),'Part'])))
lastMonthClosedRMA$Part <- factor(lastMonthClosedRMA$Part, levels = as.character(unique(lastMonthClosedRMA[with(lastMonthClosedRMA, order(Record, decreasing=TRUE)),'Part'])))
p.CurrentClosedRMA <- ggplot(currentClosedRMA, aes(x=Part, y=Record)) + geom_bar(stat='identity', fill='midnightblue') + labs(title = paste('RMAs Closed in', curMonthName), x = 'RMA Type', y ='Number of RMAs') + geom_text(aes(label=Record), vjust = -0.75, size = 5)
p.LastMonthClosedRMA <- ggplot(lastMonthClosedRMA, aes(x=Part, y=Record)) + geom_bar(stat='identity', fill='midnightblue') + labs(title = paste('RMAs Closed in', prevMonthName), x = 'RMA Type', y ='Number of RMAs') + geom_text(aes(label=Record), vjust = -0.75, size = 5)

# RMAs closed over time by month
p.AllClosedRMA <- ggplot(closedRMA, aes(DateGroup, y=Record, fill=Part)) + geom_bar(stat='identity') + scale_fill_manual(name='RMA Type', values = createPaletteOfVariableLength(closedRMA, 'Part')) + theme(axis.text.x=element_text(angle = 90)) + labs(title = 'Closed RMAs', x = 'Date\n(Year-Month)', y ='Number of RMAs') 

# RMA TAT for all service centers
rmaTAT.levels <- c('Days To Ship','Days To Sales Order','Days In Loaner RMA','Days In QC','Days In Service','Days In Quarantine/Decon')
rmaTAT <- subset(rmas.df, Disposition == 'Return to Customer' & Part == 'Instrument', select = c('YearShip', 'MonthShip', 'ServiceCenter', 'DaysInReceiving', 'DaysInQuarantine/Decon', 'DaysInService', 'DaysInQC', 'DaysInLoanerRMA', 'DaysToSalesOrder', 'DaysToShip', 'Record'))
rmaTAT$DateGroup <- with(rmaTAT, ifelse(MonthShip < 10, paste0(YearShip,'-0',MonthShip), paste0(YearShip,'-',MonthShip)))
rmaTAT <- subset(rmaTAT, DateGroup >= startString.month3yr)
dateGroups <- sort(as.character(unique(rmaTAT$DateGroup)))
avgDaysperPhase <- c()
for(i in 1:length(dateGroups)) {
  temp <- subset(rmaTAT, DateGroup == dateGroups[i])
  avgDaysInQuarantineDecon <- data.frame(DateGroup = dateGroups[i], Key = 'Days In Quarantine/Decon', Record = mean(temp$'DaysInQuarantine/Decon', na.rm=TRUE))
  avgDaysInService <- data.frame(DateGroup=dateGroups[i], Key = 'Days In Service', Record = mean(temp$DaysInService, na.rm=TRUE))
  avgDaysInQC <- data.frame(DateGroup = dateGroups[i], Key = 'Days In QC', Record = mean(temp$DaysInQC, na.rm=TRUE))
  avgDaysInLoanerRMA <- data.frame(DateGroup = dateGroups[i], Key = 'Days In Loaner RMA', Record = mean(temp$DaysInLoanerRMA, na.rm=TRUE))
  avgDaysToSalesOrder <- data.frame(DateGroup = dateGroups[i], Key = 'Days To Sales Order', Record = mean(temp$DaysToSalesOrder, na.rm=TRUE))
  avgDaysToShip <- data.frame(DateGroup = dateGroups[i], Key = 'Days To Ship', Record = mean(temp$DaysToShip, na.rm=TRUE))
  avgDaysperPhase <- rbind(avgDaysperPhase, avgDaysInQuarantineDecon, avgDaysInService, avgDaysInQC, avgDaysInLoanerRMA, avgDaysToSalesOrder, avgDaysToShip)
}
avgDays.agg <- with(avgDaysperPhase, aggregate(Record~DateGroup, FUN=sum))
l <- length(avgDays.agg$DateGroup)
avgDays.agg <- cbind(avgDays.agg[4:l,], sapply(4:l, function(x) mean(avgDays.agg[(x-3):x,'Record'])))
colnames(avgDays.agg)[3] <- 'RollingAvg'
avgDaysperPhase <- merge(avgDaysperPhase, subset(avgDays.agg, select=c('DateGroup', 'RollingAvg')))
avgDaysperPhase$Key <- factor(avgDaysperPhase$Key, levels = rmaTAT.levels)
p.RMATaT <- ggplot(avgDaysperPhase, aes(x=DateGroup, y=Record, fill=Key)) + geom_bar(stat='identity') + geom_line(inherit.aes=FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + geom_point(inherit.aes=FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + scale_fill_manual(name='', values = createPaletteOfVariableLength(avgDaysperPhase, 'Key')) + geom_hline(aes(yintercept = 14), lty='dashed', color = 'forestgreen') + theme(axis.text.x=element_text(angle = 90), legend.position = 'bottom', plot.caption = element_text(hjust=0, size=14)) + labs(title = 'Days Per RMA Process', subtitle = paste('Goal = 14 days, Rolling Average for', curMonthName, ':', format(subset(avgDays.agg, DateGroup == currentMonth)[,'RollingAvg'], digits=3)), x = 'Shipping Date\n(Year-Month)', y ='Average Days\n4 Month Rolling Average Line', caption = 'Instrument RMAs where Disposition is "Return to Customer"') + geom_text(data = avgDays.agg, inherit.aes=FALSE, aes(x=DateGroup, y=Record, label=format(Record, digits=2)), size=5, fontface='bold', vjust=-0.5)

# RMA TAT for SL service center
rmaTAT.SL <- subset(rmaTAT, ServiceCenter == 'Salt Lake')
dateGroups <- sort(as.character(unique(rmaTAT.SL$DateGroup)))
avgDaysperPhase.SL <- c()
for(i in 1:length(dateGroups)) {
  temp <- subset(rmaTAT.SL, DateGroup == dateGroups[i])
  avgDaysInQuarantineDecon <- data.frame(DateGroup = dateGroups[i], Key = 'Days In Quarantine/Decon', Record = mean(temp$'DaysInQuarantine/Decon', na.rm=TRUE))
  avgDaysInService <- data.frame(DateGroup=dateGroups[i], Key = 'Days In Service', Record = mean(temp$DaysInService, na.rm=TRUE))
  avgDaysInQC <- data.frame(DateGroup = dateGroups[i], Key = 'Days In QC', Record = mean(temp$DaysInQC, na.rm=TRUE))
  avgDaysInLoanerRMA <- data.frame(DateGroup = dateGroups[i], Key = 'Days In Loaner RMA', Record = mean(temp$DaysInLoanerRMA, na.rm=TRUE))
  avgDaysToSalesOrder <- data.frame(DateGroup = dateGroups[i], Key = 'Days To Sales Order', Record = mean(temp$DaysToSalesOrder, na.rm=TRUE))
  avgDaysToShip <- data.frame(DateGroup = dateGroups[i], Key = 'Days To Ship', Record = mean(temp$DaysToShip, na.rm=TRUE))
  avgDaysperPhase.SL <- rbind(avgDaysperPhase.SL, avgDaysInQuarantineDecon, avgDaysInService, avgDaysInQC, avgDaysInLoanerRMA, avgDaysToSalesOrder, avgDaysToShip)
}
avgDaysSL.agg <- with(avgDaysperPhase.SL, aggregate(Record~DateGroup, FUN=sum))
l <- length(avgDaysSL.agg$DateGroup)
avgDaysSL.agg <- cbind(avgDaysSL.agg[4:l,], sapply(4:l, function(x) mean(avgDaysSL.agg[(x-3):x,'Record'])))
colnames(avgDaysSL.agg)[3] <- 'RollingAvg'
avgDaysperPhase.SL <- merge(avgDaysperPhase.SL, subset(avgDaysSL.agg, select=c('DateGroup', 'RollingAvg')))
avgDaysperPhase.SL$Key <- factor(avgDaysperPhase.SL$Key, levels = rmaTAT.levels)
p.RMATaT.SaltLake <- ggplot(avgDaysperPhase.SL, aes(x=DateGroup, y=Record, fill=Key)) + geom_bar(stat='identity') + geom_line(inherit.aes=FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + geom_point(inherit.aes=FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + scale_fill_manual(name='', values = createPaletteOfVariableLength(avgDaysperPhase, 'Key')) + geom_hline(aes(yintercept = 14), lty='dashed', color = 'forestgreen') + theme(axis.text.x=element_text(angle = 90), legend.position = 'bottom', plot.caption = element_text(hjust=0, size=14)) + labs(title = 'Days Per RMA Process for Salt Lake Service Center', subtitle = paste('Goal = 14 days, Rolling Average for', curMonthName, ':', format(subset(avgDaysSL.agg, DateGroup == currentMonth)[,'RollingAvg'], digits=3)), x = 'Shipping Date\n(Year-Month)', y ='Average Days\n4 Month Rolling Average Line', caption = 'Instrument RMAs where Disposition is "Return to Customer"') + geom_text(data = avgDaysSL.agg, inherit.aes=FALSE, aes(x=DateGroup, y=Record, label=format(Record, digits=2)), size=5, fontface='bold', vjust=-0.5)  
# current month table 
avgDaysinReceiving.cur <- mean(subset(rmaTAT.SL, DateGroup == currentMonth)[,'DaysInReceiving'], na.rm=TRUE)
avgDaysinReceiving.prev <- mean(subset(rmaTAT.SL, DateGroup == lastMonth)[,'DaysInReceiving'], na.rm=TRUE)
avgDaysinReceiving.year <- mean(subset(rmaTAT.SL, DateGroup >= findStartDate(calendar.month, 'Month', 12, 0))[,'DaysInReceiving'], na.rm=TRUE)
avgDaysInQuarantineDecon.cur <- subset(avgDaysperPhase.SL, DateGroup == currentMonth & Key == 'Days In Quarantine/Decon')[,'Record']
avgDaysInQuarantineDecon.prev <- subset(avgDaysperPhase.SL, DateGroup == lastMonth & Key == 'Days In Quarantine/Decon')[,'Record']
avgDaysInQuarantineDecon.year <- mean(subset(rmaTAT.SL, DateGroup >= findStartDate(calendar.month, 'Month', 12, 0))[,'DaysInQuarantine/Decon'], na.rm=TRUE)
avgDaysInService.cur <- subset(avgDaysperPhase.SL, DateGroup == currentMonth & Key == 'Days In Service')[,'Record']
avgDaysInService.prev <- subset(avgDaysperPhase.SL, DateGroup == lastMonth & Key == 'Days In Service')[,'Record']
avgDaysInService.year <- mean(subset(rmaTAT.SL, DateGroup >= findStartDate(calendar.month, 'Month', 12, 0))[,'DaysInService'], na.rm=TRUE)
avgDaysInQC.cur <- subset(avgDaysperPhase.SL, DateGroup == currentMonth & Key == 'Days In QC')[,'Record']
avgDaysInQC.prev <- subset(avgDaysperPhase.SL, DateGroup == lastMonth & Key == 'Days In QC')[,'Record']
avgDaysInQC.year <- mean(subset(rmaTAT.SL, DateGroup >= findStartDate(calendar.month, 'Month', 12, 0))[,'DaysInQC'], na.rm=TRUE)
avgDaysInLoaner.cur <- subset(avgDaysperPhase.SL, DateGroup == currentMonth & Key == 'Days In Loaner RMA')[,'Record']
avgDaysInLoaner.prev <- subset(avgDaysperPhase.SL, DateGroup == lastMonth & Key == 'Days In Loaner RMA')[,'Record']
avgDaysInLoaner.year <- mean(subset(rmaTAT.SL, DateGroup >= findStartDate(calendar.month, 'Month', 12, 0))[,'DaysInLoanerRMA'], na.rm=TRUE)
avgDaysInSO.cur <- subset(avgDaysperPhase.SL, DateGroup == currentMonth & Key == 'Days To Sales Order')[,'Record']
avgDaysInSO.prev <- subset(avgDaysperPhase.SL, DateGroup == lastMonth & Key == 'Days To Sales Order')[,'Record']
avgDaysInSO.year <- mean(subset(rmaTAT.SL, DateGroup >= findStartDate(calendar.month, 'Month', 12, 0))[,'DaysToSalesOrder'], na.rm=TRUE)
avgDaysInShip.cur <- subset(avgDaysperPhase.SL, DateGroup == currentMonth & Key == 'Days To Ship')[,'Record']
avgDaysInShip.prev <- subset(avgDaysperPhase.SL, DateGroup == lastMonth & Key == 'Days To Ship')[,'Record']
avgDaysInShip.year <- mean(subset(rmaTAT.SL, DateGroup >= findStartDate(calendar.month, 'Month', 12, 0))[,'DaysToShip'], na.rm=TRUE)
table.RMASaltLake <- data.frame('PhaseofRMA' = c('Receiving', 
                                                 'Quarantine/Release', 
                                                 'Service', 
                                                 'Instrument QC and DHR', 
                                                 'Loaner RMA', 
                                                 'Sales Order Generation', 
                                                 'Shipping'),
           'DaysPerProcessGoal' = c('< 6 Days', 
                                    '2 Days', 
                                    '4 Days', 
                                    '2 Days', 
                                    '< 1 Day', 
                                    '1 Day', 
                                    '1 Day'),
           'CurrentMonth' = c(format(avgDaysinReceiving.cur, digits = 3),
                              format(avgDaysInQuarantineDecon.cur, digits = 3),
                              format(avgDaysInService.cur, digits = 3),
                              format(avgDaysInQC.cur, digits = 3),
                              format(avgDaysInLoaner.cur, digits = 3),
                              format(avgDaysInSO.cur, digits = 3),
                              format(avgDaysInShip.cur, digits = 3)),
           'PreviousMonth' = c(format(avgDaysinReceiving.prev, digits = 3),
                               format(avgDaysInQuarantineDecon.prev, digits = 3),
                               format(avgDaysInService.prev, digits = 3),
                               format(avgDaysInQC.prev, digits = 3),
                               format(avgDaysInLoaner.prev, digits = 3),
                               format(avgDaysInSO.prev, digits = 3),
                               format(avgDaysInShip.prev, digits = 3)),
           'Delta' = c(format(abs(avgDaysinReceiving.cur - avgDaysinReceiving.prev), digits=3),
                       format(abs(avgDaysInQuarantineDecon.cur - avgDaysInQuarantineDecon.prev), digits=3),
                       format(abs(avgDaysInService.cur - avgDaysInService.prev), digits=3),
                       format(abs(avgDaysInQC.cur - avgDaysInQC.prev), digits=3),
                       format(abs(avgDaysInLoaner.cur - avgDaysInLoaner.prev), digits=3),
                       format(abs(avgDaysInSO.cur - avgDaysInSO.prev), digits=3),
                       format(abs(avgDaysInShip.cur - avgDaysInShip.prev), digits=3)),
           'AverageDaysForPrevious1Year' = c(format(avgDaysinReceiving.year, digits=3),
                                             format(avgDaysInQuarantineDecon.year, digits=3),
                                             format(avgDaysInService.year, digits=3),
                                             format(avgDaysInQC.year, digits=3),
                                             format(avgDaysInLoaner.year, digits=3),
                                             format(avgDaysInSO.year, digits=3),
                                             format(avgDaysInShip.year, digits=3)))
colnames(table.RMASaltLake) <- c('Phase of RMA', 'Days Per Process -\nGoal', 'Current Month', 'Previous Month', 'Delta', 'Average Days For\nPrevious 1 Year')
if(!is.na(avgDaysinReceiving.cur) & avgDaysinReceiving.cur >= 6) {
  curTableFill <- 'red'
} else {
  curTableFill <- 'green'
}
if(!is.na(avgDaysInQuarantineDecon.cur) & avgDaysInQuarantineDecon.cur > 2) {
  curTableFill <- c(curTableFill, 'red')
} else {
  curTableFill <- c(curTableFill, 'green')
}
if(!is.na(avgDaysInService.cur) & avgDaysInService.cur > 4) {
  curTableFill <- c(curTableFill, 'red')
} else { 
  curTableFill <- c(curTableFill, 'green')
}
if(!is.na(avgDaysInQC.cur) & avgDaysInQC.cur > 2) {
  curTableFill <- c(curTableFill, 'red')
} else { 
  curTableFill <- c(curTableFill, 'green')
}
if(!is.na(avgDaysInLoaner.cur) & avgDaysInLoaner.cur >= 1) {
  curTableFill <- c(curTableFill, 'red')
} else { 
  curTableFill <- c(curTableFill, 'green')
} 
if(!is.na(avgDaysInSO.cur) & avgDaysInSO.cur > 1) {
  curTableFill <- c(curTableFill, 'red')
} else { 
  curTableFill <- c(curTableFill, 'green')
} 
if(!is.na(avgDaysInShip.cur) & avgDaysInShip.cur > 1) {
  curTableFill <- c(curTableFill, 'red')
} else { 
  curTableFill <- c(curTableFill, 'green')
} 
tt1 <- ttheme_minimal(
  core=list(bg_params = list(fill = curTableFill, alpha = 0.5, col=1),
            fg_params=list(fontface=1, fontsize=18)),
  colhead=list(fg_params=list(col="black", fontface='bold', fontsize=20)))

t1 <- tableGrob(table.RMASaltLake, rows=NULL, theme = tt1)
title <- textGrob(paste0("Salt Lake RMA Process Flow - ", curMonthName, '\nGreen = Within Goal, Red = Out of Goal'),gp=gpar(fontsize=20, fontface='bold'))
padding <- unit(5,"mm")
table1 <- gtable_add_rows(
  t1, 
  heights = grobHeight(title) + padding,
  pos = 0)
table1 <- gtable_add_grob(
  table1, 
  title, 
  1, 1, 1, ncol(table1))

# prev month table 
if(month(Sys.Date()) < 3) {
  lly <- year(Sys.Date())-1
  if(month(Sys.Date()) == 1) {
    llm <- 11
  } else {
    llm <- 12
  }
} else {
  llm <- month(Sys.Date())-2
  lly <- year(Sys.Date())
}
prevprevMonth <- ifelse(llm < 10, paste0(lly,'-0',llm), paste0(lly,'-',llm))
avgDaysinReceiving.cur <- mean(subset(rmaTAT.SL, DateGroup == lastMonth)[,'DaysInReceiving'], na.rm=TRUE)
avgDaysinReceiving.prev <- mean(subset(rmaTAT.SL, DateGroup == prevprevMonth)[,'DaysInReceiving'], na.rm=TRUE)
avgDaysinReceiving.year <- mean(subset(rmaTAT.SL, DateGroup >= findStartDate(calendar.month, 'Month', 13, 0) & DateGroup <= lastMonth)[,'DaysInReceiving'], na.rm=TRUE)
avgDaysInQuarantineDecon.cur <- subset(avgDaysperPhase.SL, DateGroup == lastMonth & Key == 'Days In Quarantine/Decon')[,'Record']
avgDaysInQuarantineDecon.prev <- subset(avgDaysperPhase.SL, DateGroup == prevprevMonth & Key == 'Days In Quarantine/Decon')[,'Record']
avgDaysInQuarantineDecon.year <- mean(subset(rmaTAT.SL, DateGroup >= findStartDate(calendar.month, 'Month', 13, 0) & DateGroup <= lastMonth)[,'DaysInQuarantine/Decon'], na.rm=TRUE)
avgDaysInService.cur <- subset(avgDaysperPhase.SL, DateGroup == lastMonth & Key == 'Days In Service')[,'Record']
avgDaysInService.prev <- subset(avgDaysperPhase.SL, DateGroup == prevprevMonth & Key == 'Days In Service')[,'Record']
avgDaysInService.year <- mean(subset(rmaTAT.SL, DateGroup >= findStartDate(calendar.month, 'Month', 13, 0) & DateGroup <= lastMonth)[,'DaysInService'], na.rm=TRUE)
avgDaysInQC.cur <- subset(avgDaysperPhase.SL, DateGroup == lastMonth & Key == 'Days In QC')[,'Record']
avgDaysInQC.prev <- subset(avgDaysperPhase.SL, DateGroup == prevprevMonth & Key == 'Days In QC')[,'Record']
avgDaysInQC.year <- mean(subset(rmaTAT.SL, DateGroup >= findStartDate(calendar.month, 'Month', 13, 0) & DateGroup <= lastMonth)[,'DaysInQC'], na.rm=TRUE)
avgDaysInLoaner.cur <- subset(avgDaysperPhase.SL, DateGroup == lastMonth & Key == 'Days In Loaner RMA')[,'Record']
avgDaysInLoaner.prev <- subset(avgDaysperPhase.SL, DateGroup == prevprevMonth & Key == 'Days In Loaner RMA')[,'Record']
avgDaysInLoaner.year <- mean(subset(rmaTAT.SL, DateGroup >= findStartDate(calendar.month, 'Month', 13, 0) & DateGroup <= lastMonth)[,'DaysInLoanerRMA'], na.rm=TRUE)
avgDaysInSO.cur <- subset(avgDaysperPhase.SL, DateGroup == lastMonth & Key == 'Days To Sales Order')[,'Record']
avgDaysInSO.prev <- subset(avgDaysperPhase.SL, DateGroup == prevprevMonth & Key == 'Days To Sales Order')[,'Record']
avgDaysInSO.year <- mean(subset(rmaTAT.SL, DateGroup >= findStartDate(calendar.month, 'Month', 13, 0) & DateGroup <= lastMonth)[,'DaysToSalesOrder'], na.rm=TRUE)
avgDaysInShip.cur <- subset(avgDaysperPhase.SL, DateGroup == lastMonth & Key == 'Days To Ship')[,'Record']
avgDaysInShip.prev <- subset(avgDaysperPhase.SL, DateGroup == prevprevMonth & Key == 'Days To Ship')[,'Record']
avgDaysInShip.year <- mean(subset(rmaTAT.SL, DateGroup >= findStartDate(calendar.month, 'Month', 13, 0) & DateGroup <= lastMonth)[,'DaysToShip'], na.rm=TRUE)
table.RMASaltLake.prev <- data.frame('PhaseofRMA' = c('Receiving', 
                                                 'Quarantine/Release', 
                                                 'Service', 
                                                 'Instrument QC and DHR', 
                                                 'Loaner RMA', 
                                                 'Sales Order Generation', 
                                                 'Shipping'),
                                'DaysPerProcessGoal' = c('< 6 Days', 
                                                         '2 Days', 
                                                         '4 Days', 
                                                         '2 Days', 
                                                         '< 1 Day', 
                                                         '1 Day', 
                                                         '1 Day'),
                                'CurrentMonth' = c(format(avgDaysinReceiving.cur, digits = 3),
                                                   format(avgDaysInQuarantineDecon.cur, digits = 3),
                                                   format(avgDaysInService.cur, digits = 3),
                                                   format(avgDaysInQC.cur, digits = 3),
                                                   format(avgDaysInLoaner.cur, digits = 3),
                                                   format(avgDaysInSO.cur, digits = 3),
                                                   format(avgDaysInShip.cur, digits = 3)),
                                'PreviousMonth' = c(format(avgDaysinReceiving.prev, digits = 3),
                                                    format(avgDaysInQuarantineDecon.prev, digits = 3),
                                                    format(avgDaysInService.prev, digits = 3),
                                                    format(avgDaysInQC.prev, digits = 3),
                                                    format(avgDaysInLoaner.prev, digits = 3),
                                                    format(avgDaysInSO.prev, digits = 3),
                                                    format(avgDaysInShip.prev, digits = 3)),
                                'Delta' = c(format(abs(avgDaysinReceiving.cur - avgDaysinReceiving.prev), digits=3),
                                            format(abs(avgDaysInQuarantineDecon.cur - avgDaysInQuarantineDecon.prev), digits=3),
                                            format(abs(avgDaysInService.cur - avgDaysInService.prev), digits=3),
                                            format(abs(avgDaysInQC.cur - avgDaysInQC.prev), digits=3),
                                            format(abs(avgDaysInLoaner.cur - avgDaysInLoaner.prev), digits=3),
                                            format(abs(avgDaysInSO.cur - avgDaysInSO.prev), digits=3),
                                            format(abs(avgDaysInShip.cur - avgDaysInShip.prev), digits=3)),
                                'AverageDaysForPrevious1Year' = c(format(avgDaysinReceiving.year, digits=3),
                                                                  format(avgDaysInQuarantineDecon.year, digits=3),
                                                                  format(avgDaysInService.year, digits=3),
                                                                  format(avgDaysInQC.year, digits=3),
                                                                  format(avgDaysInLoaner.year, digits=3),
                                                                  format(avgDaysInSO.year, digits=3),
                                                                  format(avgDaysInShip.year, digits=3)))
colnames(table.RMASaltLake.prev) <- c('Phase of RMA', 'Days Per Process -\nGoal', 'Current Month', 'Previous Month', 'Delta', 'Average Days For\nPrevious 1 Year')
if(!is.na(avgDaysinReceiving.cur) & avgDaysinReceiving.cur >= 6) {
  prevTableFill <- 'red'
} else {
  prevTableFill <- 'green'
}
if(!is.na(avgDaysInQuarantineDecon.cur) & avgDaysInQuarantineDecon.cur > 2) {
  prevTableFill <- c(prevTableFill, 'red')
} else {
  prevTableFill <- c(prevTableFill, 'green')
}
if(!is.na(avgDaysInService.cur) & avgDaysInService.cur > 4) {
  prevTableFill <- c(prevTableFill, 'red')
} else { 
  prevTableFill <- c(prevTableFill, 'green')
}
if(!is.na(avgDaysInQC.cur) & avgDaysInQC.cur > 2) {
  prevTableFill <- c(prevTableFill, 'red')
} else { 
  prevTableFill <- c(prevTableFill, 'green')
}
if(!is.na(avgDaysInLoaner.cur) & avgDaysInLoaner.cur >= 1) {
  prevTableFill <- c(prevTableFill, 'red')
} else { 
  prevTableFill <- c(prevTableFill, 'green')
} 
if(!is.na(avgDaysInSO.cur) & avgDaysInSO.cur > 1) {
  prevTableFill <- c(prevTableFill, 'red')
} else { 
  prevTableFill <- c(prevTableFill, 'green')
} 
if(!is.na(avgDaysInShip.cur) & avgDaysInShip.cur > 1) {
  prevTableFill <- c(prevTableFill, 'red')
} else { 
  prevTableFill <- c(prevTableFill, 'green')
} 
tt2 <- ttheme_minimal(
  core=list(bg_params = list(fill = prevTableFill, alpha = 0.5, col=1),
            fg_params=list(fontface=1, fontsize=18)),
  colhead=list(fg_params=list(col="black", fontface='bold', fontsize=20)))

t2 <- tableGrob(table.RMASaltLake.prev, rows=NULL, theme = tt2)
title <- textGrob(paste0("Salt Lake RMA Process Flow - ", prevMonthName, '\nGreen = Within Goal, Red = Out of Goal'),gp=gpar(fontsize=20, fontface='bold'))
padding <- unit(5,"mm")
table2 <- gtable_add_rows(
  t2, 
  heights = grobHeight(title) + padding,
  pos = 0)
table2 <- gtable_add_grob(
  table2, 
  title, 
  1, 1, 1, ncol(table2))

# RMA TAT for Florence service center
rmaTAT.FL <- subset(rmaTAT, ServiceCenter == 'Florence')
dateGroups <- sort(as.character(unique(rmaTAT.FL$DateGroup)))
avgDaysperPhase.FL <- c()
for(i in 1:length(dateGroups)) {
  temp <- subset(rmaTAT.FL, DateGroup == dateGroups[i])
  avgDaysInQuarantineDecon <- data.frame(DateGroup = dateGroups[i], Key = 'Days In Quarantine/Decon', Record = mean(temp$'DaysInQuarantine/Decon', na.rm=TRUE))
  avgDaysInService <- data.frame(DateGroup=dateGroups[i], Key = 'Days In Service', Record = mean(temp$DaysInService, na.rm=TRUE))
  avgDaysInQC <- data.frame(DateGroup = dateGroups[i], Key = 'Days In QC', Record = mean(temp$DaysInQC, na.rm=TRUE))
  avgDaysInLoanerRMA <- data.frame(DateGroup = dateGroups[i], Key = 'Days In Loaner RMA', Record = mean(temp$DaysInLoanerRMA, na.rm=TRUE))
  avgDaysToSalesOrder <- data.frame(DateGroup = dateGroups[i], Key = 'Days To Sales Order', Record = mean(temp$DaysToSalesOrder, na.rm=TRUE))
  avgDaysToShip <- data.frame(DateGroup = dateGroups[i], Key = 'Days To Ship', Record = mean(temp$DaysToShip, na.rm=TRUE))
  avgDaysperPhase.FL <- rbind(avgDaysperPhase.FL, avgDaysInQuarantineDecon, avgDaysInService, avgDaysInQC, avgDaysInLoanerRMA, avgDaysToSalesOrder, avgDaysToShip)
}
avgDaysFL.agg <- with(avgDaysperPhase.FL, aggregate(Record~DateGroup, FUN=sum))
l <- length(avgDaysFL.agg$DateGroup)
avgDaysFL.agg <- cbind(avgDaysFL.agg[4:l,], sapply(4:l, function(x) mean(avgDaysFL.agg[(x-3):x,'Record'])))
colnames(avgDaysFL.agg)[3] <- 'RollingAvg'
avgDaysperPhase.FL <- merge(avgDaysperPhase.FL, subset(avgDaysFL.agg, select=c('DateGroup', 'RollingAvg')))
avgDaysperPhase.FL$Key <- factor(avgDaysperPhase.FL$Key, levels = rmaTAT.levels)
p.RMATaT.Florence <- ggplot(avgDaysperPhase.FL, aes(x=DateGroup, y=Record, fill=Key)) + geom_bar(stat='identity') + geom_line(inherit.aes=FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + geom_point(inherit.aes=FALSE, aes(x=DateGroup, y=RollingAvg, group = 1)) + scale_fill_manual(name='', values = createPaletteOfVariableLength(avgDaysperPhase, 'Key')) + geom_hline(aes(yintercept = 14), lty='dashed', color = 'forestgreen') + theme(axis.text.x=element_text(angle = 90), legend.position = 'bottom', plot.caption = element_text(hjust=0, size=14)) + labs(title = 'Days Per RMA Process for Florence Service Center', subtitle = paste('Goal = 14 days, Rolling Average for', curMonthName, ':', format(subset(avgDaysFL.agg, DateGroup == currentMonth)[,'RollingAvg'], digits=3)), x = 'Shipping Date\n(Year-Month)', y ='Average Days\n4 Month Rolling Average Line', caption = 'Instrument RMAs where Disposition is "Return to Customer"') + geom_text(data = avgDaysFL.agg, inherit.aes=FALSE, aes(x=DateGroup, y=Record, label=format(Record, digits=2)), size=5, fontface='bold', vjust=-0.5)  
# current month table 
avgDaysinReceiving.cur <- mean(subset(rmaTAT.FL, DateGroup == currentMonth)[,'DaysInReceiving'], na.rm=TRUE)
avgDaysinReceiving.prev <- mean(subset(rmaTAT.FL, DateGroup == lastMonth)[,'DaysInReceiving'], na.rm=TRUE)
avgDaysinReceiving.year <- mean(subset(rmaTAT.FL, DateGroup >= findStartDate(calendar.month, 'Month', 12, 0))[,'DaysInReceiving'], na.rm=TRUE)
avgDaysInQuarantineDecon.cur <- subset(avgDaysperPhase.FL, DateGroup == currentMonth & Key == 'Days In Quarantine/Decon')[,'Record']
avgDaysInQuarantineDecon.prev <- subset(avgDaysperPhase.FL, DateGroup == lastMonth & Key == 'Days In Quarantine/Decon')[,'Record']
avgDaysInQuarantineDecon.year <- mean(subset(rmaTAT.FL, DateGroup >= findStartDate(calendar.month, 'Month', 12, 0))[,'DaysInQuarantine/Decon'], na.rm=TRUE)
avgDaysInService.cur <- subset(avgDaysperPhase.FL, DateGroup == currentMonth & Key == 'Days In Service')[,'Record']
avgDaysInService.prev <- subset(avgDaysperPhase.FL, DateGroup == lastMonth & Key == 'Days In Service')[,'Record']
avgDaysInService.year <- mean(subset(rmaTAT.FL, DateGroup >= findStartDate(calendar.month, 'Month', 12, 0))[,'DaysInService'], na.rm=TRUE)
avgDaysInQC.cur <- subset(avgDaysperPhase.FL, DateGroup == currentMonth & Key == 'Days In QC')[,'Record']
avgDaysInQC.prev <- subset(avgDaysperPhase.FL, DateGroup == lastMonth & Key == 'Days In QC')[,'Record']
avgDaysInQC.year <- mean(subset(rmaTAT.FL, DateGroup >= findStartDate(calendar.month, 'Month', 12, 0))[,'DaysInQC'], na.rm=TRUE)
avgDaysInShip.cur <- subset(avgDaysperPhase.FL, DateGroup == currentMonth & Key == 'Days To Ship')[,'Record']
avgDaysInShip.prev <- subset(avgDaysperPhase.FL, DateGroup == lastMonth & Key == 'Days To Ship')[,'Record']
avgDaysInShip.year <- mean(subset(rmaTAT.FL, DateGroup >= findStartDate(calendar.month, 'Month', 12, 0))[,'DaysToShip'], na.rm=TRUE)
table.RMAFlorence <- data.frame('PhaseofRMA' = c('Receiving', 
                                                 'Quarantine/Release', 
                                                 'Service', 
                                                 'Instrument QC and DHR', 
                                                 'Shipping'),
                                'DaysPerProcessGoal' = c('< 6 Days', 
                                                         '2 Days', 
                                                         '4 Days', 
                                                         '2 Days', 
                                                         '1 Day'),
                                'CurrentMonth' = c(format(avgDaysinReceiving.cur, digits = 3),
                                                   format(avgDaysInQuarantineDecon.cur, digits = 3),
                                                   format(avgDaysInService.cur, digits = 3),
                                                   format(avgDaysInQC.cur, digits = 3),
                                                   format(avgDaysInShip.cur, digits = 3)),
                                'PreviousMonth' = c(format(avgDaysinReceiving.prev, digits = 3),
                                                    format(avgDaysInQuarantineDecon.prev, digits = 3),
                                                    format(avgDaysInService.prev, digits = 3),
                                                    format(avgDaysInQC.prev, digits = 3),
                                                    format(avgDaysInShip.prev, digits = 3)),
                                'Delta' = c(format(abs(avgDaysinReceiving.cur - avgDaysinReceiving.prev), digits=3),
                                            format(abs(avgDaysInQuarantineDecon.cur - avgDaysInQuarantineDecon.prev), digits=3),
                                            format(abs(avgDaysInService.cur - avgDaysInService.prev), digits=3),
                                            format(abs(avgDaysInQC.cur - avgDaysInQC.prev), digits=3),
                                            format(abs(avgDaysInShip.cur - avgDaysInShip.prev), digits=3)),
                                'AverageDaysForPrevious1Year' = c(format(avgDaysinReceiving.year, digits=3),
                                                                  format(avgDaysInQuarantineDecon.year, digits=3),
                                                                  format(avgDaysInService.year, digits=3),
                                                                  format(avgDaysInQC.year, digits=3),
                                                                  format(avgDaysInShip.year, digits=3)))
colnames(table.RMAFlorence) <- c('Phase of RMA', 'Days Per Process -\nGoal', 'Current Month', 'Previous Month', 'Delta', 'Average Days For\nPrevious 1 Year')
if(!is.na(avgDaysinReceiving.cur) & avgDaysinReceiving.cur >= 6) {
  curTableFill.f <- 'red'
} else {
  curTableFill.f <- 'green'
}
if(!is.na(avgDaysInQuarantineDecon.cur) & avgDaysInQuarantineDecon.cur > 2) {
  curTableFill.f <- c(curTableFill.f, 'red')
} else {
  curTableFill.f <- c(curTableFill.f, 'green')
}
if(!is.na(avgDaysInService.cur) & avgDaysInService.cur > 4) {
  curTableFill.f <- c(curTableFill.f, 'red')
} else { 
  curTableFill.f <- c(curTableFill.f, 'green')
}
if(!is.na(avgDaysInQC.cur) & avgDaysInQC.cur > 2) {
  curTableFill.f <- c(curTableFill.f, 'red')
} else { 
  curTableFill.f <- c(curTableFill.f, 'green')
}
if(is.na(avgDaysInShip.cur) | avgDaysInShip.cur <= 1) {
  curTableFill.f <- c(curTableFill.f, 'green')
} else { 
  curTableFill.f <- c(curTableFill.f, 'red')
} 
tt3 <- ttheme_minimal(
  core=list(bg_params = list(fill = curTableFill.f, alpha = 0.5, col=1),
            fg_params=list(fontface=1, fontsize=18)),
  colhead=list(fg_params=list(col="black", fontface='bold', fontsize=20)))

t3 <- tableGrob(table.RMAFlorence, rows=NULL, theme = tt3)
title <- textGrob(paste0("Florence RMA Process Flow - ", curMonthName, '\nGreen = Within Goal, Red = Out of Goal'),gp=gpar(fontsize=20, fontface='bold'))
padding <- unit(5,"mm")
table3 <- gtable_add_rows(
  t3, 
  heights = grobHeight(title) + padding,
  pos = 0)
table3 <- gtable_add_grob(
  table3, 
  title, 
  1, 1, 1, ncol(table3))

# prev month table 
avgDaysinReceiving.cur <- mean(subset(rmaTAT.FL, DateGroup == lastMonth)[,'DaysInReceiving'], na.rm=TRUE)
avgDaysinReceiving.prev <- mean(subset(rmaTAT.FL, DateGroup == prevprevMonth)[,'DaysInReceiving'], na.rm=TRUE)
avgDaysinReceiving.year <- mean(subset(rmaTAT.FL, DateGroup >= findStartDate(calendar.month, 'Month', 13, 0) & DateGroup <= lastMonth)[,'DaysInReceiving'], na.rm=TRUE)
avgDaysInQuarantineDecon.cur <- subset(avgDaysperPhase.FL, DateGroup == lastMonth & Key == 'Days In Quarantine/Decon')[,'Record']
avgDaysInQuarantineDecon.prev <- subset(avgDaysperPhase.FL, DateGroup == prevprevMonth & Key == 'Days In Quarantine/Decon')[,'Record']
avgDaysInQuarantineDecon.year <- mean(subset(rmaTAT.FL, DateGroup >= findStartDate(calendar.month, 'Month', 13, 0) & DateGroup <= lastMonth)[,'DaysInQuarantine/Decon'], na.rm=TRUE)
avgDaysInService.cur <- subset(avgDaysperPhase.FL, DateGroup == lastMonth & Key == 'Days In Service')[,'Record']
avgDaysInService.prev <- subset(avgDaysperPhase.FL, DateGroup == prevprevMonth & Key == 'Days In Service')[,'Record']
avgDaysInService.year <- mean(subset(rmaTAT.FL, DateGroup >= findStartDate(calendar.month, 'Month', 13, 0) & DateGroup <= lastMonth)[,'DaysInService'], na.rm=TRUE)
avgDaysInQC.cur <- subset(avgDaysperPhase.FL, DateGroup == lastMonth & Key == 'Days In QC')[,'Record']
avgDaysInQC.prev <- subset(avgDaysperPhase.FL, DateGroup == prevprevMonth & Key == 'Days In QC')[,'Record']
avgDaysInQC.year <- mean(subset(rmaTAT.FL, DateGroup >= findStartDate(calendar.month, 'Month', 13, 0) & DateGroup <= lastMonth)[,'DaysInQC'], na.rm=TRUE)
avgDaysInShip.cur <- subset(avgDaysperPhase.FL, DateGroup == lastMonth & Key == 'Days To Ship')[,'Record']
avgDaysInShip.prev <- subset(avgDaysperPhase.FL, DateGroup == prevprevMonth & Key == 'Days To Ship')[,'Record']
avgDaysInShip.year <- mean(subset(rmaTAT.FL, DateGroup >= findStartDate(calendar.month, 'Month', 13, 0) & DateGroup <= lastMonth)[,'DaysToShip'], na.rm=TRUE)
table.RMAFlorence.prev <- data.frame('PhaseofRMA' = c('Receiving', 
                                                      'Quarantine/Release', 
                                                      'Service', 
                                                      'Instrument QC and DHR', 
                                                      'Shipping'),
                                     'DaysPerProcessGoal' = c('< 6 Days', 
                                                              '2 Days', 
                                                              '4 Days', 
                                                              '2 Days', 
                                                              '1 Day'),
                                     'CurrentMonth' = c(format(avgDaysinReceiving.cur, digits = 3),
                                                        format(avgDaysInQuarantineDecon.cur, digits = 3),
                                                        format(avgDaysInService.cur, digits = 3),
                                                        format(avgDaysInQC.cur, digits = 3),
                                                        format(avgDaysInShip.cur, digits = 3)),
                                     'PreviousMonth' = c(format(avgDaysinReceiving.prev, digits = 3),
                                                         format(avgDaysInQuarantineDecon.prev, digits = 3),
                                                         format(avgDaysInService.prev, digits = 3),
                                                         format(avgDaysInQC.prev, digits = 3),
                                                         format(avgDaysInShip.prev, digits = 3)),
                                     'Delta' = c(format(abs(avgDaysinReceiving.cur - avgDaysinReceiving.prev), digits=3),
                                                 format(abs(avgDaysInQuarantineDecon.cur - avgDaysInQuarantineDecon.prev), digits=3),
                                                 format(abs(avgDaysInService.cur - avgDaysInService.prev), digits=3),
                                                 format(abs(avgDaysInQC.cur - avgDaysInQC.prev), digits=3),
                                                 format(abs(avgDaysInShip.cur - avgDaysInShip.prev), digits=3)),
                                     'AverageDaysForPrevious1Year' = c(format(avgDaysinReceiving.year, digits=3),
                                                                       format(avgDaysInQuarantineDecon.year, digits=3),
                                                                       format(avgDaysInService.year, digits=3),
                                                                       format(avgDaysInQC.year, digits=3),
                                                                       format(avgDaysInShip.year, digits=3)))
colnames(table.RMAFlorence.prev) <- c('Phase of RMA', 'Days Per Process -\nGoal', 'Current Month', 'Previous Month', 'Delta', 'Average Days For\nPrevious 1 Year')
if(!is.na(avgDaysinReceiving.cur) & avgDaysinReceiving.cur >= 6) {
  prevTableFill.f <- 'red'
} else {
  prevTableFill.f <- 'green'
}
if(!is.na(avgDaysInQuarantineDecon.cur) & avgDaysInQuarantineDecon.cur > 2) {
  prevTableFill.f <- c(prevTableFill.f, 'red')
} else {
  prevTableFill.f <- c(prevTableFill.f, 'green')
}
if(!is.na(avgDaysInService.cur) & avgDaysInService.cur > 4) {
  prevTableFill.f <- c(prevTableFill.f, 'red')
} else { 
  prevTableFill.f <- c(prevTableFill.f, 'green')
}
if(!is.na(avgDaysInQC.cur) & avgDaysInQC.cur > 2) {
  prevTableFill.f <- c(prevTableFill.f, 'red')
} else { 
  prevTableFill.f <- c(prevTableFill.f, 'green')
}
if(!is.na(avgDaysInShip.cur) & avgDaysInShip.cur > 1) {
  prevTableFill.f <- c(prevTableFill.f, 'red')
} else { 
  prevTableFill.f <- c(prevTableFill.f, 'green')
} 
tt4 <- ttheme_minimal(
  core=list(bg_params = list(fill = prevTableFill.f, alpha = 0.5, col=1),
            fg_params=list(fontface=1, fontsize=18)),
  colhead=list(fg_params=list(col="black", fontface='bold', fontsize=20)))

t4 <- tableGrob(table.RMAFlorence.prev, rows=NULL, theme = tt4)
title <- textGrob(paste0("Florence RMA Process Flow - ", prevMonthName, '\nGreen = Within Goal, Red = Out of Goal'),gp=gpar(fontsize=20, fontface='bold'))
padding <- unit(5,"mm")
table4 <- gtable_add_rows(
  t4, 
  heights = grobHeight(title) + padding,
  pos = 0)
table4 <- gtable_add_grob(
  table4, 
  title, 
  1, 1, 1, ncol(table4))

#--- plots of the average days it takes for an rma'd instrument to get to a service center
serviceCenter.df$DateGroup <- with(serviceCenter.df, ifelse(Month < 10, paste0(Year,'-0', Month), paste0(Year,'-',Month)))
#average days per month, overall average and 4 month moving average
dategroups <- sort(unique(as.character(subset(calendar.month, DateGroup >= '2015-01')[,'DateGroup'])))
l <- length(dategroups)
# Salt Lake - US customers (including biofire defense)
avgreceived.saltlake <- c()
temp <- subset(serviceCenter.df, ServiceCenter == 'Salt Lake' & CustomerType != 'BMX' & DateGroup >= '2015-01')
for(i in 1:l) {
  temp2 <- subset(temp, DateGroup == dategroups[i])
  if(nrow(temp2) > 0) {
    avgreceived.saltlake <- rbind(avgreceived.saltlake, data.frame(DateGroup = dategroups[i], Key = 'Salt Lake - US Customers', avgDays = mean(temp2$DaysUntilReceipt, na.rm=TRUE)))
  } else {
    avgreceived.saltlake <- rbind(avgreceived.saltlake, data.frame(DateGroup = dategroups[i], Key = 'Salt Lake - US Customers', avgDays = NA))
  }
}
avgreceived.saltlake$OverallAvg <- with(avgreceived.saltlake, mean(avgDays, na.rm=TRUE))
avgreceived.saltlake <- cbind(avgreceived.saltlake[4:l,], sapply(4:l, function(x) mean(avgreceived.saltlake[(x-3):x,'avgDays'], na.rm=TRUE)))
colnames(avgreceived.saltlake)[5] <- 'RollingAvg'
avgreceived.saltlake$facetHeader <- paste0('Salt Lake - US Customers\nOverall Avg = ', format(subset(avgreceived.saltlake, DateGroup == currentMonth)[,'OverallAvg'], digits=3), ', Current Rolling Avg = ', format(subset(avgreceived.saltlake, DateGroup == currentMonth)[,'RollingAvg'], digits = 3))
# Salt Lake - BioFire Defense
avgreceived.defense <- c()
temp <- subset(serviceCenter.df, CustomerType == 'Defense' & DateGroup >= '2015-01')
for(i in 1:l) {
  temp2 <- subset(temp, DateGroup == dategroups[i])
  if(nrow(temp2) > 0) {
    avgreceived.defense <- rbind(avgreceived.defense, data.frame(DateGroup = dategroups[i], Key = 'Salt Lake - BioFire Defense', avgDays = mean(temp2$DaysUntilReceipt, na.rm=TRUE)))
  } else {
    avgreceived.defense <- rbind(avgreceived.defense, data.frame(DateGroup = dategroups[i], Key = 'Salt Lake - BioFire Defense', avgDays = NA))
  }
}
avgreceived.defense$OverallAvg <- with(avgreceived.defense, mean(avgDays, na.rm=TRUE))
avgreceived.defense <- cbind(avgreceived.defense[4:l,], sapply(4:l, function(x) mean(avgreceived.defense[(x-3):x,'avgDays'], na.rm=TRUE)))
colnames(avgreceived.defense)[5] <- 'RollingAvg'
avgreceived.defense$facetHeader <- paste0('Salt Lake - BioFire Defense\nOverall Avg = ', format(subset(avgreceived.defense, DateGroup == currentMonth)[,'OverallAvg'], digits=3), ', Current Rolling Avg = ', format(subset(avgreceived.defense, DateGroup == currentMonth)[,'RollingAvg'], digits = 3))
# Salt Lake - BMX
avgreceived.slbmx <- c()
temp <- subset(serviceCenter.df, ServiceCenter == 'Salt Lake' & CustomerType == 'BMX' & DateGroup >= '2015-01')
for(i in 1:l) {
  temp2 <- subset(temp, DateGroup == dategroups[i])
  if(nrow(temp2) > 0) {
    avgreceived.slbmx <- rbind(avgreceived.slbmx, data.frame(DateGroup = dategroups[i], Key = 'Salt Lake - BMX Customers', avgDays = mean(temp2$DaysUntilReceipt, na.rm=TRUE)))
  } else {
    avgreceived.slbmx <- rbind(avgreceived.slbmx, data.frame(DateGroup = dategroups[i], Key = 'Salt Lake - BMX Customers', avgDays = NA))
  }
}
avgreceived.slbmx$OverallAvg <- with(avgreceived.slbmx, mean(avgDays, na.rm=TRUE))
avgreceived.slbmx <- cbind(avgreceived.slbmx[4:l,], sapply(4:l, function(x) mean(avgreceived.slbmx[(x-3):x,'avgDays'], na.rm=TRUE)))
colnames(avgreceived.slbmx)[5] <- 'RollingAvg'
avgreceived.slbmx$facetHeader <- paste0('Salt Lake - BMX Customers\nOverall Avg = ', format(subset(avgreceived.slbmx, DateGroup == currentMonth)[,'OverallAvg'], digits=3), ', Current Rolling Avg = ', format(subset(avgreceived.slbmx, DateGroup == currentMonth)[,'RollingAvg'], digits = 3))
# Florence - All customers
avgreceived.fl <- c()
temp <- subset(serviceCenter.df, ServiceCenter == 'Florence' & DateGroup >= '2015-01')
for(i in 1:l) {
  temp2 <- subset(temp, DateGroup == dategroups[i])
  if(nrow(temp2) > 0) {
    avgreceived.fl <- rbind(avgreceived.fl, data.frame(DateGroup = dategroups[i], Key = 'Florence - All Customers', avgDays = mean(temp2$DaysUntilReceipt, na.rm=TRUE)))
  } else {
    avgreceived.fl <- rbind(avgreceived.fl, data.frame(DateGroup = dategroups[i], Key = 'Florence - All Customers', avgDays = NA))
  }
}
avgreceived.fl$OverallAvg <- with(avgreceived.fl, mean(avgDays, na.rm=TRUE))
avgreceived.fl <- cbind(avgreceived.fl[4:l,], sapply(4:l, function(x) mean(avgreceived.fl[(x-3):x,'avgDays'], na.rm=TRUE)))
colnames(avgreceived.fl)[5] <- 'RollingAvg'
avgreceived.fl$facetHeader <- paste0('Florence - All Customers\nOverall Avg = ', format(subset(avgreceived.fl, DateGroup == currentMonth)[,'OverallAvg'], digits=3), ', Current Rolling Avg = ', format(subset(avgreceived.fl, DateGroup == currentMonth)[,'RollingAvg'], digits = 3))
avgreceived <- rbind(avgreceived.defense, avgreceived.fl, avgreceived.saltlake, avgreceived.slbmx)
datebreaks.received <- sort(unique(as.character(avgreceived$DateGroup)))[seq(1,length(unique(as.character(avgreceived$DateGroup))), 3)]
p.AllServiceCenters <- ggplot(avgreceived, aes(x=DateGroup, y=avgDays, fill='1')) + geom_bar(stat='identity') + facet_wrap(~facetHeader) + scale_fill_manual(name ='', values=c('forestgreen'), guide=FALSE) + theme(axis.text.x = element_text(angle=90, vjust=0.5)) + scale_x_discrete(breaks=datebreaks.received) + labs(title = 'Average Days for Customer RMA to be Received by Service Center', x = 'Date\n(Year-Month)', y = 'Average Days') + geom_text(aes(label=format(avgDays, digits = 1)), size = 4, fontface = 'bold', vjust = -0.5)

# All RMAs opened by type (part) 
openedRMA <- subset(rmas.df, select = c('YearOpen', 'MonthOpen', 'Part', 'Type', 'Record'))
colnames(openedRMA)[colnames(openedRMA)=='YearOpen'] <- 'Year'
colnames(openedRMA)[colnames(openedRMA)=='MonthOpen'] <- 'Month'
openedRMA <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', openedRMA, c('Part', 'Type'), startString.month3yr.rolling, 'Record', 'sum', 0)
temp.agg <- with(openedRMA, aggregate(Record~DateGroup, FUN=sum))
l <- length(temp.agg$DateGroup)
temp.agg <- cbind(temp.agg[4:l,], sapply(4:l, function(x) mean(temp.agg[(x-3):x,'Record'])))
colnames(temp.agg)[3] <- 'RollingAvg'
openedRMA <- merge(openedRMA, subset(temp.agg, select=c('DateGroup', 'RollingAvg')))
openedRMA.agg <- with(openedRMA, aggregate(Record~DateGroup, FUN=sum))
p.AllOpenedRMA <- ggplot(openedRMA, aes(DateGroup, y=Record, fill=Part)) + scale_fill_manual(name='RMA Type', values = createPaletteOfVariableLength(openedRMA, 'Part')) + geom_bar(stat='identity') + geom_line(inherit.aes=FALSE, aes(x=DateGroup, y=RollingAvg, group=1)) + geom_point(inherit.aes=FALSE, aes(x=DateGroup, y=RollingAvg, group=1)) + theme(axis.text.x=element_text(angle = 90)) + labs(title = 'Opened RMAs', subtitle = paste('Rolling Average for', curMonthName, ':', format(unique(subset(openedRMA, DateGroup == currentMonth)[,'RollingAvg']), digits=3)), x = 'Date\n(Year-Month)', y ='Number of RMAs\n4-Month Rolling Average Line') + geom_text(data = openedRMA.agg, inherit.aes = FALSE, aes(x=DateGroup, y=Record, label=Record), size=5, vjust=-0.5)
#prev month freeze
p.AllOpenedRMA.Prev <- ggplot(subset(openedRMA, DateGroup <= lastMonth), aes(DateGroup, y=Record, fill=Part)) + scale_fill_manual(name='RMA Type', values = createPaletteOfVariableLength(openedRMA, 'Part')) + geom_bar(stat='identity') + geom_line(inherit.aes=FALSE, aes(x=DateGroup, y=RollingAvg, group=1)) + geom_point(inherit.aes=FALSE, aes(x=DateGroup, y=RollingAvg, group=1)) + theme(axis.text.x=element_text(angle = 90)) + labs(title = 'Opened RMAs', subtitle = paste('Rolling Average for', prevMonthName, ':', format(unique(subset(openedRMA, DateGroup == lastMonth)[,'RollingAvg']), digits=3)), x = 'Date\n(Year-Month)', y ='Number of RMAs\n4-Month Rolling Average Line') + geom_text(data = subset(openedRMA.agg, DateGroup <= lastMonth), inherit.aes = FALSE, aes(x=DateGroup, y=Record, label=Record), size=5, vjust=-0.5) 

# Customer RMAs opened by type (part)
custOpenedRMA <- subset(openedRMA, Type == 'Customer - Failure' | Type == 'Customer - No failure')
temp.agg <- with(custOpenedRMA, aggregate(Record~DateGroup, FUN=sum))
l <- length(temp.agg$DateGroup)
temp.agg <- cbind(temp.agg[4:l,], sapply(4:l, function(x) mean(temp.agg[(x-3):x,'Record'])))
colnames(temp.agg)[3] <- 'RollingAvg'
custOpenedRMA <- merge(subset(custOpenedRMA, select = c('DateGroup', 'Part', 'Record')), subset(temp.agg, select=c('DateGroup', 'RollingAvg')), by='DateGroup')
custOpenedRMA.agg <- with(custOpenedRMA, aggregate(Record~DateGroup, FUN=sum))
p.CustomerOpenedRMA <- ggplot(custOpenedRMA, aes(DateGroup, y=Record, fill=Part)) + geom_bar(stat='identity') + geom_line(inherit.aes=FALSE, aes(x=DateGroup, y=RollingAvg, group=1)) + geom_point(inherit.aes=FALSE, aes(x=DateGroup, y=RollingAvg, group=1)) + scale_fill_manual(name='RMA Type', values = createPaletteOfVariableLength(openedRMA, 'Part')) + theme(axis.text.x=element_text(angle = 90)) + labs(title = 'Opened Customer RMAs', subtitle = paste('Rolling Average for', curMonthName, ':', format(unique(subset(custOpenedRMA, DateGroup == currentMonth)[,'RollingAvg']), digits=3)), x = 'Date\n(Year-Month)', y ='Number of RMAs\n4-Month Rolling Average Line') + geom_text(data = custOpenedRMA.agg, inherit.aes = FALSE, aes(x=DateGroup, y=Record, label=Record), size=5, vjust=-0.5) 
#prev month freeze
p.CustomerOpenedRMA.Prev <- ggplot(subset(custOpenedRMA, DateGroup <= lastMonth), aes(DateGroup, y=Record, fill=Part)) + geom_bar(stat='identity') + geom_line(inherit.aes=FALSE, aes(x=DateGroup, y=RollingAvg, group=1)) + geom_point(inherit.aes=FALSE, aes(x=DateGroup, y=RollingAvg, group=1)) + scale_fill_manual(name='RMA Type', values = createPaletteOfVariableLength(openedRMA, 'Part')) + theme(axis.text.x=element_text(angle = 90)) + labs(title = 'Opened Customer RMAs', subtitle = paste('Rolling Average for', prevMonthName, ':', format(unique(subset(custOpenedRMA, DateGroup == lastMonth)[,'RollingAvg']), digits=3)), x = 'Date\n(Year-Month)', y ='Number of RMAs\n4-Month Rolling Average Line') + geom_text(data = subset(custOpenedRMA.agg, DateGroup <= lastMonth), inherit.aes = FALSE, aes(x=DateGroup, y=Record, label=Record), size=5, vjust=-0.5) 

# Customer RMAs by version
custRMA.version <- subset(rmas.df, (Type == 'Customer - Failure' | Type == 'Customer - No failure'))
colnames(custRMA.version)[colnames(custRMA.version)=='YearOpen'] <- 'Year'
colnames(custRMA.version)[colnames(custRMA.version)=='MonthOpen'] <- 'Month'
custIRMA.ver <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', subset(custRMA.version, Part == 'Instrument'), 'Version', startString.monthRoll, 'Record', 'sum', 0)
temp.agg <- subset(custIRMA.ver, Version == 'FA 1.5')
l <- length(temp.agg$DateGroup)
temp.agg <- cbind(temp.agg[4:l,], sapply(4:l, function(x) mean(temp.agg[(x-3):x,'Record'])))
colnames(temp.agg)[4] <- 'RollingAvg'
custIRMA.ver <- merge(custIRMA.ver, subset(temp.agg, select=c('DateGroup', 'Version', 'RollingAvg')), by=c('DateGroup','Version'), all.x=TRUE)
temp.agg <- subset(custIRMA.ver, Version == 'FA 2.0', select = c('DateGroup', 'Version', 'Record'))
l <- length(temp.agg$DateGroup)
temp.agg <- cbind(temp.agg[4:l,], sapply(4:l, function(x) mean(temp.agg[(x-3):x,'Record'])))
colnames(temp.agg)[4] <- 'RollingAvg'
custIRMA.ver$RollingAvg[custIRMA.ver$Version == 'FA 2.0'] <- c(NA, NA, NA, temp.agg$RollingAvg)
temp.agg <- subset(custIRMA.ver, Version == 'Torch', select = c('DateGroup', 'Version', 'Record'))
l <- length(temp.agg$DateGroup)
temp.agg <- cbind(temp.agg[4:l,], sapply(4:l, function(x) mean(temp.agg[(x-3):x,'Record'])))
colnames(temp.agg)[4] <- 'RollingAvg'
custIRMA.ver$RollingAvg[custIRMA.ver$Version == 'Torch'] <- c(NA, NA, NA, temp.agg$RollingAvg)
custIRMA.ver <- subset(custIRMA.ver, !is.na(RollingAvg))
custIRMA.ver$facetHeader[custIRMA.ver$Version == 'FA 1.5'] <- paste0('FA 1.5\n4 Month Rolling Average = ', subset(custIRMA.ver, DateGroup == currentMonth & Version == 'FA 1.5')[,'RollingAvg'])
custIRMA.ver$facetHeader[custIRMA.ver$Version == 'FA 2.0'] <- paste0('FA 2.0\n4 Month Rolling Average = ', subset(custIRMA.ver, DateGroup == currentMonth & Version == 'FA 2.0')[,'RollingAvg'])
custIRMA.ver$facetHeader[custIRMA.ver$Version == 'Torch'] <- paste0('Torch\n4 Month Rolling Average = ', subset(custIRMA.ver, DateGroup == currentMonth & Version == 'Torch')[,'RollingAvg'])
p.custInstRMA <- ggplot(custIRMA.ver, aes(x=DateGroup, y=Record, fill=Version)) + geom_bar(stat='identity') + facet_wrap(~facetHeader) + scale_fill_manual(guide=FALSE, values=createPaletteOfVariableLength(custIRMA.ver, 'Version')) + theme(axis.text.x = element_text(angle = 90, vjust=0.5)) + geom_text(aes(label=Record), vjust=-0.5, size=4, fontface='bold') + labs(title='Customer Instrument RMAs Opened', x='Date\n(Year-Month)', y='RMAs Opened')
custCRMA.ver <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', subset(custRMA.version, Part == 'Computer'), 'Version', startString.monthRoll, 'Record', 'sum', 0)
temp.agg <- subset(custCRMA.ver, Version == 'FA 1.5')
l <- length(temp.agg$DateGroup)
temp.agg <- cbind(temp.agg[4:l,], sapply(4:l, function(x) mean(temp.agg[(x-3):x,'Record'])))
colnames(temp.agg)[4] <- 'RollingAvg'
custCRMA.ver <- merge(custCRMA.ver, subset(temp.agg, select=c('DateGroup', 'Version', 'RollingAvg')), by=c('DateGroup','Version'), all.x=TRUE)
temp.agg <- subset(custCRMA.ver, Version == 'FA 2.0', select = c('DateGroup', 'Version', 'Record'))
l <- length(temp.agg$DateGroup)
temp.agg <- cbind(temp.agg[4:l,], sapply(4:l, function(x) mean(temp.agg[(x-3):x,'Record'])))
colnames(temp.agg)[4] <- 'RollingAvg'
custCRMA.ver$RollingAvg[custCRMA.ver$Version == 'FA 2.0'] <- c(NA, NA, NA, temp.agg$RollingAvg)
temp.agg <- subset(custCRMA.ver, Version == 'Torch', select = c('DateGroup', 'Version', 'Record'))
l <- length(temp.agg$DateGroup)
temp.agg <- cbind(temp.agg[4:l,], sapply(4:l, function(x) mean(temp.agg[(x-3):x,'Record'])))
colnames(temp.agg)[4] <- 'RollingAvg'
custCRMA.ver$RollingAvg[custCRMA.ver$Version == 'Torch'] <- c(NA, NA, NA, temp.agg$RollingAvg)
custCRMA.ver <- subset(custCRMA.ver, !is.na(RollingAvg))
custCRMA.ver$facetHeader[custCRMA.ver$Version == 'FA 1.5'] <- paste0('FA 1.5\n4 Month Rolling Average = ', subset(custCRMA.ver, DateGroup == currentMonth & Version == 'FA 1.5')[,'RollingAvg'])
custCRMA.ver$facetHeader[custCRMA.ver$Version == 'FA 2.0'] <- paste0('FA 2.0\n4 Month Rolling Average = ', subset(custCRMA.ver, DateGroup == currentMonth & Version == 'FA 2.0')[,'RollingAvg'])
custCRMA.ver$facetHeader[custCRMA.ver$Version == 'Torch'] <- paste0('Torch\n4 Month Rolling Average = ', subset(custCRMA.ver, DateGroup == currentMonth & Version == 'Torch')[,'RollingAvg'])
p.custCompRMA <- ggplot(custCRMA.ver, aes(x=DateGroup, y=Record, fill=Version)) + geom_bar(stat='identity') + facet_wrap(~facetHeader) + scale_fill_manual(guide=FALSE, values=createPaletteOfVariableLength(custCRMA.ver, 'Version')) + theme(axis.text.x = element_text(angle = 90, vjust=0.5)) + geom_text(aes(label=Record), vjust=-0.5, size=4, fontface='bold') + labs(title='Customer Computer RMAs Opened', x='Date\n(Year-Month)', y='RMAs Opened')

# Rate of Loaner RMA acceptance / all US customer RMAs
loaner.yes <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', subset(loaners.df, Loaner == 'Yes'), 'Key', startString.month3yr, 'Record', 'sum', 0) 
allcustRMA <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', loaners.df, 'Key', startString.month3yr, 'Record', 'sum', 0)
loaner.rate <- mergeCalSparseFrames(loaner.yes, allcustRMA, c('DateGroup', 'Key'), c('DateGroup', 'Key'), 'Record', 'Record', 0, 4)
overallAcceptance <- sum(loaner.yes$Record) / sum(allcustRMA$Record)
p.LoanerAcceptance <- ggplot(subset(loaner.rate, DateGroup >= '2015-01'), aes(x=DateGroup, y=Rate, group=1)) + geom_line() + geom_point() + theme(axis.text.x=element_text(angle = 90)) + labs(title = 'Acceptance Rate of Loaners in US Customer Instrument RMAs', subtitle = paste0('Overall Acceptance Rate = ', format(overallAcceptance*100, digits = 3), '%'), x = 'Date\n(Year-Month)', y ='Loaners Accepted / Customer RMAs\n(4 Month Rolling Average)') 

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
p1 <- ggplot(CloseDate, aes(x=DateGroup, y=Record)) + geom_bar(stat='identity', fill='cornflowerblue') + geom_text(aes(label=Record), position = position_stack(vjust = 0.25), size = 5) + theme(axis.text.x=element_text(angle=90)) + labs(title = 'Complaints Closed - Average Days Open', subtitle = paste('Complaints Closed in', curMonthName,':', ClosedComplaints,'\nAverage Days Open in', curMonthName,':',subset(avgDays.agg, DateGroup == currentMonth)[,'DaysOpen'],' Goal = 30 days'), x = 'Date\n(Year-Month)', y ='Number of Complaints')
p2 <- ggplot(avgDays.agg, aes(x=DateGroup, y=DaysOpen, group=1)) + geom_line(color='midnightblue', size = 1.5) + theme(panel.background = element_blank(), panel.grid.major = element_blank(), panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(), axis.text.x=element_blank(), axis.title.x=element_blank(), axis.ticks.x = element_blank()) + labs(x='', y ='Average Days Open') + scale_y_continuous(position = 'right', limits = c(0,60)) + geom_hline(aes(yintercept=30), color='forestgreen', lty='dashed', size=1.5)
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
#prev month freeze
p3 <- ggplot(subset(CloseDate, DateGroup <= lastMonth), aes(x=DateGroup, y=Record)) + geom_bar(stat='identity', fill='cornflowerblue') + geom_text(aes(label=Record), position = position_stack(vjust = 0.25), size = 5) + theme(axis.text.x=element_text(angle=90)) + labs(title = 'Complaints Closed - Average Days Open', subtitle = paste('Complaints Closed in', prevMonthName,':', sum(subset(CloseDate, DateGroup == lastMonth)[,'Record']),'\nAverage Days Open in', prevMonthName,':',subset(avgDays.agg, DateGroup == lastMonth)[,'DaysOpen'],' Goal = 30 days'), x = 'Date\n(Year-Month)', y ='Number of Complaints')
p4 <- ggplot(subset(avgDays.agg, as.character(DateGroup) <= lastMonth), aes(x=DateGroup, y=DaysOpen, group=1)) + geom_line(color='midnightblue', size = 1.5) + theme(panel.background = element_blank(), panel.grid.major = element_blank(), panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(), axis.text.x=element_blank(), axis.title.x=element_blank(), axis.ticks.x = element_blank()) + labs(x='', y ='Average Days Open') + scale_y_continuous(position = 'right', limits = c(0,60)) + geom_hline(aes(yintercept=30), color='forestgreen', lty='dashed', size=1.5)
g3 <- ggplotGrob(p3)
g4 <- ggplotGrob(p4)
pp <- c(subset(g1$layout, name == 'panel', se = t:r))
g3 <- gtable_add_grob(g3, g4$grobs[[which(g4$layout$name == 'panel')]], pp$t, pp$l, pp$b, pp$r)
index2 <- which(g4$layout$name == "ylab-r")
yaxislab <- g4$grobs[[index2]]
g3 <- gtable_add_cols(g3, g4$widths[g4$layout[index2, ]$l], pp$r)
g3 <- gtable_add_grob(g3, yaxislab, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "ylab-r")
index <- which(g4$layout$name == "axis-r")
yaxis <- g4$grobs[[index]]
g3 <- gtable_add_cols(g3, g4$widths[g4$layout[index, ]$l], pp$r)
g3 <- gtable_add_grob(g3, yaxis, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "axis-r")

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
png(file='ComplaintsClosedAvgDaysOpen.Prev.png', width=1200, height=800, units='px')
grid.draw(g3)
makeTimeStamp(timeStamp = Sys.time(), author='Data Science')
dev.off()
png(file='SLRMAProcessTable.Prev.png', width=1200, height=800, units='px')
grid.draw(table2)
makeTimeStamp(timeStamp = Sys.time(), author='Data Science')
dev.off()
png(file='SLRMAProcessTable.png', width=1200, height=800, units='px')
grid.draw(table1)
makeTimeStamp(timeStamp = Sys.time(), author='Data Science')
dev.off()
png(file='FlorenceRMAProcessTable.Prev.png', width=1200, height=800, units='px')
grid.draw(table4)
makeTimeStamp(timeStamp = Sys.time(), author='Data Science')
dev.off()
png(file='FlorenceRMAProcessTable.png', width=1200, height=800, units='px')
grid.draw(table3)
makeTimeStamp(timeStamp = Sys.time(), author='Data Science')
dev.off()

# Export PDF for the Web Hub
setwd(pdfDir)
pdf("CustomerSupport.pdf", width = 11, height = 8)
for(i in 1:length(plots)) {
  print(get(plots[i]))
}
grid.newpage()
grid.draw(g1)
grid.newpage()
grid.draw(g3)
grid.newpage()
grid.draw(table1)
grid.newpage()
grid.draw(table2)
grid.newpage()
grid.draw(table3)
grid.newpage()
grid.draw(table4)
dev.off()

rm(list = ls())

workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_InstrumentServicing'
pdfDir <- '~/WebHub/pdfs/'

setwd(workDir)

# Load needed libraries
library(ggplot2)
library(scales)
library(zoo)
library(lubridate)
library(dateManip)

# load the data from SQL
source('Portfolios/O_ISERV_load.R')

source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/makeTimeStamp.R')

calendar.week <- createCalendarLikeMicrosoft(year(Sys.Date())-2, 'Week')
startString.week <- findStartDate(calendar.week, 'Week', 54, 5)
calendar.month <- createCalendarLikeMicrosoft(2013, 'Month')

#----------------------------------Instruments Thru Service During Previous Week ----------------------------------------------------------------------------------------------

service.df$Key <- paste(service.df$Disposition, service.df$Version, sep=" ")

service.open.df <- subset(service.df, select=c('Year','Week','Key','Opened'))
colnames(service.open.df)[grep('Opened', colnames(service.open.df))] <- 'Record'
service.open.df <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', service.open.df, 'Key', startString.week,'Record','sum',0)
service.open.df$State <- 'Opened'

service.rec.df <- subset(service.df, select=c('Year','Week','Key','Received'))
colnames(service.rec.df)[grep('Received', colnames(service.rec.df))] <- 'Record'
service.rec.df <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', service.rec.df, 'Key', startString.week, 'Record', 'sum', 0)
service.rec.df$State <- 'Received'

service.to.df <- subset(service.df, select=c('Year','Week','Key','ToQC'))
colnames(service.to.df)[grep('ToQC', colnames(service.to.df))] <- 'Record'
service.to.df <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', service.to.df, 'Key', startString.week, 'Record', 'sum', 0)
service.to.df$State <- 'ToQC'

service.thru.df <- subset(service.df, select=c('Year','Week','Key','ThruQC'))
colnames(service.thru.df)[grep('ThruQC', colnames(service.thru.df))] <- 'Record'
service.thru.df <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', service.thru.df, 'Key', startString.week, 'Record', 'sum', 0)
service.thru.df$State <- 'ThruQC'

service.ship.df <- subset(service.df, select=c('Year','Week','Key','Shipped'))
colnames(service.ship.df)[grep('Shipped', colnames(service.ship.df))] <- 'Record'
service.ship.df <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', service.ship.df, 'Key', startString.week, 'Record', 'sum', 0)
service.ship.df$State <- 'Shipped'

service.all.df <- Reduce(function(x, y) merge(x, y, all=TRUE), list(service.to.df, service.rec.df, service.thru.df, service.open.df, service.ship.df))

prevWeekSql <- subset(calendar.week, Date == Sys.Date())[,'Week']-1
prevYearSql <- ifelse(prevWeekSql == 1,
                      year(Sys.Date())-1,
                      year(Sys.Date()))

ww <- ifelse(prevWeekSql < 10, 
             paste(prevYearSql, paste('0',prevWeekSql,sep=''), sep='-'),
             paste(prevYearSql, prevWeekSql, sep='-'))

BioFirePrevWeek <- ifelse(prevWeekSql-1 < 10, 
                  paste(prevYearSql, paste('0',prevWeekSql-1,sep=''), sep='-'),
                  paste(prevYearSql, prevWeekSql-1, sep='-'))

#Reorder factors to make chart have customer on bottom, refurb in middle, and BFDx on top
#fillOrder <- c('Customer FA1.5','Customer FA2.0','Customer Torch','Customer Laptop','Refurbish FA1.5','Refurbish FA2.0','Refurbish Torch','Refurbish Laptop','BFDx FA1.5','BFDx FA2.0','BFDx Torch','BFDx Laptop','Other FA1.5', 'Other FA2.0','Other Torch', 'Other Laptop')
fillOrder <- c('Other Laptop','Other Torch','Other FA2.0','Other FA1.5','BFDx Laptop','BFDx Torch','BFDx FA2.0','BFDx FA1.5','Refurbish Laptop','Refurbish Torch','Refurbish FA2.0','Refurbish FA1.5','Customer Laptop','Customer Torch','Customer FA2.0','Customer FA1.5')
#fillColors <- createPaletteOfVariableLength(service.all.df, 'Key')
# fillColors <- c('#4576A3','#5B9BD5','#9DC3E6','#0d0d0d','#C46829','#ED7D31','#F4B183','#5C5C5C','#59873A','#70AD47','#A9D18E','#a3a3a3','#efbbff','#d896ff','#be29ec','#cccccc')
fillColors <- c('#cccccc','#be29ec','#d896ff','#efbbff','#a3a3a3','#A9D18E','#70AD47','#59873A','#5C5C5C','#F4B183','#ED7D31','#C46829','#0d0d0d','#9DC3E6','#5B9BD5','#4576A3')
names(fillColors) <- fillOrder
service.all.df$Key <- factor(service.all.df$Key, levels = fillOrder, ordered=TRUE)
service.all.df<- service.all.df[with(service.all.df, order(Key)), ]

#Reorder X Axis factors
service.all.df$State <- factor(service.all.df$State, levels = c('Opened','Received','ToQC','ThruQC', 'Shipped'), ordered=TRUE)
service.all.df<- service.all.df[with(service.all.df, order(State)), ]

p.Service.PrevWk <- ggplot(subset(service.all.df, as.character(DateGroup) == ww), aes(x=State, y=Record, fill=Key)) + 
  geom_bar(stat="identity", position="stack") + xlab('State') + ylab('Instruments') + theme(text=element_text(size=20, face='bold'), 
  axis.text.x=element_text(color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  ggtitle(paste('Instrument Movement Through Service\nFor Previous Week: ',BioFirePrevWeek)) + 
  scale_fill_manual(values=fillColors, name=' ') + scale_y_continuous(breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30))

#-----------------------------------------Instruments Thru Service During Current Week ----------------------------------------------------------------------

currWeekSql <- subset(calendar.week, Date == Sys.Date())[,'Week']
currYearSql <- ifelse(currWeekSql == 1,
                      year(Sys.Date())-1,
                      year(Sys.Date()))

curr <- ifelse(currWeekSql < 10, 
             paste(currYearSql, paste('0',currWeekSql,sep=''), sep='-'),
             paste(currYearSql, currWeekSql, sep='-'))

BioFireCurrWeek <- ifelse(currWeekSql-1 < 10, 
                          paste(currYearSql, paste('0',currWeekSql-1,sep=''), sep='-'),
                          paste(currYearSql, currWeekSql-1, sep='-'))

p.Service.CurrWk <- ggplot(subset(service.all.df, as.character(DateGroup) == curr), aes(x=State, y=Record, fill=Key)) + 
  geom_bar(stat="identity", position="stack") + xlab('State') + ylab('Instruments') + theme(text=element_text(size=20, face='bold'), 
  axis.text.x=element_text(color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  ggtitle(paste('Instrument Movement Through Service\nFor Current Week:', BioFireCurrWeek)) + 
  scale_fill_manual(values=fillColors, name=' ') + scale_y_continuous(breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30))

#-----------------------------------Service Output Thru QC by week ---------------------------------------------------------------------

#5 week rolling avg
agg.thru.df <- with(service.thru.df, aggregate(Record~DateGroup, FUN =sum))
l <- length(agg.thru.df$DateGroup)
agg.thru.df <- cbind(agg.thru.df[5:l,], sapply(5:l, function(x) mean(agg.thru.df[(x-4):x,'Record'])))
colnames(agg.thru.df)[3] <- 'RollingAvg'

agg.thru.df <- merge(service.thru.df, agg.thru.df, by='DateGroup')
agg.thru.df <- subset(agg.thru.df, select = c('DateGroup', 'Key', 'Record.x', 'RollingAvg'))
colnames(agg.thru.df)[colnames(agg.thru.df) == 'Record.x'] <- 'Record'

#Reorder factors to make chart have customer on bottom, refurb in middle, and BFDx on top
agg.thru.df$Key <- factor(agg.thru.df$Key, levels = fillOrder, ordered=TRUE)
agg.thru.df <- agg.thru.df[with(agg.thru.df, order(Key)), ]
agg.thru.df <- subset(agg.thru.df, as.character(DateGroup) <= ww)
agg.thru.df <- droplevels(agg.thru.df)

dateLabels <- as.character(unique(agg.thru.df[,'DateGroup']))[order(as.character(unique(agg.thru.df[,'DateGroup'])))][seq(1,length(as.character(unique(agg.thru.df[,'DateGroup']))), 12)]
dateBreaks <- seq(1,length(as.character(unique(agg.thru.df[,'DateGroup']))),12)

p.ThruQC.service <- ggplot(agg.thru.df, aes(x=as.numeric(as.factor(DateGroup)), y=Record, fill=Key)) + geom_area(stat="identity", position="stack") + 
  geom_line(aes(x=as.numeric(as.factor(DateGroup)), y=RollingAvg, group=1), inherit.aes=FALSE, color='black') + geom_point(aes(x=as.numeric(as.factor(DateGroup)), y=RollingAvg, group=1), inherit.aes=FALSE) +
  scale_x_continuous(breaks=dateBreaks, labels=dateLabels) + xlab('Date\n(Year-Week)\n5-week Rolling Average Line') + ylab('Instruments') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90,vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20), legend.position = 'left') + 
  ggtitle('Service Output Through QC') + scale_fill_manual(values=fillColors, name=' ') + scale_y_continuous(breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30), position = 'right')

#-----------------------------------------------FilmArray Received by week -------------------------------------------------------------

#5 week rolling avg
agg.rec.df <- with(service.rec.df, aggregate(Record~DateGroup, FUN =sum))
l <- length(agg.rec.df$DateGroup)
agg.rec.df <- cbind(agg.rec.df[5:l,], sapply(5:l, function(x) mean(agg.rec.df[(x-4):x,'Record'])))
colnames(agg.rec.df)[3] <- 'RollingAvg'

agg.rec.df <- merge(service.rec.df, agg.rec.df, by='DateGroup')
agg.rec.df <- subset(agg.rec.df, select = c('DateGroup', 'Key', 'Record.x', 'RollingAvg'))
colnames(agg.rec.df)[colnames(agg.rec.df) == 'Record.x'] <- 'Record'

#Reorder factors to make chart have customer on bottom, refurb in middle, and BFDx on top
agg.rec.df$Key <- factor(agg.rec.df$Key, levels = fillOrder, ordered=TRUE)
agg.rec.df <- agg.rec.df[with(agg.rec.df, order(Key)), ]
agg.rec.df <- subset(agg.rec.df, as.character(DateGroup) <= ww)
agg.rec.df <- droplevels(agg.rec.df)

dateLabels <- as.character(unique(agg.rec.df[,'DateGroup']))[order(as.character(unique(agg.rec.df[,'DateGroup'])))][seq(1,length(as.character(unique(agg.rec.df[,'DateGroup']))), 12)]
dateBreaks <- seq(1,length(as.character(unique(agg.rec.df[,'DateGroup']))),12)

p.RecvdRMA.service <- ggplot(agg.rec.df, aes(x=as.numeric(as.factor(DateGroup)), y=Record, fill=Key)) + geom_area(stat="identity", position="stack") + 
  geom_line(aes(x=as.numeric(as.factor(DateGroup)), y=RollingAvg, group=1), inherit.aes=FALSE, color='black') + geom_point(aes(x=as.numeric(as.factor(DateGroup)), y=RollingAvg, group=1), inherit.aes=FALSE) +
  scale_x_continuous(breaks=dateBreaks,labels=dateLabels) + xlab('Date\n(Year-Week)\n5-week Rolling Average Line') + ylab('Instruments') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20), legend.position = 'left') + 
  ggtitle('FilmArray Received') + scale_fill_manual(values=fillColors, name=' ') + scale_y_continuous(breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30), position = 'right')

#----------------------------------------------Service RMAs Created by week -------------------------------------------------------------
#5 week rolling avg
agg.open.df <- with(service.open.df, aggregate(Record~DateGroup, FUN =sum))
l <- length(agg.open.df$DateGroup)
agg.open.df <- cbind(agg.open.df[5:l,], sapply(5:l, function(x) mean(agg.open.df[(x-4):x,'Record'])))
colnames(agg.open.df)[3] <- 'RollingAvg'

agg.open.df <- merge(service.open.df, agg.open.df, by='DateGroup')
agg.open.df <- subset(agg.open.df, select = c('DateGroup', 'Key', 'Record.x', 'RollingAvg'))
colnames(agg.open.df)[colnames(agg.open.df) == 'Record.x'] <- 'Record'

#Reorder factors to make chart have customer on bottom, refurb in middle, and BFDx on top
agg.open.df$Key <- factor(agg.open.df$Key, levels = fillOrder, ordered=TRUE)
agg.open.df <- agg.open.df[with(agg.open.df, order(Key)), ]
agg.open.df <- subset(agg.open.df, as.character(DateGroup) <= ww)
agg.open.df <- droplevels(agg.open.df)

dateLabels <- as.character(unique(agg.open.df[,'DateGroup']))[order(as.character(unique(agg.open.df[,'DateGroup'])))][seq(1,length(as.character(unique(agg.open.df[,'DateGroup']))), 12)]
dateBreaks <- seq(1,length(as.character(unique(agg.open.df[,'DateGroup']))),12)

p.OpenRMA.service <- ggplot(agg.open.df, aes(x=as.numeric(as.factor(DateGroup)), y=Record, fill=Key)) + geom_area(stat="identity", position="stack") + 
  geom_line(aes(x=as.numeric(as.factor(DateGroup)), y=RollingAvg, group=1), inherit.aes=FALSE, color='black') + geom_point(aes(x=as.numeric(as.factor(DateGroup)), y=RollingAvg, group=1), inherit.aes=FALSE) +
  scale_x_continuous(breaks=dateBreaks,labels=dateLabels) + xlab('Date\n(Year-Week)\n5-week Rolling Average Line') + ylab('Instruments') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20), legend.position = 'left') + 
  ggtitle('Service RMAs Created') + scale_fill_manual(values=fillColors, name=' ') + scale_y_continuous(breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30), position = 'right')

#----------------------------------------------Shipped RMAs Created by week-------------------------------------------------------------
#5 week rolling avg
agg.shipped.df <- with(service.ship.df, aggregate(Record~DateGroup, FUN =sum))
l <- length(agg.shipped.df$DateGroup)
agg.shipped.df <- cbind(agg.shipped.df[5:l,], sapply(5:l, function(x) mean(agg.shipped.df[(x-4):x,'Record'])))
colnames(agg.shipped.df)[3] <- 'RollingAvg'

agg.shipped.df <- merge(service.ship.df, agg.shipped.df, by='DateGroup')
agg.shipped.df <- subset(agg.shipped.df, select = c('DateGroup', 'Key', 'Record.x', 'RollingAvg'))
colnames(agg.shipped.df)[colnames(agg.shipped.df) == 'Record.x'] <- 'Record'

#Reorder factors to make chart have customer on bottom, refurb in middle, and BFDx on top
agg.shipped.df$Key <- factor(agg.shipped.df$Key, levels = fillOrder, ordered=TRUE)
agg.shipped.df <- agg.shipped.df[with(agg.shipped.df, order(Key)), ]
agg.shipped.df <- subset(agg.shipped.df, as.character(DateGroup) <= ww)
agg.shipped.df <- droplevels(agg.shipped.df)

dateLabels <- as.character(unique(agg.shipped.df[,'DateGroup']))[order(as.character(unique(agg.shipped.df[,'DateGroup'])))][seq(1,length(as.character(unique(agg.shipped.df[,'DateGroup']))), 12)]
dateBreaks <- seq(1,length(as.character(unique(agg.shipped.df[,'DateGroup']))),12)

p.ShippedRMA.service <- ggplot(agg.shipped.df, aes(x=as.numeric(as.factor(DateGroup)), y=Record, fill=Key)) + geom_area(stat="identity", position="stack") + 
  geom_line(aes(x=as.numeric(as.factor(DateGroup)), y=RollingAvg, group=1), inherit.aes=FALSE, color='black') + geom_point(aes(x=as.numeric(as.factor(DateGroup)), y=RollingAvg, group=1), inherit.aes=FALSE) +
  scale_x_continuous(breaks=dateBreaks,labels=dateLabels) + xlab('Date\n(Year-Week)\n5-week Rolling Average Line') + ylab('Instruments') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20), legend.position = 'left') + 
  ggtitle('Shipped RMAs') + scale_fill_manual(values=fillColors, name=' ') + scale_y_continuous(breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30), position = 'right')

#----------------------------------------NEEDS WORK!-----Instruments in Service by month------------------------------------------------
# Try instruments rec - instruments at QC
# smallGroup <- 'Month'
# 
# service.open.m.df <- subset(service.df, select=c('Year','Month','Version','Key','Opened'))
# colnames(service.open.m.df)[grep('Opened', colnames(service.open.m.df))] <- 'Record'
# service.open.m.df <- makeDateGroupAndFillGaps(calendar.df, service.open.m.df, bigGroup, smallGroup, c('Version', 'Key'), startString.month)
# service.open.m.df$State <- 'Opened'
# service.open.m.df$Type <- paste(service.open.m.df$Key, service.open.m.df$Version, sep=" ")
# 
# service.rec.m.df <- subset(service.df, select=c('Year','Month','Version','Key','Received'))
# colnames(service.rec.m.df)[grep('Received', colnames(service.rec.m.df))] <- 'Record'
# service.rec.m.df <- makeDateGroupAndFillGaps(calendar.df, service.rec.m.df, bigGroup, smallGroup, c('Version', 'Key'), startString.month)
# service.rec.m.df$State <- 'Received'
# service.rec.m.df$Type <- paste(service.rec.m.df$Key, service.rec.m.df$Version, sep=" ")
# 
# service.to.m.df <- subset(service.df, select=c('Year','Month','Version','Key','ToQC'))
# colnames(service.to.m.df)[grep('ToQC', colnames(service.to.m.df))] <- 'Record'
# service.to.m.df <- makeDateGroupAndFillGaps(calendar.df, service.to.m.df, bigGroup, smallGroup, c('Version', 'Key'), startString.month)
# service.to.m.df$State <- 'ToQC'
# service.to.m.df$Type <- paste(service.to.m.df$Key, service.to.m.df$Version, sep=" ")
# 
# service.thru.m.df <- subset(service.df, select=c('Year','Month','Version','Key','ThruQC'))
# colnames(service.thru.m.df)[grep('ThruQC', colnames(service.thru.m.df))] <- 'Record'
# service.thru.m.df <- makeDateGroupAndFillGaps(calendar.df, service.thru.m.df, bigGroup, smallGroup, c('Version', 'Key'), startString.month)
# service.thru.m.df$State <- 'ThruQC'
# service.thru.m.df$Type <- paste(service.thru.m.df$Key, service.thru.m.df$Version, sep=" ")
# 
# service.allm.df <- Reduce(function(x, y) merge(x, y, all=TRUE), list(service.to.m.df, service.rec.m.df, service.thru.m.df, service.open.m.df))
# #not opened, not rec
# service.allm.df <- Reduce(function(x, y) merge(x, y, all=TRUE), list(service.thru.m.df, service.to.m.df))
# ggplot(service.allm.df, aes(x=DateGroup, y=Record, fill=Type)) + geom_bar(stat="identity", position="stack")

#---------------------NEEDS WORK!!!-----------Open RMAs awaiting receipt by week------------------------------------------------------------------------------
# smallGroup <- 'Week'
# 
# #running total of opened - running total of recd
# service.waiting.df <- subset(service.df, select=c('Year','Week','Version','Key','Opened','Received'))
# service.waiting.df$runOpen <- sapply(1:length(service.waiting.df[,1]), function(x) sum(service.waiting.df[1:x, 'Opened']))
# service.waiting.df$runRec <- sapply(1:length(service.waiting.df[,1]), function(x) sum(service.waiting.df[1:x, 'Received']))
# service.waiting.df$Record <- service.waiting.df$runOpen - service.waiting.df$runRec
# 
# service.waiting.df <- makeDateGroupAndFillGaps(calendar.df, service.waiting.df, bigGroup, smallGroup, c('Version', 'Key'), startString.week)

#----------------------------Inventory Stock Levels and Goals-------------------------------------------------------------------------------------
#add all ItemIDs to be sure there is at least one row for each
stockInv.df$ItemID <- as.character(stockInv.df$ItemID)
stockInv.df <- rbind(stockInv.df, c('HTFA-ASY-0001R', 0), c('HTFA-ASY-0003R', 0))
stockInv.df$Record <- as.numeric(stockInv.df$Record)
stockInv.df$ItemID <- as.factor(stockInv.df$ItemID)

stockInv.agg <- with(stockInv.df, aggregate(Record~ItemID, FUN=sum))

#add goals
stockInv.agg$Goal[stockInv.agg$ItemID == 'FLM1-ASY-0001R'] <- 150 
stockInv.agg$Goal[stockInv.agg$ItemID == 'FLM2-ASY-0001R'] <- 400
stockInv.agg$Goal[stockInv.agg$ItemID == 'HTFA-ASY-0001R'] <- 2 
stockInv.agg$Goal[stockInv.agg$ItemID == 'HTFA-ASY-0003R'] <- 30 

stockInv.agg$Key <- ' '

# #new ggplot 2.2.0
p.StockInventory <- ggplot(stockInv.agg, aes(x=Key, y=Record)) + geom_bar(stat='identity', width = 0.5) + xlab(' ') + ylab('Inventory') +
  facet_wrap(~ItemID, scales='free_y', strip.position = 'bottom') + geom_hline(aes(yintercept=Goal),linetype = 'dashed', color = 'blue') +
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20),
  axis.text.y=element_text(hjust=1, color='black', size=20), strip.background = element_blank(), strip.placement = 'outside',
  plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) +
  ggtitle('Stock Inventory Levels', subtitle='Goal Lines in Blue') + scale_y_continuous(breaks=pretty_breaks(n=10))

#old ggplot 2.1.0
# p.StockInventory <- ggplot(stockInv.agg, aes(x=Key, y=Record)) + geom_bar(stat='identity', width = 0.5) + xlab(' ') + ylab('Inventory') +
#   facet_wrap(~ItemID, scales='free_y') + geom_hline(aes(yintercept=Goal),linetype = 'dashed', color = 'blue') +
#   theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) +
#   ggtitle('Stock Inventory Levels\nGoal Lines in Blue') + scale_y_continuous(breaks=pretty_breaks(n=10))

#----------------------FA1.5 To 2.0 Conversions Through QC------------------------------------------------------------------------------------
conversion.agg <- aggregateAndFillDateGroupGaps(calendar.month,'Month', conversion.df, 'Key', '2015-06', 'Record', 'sum',0)

p.Conversions <- ggplot(conversion.agg, aes(x=DateGroup, y=Record)) + geom_bar(stat='identity') + xlab('QC Date\n(Year-Month)') + ylab('Conversions') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  ggtitle('FA1.5 To 2.0 Conversions Through QC') + scale_y_continuous(breaks=pretty_breaks(n=10))


# Export Images for the Web Hub
setwd(imgDir)
plots <- ls()[grep('^p\\.', ls())]
for(i in 1:length(plots)) {
  imgName <- paste(substring(plots[i],3),'.png',sep='')
  
  png(file=imgName, width=1200, height=800, units='px')
  print(get(plots[i]))
  makeTimeStamp(author='Post Market Surveillance')
  dev.off()
}

# Export PDF for the Web Hub
setwd(pdfDir)
pdf("InstrumentServicing.pdf", width = 11, height = 8)
for(i in 1:length(plots)) {
  print(get(plots[i]))
}
dev.off()

rm(list = ls())

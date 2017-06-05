workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_InstrumentDashboard'
pdfDir <- '~/WebHub/pdfs/'

setwd(workDir)

# Load needed libraries
library(ggplot2)
library(scales)
library(zoo)
library(lubridate)
library(dateManip)

# load the data from SQL
source('Portfolios/E_ID_load.R')
source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/makeTimeStamp.R')

# Environmental variables
calendar.week <- createCalendarLikeMicrosoft(year(Sys.Date()) - 2, 'Week')
calendar.month <- createCalendarLikeMicrosoft(2012, 'Month')
start.month <- findStartDate(calendar.month, 'Month', 13, 0, keepPeriods=12)
plot.start.month <- findStartDate(calendar.month, 'Month', 13, 0, keepPeriods=0)
start.monthyr <- findStartDate(calendar.month, 'Month', 12, 0, keepPeriods=12)
plot.start.monthyr <- findStartDate(calendar.month, 'Month', 12, 0, keepPeriods=0)
start.month4 <- findStartDate(calendar.month, 'Month', 12, 4, keepPeriods=12)
plot.start.month4 <- findStartDate(calendar.month, 'Month', 12, 4, keepPeriods=0)
start.week <- findStartDate(calendar.week, 'Week', 53, 0, keepPeriods=53)
plot.start.week <- findStartDate(calendar.week, 'Week', 53, 0, keepPeriods=0)
start.weekRoll <- findStartDate(calendar.week, 'Week', 53, 4, keepPeriods=53)
plot.start.weekRoll <- findStartDate(calendar.week, 'Week', 53, 4, keepPeriods=0)
periods <- 4
lagPeriods <- 4
fontSize <- 20
fontFace <- 'bold'
seqBreak <- 12
dateBreaks.wk <- as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= plot.start.week,'DateGroup']))[order(as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= plot.start.week,'DateGroup'])))][seq(1,length(as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= plot.start.week,'DateGroup']))), seqBreak)]
theme_set(theme_grey()+theme(plot.title=element_text(hjust=0.5), plot.subtitle=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(color='black',size=fontSize,face=fontFace)))

# 2017 FilmArray Production
instreleased <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', transferred.df, 'Version', start.month, 'Record', 'sum', 0)
#adding 17 torch modules that were shipped to Greg Feucht before released from QC in 2/2017
instreleased$Record[instreleased$Version == 'Torch Module' & instreleased$DateGroup == '2017-02'] <- instreleased$Record[instreleased$Version == 'Torch Module' & instreleased$DateGroup == '2017-02'] + 17
beg <- paste0(year(Sys.Date()), '-01')
current <- ifelse(month(Sys.Date()) < 10, paste0(year(Sys.Date()), '-0', month(Sys.Date())), paste0(year(Sys.Date(), '-', month(Sys.Date())))) 
goals.FAprod <- data.frame(DateGroup = c('2017-01','2017-02','2017-03','2017-04','2017-05','2017-06','2017-07','2017-08','2017-09','2017-10','2017-11','2017-12'),
                           Goal = c(306,289,357,306,340,323,289,357,306,340,306,224))
goals90.FAprod <- data.frame(DateGroup = c('2017-01','2017-02','2017-03','2017-04','2017-05','2017-06','2017-07','2017-08','2017-09','2017-10','2017-11','2017-12'),
                           Goal = c(275.4,260.1,321.3,275.4,306.0,290.7,260.1,321.3,275.4,306.0,275.4,201.6))
p.FilmArrayProduction <- ggplot(subset(instreleased, DateGroup >= beg), aes(x=DateGroup, y=Record, fill=Version)) + geom_bar(stat='identity') + geom_line(data=subset(goals.FAprod, as.character(DateGroup) <= current), inherit.aes=FALSE, aes(x=DateGroup, y=Goal, group=1), color='forestgreen', size=1) + geom_point(data=subset(goals.FAprod, as.character(DateGroup) <= current), inherit.aes=FALSE, aes(x=DateGroup, y=Goal, group=1), color='forestgreen') + labs(title = '2017 FilmArray Production', subtitle='Goal = Green Line, 90% of Goal = Blue Line', x = 'Date\n(Year-Month)', y = 'Instruments') + theme(axis.text.x=element_text(angle=90, vjust=0.5)) + scale_fill_manual(values=createPaletteOfVariableLength(instreleased, 'Version')) + geom_line(data=subset(goals90.FAprod, as.character(DateGroup) <= current), inherit.aes=FALSE, aes(x=DateGroup, y=Goal, group=1), color='blue', size=1) + geom_point(data=subset(goals90.FAprod, as.character(DateGroup) <= current), inherit.aes=FALSE, aes(x=DateGroup, y=Goal, group=1), color='blue') + geom_text(data = subset(instreleased, DateGroup >= beg & Record != 0), aes(label=Record), size = 4, position = position_stack(vjust = 0.5), fontface = fontFace)

# New Instrument Shipments by Sales Type (IMAN chart)
newinstruments <- subset(shipments.inst, ShipOrder == 1 & Product %in% c('FA1.5','FA2.0','Torch Base','Torch Module'))
shipSource <- subset(newinstruments, select=c('Product','SalesType','Year','Month','Record'))
shipSource <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', shipSource, c('SalesType'), plot.start.month, 'Record', 'sum', 0)
if(nrow(subset(refurbConv.df, TranDate >= Sys.Date()-365)) > 0) {
  refurb <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', refurbConv.df, c('Key'), plot.start.month, 'Record', 'sum', 0)
  colnames(refurb)[colnames(refurb) == 'Key'] <- 'SalesType'
  ship.refurb <- rbind(shipSource, refurb)
} else {
  ship.refurb <- shipSource
}
ship.refurb$SalesType <- factor(ship.refurb$SalesType, levels = c('Domestic Sale','International Sale','Trade-Up','Refurb Conversion','EAP','Replacement','Loaner','Demo','Short Term Rental','Internal','Other'))
p.Ship.SalesType <- ggplot(ship.refurb, aes(x=DateGroup, y=Record, fill=SalesType)) + geom_bar(stat="identity", position="stack") + labs(title = 'New Instrument Shipments by Sales Type', subtitle = 'Including Refurb Conversions, FA 1.5, FA 2.0, and Torch', x = 'Date\n(Year-Month)', y = 'Shipments') + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=fontSize), axis.text.y=element_text(hjust=1, color='black', size=fontSize), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5)) + scale_fill_manual(values=createPaletteOfVariableLength(ship.refurb, 'SalesType'), name='Sales Type') + scale_y_continuous(breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30)) + geom_text(data = with(ship.refurb, aggregate(Record~DateGroup, FUN=sum)), inherit.aes=FALSE, aes(x=DateGroup, y=Record, label=Record), vjust = -0.5, fontface = 'bold', size = 5)

# New Instrument Shipments by Version (IMAN chart)
shipVer <- subset(newinstruments, select=c('Product','Year','Month','Record')) 
shipVer <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', shipVer, c('Product'), plot.start.month, 'Record', 'sum', 0)
if(nrow(subset(refurbConv.df, TranDate >= Sys.Date()-365)) > 0) {
  refurb.ver <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', refurbConv.df, c('Product'), plot.start.month, 'Record', 'sum', 0)  
  shipVer <- rbind(shipVer, refurb.ver)
}
shipVer$Product <- factor(shipVer$Product, levels = c('FA1.5', 'FA2.0', 'Torch Module', 'Torch Base'))
p.Ship.Version <- ggplot(shipVer, aes(x=DateGroup, y=Record, fill=Product)) + geom_bar(stat="identity", position="stack") + labs(title = 'New Instrument Shipments by Version', subtitle = 'FA 1.5, FA 2.0, and Torch', x= 'Date\n(Year-Month)', y='Shipments') + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=fontSize), axis.text.y=element_text(hjust=1, color='black', size=fontSize), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5)) + scale_fill_manual(values=createPaletteOfVariableLength(shipVer, 'Product'), name='Version') + scale_y_continuous(breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30)) + geom_text(data = with(shipVer, aggregate(Record~DateGroup, FUN=sum)), inherit.aes=FALSE, aes(x=DateGroup, y=Record, label=Record), vjust = -0.5, fontface = 'bold', size = 5)

# Early Failure Rates by Month (RMA chart)
newShipments <- subset(shipments.inst, ShipOrder == 1)
newShip.month <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', newShipments, c('Product'), plot.start.monthyr, 'Record', 'sum', 0)
failures.month <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', subset(fail.modes.df, Version != 'Torch Base'), c('Version','Fail','Department'), plot.start.monthyr, 'Record', 'sum', 0)
prod.fail.month <- mergeCalSparseFrames(subset(failures.month, Department=='Production' & Version != 'FA1.5'), newShip.month, c('DateGroup','Version'), c('DateGroup','Product'), 'Record', 'Record', 0, 0)
prod.fail.month <- prod.fail.month[!(prod.fail.month$Version == 'Torch Module' & prod.fail.month$DateGroup < '2016-07'), ]
failures.month[,'ComboCat'] <- do.call(paste, c(failures.month[,c('Version','Fail','Department')], sep=','))
failures.month.cum <- do.call(rbind, lapply(1:length(unique(failures.month$ComboCat)), function(x) data.frame(DateGroup =  failures.month[failures.month$ComboCat == unique(failures.month$ComboCat)[x], 'DateGroup'], ComboCat = unique(failures.month$ComboCat)[x], CumFail = sapply(1:length(failures.month[failures.month$ComboCat == unique(failures.month$ComboCat)[x], 'DateGroup']), function(y) sum(failures.month[failures.month$ComboCat == unique(failures.month$ComboCat)[x], 'Record'][1:y], na.rm = TRUE)))))
failures.month.cum <- data.frame(DateGroup = failures.month.cum$DateGroup, Version = do.call(rbind, strsplit(as.character(failures.month.cum[,'ComboCat']), split=','))[,1], Key = do.call(rbind, strsplit(as.character(failures.month.cum[,'ComboCat']), split=','))[,2], Department = do.call(rbind, strsplit(as.character(failures.month.cum[,'ComboCat']), split=','))[,3], Record = failures.month.cum$CumFail)
newShip.month.cum <- do.call(rbind, lapply(1:length(unique(newShip.month$Product)), function(x) data.frame(DateGroup = newShip.month[newShip.month$Product == unique(newShip.month$Product)[x], 'DateGroup'], Product = unique(newShip.month$Product)[x], Record = sapply(1:length(newShip.month[newShip.month$Product == unique(newShip.month$Product)[x], 'DateGroup']), function(y) sum(newShip.month[newShip.month$Product == unique(newShip.month$Product)[x],'Record'][1:y])))))
newShip.month.cum <- newShip.month.cum[!(newShip.month.cum$Product == 'Torch Module' & as.character(newShip.month.cum$DateGroup) < '2016-07'), ] 
prod.fail.month.cum <- merge(subset(failures.month.cum, Department=='Production'), newShip.month.cum, by.x=c('DateGroup','Version'), by.y=c('DateGroup', 'Product'))
prod.fail.month.cum$CumulativeRate <- with(prod.fail.month.cum, Record.x/Record.y)
prod.fail.month <- merge(prod.fail.month, prod.fail.month.cum[,c('DateGroup','Version','Key','Department','CumulativeRate')], by.x=c('DateGroup','Version','Fail','Department'), by.y=c('DateGroup','Version','Key','Department'))
p.Prod.Fail.Month <- ggplot(prod.fail.month, aes(x=DateGroup, y=Rate, fill=Fail)) + geom_bar(stat='identity') + scale_fill_manual(values=createPaletteOfVariableLength(prod.fail.month, 'Fail'), name='') + facet_wrap(~Version, ncol=1, scale='free_y') + geom_line(data = prod.fail.month, aes(x=DateGroup, y=CumulativeRate, group=Fail, color=Fail), lwd=1.5, lty='dashed') + scale_color_manual(values=c('darkblue', 'chocolate4'), guide=FALSE) + scale_y_continuous(label=percent) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5)) + labs(title='Early Failure Rates by Month', subtitle = '(12 Month Cumulative Rate Overlay)', x='Date\n(Year-Month)', y='Failures/New Instruments Shipped')

# Instrument First Pass Yield in final QC (Final QC chart)
firstPass.runs <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', subset(firstPass.df, TestNo==1), 'Key', plot.start.weekRoll, 'Record', 'sum', 0)
firstPass.pass <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', subset(firstPass.df, TestNo==1 & Result=='Pass'), 'Key', plot.start.weekRoll, 'Record', 'sum', 0)
firstPass.rate <- mergeCalSparseFrames(firstPass.pass, firstPass.runs, c('DateGroup','Key'), c('DateGroup','Key'), 'Record', 'Record', NA, 4)
p.Production.FirstPass <- ggplot(subset(firstPass.rate, Key == 'Production'), aes(x=DateGroup, y=Rate, group=Key)) + geom_line() + geom_point() + scale_x_discrete(breaks=dateBreaks.wk) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace), plot.subtitle=element_text(hjust=0.5)) + labs(x='Date\n(Year-Week)', y='First Pass Yield (4-week moving average)', title='Instrument First Pass Yield in Final QC', subtitle = 'Production') + geom_hline(aes(yintercept=0.9), color='mediumseagreen', lty='dashed') + scale_y_continuous(labels=percent) + expand_limits(y=0.5)

# Rate of Instrument NCRs per Instruments Built (NCR chart)
instBuilt.all <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', instBuilt.df, c('Key'), start.weekRoll, 'Record', 'sum', 0)
instNCRs.all <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', instNCRs.df, c('Key'), start.weekRoll, 'Record', 'sum', 0)
ncr.rate.all <- mergeCalSparseFrames(instNCRs.all, instBuilt.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
ncr.lims.all <- addStatsToSparseHandledData(ncr.rate.all, c('Key'), lagPeriods, TRUE, 2, 'upper', keepPeriods=53)
x_positions <- c('2016-39', '2016-51')
rate.all.annotations <- c('Process Change\n1 NCR/Lot', 'Manifold-DX-DCN-33636,DX-CO-35011\nPCB-CAPA 13210')
y_positions <- ncr.lims.all[(ncr.lims.all[,'DateGroup']) %in% x_positions, 'Rate'] + 0.4
p.NCR.Rate.All <- ggplot(ncr.lims.all, aes(x=DateGroup, y=Rate, group=Key)) + geom_line(color='black') + geom_point() + geom_line(aes(y=UL), color='blue', lty=2) + scale_x_discrete(breaks=dateBreaks.wk) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5)) + labs(title='Rate of Instrument NCRs per Instruments Built (not released)', subtitle ='FYI Limit = +2 standard deviations', x='Date\n(Year-Week)', y='4-week Rolling Average') + annotate("text",x=x_positions,y=y_positions,label=rate.all.annotations, size=6)

# Problem Area in Instrument NCRs (NCR chart)
wpfs.count <- with(wpfsNCR.df, aggregate(Record~Year+Week+Version+RecordedValue, FUN=sum))
wpfs.count[,'DateGroup'] <- with(wpfs.count, ifelse(Week < 10, paste(Year, Week, sep='-0'), paste(Year, Week, sep='-')))
wpfs.count <- wpfs.count[wpfs.count[,'DateGroup'] >= findStartDate(calendar.week, 'Week', 8, keepPeriods=0), ]
wpfs.count <- merge(wpfs.count[,c('DateGroup','Version','RecordedValue','Record')], with(wpfs.count, aggregate(Record~RecordedValue, FUN=sum)), by='RecordedValue')
wpfs.count[,'RecordedValue'] <- factor(wpfs.count[,'RecordedValue'], levels = unique(wpfs.count[with(wpfs.count, order(Record.y, decreasing=TRUE)),'RecordedValue']))
pareto.wpfsncr <- data.frame(RecordedValue = unique(wpfs.count[,c('RecordedValue','Record.y')])[with(unique(wpfs.count[,c('RecordedValue','Record.y')]), order(Record.y, decreasing=TRUE)),'RecordedValue'], CumPercent = sapply(1:length(unique(wpfs.count[,c('RecordedValue','Record.y')])[with(unique(wpfs.count[,c('RecordedValue','Record.y')]), order(Record.y, decreasing=TRUE)),'RecordedValue']), function(x) sum(unique(wpfs.count[,c('RecordedValue','Record.y')])[with(unique(wpfs.count[,c('RecordedValue','Record.y')]), order(Record.y, decreasing=TRUE)),'Record.y'][1:x])/sum(unique(wpfs.count[,c('RecordedValue','Record.y')])[with(unique(wpfs.count[,c('RecordedValue','Record.y')]), order(Record.y, decreasing=TRUE)),'Record.y'])))
pal.wpfs <- createPaletteOfVariableLength(wpfs.count, 'Version')
if(max(which(pareto.wpfsncr[with(pareto.wpfsncr, order(CumPercent)), 'CumPercent'] > 0.8)) <= 10) {
  p.WPFS.pareto <- ggplot(wpfs.count, aes(x=RecordedValue, y=Record.x, fill=Version, order=Version)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=70, hjust=1), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5)) + labs(title='Problem Area in Instrument NCRs', subtitle= 'Last 8 weeks', y='Count of Occurrences', x='') + scale_fill_manual(values=pal.wpfs)
} else {
  pareto.wpfsncr <- pareto.wpfsncr[1:min(which(pareto.wpfsncr[with(pareto.wpfsncr, order(CumPercent)), 'CumPercent'] >= 0.8)),]
  p.WPFS.pareto <- ggplot(subset(wpfs.count, RecordedValue %in% pareto.wpfsncr[,'RecordedValue']), aes(x=RecordedValue, y=Record.x, fill=Version, order=Version)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=70, hjust=1), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5)) + labs(title='Problem Area in Instrument NCRs', subtitle = 'Last 8 weeks, Top 80%', y='Count of Occurrences', x='') + scale_fill_manual(values=pal.wpfs)
}

# 2017 FA 2.0 ELF/DOA Rate (4-month rolling average) (new chart)
# rate calculated by using 4 month moving average of instruments shipped as denominator
fails <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', subset(fail.modes.df, Department == 'Production'), c('Fail', 'Version'), plot.start.monthyr, 'DistinctRecord', 'sum', 0)
new.ship <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', newShipments, 'Product', plot.start.month4, 'Record', 'sum', 0)
#4 month moving average for denom for each version
new.shipavg <- c()
versions <- as.character(unique(new.ship$Product))
for(i in 1:length(versions)) {
  temp <- subset(new.ship, Product == versions[i])
  l <- length(temp$DateGroup)  
  temp <- cbind(temp[4:l,], sapply(4:l, function(x) mean(temp[(x-3):x,'Record'])))
  colnames(temp)[4] <- 'RollingAvg'
  new.shipavg <- rbind(new.shipavg, temp)
}
fail.rate <- mergeCalSparseFrames(fails, new.shipavg, c('DateGroup', 'Version'), c('DateGroup','Product'), 'DistinctRecord','RollingAvg',0,0)
fail.pal <- createPaletteOfVariableLength(fail.rate, 'Fail')
#YTD rates 
fails.2017 <- subset(fails, DateGroup >= beg)
new.ship2017 <- subset(new.ship, DateGroup >= beg)
#cum sum per version
fails.2017cum <- c()
ship2017.cum <- c()
for(i in 1:length(versions)) {
  temp <- subset(fails.2017, Version == versions[i])
  keys <- as.character(unique(temp$Fail))
  for(j in 1:length(keys)) {
    temp2 <- subset(temp, Fail == keys[j])
    temp2$CumSum <- cumsum(temp2$DistinctRecord)
    fails.2017cum <- rbind(fails.2017cum, temp2)
  }
  temp <- subset(new.ship2017, Product == versions[i])
  temp$CumSum <- cumsum(temp$Record)
  ship2017.cum <- rbind(ship2017.cum, temp)
}
ytdrates <- mergeCalSparseFrames(fails.2017cum, ship2017.cum, c('DateGroup', 'Version'), c('DateGroup', 'Product'), 'CumSum', 'CumSum', 0, 0)
ytdrates$Key <- with(ytdrates, ifelse(Fail == 'ELF', 'ELF YTD Rate', 'DOA YTD Rate'))
p.FA2.0ELFDOA <- ggplot(subset(fail.rate, DateGroup >= '2017-01' & Version == 'FA2.0'), aes(x=DateGroup, y=Rate, fill=Fail)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5), legend.position = 'bottom') + labs(title='2017 FA 2.0 DOA/ELF Rate', subtitle= 'DOA/ELF Per 4-Month Moving Average of Instruments Shipped\nGoal = Green Line', y='DOA/ELF Rate', x='Date\n(Year-Month)') + scale_fill_manual(values=fail.pal, name='') + geom_hline(yintercept=0.025, color='forestgreen', size=1) + geom_line(data=subset(ytdrates, Version == 'FA2.0'), inherit.aes = FALSE, aes(x=DateGroup, y=Rate, group=Key, color=Key), size=1) + geom_point(data=subset(ytdrates, Version == 'FA2.0'), inherit.aes = FALSE, aes(x=DateGroup, y=Rate, group=Key, color=Key)) + scale_color_manual(values=c('mediumblue','chocolate4'), name='') + guides(color=guide_legend(nrow=1, by.row=TRUE))

# 2017 Torch Module ELF/DOA Rate (new chart)
p.TorchModELFDOA <- ggplot(subset(fail.rate, DateGroup >= '2017-01' & Version == 'Torch Module'), aes(x=DateGroup, y=Rate, fill=Fail)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5), legend.position = 'bottom') + labs(title='2017 Torch Module DOA/ELF Rate', subtitle= 'DOA/ELF Per 4-Month Moving Average of Instruments Shipped\nGoal = Green Line', y='DOA/ELF Rate', x='Date\n(Year-Month)') + scale_fill_manual(values=fail.pal, name='') + geom_hline(yintercept=0.035, color='forestgreen', size=1) + geom_line(data=subset(ytdrates, Version == 'Torch Module'), inherit.aes = FALSE, aes(x=DateGroup, y=Rate, group=Key, color=Key), size=1) + geom_point(data=subset(ytdrates, Version == 'Torch Module'), inherit.aes = FALSE, aes(x=DateGroup, y=Rate, group=Key, color=Key)) + scale_color_manual(values=c('mediumblue','chocolate4'), name='') + guides(color=guide_legend(nrow=1, by.row=TRUE))

# 2017 Torch Base ELF/DOA Rate (new chart)
p.TorchBaseELFDOA <- ggplot(subset(fail.rate, DateGroup >= '2017-01' & Version == 'Torch Base'), aes(x=DateGroup, y=Rate, fill=Fail)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5), legend.position = 'bottom') + labs(title='2017 Torch Base DOA/ELF Rate', subtitle= 'DOA/ELF Per 4-Month Moving Average of Instruments Shipped\nGoal = Green Line', y='DOA/ELF Rate', x='Date\n(Year-Month)') + scale_fill_manual(values=fail.pal, name='') + geom_hline(yintercept=0.035, color='forestgreen', size=1) + geom_line(data=subset(ytdrates, Version == 'Torch Base'), inherit.aes = FALSE, aes(x=DateGroup, y=Rate, group=Key, color=Key), size=1) + geom_point(data=subset(ytdrates, Version == 'Torch Base'), inherit.aes = FALSE, aes(x=DateGroup, y=Rate, group=Key, color=Key)) + scale_color_manual(values=c('mediumblue','chocolate4'), name='') + guides(color=guide_legend(nrow=1, by.row=TRUE))

# 2017 FA 2.0 Rate of Failures at <100 run hours (4-month rolling average) (new chart)
# rate calculated by using 4 month moving average of instruments shipped as denominator
beg <- paste0(year(Sys.Date()), '-01')
fail.hours <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', fail.hours.df, c('Version'), plot.start.monthyr, 'Failure', 'sum', 0)
fail.hours$FailureLower = numeric(nrow(fail.hours));
fail.hours$FailureUpper = numeric(nrow(fail.hours));
for(i in 1:nrow(fail.hours)){
  CI = poisson.test(fail.hours$Failure[i]);
  fail.hours$FailureLower[i] = CI$conf.int[1];
  fail.hours$FailureUpper[i] = CI$conf.int[2];
}
fail.hours.rate <- mergeCalSparseFrames(fail.hours, new.shipavg, c('DateGroup', 'Version'), c('DateGroup','Product'), 'Failure','RollingAvg',0,0)
fail.hours.rateLower <- mergeCalSparseFrames(fail.hours, new.shipavg, c('DateGroup', 'Version'), c('DateGroup','Product'), 'FailureLower','RollingAvg',0,0)
fail.hours.rateUpper <- mergeCalSparseFrames(fail.hours, new.shipavg, c('DateGroup', 'Version'), c('DateGroup','Product'), 'FailureUpper','RollingAvg',0,0)
fail.hours.rate$Failure = fail.hours.rateLower$Failure;
fail.hours.rate$RateLower = fail.hours.rateLower$Rate;
fail.hours.rate$RateUpper = fail.hours.rateUpper$Rate;
fail.hours.rate = merge(fail.hours.rate, subset(new.shipavg, select=c('DateGroup', 'Product', 'RollingAvg')), by.x=c('DateGroup', 'Version'), by.y=c('DateGroup', 'Product'))

fail.pal <- createPaletteOfVariableLength(fail.rate, 'Fail')
#YTD rates
fail.hours.2017 <- subset(fail.hours, DateGroup >= beg)
new.ship2017 <- subset(new.ship, DateGroup >= beg)
#cum sum per version
fail.hours.2017cum <- c()
ship2017.cum <- c()
for(i in 1:length(versions)) {
  temp <- subset(fail.hours.2017, Version == versions[i])
  keys <- as.character(unique(temp$Fail))
  temp$CumSum <- cumsum(temp$Failure)
  fail.hours.2017cum <- rbind(fail.hours.2017cum, temp)
  temp <- subset(new.ship2017, Product == versions[i])
  temp$CumSum <- cumsum(temp$Record)
  ship2017.cum <- rbind(ship2017.cum, temp)
}
ytdrates.hours <- mergeCalSparseFrames(fail.hours.2017cum, ship2017.cum, c('DateGroup', 'Version'), c('DateGroup', 'Product'), 'CumSum', 'CumSum', 0, 0)
p.FA2.0Hours100 <- ggplot(subset(fail.hours.rate, DateGroup >= '2017-01' & Version == 'FA2.0'), aes(x=DateGroup, y=Rate)) + geom_bar(stat='identity', fill=pal.wpfs[1]) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5), legend.position = 'bottom') + labs(title='2017 FA 2.0 Rate of Failures at <100 Hours Run', subtitle= 'Per 4-Month Moving Average of Instruments Shipped',#\nGoal = Green Line', 
y='Rate of Failures at <100 Hours Run', x='Date\n(Year-Month)') + #geom_hline(yintercept=0.025, color='forestgreen', size=1) + 
  geom_line(data=subset(ytdrates.hours, Version == 'FA2.0'), inherit.aes = FALSE, aes(x=DateGroup, y=Rate, group=Version), size=1) + geom_point(data=subset(ytdrates.hours, Version == 'FA2.0'), inherit.aes = FALSE, aes(x=DateGroup, y=Rate)) + geom_errorbar(aes(ymin=RateLower, ymax=RateUpper)) + geom_text(aes(label=paste(Failure,'\n',sprintf("%.1f",RollingAvg),sep='')),  position = position_stack(vjust = 0.5), size=8)   #+ guides(color=guide_legend(nrow=1, by.row=TRUE))

# 2017 Torch Module Rate of failure at <100 run hours (new chart)
p.TorchModHours100 <- ggplot(subset(fail.hours.rate, DateGroup >= '2017-01' & Version == 'Torch Module'), aes(x=DateGroup, y=Rate)) + geom_bar(stat='identity', fill=pal.wpfs[1]) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5), legend.position = 'bottom') + labs(title='2017 Torch Module Rate of Failures at <100 Hours Run', subtitle= 'Per 4-Month Moving Average of Instruments Shipped',#\nGoal = Green Line', 
y='Rate of Failures at <100 Hours Run', x='Date\n(Year-Month)') + #geom_hline(yintercept=0.025, color='forestgreen', size=1) + 
  geom_line(data=subset(ytdrates.hours, Version == 'Torch Module'), inherit.aes = FALSE, aes(x=DateGroup, y=Rate, group=Version), size=1) + geom_point(data=subset(ytdrates.hours, Version == 'Torch Module'), inherit.aes = FALSE, aes(x=DateGroup, y=Rate)) + geom_errorbar(aes(ymin=RateLower, ymax=RateUpper)) + geom_text(aes(label=paste(Failure,'\n',sprintf("%.1f",RollingAvg),sep='')),  position = position_stack(vjust = 0.5), size=8) #+ guides(color=guide_legend(nrow=1, by.row=TRUE))

# Long-term FA 2.0 Rate of Failures at <100 run hours (4-month rolling average) (new chart)
# rate calculated by using 4 month moving average of instruments shipped as denominator
beg <- '2000-01';
begFA2 <- '2015-05';
new.ship <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', newShipments, 'Product', beg, 'Record', 'sum', 0)
new.shipavg <- c()
versions <- as.character(unique(new.ship$Product))
for(i in 1:length(versions)) {
  temp <- subset(new.ship, Product == versions[i])
  l <- length(temp$DateGroup)  
  temp <- cbind(temp[4:l,], sapply(4:l, function(x) mean(temp[(x-3):x,'Record'])))
  colnames(temp)[4] <- 'RollingAvg'
  new.shipavg <- rbind(new.shipavg, temp)
}
#start.monthyr <- findStartDate(calendar.month, 'Month', 12, 0)
fail.hours <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', fail.hours.df, c('Version'), beg, 'Failure', 'sum', 0)
fail.hours$FailureLower = numeric(nrow(fail.hours));
fail.hours$FailureUpper = numeric(nrow(fail.hours));
for(i in 1:nrow(fail.hours)){
  CI = poisson.test(fail.hours$Failure[i]);
  fail.hours$FailureLower[i] = CI$conf.int[1];
  fail.hours$FailureUpper[i] = CI$conf.int[2];
}
fail.hours.rate <- mergeCalSparseFrames(fail.hours, new.shipavg, c('DateGroup', 'Version'), c('DateGroup','Product'), 'Failure','RollingAvg',0,0)
fail.hours.rateLower <- mergeCalSparseFrames(fail.hours, new.shipavg, c('DateGroup', 'Version'), c('DateGroup','Product'), 'FailureLower','RollingAvg',0,0)
fail.hours.rateUpper <- mergeCalSparseFrames(fail.hours, new.shipavg, c('DateGroup', 'Version'), c('DateGroup','Product'), 'FailureUpper','RollingAvg',0,0)
fail.hours.rate$Failure = fail.hours.rateLower$Failure;
fail.hours.rate$RateLower = fail.hours.rateLower$Rate;
fail.hours.rate$RateUpper = fail.hours.rateUpper$Rate;
fail.hours.rate = merge(fail.hours.rate, subset(new.shipavg, select=c('DateGroup', 'Product', 'RollingAvg')), by.x=c('DateGroup', 'Version'), by.y=c('DateGroup', 'Product'))

fail.pal <- createPaletteOfVariableLength(fail.rate, 'Fail')
#YTD rates
fail.hours.2017 <- subset(fail.hours, DateGroup >= beg)
new.ship2017 <- subset(new.ship, DateGroup >= beg)
#cum sum per version
fail.hours.2017cum <- c()
ship2017.cum <- c()
for(i in 1:length(versions)) {
  temp <- subset(fail.hours.2017, Version == versions[i])
  keys <- as.character(unique(temp$Fail))
  temp$CumSum <- cumsum(temp$Failure)
  fail.hours.2017cum <- rbind(fail.hours.2017cum, temp)
  temp <- subset(new.ship2017, Product == versions[i])
  temp$CumSum <- cumsum(temp$Record)
  ship2017.cum <- rbind(ship2017.cum, temp)
}
ytdrates.hours <- mergeCalSparseFrames(fail.hours.2017cum, ship2017.cum, c('DateGroup', 'Version'), c('DateGroup', 'Product'), 'CumSum', 'CumSum', 0, 0)
p.FA2.0Hours100.long <- ggplot(subset(fail.hours.rate, DateGroup >= begFA2 & Version == 'FA2.0'), aes(x=DateGroup, y=Rate)) + geom_bar(stat='identity', fill=pal.wpfs[1]) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5), legend.position = 'bottom') + labs(title='Long-term FA 2.0 Rate of Failures at <100 Hours Run', subtitle= 'Per 4-Month Moving Average of Instruments Shipped',y='Rate of Failures at <100 Hours Run', x='Date\n(Year-Month)') + #geom_hline(yintercept=0.025, color='forestgreen', size=1) + 
  geom_line(data=subset(ytdrates.hours, Version == 'FA2.0' & DateGroup >= begFA2), inherit.aes = FALSE, aes(x=DateGroup, y=Rate, group=Version), size=1) + geom_point(data=subset(ytdrates.hours, Version == 'FA2.0'  & DateGroup >= begFA2), inherit.aes = FALSE, aes(x=DateGroup, y=Rate)) + geom_errorbar(aes(ymin=RateLower, ymax=RateUpper)) + geom_text(aes(label=paste(Failure,'\n',sprintf("%.1f",RollingAvg),sep='')),  position = position_stack(vjust = 0.5), size=5)   #+ guides(color=guide_legend(nrow=1, by.row=TRUE))

# Long-term Torch Module Rate of failure at <100 run hours (new chart)
begTorch = '2016-04'
p.TorchModHours100.long <- ggplot(subset(fail.hours.rate, DateGroup >= begTorch & Version == 'Torch Module'), aes(x=DateGroup, y=Rate)) + geom_bar(stat='identity', fill=pal.wpfs[1]) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5), legend.position = 'bottom') + labs(title='Long-term Torch Module Rate of Failures at <100 Hours Run', subtitle= 'Per 4-Month Moving Average of Instruments Shipped',y='Rate of Failures at <100 Hours Run', x='Date\n(Year-Month)') + #geom_hline(yintercept=0.025, color='forestgreen', size=1) + 
  geom_line(data=subset(ytdrates.hours, Version == 'Torch Module' & DateGroup >= begTorch), inherit.aes = FALSE, aes(x=DateGroup, y=Rate, group=Version), size=1) + geom_point(data=subset(ytdrates.hours, Version == 'Torch Module' & DateGroup >= begTorch), inherit.aes = FALSE, aes(x=DateGroup, y=Rate)) + geom_errorbar(aes(ymin=RateLower, ymax=RateUpper)) + geom_text(aes(label=paste(Failure,'\n',sprintf("%.1f",RollingAvg),sep='')),  position = position_stack(vjust = 0.5), size=8) #+ guides(color=guide_legend(nrow=1, by.row=TRUE))

# FA 2.0 DOA/ELF Failures Modes (new chart)
failmodes.yr <- fail.modes.df
failmodes.yr$DateGroup <- with(failmodes.yr, ifelse(Month < 10, paste0(Year, '-0', Month), paste0(Year,'-', Month)))
failmodes.yr <- subset(failmodes.yr, DateGroup >= start.monthyr)
modes2.0 <- subset(failmodes.yr, Department == 'Production' & Version == 'FA2.0')
modes2.0.agg <- with(modes2.0, aggregate(Record~ProblemArea+Fail, FUN=sum))
modes2.0.agg$ProblemArea <- factor(modes2.0.agg$ProblemArea, levels = as.character(with(modes2.0.agg, aggregate(Record~ProblemArea, FUN=sum))[with(with(modes2.0.agg, aggregate(Record~ProblemArea, FUN=sum)),order(-Record)),'ProblemArea']))
p.FA20FailureModes <- ggplot(modes2.0.agg, aes(x=ProblemArea, y=Record, fill=Fail)) + geom_bar(stat='identity') + scale_fill_manual(values=createPaletteOfVariableLength(modes2.0.agg, 'Fail'), name='') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=45, hjust=1), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5)) + labs(title='FA 2.0 DOA/ELF Problem Areas', subtitle='Last 12 Months', y='Count', x='Problem Area')

# Torch Module DOA/ELF Failures Modes (new chart)
modesMod <- subset(failmodes.yr, Department == 'Production' & Version == 'Torch Module')
modesMod.agg <- with(modesMod, aggregate(Record~ProblemArea+Fail, FUN=sum))
modesMod.agg$ProblemArea <- factor(modesMod.agg$ProblemArea, levels = as.character(with(modesMod.agg, aggregate(Record~ProblemArea, FUN=sum))[with(with(modesMod.agg, aggregate(Record~ProblemArea, FUN=sum)),order(-Record)),'ProblemArea']))
p.TorchModFailureModes <- ggplot(modesMod.agg, aes(x=ProblemArea, y=Record, fill=Fail)) + geom_bar(stat='identity') + scale_fill_manual(values=createPaletteOfVariableLength(modesMod.agg, 'Fail'), name='') + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=45, hjust=1), axis.text=element_text(size=fontSize, face=fontFace, color='black'), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5)) + labs(title='Torch Module DOA/ELF Problem Areas', subtitle='Last 12 Months', y='Count', x='Problem Area')

# Torch Base DOA/ELF Failures Modes (new chart)
modesBase <- subset(failmodes.yr, Department == 'Production' & Version == 'Torch Base')
modesBase.agg <- with(modesBase, aggregate(Record~ProblemArea+Fail, FUN=sum))
modesBase.agg$ProblemArea <- factor(modesBase.agg$ProblemArea, levels = as.character(with(modesBase.agg, aggregate(Record~ProblemArea, FUN=sum))[with(with(modesBase.agg, aggregate(Record~ProblemArea, FUN=sum)),order(-Record)),'ProblemArea']))
p.TorchBaseFailureModes <- ggplot(modesBase.agg, aes(x=ProblemArea, y=Record, fill=Fail)) + geom_bar(stat='identity') + scale_fill_manual(values=createPaletteOfVariableLength(modesBase.agg, 'Fail'), name='') + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=45, hjust=1), axis.text=element_text(size=fontSize, face=fontFace, color='black'), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5)) + labs(title='Torch Base DOA/ELF Problem Areas', subtitle='Last 12 Months', y='Count', x='Problem Area')

# Instrument NCR Problem Area per Instruments Built (NCR chart)
wpfs.all <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', wpfsNCR.df, c('RecordedValue'), start.weekRoll, 'Record', 'sum', 0)
wpfs.rate.all <- mergeCalSparseFrames(subset(wpfs.all, RecordedValue %in% pareto.wpfsncr[,'RecordedValue']), instBuilt.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
wpfs.lims.all.blue <- addStatsToSparseHandledData(wpfs.rate.all, c('RecordedValue'), lagPeriods, TRUE, 3, 'upper', 0.04, keepPeriods=53)
wpfs.lims.all.red <- addStatsToSparseHandledData(wpfs.rate.all, c('RecordedValue'), lagPeriods, TRUE, 4, 'upper', 0.05, keepPeriods=53)
x_pos.wpfs <- c('2016-49', '2017-02')
problemArea.annot <- c('Board', 'Wire Harness')
y_pos.wpfs <- c(0.35, 0.22)
text.annot <- c('CAPA 13210', 'DX-CO-034917')
annot.wpfs <- data.frame(DateGroup = x_pos.wpfs, Rate = y_pos.wpfs, RecordedValue = problemArea.annot, Text = text.annot)
p.WPFS.all <- ggplot(subset(wpfs.lims.all.red,RecordedValue %in% pareto.wpfsncr[,'RecordedValue']), aes(x=DateGroup, y=Rate, color=Color, group=RecordedValue)) + geom_line(color='black') + geom_point() + facet_wrap(~RecordedValue, scale='free_y') + scale_y_continuous(labels = percent) + scale_x_discrete(breaks=dateBreaks.wk) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5), plot.caption = element_text(hjust=0)) + labs(title='Instrument NCR Problem Area per Instruments Built (all Versions)', subtitle = 'FYI Limit = +3 standard deviations; Limit = +4 standard deviations', x='Date\n(Year-Week)', y='4-week Rolling Average', caption = 'Red limits on this chart are actionable in the Instrument NCR portfolio.') + scale_color_manual(values=c('blue','red'), guide=FALSE) + geom_line(data = wpfs.lims.all.blue, aes(y=UL), color='blue', lty=2) + geom_line(aes(y=UL), color='red', lty=2) + geom_text(data = annot.wpfs, inherit.aes=FALSE, aes(x=DateGroup, y=Rate, label=Text))

# Instrument NCRs Where Found (IMAN chart)
months.all <- sort(as.character(unique(calendar.month$DateGroup)))
mon <- months.all[length(months.all)-2]
ncr.df$DateGroup <- with(ncr.df, ifelse(Month < 10, paste0(Year,'-0', Month), paste0(Year,'-', Month)))
transferred.denom <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', transferred.df, 'Key', plot.start.month, 'Record', 'sum', 0)

where.ncr <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', subset(ncr.df, ncr.df$DateGroup >= mon, select = c('Year', 'Month', 'WhereFound', 'Record')), 'WhereFound', mon, 'Record', 'sum', 0)
where.ncr$Where <- as.character(where.ncr$WhereFound)
where.ncr$Where[grep('Incoming Inspection', where.ncr$WhereFound)] <- '1-Incoming Inspection'
where.ncr$Where[grep('Assembly$', where.ncr$WhereFound)] <- '2-Assembly'
where.ncr$Where[grep('Assembly Testing', where.ncr$WhereFound)] <- '3-Assembly Testing'
where.ncr$Where[grep('Functional Testing', where.ncr$WhereFound)] <- '4-Functional Testing'
where.ncr$Where[grep('Burn', where.ncr$WhereFound)] <- '5-Burn In'
where.ncr$Where[grep('Final QC', where.ncr$WhereFound)] <- '6-Final QC'
where.ncr <- with(where.ncr, aggregate(Record~DateGroup+Where, FUN=sum))
where.ncr <- merge(where.ncr, transferred.denom, by='DateGroup')
where.ncr$Rate <- where.ncr$Record.x / where.ncr$Record.y
p.WhereFound <- ggplot(subset(where.ncr, Where %in% c('1-Incoming Inspection','2-Assembly','3-Assembly Testing','4-Functional Testing','5-Burn In','6-Final QC')), aes(x=Where, y=Rate, fill=DateGroup)) + geom_bar(stat="identity", position='dodge') + scale_y_continuous(labels=percent, breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30)) + scale_fill_manual(values = createPaletteOfVariableLength(where.ncr, 'DateGroup')) + labs(title = 'Instrument NCRs - Where Found', x='Where Found', y='Percent of Instruments Released') + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90,vjust=0.5,color='black',size=fontSize), axis.text.y=element_text(hjust=1, color='black', size=fontSize), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5))

# Instrument NCRs Problem Area (IMAN chart)
problem.ncr <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', subset(ncr.df, ncr.df$DateGroup >= mon, select = c('Year', 'Month', 'ProblemArea', 'Record')), 'ProblemArea', mon, 'Record', 'sum', 0)
problemtop <- with(problem.ncr, aggregate(as.formula(Record~ProblemArea), FUN=sum))
problemtop <- problemtop[with(problemtop, order(-Record)),]
topAreas <- as.character(head(problemtop, 10)[, 'ProblemArea'])
problem.ncr <- with(subset(problem.ncr, ProblemArea %in% topAreas), aggregate(Record~DateGroup+ProblemArea, FUN=sum))
problem.ncr <- merge(problem.ncr, transferred.denom, by='DateGroup')
problem.ncr$Rate <- problem.ncr$Record.x / problem.ncr$Record.y
problem.ncr$ProblemArea <- factor(problem.ncr$ProblemArea, levels = topAreas)
p.ProblemArea <- ggplot(problem.ncr, aes(x=ProblemArea, y=Rate, fill=DateGroup)) + geom_bar(stat="identity", position='dodge') + scale_y_continuous(labels=percent, breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30)) +scale_fill_manual(values=createPaletteOfVariableLength(problem.ncr, 'DateGroup')) + labs(title='Instrument NCRs - Problem Area', x='Top 10 Problem Areas', y='Percent of Instruments Released') + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=45, vjust=0.5,color='black',size=fontSize), axis.text.y=element_text(hjust=1, color='black', size=fontSize), plot.title = element_text(hjust=0.5))

# Instrument NCRs Failed Part (IMAN chart)
failed.ncr <- aggregateAndFillDateGroupGaps(calendar.month, 'Month',failCats.df,'FailureCat',mon,'Record','sum',0)
failedtop <- with(failed.ncr, aggregate(Record~FailureCat, FUN=sum))
failedtop <- failedtop[with(failedtop, order(-Record)),]
topAreas <- as.character(head(failedtop, 10)[,'FailureCat'])
failed.ncr <- merge(subset(failed.ncr, FailureCat %in% topAreas), transferred.denom, by='DateGroup')
failed.ncr$Rate <- failed.ncr$Record.x / failed.ncr$Record.y
failed.ncr$FailureCat <- factor(failed.ncr$FailureCat, levels = topAreas, ordered=TRUE)
p.FailureCategories <- ggplot(failed.ncr, aes(x=FailureCat, y=Rate, fill=DateGroup)) + geom_bar(stat="identity", position='dodge') + scale_y_continuous(labels=percent, breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30)) + scale_fill_manual(values=createPaletteOfVariableLength(failed.ncr, 'DateGroup')) + labs(title='Instrument NCRs - Failure Category', x='Top 10 Failure Categories', y='% of Instruments Released') + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=70,hjust=1, vjust=1, color='black',size=16), axis.text.y=element_text(hjust=1, color='black', size=fontSize), plot.title = element_text(hjust=0.5))

# Customer Reported Failure Mode in Early Failure RMAs by customer reported date of failure (RMA chart)
ef.report.lead.fill <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', leadingEF.df, c('Key','RecordedValue'), plot.start.week, 'Record', 'sum', 0)
pal.ef <- createPaletteOfVariableLength(ef.report.lead.fill,'RecordedValue')
p.Indicator <- ggplot(ef.report.lead.fill, aes(x=DateGroup, y=Record, fill=RecordedValue)) + geom_bar(stat='identity') + facet_wrap(~Key) + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, hjust=1), axis.text=element_text(color='black',size=fontSize,face=fontFace), legend.position='bottom', plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5)) + scale_x_discrete(breaks=dateBreaks.wk) + guides(fill=guide_legend(nrow=3, byrow=TRUE)) + labs(title='Customer Reported Failure Mode in Early Failure RMAs', subtitle='By Customer Reported Date of Failure ', x='Report Date\n(Year-Week)', y='Failures') + scale_fill_manual(values = pal.ef, name='')

# Early Failures per Instruments Shipped (IRMA)
failures <- subset(fail.modes.df, Version != 'Torch Base')
instShip <- subset(newShipments, Product != 'Torch Base', select = c('Year', 'Month', 'Week', 'Product', 'Record'))
instShip[,'Key'] <- 'Production'
colnames(instShip)[colnames(instShip) == 'Product'] <- 'Version'
rmasShip.df[,'Key'] <- 'Service'
ships.df <- rbind(instShip, rmasShip.df)
ships.fill <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', ships.df, c('Key'), start.weekRoll, 'Record', 'sum', 1)
failures.fill <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', failures, c('Department','Fail'), start.weekRoll, 'DistinctRecord', 'sum', 0)
failures.rate <- mergeCalSparseFrames(failures.fill, ships.fill, c('DateGroup','Department'),c('DateGroup','Key'), 'DistinctRecord', 'Record', 0, 4)
failures.lim <- addStatsToSparseHandledData(failures.rate, c('Department'), lagPeriods, TRUE, 3, 'upper', keepPeriods=53)
# annotations for early failure rate
# x_positions <- c('2016-08')
# fail.annotations <- c('CAPA-13226')
# y_positions <- max(failures.lim[as.character(failures.lim[,'DateGroup']) %in% x_positions, 'UL']) + 0.02
pal.fail <- createPaletteOfVariableLength(failures.lim, 'Fail')
p.Failures.all <- ggplot(failures.lim, aes(x=DateGroup, y=Rate, fill=Fail)) + geom_bar(stat='identity') + facet_wrap(~Department, ncol=1) + scale_fill_manual(values=pal.fail) + scale_y_continuous(labels=percent) + labs(title='Early Failures per Instruments Shipped:\nLimit = +3 standard deviations', caption = 'Red limits on this chart are actionable in the Instrument RMA portfolio.', x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1), plot.caption = element_text(hjust=0)) + scale_x_discrete(breaks = dateBreaks.wk) + geom_line(aes(y=UL), color='red', lty=2, group=1) #+ annotate("text",x=x_positions,y=y_positions,label=fail.annotations, size=4)

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

# Export PDF for the Web Hub
setwd(pdfDir)
pdf("InstrumentDashboard.pdf", width = 11, height = 8)
for(i in 1:length(plots)) {
  print(get(plots[i]))
}
dev.off()

rm(list = ls())

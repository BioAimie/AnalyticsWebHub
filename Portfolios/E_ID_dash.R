workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '../images/Dashboard_InstrumentDashboard/'
pdfDir <- '../pdfs/'

setwd(workDir)

# Load needed libraries
library(tidyverse)
library(forcats)
library(scales)
library(zoo)
library(lubridate)
library(dateManip)
library(colorspace)
library(gridExtra)
source('Rfunctions/loadSQL.R')
source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/makeTimeStamp.R')

# load the data from SQL
PMScxn <- odbcConnect('PMS_PROD')
loadSQL(PMScxn, 'SQL/O_IMAN_InstShipments.sql', 'shipments.inst')
loadSQL(PMScxn, 'SQL/O_IMAN_refurbConv.sql', 'refurbConv.df')
loadSQL(PMScxn, 'SQL/O_IMAN_newInstTrans.sql', 'transferred.df')
loadSQL(PMScxn, 'SQL/O_IMAN_InstrumentNCRBreakdown.sql', 'ncr.df')
loadSQL(PMScxn, 'SQL/O_IMAN_FailureCatsNCRs.sql', 'failCats.df')
loadSQL(PMScxn, 'SQL/R_IRMA_EarlyFailuresByCodeFromField.sql', 'leadingEF.df')
loadSQL(PMScxn, 'SQL/R_IQC_FirstPassYield.sql', 'firstPass.df')
loadSQL(PMScxn, 'SQL/R_INCR_InstrumentsProduced_denom.sql', 'instBuilt.df')
loadSQL(PMScxn, 'SQL/R_INCR_InstrumentNCRs.sql', 'instNCRs.df')
loadSQL(PMScxn, 'SQL/R_INCR_InstrumentNCRs_WPFS.sql', 'wpfsNCR.df')
loadSQL(PMScxn, 'SQL/E_ID_EarlyFailureHours.sql', 'fail.hours.df')
loadSQL(PMScxn, 'SQL/E_ID_TorchBaseFailures.sql', 'torchBase.fail.df')
odbcClose(PMScxn)

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
seqBreak <- 12
dateBreaks.wk <- as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= plot.start.week,'DateGroup']))[order(as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= plot.start.week,'DateGroup'])))][seq(1,length(as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= plot.start.week,'DateGroup']))), seqBreak)]

# Chart theme
fontSize <- 20
fontFace <- 'bold'
theme_set(theme_grey() +
          theme(plot.title = element_text(hjust = 0.5), 
                plot.subtitle = element_text(hjust = 0.5), 
                text = element_text(size = fontSize, face = fontFace), 
                axis.text = element_text(color='black',size = fontSize,face = fontFace),
                axis.text.x=element_text(angle=90, hjust=1),
                legend.margin = margin(b = .7, unit = 'cm')));

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

# Aggregate failure RMAs and new shipments for use in next 4 charts: -------------------------------------
newShipments.cust = shipments.inst %>%
  filter(ShipOrder == 1, CustID != 'IDATEC') %>%
  mutate(Product = ifelse(Product == 'Torch Module', 'Torch', Product)) %>%
  inner_join(calendar.month, by = c(ShipDate = 'Date')) %>%
  group_by(DateGroup, Product) %>% summarize(Shipped = n()) %>% ungroup() %>%
  complete(DateGroup = calendar.month$DateGroup, Product, fill = list(Shipped = 0)) %>%
  group_by(Product) %>% mutate(RollingAvg = rollmeanr(Shipped, 4, fill = NA)) %>% ungroup()
fail.hours <- fail.hours.df %>%
  filter(CustomerId != 'IDATEC', Version %in% c('FA2.0', 'Torch')) %>%
  inner_join(calendar.month, by = c(CreatedDate = 'Date')) %>%
  group_by(TicketId) %>% mutate(Weight = 1/n()) %>%
  ungroup() %>% mutate(ProblemArea = fct_relevel(
    fct_relevel(fct_infreq(ProblemArea), 'Cannot verify', after = Inf), 
    'No failure complaint', after = Inf)) %>%
  group_by(DateGroup, Version, ProblemArea) %>% summarize(Failure = sum(Weight)) %>% ungroup() %>%
  complete(DateGroup = calendar.month$DateGroup, Version, ProblemArea, fill = list(Failure = 0)) %>%
  inner_join(newShipments.cust, by=c('DateGroup', Version='Product')) %>%
  mutate(Rate = Failure/RollingAvg)
fail.hours.summary <- fail.hours %>%
  group_by(DateGroup, Version, RollingAvg, Shipped) %>% summarize(Failure = sum(Failure)) %>% do({
    CI = poisson.test(round(.$Failure));
    mutate(as_tibble(.), FailureLower = CI$conf.int[1], FailureUpper = CI$conf.int[2])
  }) %>% ungroup() %>% 
  mutate(RateLower = FailureLower / RollingAvg,
         Rate = Failure / RollingAvg,
         RateUpper = FailureUpper / RollingAvg)

makePalette = function(f){
  n = nlevels(f)
  h = 0:(n-1) * 360 / n
  s = 1 - .5 * ((0:(n-1) %/% 2) %% 2)
  v = .75 + .25 * (0:(n-1) %% 2)
  C = hex(HSV(h, s, v))
  setNames(C[1:n], levels(f))
} 


fail.hours.pal = makePalette(fail.hours$ProblemArea)
fail.hours.lineColor = '#404040';

# FA 2.0 Rate of Field Failures at <100 Hours Run
summ = fail.hours.summary %>% 
  filter(DateGroup >= '2015-05', Version == 'FA2.0') %>%
  mutate(CumulativeRate = cumsum(Failure) / cumsum(Shipped))
p.FA2.0Hours100.long <- fail.hours %>%
  filter(DateGroup >= '2015-05', Version == 'FA2.0') %>%
  ggplot(aes(x = DateGroup, y = Rate)) + 
  geom_col(aes(fill = ProblemArea), 
           color = 'black', position = position_stack(reverse = TRUE)) + 
  geom_line(data = summ, aes(y = CumulativeRate), size = 1, group = 1, color = fail.hours.lineColor) + 
  geom_point(data = summ, aes(y = CumulativeRate), size = 3, color = fail.hours.lineColor) +
  geom_errorbar(data = summ, aes(ymin = RateLower, ymax = RateUpper), width = .4,
                position = position_nudge(x = -.25)) + 
  geom_text(data = summ, aes(y = Rate, label = Failure), vjust = -.5, size = 6) +
  geom_text(data = summ, aes(y = 0, label = RollingAvg), vjust = 1.3, size = 4) +
  scale_fill_manual(values = rev(fail.hours.pal)) +
  scale_y_continuous(labels = scales::percent) +
  guides(fill = guide_legend(nrow = 4)) +
  theme(legend.position = 'bottom') +
  labs(title = 'FA 2.0 Rate of Field Failures at <100 Hours Run', 
       subtitle = 'Per 4-Month Moving Average of Customer Instruments Shipped',
       x='RMA Created Date\n(Year-Month)',
       y='Rate of Failure RMAs at <100 Hours Run',
       fill = '')

# Torch Module Rate of Field Failures at <100 Hours Run
summ = fail.hours.summary %>% 
  filter(DateGroup >= '2016-08', Version == 'Torch') %>%
  mutate(CumulativeRate = cumsum(Failure) / cumsum(Shipped))
p.TorchModHours100.long <- fail.hours %>%
  filter(DateGroup >= '2016-08', Version == 'Torch') %>%
  ggplot(aes(x = DateGroup, y = Rate)) + 
  geom_col(aes(fill = ProblemArea), 
           color = 'black', position = position_stack(reverse = TRUE)) + 
  geom_line(data = summ, aes(y = CumulativeRate), size = 1, group = 1, color = fail.hours.lineColor) + 
  geom_point(data = summ, aes(y = CumulativeRate), size = 3, color = fail.hours.lineColor) +
  geom_errorbar(data = summ, aes(ymin = RateLower, ymax = RateUpper), width = .4,
                position = position_nudge(x = -.25)) + 
  geom_text(data = summ, aes(y = Rate, label = Failure), vjust = -.5, size = 6) +
  geom_text(data = summ, aes(y = 0, label = RollingAvg), vjust = 1.3, size = 6) +
  scale_fill_manual(values = rev(fail.hours.pal)) +
  scale_y_continuous(labels = scales::percent) +
  guides(fill = guide_legend(nrow = 4)) +
  theme(legend.position = 'bottom') +
  labs(title = 'Torch Module Rate of Field Failures at <100 Hours Run', 
       subtitle = 'Per 4-Month Moving Average of Customer Instruments Shipped',
       x='RMA Created Date\n(Year-Month)',
       y='Rate of Failure RMAs at <100 Hours Run',
       fill = '')

# Torch Base Field Failures
torchBase.fail <- torchBase.fail.df %>%
  mutate(ProblemArea = ifelse(is.na(ProblemArea), 'Unknown', ProblemArea)) %>%
  inner_join(calendar.month, by = c(CreatedDate = 'Date')) %>%
  group_by(TicketId) %>% mutate(Weight = 1/n()) %>% ungroup() %>%
  group_by(DateGroup, ProblemArea, EarlyFailureType) %>% summarize(Failure = sum(Weight)) %>% ungroup() %>%
  complete(DateGroup = calendar.month$DateGroup, ProblemArea, EarlyFailureType, fill = list(Failure = 0)) %>%
  filter(DateGroup >= '2016-08') %>%
  mutate(ProblemArea = fct_relevel(fct_infreq(ProblemArea), 
                                   'No failure complaint', after = Inf),
         EarlyFailureType = factor(EarlyFailureType)) %>%
  inner_join(newShipments.cust %>% filter(Product == 'Torch Base'), by=c('DateGroup')) %>%
  mutate(Rate = Failure/RollingAvg)
torchBase.summary <- torchBase.fail %>%
  group_by(DateGroup, RollingAvg, Shipped) %>% summarize(Failure = sum(Failure)) %>% do({
    CI = poisson.test(round(.$Failure));
    mutate(as_tibble(.), FailureLower = CI$conf.int[1], FailureUpper = CI$conf.int[2])
  }) %>% ungroup() %>% 
  mutate(RateLower = FailureLower / RollingAvg,
         Rate = Failure / RollingAvg,
         RateUpper = FailureUpper / RollingAvg)
summ = torchBase.summary %>% 
  mutate(CumulativeRate = cumsum(Failure) / cumsum(Shipped))
torchBase.pal = makePalette(torchBase.fail$ProblemArea)
torchBase.colorPal = createPaletteOfVariableLength(as.data.frame(torchBase.fail), 'EarlyFailureType')
torchBase.colorPal['N/A'] = '#808080'
p.TorchBase.fail <- torchBase.fail %>%
  filter(Rate > 0) %>%
  ggplot(aes(x = DateGroup, y = Rate)) + 
  geom_col(aes(fill = ProblemArea, color = EarlyFailureType), 
           position = position_stack(reverse = TRUE), size = 2) + 
  geom_text(data = summ, aes(y = Rate, label = Failure), vjust = -.5, size = 6) +
  geom_text(data = summ, aes(y = 0, label = RollingAvg), vjust = 1.3, size = 6) +
  scale_fill_manual(values = rev(torchBase.pal)) +
  scale_color_manual(values = torchBase.colorPal) +
  scale_y_continuous(labels = scales::percent) +
  #guides(fill = guide_legend(nrow = 4)) +
  #theme(legend.position = 'bottom') +
  labs(title = 'Torch Base Rate of Field Failures', 
       subtitle = 'Per 4-Month Moving Average of Torch Bases Shipped to Customers',
       x='RMA Created Date\n(Year-Month)',
       y='Rate of Failure RMAs',
       fill = 'Problem Area',
       color = 'Early Failure Type')


makeProblemAreaChart = function(version, versionName, plotName){
  # Problem Areas at <100 hours run
  startDateGroup6 = (tibble(Date = today()-months(5)) %>% inner_join(calendar.month, by = 'Date'))$DateGroup
  startDateGroup12 = (tibble(Date = today()-months(11)) %>% inner_join(calendar.month, by = 'Date'))$DateGroup
  endDateGroup12 = (tibble(Date = today()-months(6)) %>% inner_join(calendar.month, by = 'Date'))$DateGroup
  
  df = fail.hours %>% 
    mutate(DatePeriod = ifelse(DateGroup >= startDateGroup6, 
                               paste0(startDateGroup6, ' to Present'),
                               ifelse(DateGroup >= startDateGroup12,
                                      paste0(startDateGroup12, ' to ', endDateGroup12),
                                                    NA))) %>%
    filter(Version == version, DateGroup >= startDateGroup12) %>%
    group_by(ProblemArea, DatePeriod) %>% summarize(Count = sum(Failure)) %>% ungroup() %>%
    filter(Count > 0) %>%
    mutate(ProblemArea = fct_reorder(ProblemArea, -Count, fun = sum))
  
  plot <- df %>% 
    ggplot(aes(x=ProblemArea, y=Count)) + 
    geom_bar(aes(fill = DatePeriod), stat='identity') + 
    scale_fill_manual(values=createPaletteOfVariableLength(as.data.frame(df), 'DatePeriod'), name='') + 
    scale_y_continuous(breaks = pretty_breaks()) +
    theme(axis.text.x=element_text(angle=45, hjust=1)) + 
    labs(title=paste0(versionName, ' Problem Areas at <100 Hours Run'), 
         subtitle='Past 12 Months', 
         y='Count', 
         x=element_blank())
  
  assign(plotName, plot, envir = globalenv())
}

makeProblemAreaChart('FA2.0', 'FA 2.0', 'p.FA20FailureModes100')
makeProblemAreaChart('Torch', 'Torch Module', 'p.TorchModFailureModes100')

# Torch Base Problem Areas
startDateGroup6 = (tibble(Date = today()-months(5)) %>% inner_join(calendar.month, by = 'Date'))$DateGroup
startDateGroup12 = (tibble(Date = today()-months(11)) %>% inner_join(calendar.month, by = 'Date'))$DateGroup
endDateGroup12 = (tibble(Date = today()-months(6)) %>% inner_join(calendar.month, by = 'Date'))$DateGroup

df = torchBase.fail %>% 
  mutate(DatePeriod = ifelse(DateGroup >= startDateGroup6, 
                             paste0(startDateGroup6, ' to Present'),
                             ifelse(DateGroup >= startDateGroup12,
                                    paste0(startDateGroup12, ' to ', endDateGroup12),
                                    NA))) %>%
  filter(DateGroup >= startDateGroup12) %>%
  group_by(ProblemArea, DatePeriod) %>% summarize(Count = sum(Failure)) %>% ungroup() %>%
  filter(Count > 0) %>%
  mutate(ProblemArea = fct_reorder(ProblemArea, -Count, fun = sum))

p.TorchBaseProblemAreas <- df %>% 
  ggplot(aes(x=ProblemArea, y=Count)) + 
  geom_bar(aes(fill = DatePeriod), stat='identity') + 
  scale_fill_manual(values = createPaletteOfVariableLength(as.data.frame(df), 'DatePeriod'), name='') + 
  scale_y_continuous(breaks = pretty_breaks()) +
  theme(axis.text.x=element_text(angle=45, hjust=1)) + 
  labs(title=paste0('Torch Base Problem Areas'), 
       subtitle='Past 12 Months', 
       y='Count', 
       x=element_blank())

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

# Export Images for the Web Hub
plots <- ls()[grep('^p\\.', ls())]
for(i in 1:length(plots)) {
  imgName <- paste(substring(plots[i], 3), '.png', sep='')
  png(file = paste0(imgDir, imgName), width = 1200, height = 800, units = 'px')
  p = get(plots[i])
  if(is(p, 'grob')){
    grid.draw(p)
  }else{
    print(p)
  }
  makeTimeStamp(author='Data Science')
  dev.off()
}

# Export PDF for the Web Hub
pdf(paste0(pdfDir,"InstrumentDashboard.pdf"), width = 15, height = 10)
for(i in 1:length(plots)) {
  p = get(plots[i])
  if(is(p, 'grob')){
    grid.draw(p)
  }else{
    print(p)
  }
}
dev.off()

rm(list = ls())

workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_InstrumentNCR/'
pdfDir <- '~/WebHub/pdfs/'
setwd(workDir)

# load necessary libraries
library(ggplot2)
library(zoo)
library(RODBC)
library(scales)
library(devtools)
install_github('BioAimie/dateManip')
library(lubridate)
library(dateManip)

# load dashboard data
source('Portfolios/R_INCR_load.R')
source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/makeTimeStamp.R')

# establish some properties used throughout the code- these are kept up top to facilitate changes
bigGroup <- 'Year'
smallGroup <- 'Week'
periods <- 4
weeks <- 53
lagPeriods <- 4
validateDate <- '2015-40'

# make a calendar that matches the weeks from SQL DATEPART function and find a start date such that charts show one year
startYear <- year(Sys.Date()) - 2
calendar.df <- createCalendarLikeMicrosoft(startYear, smallGroup)
startDate <- findStartDate(calendar.df, 'Week', weeks, periods)
# set theme for line charts ------------------------------------------------------------------------------------------------------------------
seqBreak <- 12
dateBreaks <- as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup']))[order(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup'])))][seq(4,length(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup']))), seqBreak)]
fontSize <- 20
fontFace <- 'bold'
# set theme for line charts ------------------------------------------------------------------------------------------------------------------

# create some high-level charts that are overall NCR rate per all instruments built, and then by version
instBuilt.ver <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', instBuilt.df, c('Version'), startDate, 'Record', 'sum', 0)
instBuilt.all <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', instBuilt.df, c('Key'), startDate, 'Record', 'sum', 0)
instNCRs.ver <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', instNCRs.df, c('Version'), startDate, 'Record', 'sum', NA)
instNCRs.ver$VersionGroup <- as.character(instNCRs.ver$Version)
instNCRs.ver$VersionGroup[as.character(instNCRs.ver$Version) == 'Torch Module' | as.character(instNCRs.ver$Version) == 'Torch Base'] <- 'Torch'
instNCRs.all <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', instNCRs.df, c('Key'), startDate, 'Record', 'sum', 0)
ncr.rate.all <- mergeCalSparseFrames(instNCRs.all, instBuilt.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
ncr.rate.ver <- mergeCalSparseFrames(instNCRs.ver, instBuilt.ver, c('DateGroup','VersionGroup'), c('DateGroup','Version'), 'Record', 'Record', NA, periods)
ncr.lims.all <- addStatsToSparseHandledData(ncr.rate.all, c('Key'), lagPeriods, TRUE, 2, 'upper')
x_positions <- c('2016-23','2016-39', '2016-51')
rate.all.annotations <- c('Bead Beater Rework-CAPA 13262,\nTorch Build Ramp','Process Change\n1 NCR/Lot', 'Manifold-DX-DCN-33636,DX-CO-35011\nPCB-CAPA 13210')
y_positions <- ncr.lims.all[(ncr.lims.all[,'DateGroup']) %in% x_positions, 'Rate'] + 0.4
p.ncr.rate.all <- ggplot(ncr.lims.all, aes(x=DateGroup, y=Rate, group=Key)) + geom_line(color='black') + geom_point() + geom_hline(aes(yintercept=UL), color='blue', lty=2) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Rate of Instrument NCRs per Instruments Built (not released):\n FYI Limit = +2 standard deviations', x='Date\n(Year-Week)', y='4-week Rolling Average') + annotate("text",x=x_positions,y=y_positions,label=rate.all.annotations, size=6)
#fixed scale in torch module chart 
fix.dategroup <- c('2016-21','2016-22')
ncr.rate.ver$CRate <- ncr.rate.ver$Rate
ncr.rate.ver$CRate[as.character(ncr.rate.ver$DateGroup) %in% fix.dategroup & as.character(ncr.rate.ver$Version) == 'Torch Module'] <- NA
removed.points <- data.frame(DateGroup = c('2016-21','2016-22'), Version = 'Torch Module', Point = 5)
p.ncr.rate.ver <- ggplot(subset(ncr.rate.ver, Version %in% c('FA2.0', 'Torch Module', 'Torch Base')), aes(x=DateGroup, y=CRate, group=Version)) + geom_line(color='black') + facet_wrap(~Version, ncol=1, scale='free_y') + geom_point(color='black') + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Instrument NCRs per Instruments Built by Version', subtitle ='(x indicates data point above axis limit)', x='Date\n(Year-Week)', y='4-week Rolling Average') + geom_point(data=removed.points, inherit.aes=FALSE, aes(x=DateGroup, y=Point), shape=4) 

# make a chart for the incoming inspection 
incomingInspection.all <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', incomingInspection.df, c('RecordedValue'), startDate, 'Record', 'sum', 0)
incomingInspection.rate <- mergeCalSparseFrames(incomingInspection.all, instNCR.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0)
p.ncr.incoming.inspection <- ggplot(incomingInspection.rate, aes(x=DateGroup, y=Rate)) + geom_bar(stat='identity', fill='cornflowerblue') + geom_hline(yintercept=.25, col="green", linetype="dashed", size=1.3) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Percent of NCRs found in Incoming Inspection \n Goal=25% ' , y='Percent', x='Date \n (Year-Week)') + scale_x_discrete(breaks=dateBreaks) + scale_y_continuous(labels=percent)
 

# make some charts for NCRs that are found in Final QC: pareto (stacked) and line charts
final.qc.count <- with(finalQC.df, aggregate(Record~Year+Week+Version+RecordedValue, FUN=sum))
final.qc.count[,'DateGroup'] <- with(final.qc.count, ifelse(Week < 10, paste(Year, Week, sep='-0'), paste(Year, Week, sep='-')))
startPareto <- findStartDate(calendar.df, 'Week', 8)
final.qc.count <- final.qc.count[final.qc.count[,'DateGroup'] >= startPareto, ]
final.qc.count <- merge(final.qc.count[,c('DateGroup','Version','RecordedValue','Record')], with(final.qc.count, aggregate(Record~RecordedValue, FUN=sum)), by='RecordedValue')
final.qc.count[,'RecordedValue'] <- factor(final.qc.count[,'RecordedValue'], levels = unique(final.qc.count[with(final.qc.count, order(Record.y, decreasing=TRUE)),'RecordedValue']))
pareto <- data.frame(RecordedValue = unique(final.qc.count[,c('RecordedValue','Record.y')])[with(unique(final.qc.count[,c('RecordedValue','Record.y')]), order(Record.y, decreasing=TRUE)),'RecordedValue'], CumPercent = sapply(1:length(unique(final.qc.count[,c('RecordedValue','Record.y')])[with(unique(final.qc.count[,c('RecordedValue','Record.y')]), order(Record.y, decreasing=TRUE)),'RecordedValue']), function(x) sum(unique(final.qc.count[,c('RecordedValue','Record.y')])[with(unique(final.qc.count[,c('RecordedValue','Record.y')]), order(Record.y, decreasing=TRUE)),'Record.y'][1:x])/sum(unique(final.qc.count[,c('RecordedValue','Record.y')])[with(unique(final.qc.count[,c('RecordedValue','Record.y')]), order(Record.y, decreasing=TRUE)),'Record.y'])))
pal.final.qc <- createPaletteOfVariableLength(final.qc.count, 'Version')
if(max(which(pareto[with(pareto, order(CumPercent)), 'CumPercent'] > 0.8)) <= 10) {
  p.final.qc.pareto <- ggplot(final.qc.count, aes(x=RecordedValue, y=Record.x, fill=Version, order=Version)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=70, hjust=1)) + labs(title='Problem Area in Final QC (last 8 weeks)', y='Count of Occurrences', x='') + scale_fill_manual(values = pal.final.qc)
} else {
  pareto <- pareto[1:min(which(pareto[with(pareto, order(CumPercent)), 'CumPercent'] >= 0.8)),]
  p.final.qc.pareto <- ggplot(subset(final.qc.count, RecordedValue %in% pareto[,'RecordedValue']), aes(x=RecordedValue, y=Record.x, fill=Version, order=Version)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=70, hjust=1)) + labs(title='Problem Area in Final QC (last 8 weeks, top 80%)', y='Count of Occurrences', x='') + scale_fill_manual(values = pal.final.qc)
}
final.qc.ver <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', finalQC.df, c('Version','RecordedValue'), startDate, 'Record', 'sum', 0)
final.qc.rate <- mergeCalSparseFrames(final.qc.ver, instBuilt.ver, c('DateGroup','Version'), c('DateGroup','Version'), 'Record', 'Record', 0, periods)
p.final.qc.two <- ggplot(subset(final.qc.rate,RecordedValue %in% pareto[,'RecordedValue'] & Version == 'FA2.0'), aes(x=DateGroup, y=Rate, group=Version)) + geom_line() + geom_point(aes(x=DateGroup, y=Rate), data = subset(final.qc.rate,RecordedValue %in% pareto[,'RecordedValue'] & Version == 'FA2.0'), color='black') + facet_wrap(~RecordedValue, scale='free_y') + geom_hline(aes(yintercept=0.05), color='blue', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='FA 2.0 NCRs in Final QC per Instruments Built (not released):\n FYI Limit = 5% of Instruments Built', x='Date\n(Year-Week)', y='4-week Rolling Average')
final.qc.rate.torch <- subset(final.qc.rate,RecordedValue %in% pareto[,'RecordedValue'] & Version == 'Torch')
#removing over 100% on 2016-22 to fix scale
final.qc.rate.torch$Rate <- ifelse(as.character(final.qc.rate.torch$DateGroup) == '2016-22' & final.qc.rate.torch$Rate > 1, NA, final.qc.rate.torch$Rate) 
p.final.qc.torch <- ggplot(final.qc.rate.torch, aes(x=DateGroup, y=Rate, group=Version)) + geom_line() + geom_point(aes(x=DateGroup, y=Rate), data = final.qc.rate.torch, color='black') + facet_wrap(~RecordedValue, scale='free_y') + geom_hline(aes(yintercept=0.05), color='blue', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Torch NCRs in Final QC per Instruments Built (not released):\n FYI Limit = 5% of Instruments Built', x='Date\n(Year-Week)', y='4-week Rolling Average')

# make some charts for Problem Area in instrument NCRs: pareto (stacked) and line charts
wpfs.count <- with(wpfsNCR.df, aggregate(Record~Year+Week+Version+RecordedValue, FUN=sum))
wpfs.count[,'DateGroup'] <- with(wpfs.count, ifelse(Week < 10, paste(Year, Week, sep='-0'), paste(Year, Week, sep='-')))
wpfs.count <- wpfs.count[wpfs.count[,'DateGroup'] >= startPareto, ]
wpfs.count <- merge(wpfs.count[,c('DateGroup','Version','RecordedValue','Record')], with(wpfs.count, aggregate(Record~RecordedValue, FUN=sum)), by='RecordedValue')
wpfs.count[,'RecordedValue'] <- factor(wpfs.count[,'RecordedValue'], levels = unique(wpfs.count[with(wpfs.count, order(Record.y, decreasing=TRUE)),'RecordedValue']))
pareto <- data.frame(RecordedValue = unique(wpfs.count[,c('RecordedValue','Record.y')])[with(unique(wpfs.count[,c('RecordedValue','Record.y')]), order(Record.y, decreasing=TRUE)),'RecordedValue'], CumPercent = sapply(1:length(unique(wpfs.count[,c('RecordedValue','Record.y')])[with(unique(wpfs.count[,c('RecordedValue','Record.y')]), order(Record.y, decreasing=TRUE)),'RecordedValue']), function(x) sum(unique(wpfs.count[,c('RecordedValue','Record.y')])[with(unique(wpfs.count[,c('RecordedValue','Record.y')]), order(Record.y, decreasing=TRUE)),'Record.y'][1:x])/sum(unique(wpfs.count[,c('RecordedValue','Record.y')])[with(unique(wpfs.count[,c('RecordedValue','Record.y')]), order(Record.y, decreasing=TRUE)),'Record.y'])))
pal.wpfs <- createPaletteOfVariableLength(wpfs.count, 'Version')
if(max(which(pareto[with(pareto, order(CumPercent)), 'CumPercent'] > 0.8)) <= 10) {
  
  p.wpfs.pareto <- ggplot(wpfs.count, aes(x=RecordedValue, y=Record.x, fill=Version, order=Version)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=70, hjust=1)) + labs(title='Problem Area in Instrument NCRs (last 8 weeks)', y='Count of Occurrences', x='') + scale_fill_manual(values=pal.wpfs)
} else {
  
  pareto <- pareto[1:min(which(pareto[with(pareto, order(CumPercent)), 'CumPercent'] >= 0.8)),]
  p.wpfs.pareto <- ggplot(subset(wpfs.count, RecordedValue %in% pareto[,'RecordedValue']), aes(x=RecordedValue, y=Record.x, fill=Version, order=Version)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=70, hjust=1)) + labs(title='Problem Area in Instrument NCRs (last 8 weeks, top 80%)', y='Count of Occurrences', x='') + scale_fill_manual(values=pal.wpfs)
}
wpfs.ver <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', wpfsNCR.df, c('Version','RecordedValue'), startDate, 'Record', 'sum', 0)
wpfs.all <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', wpfsNCR.df, c('RecordedValue'), startDate, 'Record', 'sum', 0)
wpfs.rate.all <- mergeCalSparseFrames(subset(wpfs.all, RecordedValue %in% pareto[,'RecordedValue']), instBuilt.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
wpfs.rate.ver <- mergeCalSparseFrames(subset(wpfs.ver, RecordedValue %in% pareto[,'RecordedValue']), instBuilt.ver, c('DateGroup','Version'), c('DateGroup','Version'), 'Record', 'Record', NA, periods)
wpfs.lims.all.blue <- addStatsToSparseHandledData(wpfs.rate.all, c('RecordedValue'), lagPeriods, TRUE, 3, 'upper', 0.04)
wpfs.lims.all.red <- addStatsToSparseHandledData(wpfs.rate.all, c('RecordedValue'), lagPeriods, TRUE, 4, 'upper', 0.05)
x_pos.wpfs <- c('2016-49', '2017-02')
problemArea.annot <- c('Board', 'Wire Harness')
y_pos.wpfs <- c(0.35, 0.22)
text.annot <- c('CAPA 13210', 'DX-CO-034917')
annot.wpfs <- data.frame(DateGroup = x_pos.wpfs, Rate = y_pos.wpfs, RecordedValue = problemArea.annot, Text = text.annot)
p.wpfs.all <- ggplot(subset(wpfs.lims.all.red,RecordedValue %in% pareto[,'RecordedValue']), aes(x=DateGroup, y=Rate, color=Color, group=RecordedValue)) + geom_line(color='black') + geom_point() + facet_wrap(~RecordedValue, scale='free_y') + scale_y_continuous(labels = percent) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Instrument NCR Problem Area per Instruments Built (all Versions)', subtitle = 'FYI Limit = +3 standard deviations; Limit = +4 standard deviations', x='Date\n(Year-Week)', y='4-week Rolling Average') + scale_color_manual(values=c('blue','red'), guide=FALSE) + geom_hline(data = wpfs.lims.all.blue, aes(yintercept=UL), color='blue', lty=2) + geom_hline(aes(yintercept=UL), color='red', lty=2) + geom_text(data = annot.wpfs, inherit.aes=FALSE, aes(x=DateGroup, y=Rate, label=Text))
p.wpfs.two <- ggplot(subset(wpfs.rate.ver,Version=='FA2.0'), aes(x=DateGroup, y=Rate, group=Version)) + geom_line() + geom_point() + facet_wrap(~RecordedValue, scale='free_y') + scale_y_continuous(labels = percent) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='FA 2.0 NCRs per Instruments Built by Version', x='Date\n(Year-Week)', y='4-week Rolling Average')
p.wpfs.torch <- ggplot(subset(wpfs.rate.ver,Version=='Torch'), aes(x=DateGroup, y=Rate, group=Version)) + geom_line() + geom_point() + facet_wrap(~RecordedValue, scale='free_y') + scale_y_continuous(labels = percent, limits=c(0,1)) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Torch NCRs per Instruments Built by Version', x='Date\n(Year-Week)', y='4-week Rolling Average')

# make some charts for incoming inspection
incoming.count <- with(incoming.df, aggregate(Record~Year+Week+RecordedValue, FUN=sum))
incoming.count[,'DateGroup'] <- with(incoming.count, ifelse(Week < 10, paste(Year, Week, sep='-0'), paste(Year, Week, sep='-')))
incoming.count <- incoming.count[incoming.count[,'DateGroup'] >= startPareto, ]
incoming.count <- merge(incoming.count[,c('DateGroup','RecordedValue','Record')], with(incoming.count, aggregate(Record~RecordedValue, FUN=sum)), by='RecordedValue')
incoming.count[,'RecordedValue'] <- factor(incoming.count[,'RecordedValue'], levels = unique(incoming.count[with(incoming.count, order(Record.y, decreasing=TRUE)),'RecordedValue']))
pareto <- data.frame(RecordedValue = unique(incoming.count[,c('RecordedValue','Record.y')])[with(unique(incoming.count[,c('RecordedValue','Record.y')]), order(Record.y, decreasing=TRUE)),'RecordedValue'], CumPercent = sapply(1:length(unique(incoming.count[,c('RecordedValue','Record.y')])[with(unique(incoming.count[,c('RecordedValue','Record.y')]), order(Record.y, decreasing=TRUE)),'RecordedValue']), function(x) sum(unique(incoming.count[,c('RecordedValue','Record.y')])[with(unique(incoming.count[,c('RecordedValue','Record.y')]), order(Record.y, decreasing=TRUE)),'Record.y'][1:x])/sum(unique(incoming.count[,c('RecordedValue','Record.y')])[with(unique(incoming.count[,c('RecordedValue','Record.y')]), order(Record.y, decreasing=TRUE)),'Record.y'])))
if(max(which(pareto[with(pareto, order(CumPercent)), 'CumPercent'] > 0.8)) <= 10) {
  p.incoming.pareto <- ggplot(incoming.count, aes(x=RecordedValue, y=Record.x)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=70, hjust=1)) + labs(title='Problem Area in Incoming Inspection (last 8 weeks)', y='Count of Occurrences', x='')
} else {
  
  pareto <- pareto[1:min(which(pareto[with(pareto, order(CumPercent)), 'CumPercent'] >= 0.8)),]
  p.incoming.pareto <- ggplot(subset(incoming.count, RecordedValue %in% pareto[,'RecordedValue']), aes(x=RecordedValue, y=Record.x)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=70, hjust=1)) + labs(title='Problem Area in Incoming Inspection (last 8 weeks, top 80%)', y='Count of Occurrences', x='')
}
incoming.all <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', incoming.df, c('RecordedValue'), startDate, 'Record', 'sum', 0)
incoming.rate <- mergeCalSparseFrames(incoming.all, instNCRs.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
incoming.lims.all <- addStatsToSparseHandledData(incoming.rate, c('RecordedValue'), lagPeriods, TRUE, 3, 'upper')
p.incoming <- ggplot(subset(incoming.lims.all,RecordedValue %in% pareto[,'RecordedValue']), aes(x=DateGroup, y=Rate, group=RecordedValue)) + geom_line() + geom_point() + facet_wrap(~RecordedValue, scale='free_y') + scale_y_continuous(labels = percent) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Incoming Inspection Problem Area per Instrument NCRs', x='Date\n(Year-Week)', y='4-week Rolling Average') + geom_hline(aes(yintercept=UL), color='blue', lty=2)

# add an early failure rate per instruments built chart
min.year <- min(earlyfailures.df[,'Year'])
min.week <- min(earlyfailures.df[earlyfailures.df[,'Year'] == min.year,'Week']) + 3
startDate.alt <- ifelse(min.week < 10, paste(min.year, min.week, sep='-0'), paste(min.year, min.week, sep='-'))
dateBreaks.alt <- as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate.alt,'DateGroup']))[order(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate.alt,'DateGroup'])))][seq(4,length(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate.alt,'DateGroup']))), seqBreak)]
earlyfailures.all <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(earlyfailures.df,Key=='InternallyFlaggedFailure'), c('Key'), startDate.alt, 'Record', 'sum', 0)
instBuilt.all.alt <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', instBuilt.df, c('Key'), startDate.alt, 'Record', 'sum', 1)
earlyfailures.rate <- mergeCalSparseFrames(earlyfailures.all, instBuilt.all.alt, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
earlyfailures.lims <- addStatsToSparseHandledData(earlyfailures.rate, c('Key'), lagPeriods, TRUE, 3, 'upper')
x_pos_labels <- c('2015-30','2015-40','2016-08', '2016-28', '2016-43')
x_pos <- c('2015-30','2015-41','2016-11','2016-22','2016-42')
# y_pos <- earlyfailures.lims[earlyfailures.lims$DateGroup %in% x_pos, 'Rate'] - .01 
y_pos <- c(0.25, 0.08, 0.14, 0.20, 0.05)
fail.annotations <- do.call(c, lapply(1:length(x_pos), function(x) paste(strsplit(as.character(annotations.df[annotations.df$DateGroup %in% x_pos, 'Annotation']),split = ',')[[x]], collapse='\n')))
x1 <- as.character(unique(earlyfailures.lims[,'DateGroup']))[(length(as.character(unique(earlyfailures.lims[,'DateGroup'])))-ceiling(unname(quantile(earlyfailures.df$DeltaWeeks, probs=c(0.80)))))]
x2 <- as.character(unique(earlyfailures.lims[,'DateGroup']))[(length(as.character(unique(earlyfailures.lims[,'DateGroup'])))-ceiling(unname(quantile(earlyfailures.df$DeltaWeeks, probs=c(0.20)))))]
y1 <- 0
y2 <- max(earlyfailures.lims[,'Rate'])
# x_positions_2 <- c('2015-30','2015-41','2016-11','2016-22','2016-42')
# y_positions_2 <- c(0.25, 0.18, 0.20, 0.15, 0.05)
p.earlyfailures <- ggplot(earlyfailures.lims) + geom_rect(aes(xmin=x1, xmax=x2, ymin=y1, ymax=y2), color='cyan', fill='white', alpha=0.2) + geom_line(aes(x=DateGroup, y=Rate, group=Key), color='black') + geom_point(aes(x=DateGroup, y=Rate)) + geom_hline(aes(yintercept=UL), color='blue', lty='dashed') + labs(title='Failures at <100hrs per Instruments Built (not released):\nFYI Limit = +3 standard deviations', x='Date of Manufacture\n(Year-Week)', y='4-week Rolling Average') + scale_y_continuous(label=percent) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks=dateBreaks.alt) + annotate("text",x=x_pos_labels,y=y_pos,label=fail.annotations, size=5.25)

# make another chart that shows early failures, but instead of showing the rate per instruments built, show it as a rate of instruments in the shipment batch
earlyfailures.batchsize <- merge(earlyfailures.df[earlyfailures.df$Key=='InternallyFlaggedFailure',c('SerialNo','Record')], serialbatches.df[,c('SerialNo','Year','Week','Version','Shipments')], by=c('SerialNo'))
earlyfailures.batchsize$BatchRate <- with(earlyfailures.batchsize, Record/Shipments)
earlyfailures.batch.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', earlyfailures.batchsize, c('Version'), startDate, 'BatchRate', 'mean', NA)
pal.earlyfailures.batch <- createPaletteOfVariableLength(earlyfailures.batch.fill, 'Version')
p.ef.shipbatch <- ggplot(subset(earlyfailures.batch.fill, Version %in% c('FA2.0','Torch')), aes(x=DateGroup, y=BatchRate, fill=Version)) + geom_bar(stat='identity') + scale_fill_manual(values=pal.earlyfailures.batch, name='') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks=dateBreaks.alt) + scale_y_continuous(label=percent) + labs(title='Average Early Failure Rate of Shipment Batch', x='Shipment Date\n(Year-Week)', y='Average(Fail Count/Batch Size)')

# make denominator charts
p.denom.instsbuilt <- ggplot(instBuilt.ver, aes(x=DateGroup, y=Record, fill=Version)) + geom_bar(stat='identity') + scale_fill_manual(values=createPaletteOfVariableLength(instBuilt.ver, 'Version')) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks=dateBreaks) + labs(title='Instruments Built (not released)', x='Manufacturing Date\n(Year-Week)', y='Instruments Built')

# for the quarterly review, make the same early failure chart, but just include failures from the field
earlyfailures.cust <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(earlyfailures.df,Key!='InternallyFlaggedFailure'), c('Key'), startDate.alt, 'Record', 'sum', 0)
earlyfailures.cust.rate <- mergeCalSparseFrames(earlyfailures.cust, instBuilt.all.alt, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
earlyfailures.cust.lims <- addStatsToSparseHandledData(earlyfailures.cust.rate, c('Key'), lagPeriods, TRUE, 3, 'upper')
x_pos_cust_labels <- c('2015-13','2015-32','2015-45','2016-12','2016-27','2016-50')
x_pos_cust <- c('2015-11','2015-32','2015-43','2016-10','2016-22','2017-01')
y_pos_cust <- c(0.045, 0.085, 0.16, 0.135, 0.05, 0.015)
y2_cust <- max(earlyfailures.cust.lims[,'Rate'])
fail.annotations.cust <- do.call(c, lapply(1:length(x_pos_cust), function(x) paste(strsplit(as.character(annotations.cust.df[annotations.cust.df$DateGroup %in% x_pos_cust, 'Annotation']),split = ',')[[x]], collapse='\n')))
p.earlyfailures.cust <- ggplot(earlyfailures.cust.lims) + geom_rect(aes(xmin=x1, xmax=x2, ymin=y1, ymax=y2_cust), color='cyan', fill='white', alpha=0.2) + geom_line(aes(x=DateGroup, y=Rate, group=Key), color='black') + geom_point(aes(x=DateGroup, y=Rate)) + geom_hline(aes(yintercept=UL), color='blue', lty='dashed') + labs(title='Customer Reported DOA/ELF per Instruments Built (not released):\nFYI Limit = +3 standard deviations', x='Date of Manufacture\n(Year-Week)', y='4-week Rolling Average') + scale_y_continuous(label=percent) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks=dateBreaks.alt) + annotate("text",x=x_pos_cust_labels,y=y_pos_cust,label=fail.annotations.cust, size=5.25) + expand_limits(y=0.2)

# Make images for the web hub
setwd(imgDir)
plots <- ls()[grep('^p\\.', ls())]
for(i in 1:length(plots)) {
  
  imgName <- paste(substring(plots[i],3),'.png',sep='')
  
  png(file=imgName, width=1200, height=800, units='px')
  print(eval(parse(text = plots[i])))
  makeTimeStamp(timeStamp = Sys.time(), 'Data Science', 1, 'black')
  dev.off()
}

# Make pdf report for the web hub
setwd(pdfDir)
pdf("InstrumentNCR.pdf", width=11, height=8)
for(i in 1:length(plots)) {
  
  print(eval(parse(text = plots[i])))
}
dev.off()

rm(list = ls())
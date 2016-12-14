workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_CustomerComplaints/'
pdfDir <- '~/WebHub/pdfs/'

setwd(workDir)

# Load needed libraries
library(ggplot2)
library(scales)
library(zoo)
library(gridExtra)
library(grid)
library(lubridate)
library(devtools)
install_github('BioAimie/dateManip')
library(dateManip)

# load the data from SQL and user-defined function to create a color palette
source('Portfolios/R_CC_load.R')
source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/makeTimeStamp.R')

# establish some properties used throughout the code- these are kept up top to facilitate changes
periods <- 4
weeks <- 53
lagPeriods <- 4
sdFactor <- 3
validateDate <- '2015-50'

# make a calendar that matches the weeks from SQL DATEPART function and find a start date such that charts show one year
startYear <- year(Sys.Date()) - 3
calendar.df <- createCalendarLikeMicrosoft(startYear, 'Week')
startDate <- findStartDate(calendar.df, 'Week', weeks, periods)
threeyr <- findStartDate(calendar.df, 'Week', 159, 4)
# set theme for line charts ------------------------------------------------------------------------------------------------------------------
seqBreak <- 12
dateBreaks <- as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup']))[order(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup'])))][seq(4,length(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup']))), seqBreak)]
dateBreaks.3yr <- as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= threeyr,'DateGroup']))[order(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= threeyr,'DateGroup'])))][seq(4,length(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= threeyr,'DateGroup']))), seqBreak)]
fontSize <- 20
fontFace <- 'bold'
# set theme for line charts ------------------------------------------------------------------------------------------------------------------

# ------------------------------------------------------ OVERVIEW CHARTS ---------------------------------------------------------------------
pouches.all <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', pouches.df, c('Key'), startDate, 'Record', 'sum', 0)
complaints.all <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', data.frame(Year = failures.df[,'Year'], Week = failures.df[,'Week'], Key = 'AllFailures', Record = failures.df[,'Record']), c('Key'), startDate, 'Record', 'sum', 0)
complaints.all.rate <- mergeCalSparseFrames(complaints.all, pouches.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods) 
complaints.all.lims <- addStatsToSparseHandledData(complaints.all.rate, c('Key'), lagPeriods, TRUE, sdFactor, 'upper', 0)
x_pos <- c('2016-08')
complaints.annotations <- c('CI-14747')
y_pos <- complaints.all.lims[(complaints.all.lims[,'DateGroup']) %in% x_pos, 'Rate'] + 0.002
p.complaints.all <- ggplot(complaints.all.lims, aes(x=DateGroup, y=Rate, group=Key, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values = c('blue','red'), guide=FALSE) + geom_hline(aes(yintercept = UL), color='red', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Customer Complaints per Pouches Shipped', x='Date', y='4 Week Rolling Average') + annotate("text",x=x_pos,y=y_pos,label=complaints.annotations, size=4)
p.complaints.all.hist <- ggplot(complaints.all.lims, aes(x=Rate)) + geom_histogram(aes(y=(..count../sum(..count..)))) + scale_x_continuous(labels=percent) + coord_flip() + labs(x='Proportion', y='') + theme(plot.margin=unit(c(1.45,1,0.2,0.5), 'cm'), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(hjust=1, angle=90), axis.text=element_text(color='black', face=fontFace, size=fontSize))
complaints.all.version <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', failures.df, c('Key'), startDate, 'Record', 'sum', 0)
startDate.16 <- findStartDate(calendar.df, 'Week', 16, 0)
startDate.8 <- findStartDate(calendar.df, 'Week', 8, 0)
complaints.all.version.count <- complaints.all.version[complaints.all.version[,'DateGroup'] >= startDate.16, ]
complaints.all.version.count[,'Period'] <- with(complaints.all.version.count, ifelse(DateGroup < startDate.8, '16 Weeks', '8 Weeks'))
complaints.all.version.count <- merge(with(complaints.all.version.count, aggregate(Record~Key+Period, FUN=sum)), with(complaints.all.version.count, aggregate(Record~Key, FUN=sum)), by='Key')
complaints.all.version.count[,'Key'] <- factor(complaints.all.version.count[,'Key'], levels = complaints.all.version.count[with(complaints.all.version.count, order(Record.y, Period, decreasing = TRUE)), 'Key'])
pal.pareto <- createPaletteOfVariableLength(complaints.all.version.count, 'Period')
p.complaints.all.pareto <- ggplot(complaints.all.version.count[with(complaints.all.version.count, order(Period)), ], aes(x=Key, y=Record.x, fill=Period)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=45, hjust=1)) + labs(title='Customer Complaints by Type Pareto', x='Complaint Type', y='Quantities Affected by Type') + scale_fill_manual(values=pal.pareto)

# ------------------------------------------------- CHEMISTRY COMPLAINTS ---------------------------------------------------------------------
chemistry.all <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(failures.df, Key=='Chemistry'), c('Key'), startDate, 'Record', 'sum', 0)
chemistry.all.rate <- mergeCalSparseFrames(chemistry.all, pouches.all, c('DateGroup'), c('DateGroup'), 'Record','Record', 0, periods)
chemistry.all.lims <- addStatsToSparseHandledData(chemistry.all.rate, c('Key'), lagPeriods, TRUE, sdFactor, 'upper', 0)
p.chemistry.all <-  ggplot(chemistry.all.lims, aes(x=DateGroup, y=Rate, group=Key, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values = c('blue','red'), guide=FALSE) + geom_hline(aes(yintercept = UL), color='red', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Customer Chemistry Complaints per Pouches Shipped', x='Date', y='4 Week Rolling Average')
p.chemistry.all.hist <- ggplot(chemistry.all.lims, aes(x=Rate)) + geom_histogram(aes(y=(..count../sum(..count..)))) + scale_x_continuous(labels=percent) + coord_flip() + labs(x='Proportion', y='') + theme(plot.margin=unit(c(1.45,1,0.2,0.5), 'cm'), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(hjust=1, angle=90), axis.text=element_text(color='black', face=fontFace, size=fontSize))
chemistry.all.version <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(failures.df, Key=='Chemistry'), c('RecordedValue'), startDate, 'Record', 'sum', NA)
chemistry.all.version.count <- chemistry.all.version[chemistry.all.version[,'DateGroup'] >= startDate.16, ]
chemistry.all.version.count[,'Period'] <- with(chemistry.all.version.count, ifelse(DateGroup < startDate.8, '16 Weeks', '8 Weeks'))
chemistry.all.version.count <- merge(with(chemistry.all.version.count, aggregate(Record~RecordedValue+Period, FUN=sum)), with(chemistry.all.version.count, aggregate(Record~RecordedValue, FUN=sum)), by='RecordedValue')
chemistry.all.version.count[,'RecordedValue'] <- factor(chemistry.all.version.count[,'RecordedValue'], levels = chemistry.all.version.count[with(chemistry.all.version.count, order(Record.y, decreasing = TRUE)), 'RecordedValue'])
p.chemistry.all.pareto <- ggplot(chemistry.all.version.count[with(chemistry.all.version.count, order(Period)), ], aes(x=RecordedValue, y=Record.x, fill=Period)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=45, hjust=1)) + labs(title='Customer Chemistry Complaints by Type Pareto', x='Complaint Type', y='Quantities Affected by Type') + scale_fill_manual(values=pal.pareto)
chemistry.all.version[,'Risk'] <- with(chemistry.all.version, ifelse(RecordedValue %in% c('Patient Sample False Negative','Patient Sample False Positive','Validation False Positive','Validation Negative'), 'High','Low'))
chemistry.all.version.rate <- mergeCalSparseFrames(chemistry.all.version, pouches.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
chemistry.all.version.lims <- addStatsToSparseHandledData(chemistry.all.version.rate, c('RecordedValue'), lagPeriods, TRUE, sdFactor, 'upper', 0.001)
p.chemistry.version.high <- ggplot(subset(chemistry.all.version.lims,Risk=='High'), aes(x=DateGroup, y=Rate, group=RecordedValue, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values = c('blue','red'), guide=FALSE) + geom_hline(aes(yintercept = UL), color='red', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + facet_wrap(~RecordedValue, scale='free_y') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Customer Chemistry Complaints By Type per Pouches Shipped (Risk ^)', x='Date', y='4 Week Rolling Average')
p.chemistry.version.low <- ggplot(subset(chemistry.all.version.lims,Risk=='Low'), aes(x=DateGroup, y=Rate, group=RecordedValue, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values = c('black','black'), guide=FALSE) + geom_hline(aes(yintercept = UL), color='blue', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + facet_wrap(~RecordedValue, scale='free_y') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Customer Chemistry Complaints By Type per Pouches Shipped', x='Date', y='4 Week Rolling Average')
chemistry.panel.version.count <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(failures.df, Key=='Chemistry'), c('Version','RecordedValue'), startDate.16, 'Record', 'sum', 0)
chemistry.panel.version.count <- chemistry.panel.version.count[chemistry.panel.version.count[,'DateGroup'] >= startDate.16, ]
chemistry.panel.version.count[,'Period'] <- with(chemistry.panel.version.count, ifelse(DateGroup < startDate.8, '16 Weeks', '8 Weeks'))
chemistry.panel.version.count <- merge(with(chemistry.panel.version.count, aggregate(Record~Version+RecordedValue+Period, FUN=sum)), with(chemistry.panel.version.count, aggregate(Record~RecordedValue, FUN=sum)), by='RecordedValue')
chemistry.panel.version.count[,'RecordedValue'] <- factor(chemistry.panel.version.count[,'RecordedValue'], levels = chemistry.panel.version.count[with(chemistry.panel.version.count, order(Record.y, decreasing = TRUE)), 'RecordedValue'])
pal.panel <- createPaletteOfVariableLength(chemistry.panel.version.count, 'Version')
p.chemistry.panel.pareto <- ggplot(chemistry.panel.version.count[with(chemistry.panel.version.count, order(Version)), ], aes(x=RecordedValue, y=Record.x, fill=Version)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=45, hjust=1)) + labs(title='Customer Chemistry Complaints by Panel Pareto (16 weeks)', x='Complaint Type', y='Quantities Affected by Type') + scale_fill_manual(values=pal.panel)
chemistry.panel <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(failures.df, Key=='Chemistry'), c('Version','RecordedValue'), startDate, 'Record', 'sum', 0)
#Rename failure modes (RecordedValue) so that they show up more legibly on graph
levels(chemistry.panel$RecordedValue)[levels(chemistry.panel$RecordedValue)=='Control Failure'] <- 'Control Failure'
levels(chemistry.panel$RecordedValue)[levels(chemistry.panel$RecordedValue)=='Other Chemistry Error'] <- 'Other Chem Err'
levels(chemistry.panel$RecordedValue)[levels(chemistry.panel$RecordedValue)=='Patient Sample False Negative'] <- 'Pt False Neg'
levels(chemistry.panel$RecordedValue)[levels(chemistry.panel$RecordedValue)=='Patient Sample False Positive'] <- 'Pt False Pos'
levels(chemistry.panel$RecordedValue)[levels(chemistry.panel$RecordedValue)=='Validation False Positive'] <- 'Val False Pos'
levels(chemistry.panel$RecordedValue)[levels(chemistry.panel$RecordedValue)=='Validation Negative'] <- 'Validation Neg'
pouches.panel <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', pouches.df, c('Version'), startDate, 'Record', 'sum', 0)
chemistry.panel[,'Version'] <- as.character(chemistry.panel[,'Version'])
chemistry.panel.rate <- mergeCalSparseFrames(subset(chemistry.panel, Version %in% c('RP','GI','BCID','ME')), pouches.panel, c('DateGroup','Version'), c('DateGroup','Version'), 'Record', 'Record', 0, periods)
chemistry.panel.lims <- addStatsToSparseHandledData(chemistry.panel.rate, c('Version','RecordedValue'), lagPeriods, TRUE, 3, 'upper', 0.001)
p.chemistry.panel <- ggplot(chemistry.panel.lims, aes(x=DateGroup, y=Rate, group=Version, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values = c('black','black'), guide=FALSE) + geom_hline(aes(yintercept = UL), color='blue', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + facet_grid(RecordedValue~Version, scale='free_y') + theme(strip.text.y=element_text(size=13.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Customer Chemistry Complaints By Panel per Pouch Panels Shipped', x='Date', y='4 Week Rolling Average')

# ------------------------------------------------- POUCH COMPLAINTS ---------------------------------------------------------------------
pouch.all <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(failures.df, Key=='Pouch'), c('Key'), startDate, 'Record', 'sum', 0)
pouch.all.rate <- mergeCalSparseFrames(pouch.all, pouches.all, c('DateGroup'), c('DateGroup'), 'Record','Record', 0, periods)
pouch.all.lims <- addStatsToSparseHandledData(pouch.all.rate, c('Key'), lagPeriods, TRUE, sdFactor, 'upper', 0)
x_positions <- c('2016-08')
pouch.annotations <- c('CI-14747')
y_positions <- pouch.all.lims[(pouch.all.lims[,'DateGroup']) %in% x_positions, 'Rate'] + 0.002
p.pouch.all <- ggplot(pouch.all.lims, aes(x=DateGroup, y=Rate, group=Key, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values = c('blue','red'), guide=FALSE) + geom_hline(aes(yintercept = UL), color='red', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Customer Pouch Complaints per Pouches Shipped', x='Date', y='4 Week Rolling Average') + annotate("text",x=x_positions,y=y_positions,label=pouch.annotations, size=4)
p.pouch.all.hist <- ggplot(pouch.all.lims, aes(x=Rate)) + geom_histogram(aes(y=(..count../sum(..count..)))) + scale_x_continuous(labels=percent) + coord_flip() + labs(x='Proportion', y='') + theme(plot.margin=unit(c(1.45,1,0.2,0.5), 'cm'), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(hjust=1, angle=90), axis.text=element_text(color='black', face=fontFace, size=fontSize))
pouch.all.version <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(failures.df, Key=='Pouch'), c('RecordedValue'), startDate, 'Record', 'sum', NA)
pouch.all.version.count <- pouch.all.version[pouch.all.version[,'DateGroup'] >= startDate.16, ]
pouch.all.version.count[,'Period'] <- with(pouch.all.version.count, ifelse(DateGroup < startDate.8, '16 Weeks', '8 Weeks'))
pouch.all.version.count <- merge(with(pouch.all.version.count, aggregate(Record~RecordedValue+Period, FUN=sum)), with(pouch.all.version.count, aggregate(Record~RecordedValue, FUN=sum)), by='RecordedValue')
pouch.all.version.count[,'RecordedValue'] <- factor(pouch.all.version.count[,'RecordedValue'], levels = pouch.all.version.count[with(pouch.all.version.count, order(Record.y, decreasing = TRUE)), 'RecordedValue'])
p.pouch.all.pareto <- ggplot(pouch.all.version.count[with(pouch.all.version.count, order(Period)), ], aes(x=RecordedValue, y=Record.x, fill=Period)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=45, hjust=1)) + labs(title='Customer Pouch Complaints by Type Pareto', x='Complaint Type', y='Quantities Affected by Type') + scale_fill_manual(values=pal.pareto)
pouch.all.version[,'Risk'] <- with(pouch.all.version, ifelse(RecordedValue %in% c('Failure To Hydrate','Pouch Leak'), 'High','Low'))
pouch.all.version.rate <- mergeCalSparseFrames(pouch.all.version, pouches.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
pouch.all.version.lims <- addStatsToSparseHandledData(pouch.all.version.rate, c('RecordedValue'), lagPeriods, TRUE, sdFactor, 'upper', 0.001)
p.pouch.version.high <- ggplot(subset(pouch.all.version.lims,Risk=='High'), aes(x=DateGroup, y=Rate, group=RecordedValue, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values = c('blue','red'), guide=FALSE) + geom_hline(aes(yintercept = UL), color='red', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + facet_wrap(~RecordedValue, scale='free_y') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Customer Pouch Complaints By Type per Pouches Shipped (Risk ^)', x='Date', y='4 Week Rolling Average')
p.pouch.version.low <- ggplot(subset(pouch.all.version.lims,Risk=='Low'), aes(x=DateGroup, y=Rate, group=RecordedValue, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values = c('black','black'), guide=FALSE) + geom_hline(aes(yintercept = UL), color='blue', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + facet_wrap(~RecordedValue, scale='free_y') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Customer Pouch Complaints By Type per Pouches Shipped', x='Date', y='4 Week Rolling Average')
pouch.location.version.count <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(complaints.df, Key=='Pouch'), c('Version','RecordedValue'), startDate.16, 'Record', 'sum', 0)
pouch.location.version.count <- merge(with(pouch.location.version.count, aggregate(Record~Version+RecordedValue, FUN=sum)), with(pouch.location.version.count, aggregate(Record~RecordedValue, FUN=sum)), by='RecordedValue')
pouch.location.version.count[,'RecordedValue'] <- factor(pouch.location.version.count[,'RecordedValue'], levels = pouch.location.version.count[with(pouch.location.version.count, order(Record.y, decreasing = TRUE)), 'RecordedValue'])
pal.location <- createPaletteOfVariableLength(pouch.location.version.count, 'Version')
p.pouch.location.pareto <- ggplot(pouch.location.version.count, aes(x=RecordedValue, y=Record.x, fill=Version)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=45, hjust=1)) + labs(title='Customer Pouch Complaints by Customer Location (16 weeks)', x='Complaint Type', y='Quantities Affected by Type') + scale_fill_manual(values=pal.location)
pouch.location <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(complaints.df, Key=='Pouch'), c('Version','RecordedValue'), startDate, 'Record', 'sum', 0)
pouch.shiploc <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', pouches.df, c('RecordedValue'), startDate, 'Record', 'sum', 0)
pouch.location.rate <- mergeCalSparseFrames(pouch.location, pouch.shiploc, c('DateGroup','Version'), c('DateGroup','RecordedValue'), 'Record', 'Record', 0, periods)
pouch.location.lims <- addStatsToSparseHandledData(pouch.location.rate, c('Version','RecordedValue'), lagPeriods, TRUE, 3, 'upper', 0.001)
p.pouch.location <- ggplot(pouch.location.lims, aes(x=DateGroup, y=Rate, group=Version, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values = c('black','black'), guide=FALSE) + geom_hline(aes(yintercept = UL), color='blue', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + facet_grid(RecordedValue~Version, scale='free_y') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Customer Chemistry Complaints By Panel per Pouch Panels Shipped', x='Date', y='4 Week Rolling Average')

# ------------------------------------------------- INSTRUMENT COMPLAINTS ---------------------------------------------------------------------
instrument.all <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(failures.df, Key=='Instrument'), c('Key'), startDate, 'Record', 'sum', 0)
instrument.all.rate <- mergeCalSparseFrames(instrument.all, pouches.all, c('DateGroup'), c('DateGroup'), 'Record','Record', 0, periods)
instrument.all.lims <- addStatsToSparseHandledData(instrument.all.rate, c('Key'), lagPeriods, TRUE, sdFactor, 'upper', 0)
p.instrument.all <- ggplot(instrument.all.lims, aes(x=DateGroup, y=Rate, group=Key, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values = c('blue','red'), guide=FALSE) + geom_hline(aes(yintercept = UL), color='red', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Customer Instrument Complaints per Pouches Shipped', x='Date', y='4 Week Rolling Average')
p.instrument.all.hist <- ggplot(instrument.all.lims, aes(x=Rate)) + geom_histogram(aes(y=(..count../sum(..count..)))) + scale_x_continuous(labels=percent) + coord_flip() + labs(x='Proportion', y='') + theme(plot.margin=unit(c(1.45,1,0.2,0.5), 'cm'), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(hjust=1, angle=90), axis.text=element_text(color='black', face=fontFace, size=fontSize))
pouches.all.3yr <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', pouches.df, c('Key'), threeyr, 'Record', 'sum', 0)
instrument.all.3yr <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(failures.df, Key=='Instrument'), c('Key'), threeyr, 'Record', 'sum', 0)
instrument.all.3yr.rate <- mergeCalSparseFrames(instrument.all.3yr, pouches.all.3yr, c('DateGroup'), c('DateGroup'), 'Record','Record', 0, periods)
p.instrument.all.3yr <- ggplot(instrument.all.3yr.rate, aes(x=DateGroup, y=Rate, group=Key)) + geom_line(color='black') + geom_point() + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks.3yr) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Customer Instrument Complaints per Pouches Shipped', subtitle = 'Over Three Years', x='Date', y='4 Week Rolling Average')
instrument.all.version <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(failures.df, Key=='Instrument'), c('RecordedValue'), startDate, 'Record', 'sum', 0)
instrument.all.version.count <- instrument.all.version[instrument.all.version[,'DateGroup'] >= startDate.16, ]
instrument.all.version.count[,'Period'] <- with(instrument.all.version.count, ifelse(DateGroup < startDate.8, '16 Weeks', '8 Weeks'))
instrument.all.version.count <- merge(with(instrument.all.version.count, aggregate(Record~Period+RecordedValue, FUN=sum)), with(instrument.all.version.count, aggregate(Record~RecordedValue, FUN=sum)), by='RecordedValue')
instrument.all.version.count[,'RecordedValue'] <- factor(instrument.all.version.count[,'RecordedValue'], levels = instrument.all.version.count[with(instrument.all.version.count, order(Record.y, decreasing = TRUE)), 'RecordedValue'])
p.instrument.all.pareto <- ggplot(instrument.all.version.count, aes(x=RecordedValue, y=Record.x, fill=Period)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=45, hjust=1)) + labs(title='Customer Instrument Complaints by Type Pareto', x='Complaint Type', y='Quantities Affected by Type') + scale_fill_manual(values=pal.pareto)
instrument.all.version.rate <- mergeCalSparseFrames(instrument.all.version, pouches.all, c('DateGroup'),c('DateGroup'), 'Record', 'Record', 0, periods)
# instrument.all.version.lims <- addStatsToSparseHandledData(instrument.all.version.rate, c('RecordedValue'), lagPeriods, TRUE, 3, 'upper', 0.001)
instrument.all.version.lims <- addStatsToSparseHandledData(instrument.all.version.rate, c('RecordedValue'), lagPeriods, TRUE, 3, 'upper', 0.0005)
p.instrument.version <- ggplot(instrument.all.version.lims, aes(x=DateGroup, y=Rate, group=RecordedValue, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values = c('black','black'), guide=FALSE) + geom_hline(aes(yintercept = UL), color='blue', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + facet_wrap(~RecordedValue, scale='free_y') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Instrument Complaints By Type per Pouches Shipped', x='Date', y='4 Week Rolling Average')
instrument.build.version.count <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(failures.df, Key=='Instrument'), c('Version','RecordedValue'), startDate.16, 'Record', 'sum', 0)
instrument.build.version.count <- merge(with(instrument.build.version.count, aggregate(Record~Version+RecordedValue, FUN=sum)), with(instrument.build.version.count, aggregate(Record~RecordedValue, FUN=sum)), by='RecordedValue')
instrument.build.version.count[,'RecordedValue'] <- factor(instrument.build.version.count[,'RecordedValue'], levels = instrument.build.version.count[with(instrument.build.version.count, order(Record.y, decreasing = TRUE)), 'RecordedValue'])
pal.build <- createPaletteOfVariableLength(instrument.build.version.count, 'Version')
p.instrument.build.pareto <- ggplot(instrument.build.version.count, aes(x=RecordedValue, y=Record.x, fill=Version)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=45, hjust=1)) + labs(title='Customer Instrument Complaints by Version (16 weeks)', x='Complaint Type', y='Quantities Affected by Type') + scale_fill_manual(values=pal.build)
instrument.build <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(failures.df, Key=='Instrument'), c('Version','RecordedValue'), startDate, 'Record', 'sum', 0)
installed.fill <- do.call(rbind, lapply(1:length(unique(installed.df[,'Version'])), function(x) cbind(merge(unique(calendar.df[,c('Year','DateGroup')]), installed.df[installed.df[,'Version'] == unique(installed.df[,'Version'])[x], c('DateGroup','Record')], by='DateGroup', all.x=TRUE), Version = unique(installed.df[,'Version'])[x])))
installed.back <- do.call(rbind, lapply(1:length(unique(installed.fill[,'Version'])), function(y) data.frame(Version = unique(installed.fill[,'Version'])[y], DateGroup = installed.fill[installed.fill[,'Version'] == unique(installed.fill[,'Version'])[y], 'DateGroup'], DateGroupBackup = sapply(1:length(unique(installed.fill[,'DateGroup'])), function(x) ifelse(is.na(installed.fill[installed.fill[,'Version'] == unique(installed.fill[,'Version'])[y] & installed.fill[,'DateGroup'] == unique(installed.fill[,'DateGroup'])[x], 'Record']), max(installed.fill[installed.fill[,'Version'] == unique(installed.fill[,'Version'])[y] & !(is.na(installed.fill[,'Record'])) & installed.fill[,'DateGroup'] <= unique(installed.fill[,'DateGroup'])[x],'DateGroup']), unique(installed.fill[,'DateGroup'])[x])))))
installed.back <- merge(installed.back, installed.fill, by.x=c('DateGroupBackup','Version'), by.y=c('DateGroup','Version'))
install.base <- merge(installed.fill, installed.back, by=c('DateGroup','Version'), all.x=TRUE)
install.base[is.na(install.base[,'Record.y']),'Record.y'] <- 0
install.base <- install.base[,c('DateGroup','Version','Record.y')]
colnames(install.base) <- c('DateGroup','Version','Record')
install.base.count <- install.base
install.base <- merge(install.base, with(install.base, aggregate(Record~DateGroup, FUN=sum)), by='DateGroup')
install.base[,'Portion'] <- with(install.base, Record.x/Record.y)
install.base <- install.base[as.character(install.base[,'DateGroup']) >= startDate, ]
install.base <- merge(pouches.all[,c('DateGroup','Record')], install.base[,c('DateGroup','Version','Portion')], by='DateGroup')
install.base[,'Record'] <- with(install.base, Record*Portion)
instrument.build.rate <- mergeCalSparseFrames(instrument.build, install.base, c('DateGroup','Version'), c('DateGroup','Version'), 'Record', 'Record', 0, periods)
keepCats <- as.character(data.frame(RecordedValue = unique(instrument.build.rate[,'RecordedValue']), MaxRate = sapply(1:length(unique(instrument.build.rate[,'RecordedValue'])), function(x) max(instrument.build.rate[instrument.build.rate[,'RecordedValue'] == unique(instrument.build.rate[,'RecordedValue'])[x], 'Rate'])))[with(data.frame(RecordedValue = unique(instrument.build.rate[,'RecordedValue']), MaxRate = sapply(1:length(unique(instrument.build.rate[,'RecordedValue'])), function(x) max(instrument.build.rate[instrument.build.rate[,'RecordedValue'] == unique(instrument.build.rate[,'RecordedValue'])[x], 'Rate']))), order(MaxRate, decreasing=TRUE)), 'RecordedValue'][1:6])
# instrument.build.lims <- addStatsToSparseHandledData(instrument.build.rate[as.character(instrument.build.rate[,'RecordedValue']) %in% keepCats, ], c('Version','RecordedValue'), lagPeriods, TRUE, 3, 'upper', 0.001)
instrument.build.lims <- addStatsToSparseHandledData(instrument.build.rate[as.character(instrument.build.rate[,'RecordedValue']) %in% keepCats, ], c('Version','RecordedValue'), lagPeriods, TRUE, 3, 'upper', 0.0005)
p.instrument.build <- ggplot(instrument.build.lims, aes(x=DateGroup, y=Rate, group=Version, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values = c('black','black'), guide=FALSE) + geom_hline(aes(yintercept = UL), color='blue', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + facet_grid(RecordedValue~Version, scale='free_y') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Top 6 Instrument Complaints By Version and Type per Pouches Shipped to Install Base', x='Date', y='4 Week Rolling Average')
# add in all instrument complaints by install base
install.base.agg <- with(install.base.count, aggregate(Record~DateGroup, FUN=sum))
instrument.all.installed.3yr.rate <- mergeCalSparseFrames(instrument.all.3yr, install.base.agg, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, 4)
p.instrument.all.installed.3yr <- ggplot(instrument.all.installed.3yr.rate, aes(x=DateGroup, y=Rate, group=Key)) + geom_line(color='black') + geom_point() + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks.3yr) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Customer Instrument Complaints per Instruments Installed', subtitle = 'Over Three Years', x='Date', y='4 Week Rolling Average') 
instrument.all.version.installed.rate <- mergeCalSparseFrames(instrument.all.version, install.base.agg, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, 4)
instrument.all.version.installed.lims <- addStatsToSparseHandledData(instrument.all.version.installed.rate, c('RecordedValue'), lagPeriods, TRUE, 3, 'upper', 0)
p.instrument.version.installed <- ggplot(instrument.all.version.installed.lims, aes(x=DateGroup, y=Rate, group=RecordedValue, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values = c('black','black'), guide=FALSE) + geom_hline(aes(yintercept = UL), color='blue', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + facet_wrap(~RecordedValue, scale='free_y') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Instrument Complaints By Type per Instruments Installed', x='Date', y='4 Week Rolling Average')

# ------------------------------------------------- SOFTWARE COMPLAINTS ---------------------------------------------------------------------
software.all <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(failures.df, Key=='Software'), c('Key'), startDate, 'Record', 'sum', 0)
software.all.rate <- mergeCalSparseFrames(software.all, pouches.all, c('DateGroup'), c('DateGroup'), 'Record','Record', 0, periods)
software.all.lims <- addStatsToSparseHandledData(software.all.rate, c('Key'), lagPeriods, TRUE, sdFactor, 'upper', 0)
p.software.all <- ggplot(software.all.lims, aes(x=DateGroup, y=Rate, group=Key, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values = c('blue','red'), guide=FALSE) + geom_hline(aes(yintercept = UL), color='red', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Customer Software Complaints per Pouches Shipped', x='Date', y='4 Week Rolling Average')
p.software.all.hist <- ggplot(software.all.lims, aes(x=Rate)) + geom_histogram(aes(y=(..count../sum(..count..)))) + scale_x_continuous(labels=percent) + coord_flip() + labs(x='Proportion', y='') + theme(plot.margin=unit(c(1.45,1,0.2,0.5), 'cm'), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(hjust=1, angle=90), axis.text=element_text(color='black', face=fontFace, size=fontSize))
software.all.version <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(failures.df, Key=='Software'), c('RecordedValue'), startDate, 'Record', 'sum', NA)
software.all.version.count <- software.all.version[software.all.version[,'DateGroup'] >= startDate.16, ]
software.all.version.count[,'Period'] <- with(software.all.version.count, ifelse(DateGroup < startDate.8, '16 Weeks', '8 Weeks'))
software.all.version.count <- merge(with(software.all.version.count, aggregate(Record~RecordedValue+Period, FUN=sum)), with(software.all.version.count, aggregate(Record~RecordedValue, FUN=sum)), by='RecordedValue')
software.all.version.count[,'RecordedValue'] <- factor(software.all.version.count[,'RecordedValue'], levels = software.all.version.count[with(software.all.version.count, order(Record.y, decreasing = TRUE)), 'RecordedValue'])
p.software.all.pareto <- ggplot(software.all.version.count[with(software.all.version.count, order(Period)), ], aes(x=RecordedValue, y=Record.x, fill=Period)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=45, hjust=1)) + labs(title='Customer Software Complaints by Type Pareto', x='Complaint Type', y='Quantities Affected by Type') + scale_fill_manual(values=pal.pareto)
software.all.version[,'Risk'] <- with(software.all.version, ifelse(RecordedValue %in% c('FA Link LIS'), 'High','Low'))
software.all.version.rate <- mergeCalSparseFrames(software.all.version, pouches.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
software.all.version.lims <- addStatsToSparseHandledData(software.all.version.rate, c('RecordedValue'), lagPeriods, TRUE, sdFactor, 'upper', 0.001)
p.software.version.high <- ggplot(subset(software.all.version.lims,Risk=='High'), aes(x=DateGroup, y=Rate, group=RecordedValue, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values = c('blue','red'), guide=FALSE) + geom_hline(aes(yintercept = UL), color='red', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + facet_wrap(~RecordedValue, scale='free_y') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Software Complaints By Type per Pouches Shipped (Risk ^)', x='Date', y='4 Week Rolling Average')
p.software.version.low <- ggplot(subset(software.all.version.lims,Risk=='Low'), aes(x=DateGroup, y=Rate, group=RecordedValue, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values = c('black','black'), guide=FALSE) + geom_hline(aes(yintercept = UL), color='blue', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + facet_wrap(~RecordedValue, scale='free_y') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Software Complaints By Type per Pouches Shipped', x='Date', y='4 Week Rolling Average')
software.all.version <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(failures.df, Key=='Software'), c('RecordedValue'), startDate, 'Record', 'sum', 0)
software.all.version.count <- software.all.version[software.all.version[,'DateGroup'] >= startDate.16, ]
software.all.version.count[,'Period'] <- with(software.all.version.count, ifelse(DateGroup < startDate.8, '16 Weeks', '8 Weeks'))
software.all.version.count <- merge(with(software.all.version.count, aggregate(Record~Period+RecordedValue, FUN=sum)), with(software.all.version.count, aggregate(Record~RecordedValue, FUN=sum)), by='RecordedValue')
software.all.version.count[,'RecordedValue'] <- factor(software.all.version.count[,'RecordedValue'], levels = software.all.version.count[with(software.all.version.count, order(Record.y, decreasing = TRUE)), 'RecordedValue'])
p.software.all.pareto <- ggplot(software.all.version.count, aes(x=RecordedValue, y=Record.x, fill=Period)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=45, hjust=1)) + labs(title='Customer Software Complaints by Type Pareto', x='Complaint Type', y='Quantities Affected by Type') + scale_fill_manual(values=pal.pareto)
# software.all.version.rate <- mergeCalSparseFrames(software.all.version, pouches.all, c('DateGroup'),c('DateGroup'), 'Record', 'Record', 0, periods)
# software.all.version.lims <- addStatsToSparseHandledData(software.all.version.rate, c('RecordedValue'), lagPeriods, TRUE, 3, 'upper', 0.001)
# p.software.version <- ggplot(software.all.version.lims, aes(x=DateGroup, y=Rate, group=RecordedValue, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values = c('black','black'), guide=FALSE) + geom_hline(aes(yintercept = UL), color='blue', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + facet_wrap(~RecordedValue, scale='free_y') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Software Complaints By Type per Pouches Shipped', x='Date', y='4 Week Rolling Average')
software.build.version.count <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(failures.df, Key=='Software'), c('Version','RecordedValue'), startDate.16, 'Record', 'sum', 0)
software.build.version.count <- merge(with(software.build.version.count, aggregate(Record~Version+RecordedValue, FUN=sum)), with(software.build.version.count, aggregate(Record~RecordedValue, FUN=sum)), by='RecordedValue')
software.build.version.count[,'RecordedValue'] <- factor(software.build.version.count[,'RecordedValue'], levels = software.build.version.count[with(software.build.version.count, order(Record.y, decreasing = TRUE)), 'RecordedValue'])
pal.build.software <- createPaletteOfVariableLength(software.build.version.count, 'Version')
p.software.build.pareto <- ggplot(software.build.version.count, aes(x=RecordedValue, y=Record.x, fill=Version)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=45, hjust=1)) + labs(title='Customer Software Complaints by Version (16 weeks)', x='Complaint Type', y='Quantities Affected by Type') + scale_fill_manual(values=pal.build.software)
software.build <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(failures.df, Key=='Software'), c('Version','RecordedValue'), startDate, 'Record', 'sum', 0)
software.build.rate <- mergeCalSparseFrames(subset(software.build, Version %in% c('FA1.5','FA2.0','Torch')), install.base, c('DateGroup','Version'), c('DateGroup','Version'), 'Record', 'Record', 0, periods)
keepCats <- as.character(data.frame(RecordedValue = unique(software.build.rate[,'RecordedValue']), MaxRate = sapply(1:length(unique(software.build.rate[,'RecordedValue'])), function(x) max(software.build.rate[software.build.rate[,'RecordedValue'] == unique(software.build.rate[,'RecordedValue'])[x], 'Rate'])))[with(data.frame(RecordedValue = unique(software.build.rate[,'RecordedValue']), MaxRate = sapply(1:length(unique(software.build.rate[,'RecordedValue'])), function(x) max(software.build.rate[software.build.rate[,'RecordedValue'] == unique(software.build.rate[,'RecordedValue'])[x], 'Rate']))), order(MaxRate, decreasing=TRUE)), 'RecordedValue'][1:6])
software.build.lims <- addStatsToSparseHandledData(software.build.rate[as.character(software.build.rate[,'RecordedValue']) %in% keepCats, ], c('Version','RecordedValue'), lagPeriods, TRUE, 3, 'upper', 0.001)
p.software.build <- ggplot(software.build.lims, aes(x=DateGroup, y=Rate, group=Version, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values = c('black','black'), guide=FALSE) + geom_hline(aes(yintercept = UL), color='blue', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + facet_grid(RecordedValue~Version, scale='free_y') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Top 6 Software Complaints By Version and Type per Pouches Shipped to Install Base', x='Date', y='4 Week Rolling Average')

# ------------------------------------------------- ACCESSORY/KITTING COMPLAINTS ---------------------------------------------------------------------
acckit.all <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(failures.df, Key=='Accessory/Kitting'), c('Key'), startDate, 'Record', 'sum', 0)
acckit.all.rate <- mergeCalSparseFrames(acckit.all, pouches.all, c('DateGroup'), c('DateGroup'), 'Record','Record', 0, periods)
acckit.all.lims <- addStatsToSparseHandledData(acckit.all.rate, c('Key'), lagPeriods, TRUE, sdFactor, 'upper', 0)
p.acckit.all <- ggplot(acckit.all.lims, aes(x=DateGroup, y=Rate, group=Key, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values = c('blue','red'), guide=FALSE) + geom_hline(aes(yintercept = UL), color='red', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Customer Accessory/Kitting Complaints per Pouches Shipped', x='Date', y='4 Week Rolling Average')
p.acckit.all.hist <- ggplot(acckit.all.lims, aes(x=Rate)) + geom_histogram(aes(y=(..count../sum(..count..)))) + scale_x_continuous(labels=percent) + coord_flip() + labs(x='Proportion', y='') + theme(plot.margin=unit(c(1.45,1,0.2,0.5), 'cm'), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(hjust=1, angle=90), axis.text=element_text(color='black', face=fontFace, size=fontSize))
acckit.all.version <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(failures.df, Key=='Accessory/Kitting'), c('RecordedValue'), startDate, 'Record', 'sum', NA)
acckit.all.version.count <- acckit.all.version[acckit.all.version[,'DateGroup'] >= startDate.16, ]
acckit.all.version.count[,'Period'] <- with(acckit.all.version.count, ifelse(DateGroup < startDate.8, '16 Weeks', '8 Weeks'))
acckit.all.version.count <- merge(with(acckit.all.version.count, aggregate(Record~RecordedValue+Period, FUN=sum)), with(acckit.all.version.count, aggregate(Record~RecordedValue, FUN=sum)), by='RecordedValue')
acckit.all.version.count[,'RecordedValue'] <- factor(acckit.all.version.count[,'RecordedValue'], levels = acckit.all.version.count[with(acckit.all.version.count, order(Record.y, decreasing = TRUE)), 'RecordedValue'])
p.acckit.all.pareto <- ggplot(acckit.all.version.count[with(acckit.all.version.count, order(Period)), ], aes(x=RecordedValue, y=Record.x, fill=Period)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=45, hjust=1)) + labs(title='Customer Accessory/Kitting Complaints by Type Pareto', x='Complaint Type', y='Quantities Affected by Type') + scale_fill_manual(values=pal.pareto)
acckit.all.version.rate <- mergeCalSparseFrames(acckit.all.version, pouches.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
acckit.all.version.lims <- addStatsToSparseHandledData(acckit.all.version.rate, c('RecordedValue'), lagPeriods, TRUE, sdFactor, 'upper', 0.001)
p.acckit.version <- ggplot(acckit.all.version.lims, aes(x=DateGroup, y=Rate, group=RecordedValue, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values = c('black','black'), guide=FALSE) + geom_hline(aes(yintercept = UL), color='blue', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + facet_wrap(~RecordedValue, scale='free_y') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Accessory/Kitting Complaints By Type per Pouches Shipped', x='Date', y='4 Week Rolling Average')

# BioThreat ------------------------------------------------------------------
biothreat.df[,'Year'] <- as.factor(biothreat.df$Year)
pal.biothreat <- createPaletteOfVariableLength(biothreat.df, 'Year')
p.BioThreat.pareto <- ggplot(biothreat.df, aes(x=RecordedValue, y=Record, fill=Year)) + geom_bar(stat='identity') + facet_wrap(~Key, ncol=1) + labs(title='BioThreat Panel Customer Complaints', x='Failure Type', y='Quantity Affected') + theme(plot.title=element_text(size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=45, hjust=1), axis.text=element_text(face=fontFace, color='black', size=fontSize)) + scale_fill_manual(values=pal.biothreat)

# denominator charts
p.denom.pouches <- ggplot(pouches.panel[with(pouches.panel, order(Version, decreasing = TRUE)), ], aes(x=DateGroup, y=Record, fill=Version)) + geom_bar(stat='identity') + scale_fill_manual(values = createPaletteOfVariableLength(pouches.panel, 'Version')) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Pouches Shipped', x='Date', y='Pouches Shipped')
p.denom.installed <- ggplot(subset(install.base.count, DateGroup >= startDate), aes(x=DateGroup, y=Record, fill=Version)) + geom_bar(stat='identity') + scale_fill_manual(values = createPaletteOfVariableLength(install.base.count, 'Version')) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Instruments in Install Base', x='Date', y='Install Base Size')

# Create images for the Web Hub
setwd(imgDir)
plots <- ls()[grep('^p\\.', ls())]
plots.combo <- plots[grep('\\.all$', plots)]
plots.hist <- plots[grep('\\.hist', plots)]
plots.alt <- plots[!(plots %in% plots.hist)]
for(i in 1:length(plots.alt)) {
  
  imgName <- paste(substring(plots.alt[i],3),'.png',sep='')
  
  if(plots.alt[i] %in% plots.combo) {
    
    plot1 <- plots.alt[i]
    plot2 <- paste(plot1, 'hist', sep='.') 
    png(file=imgName, width=1200, height=800, units='px')
    eval(parse(text = paste('grid.arrange(',plot1,',',plot2,', ncol=2, nrow=1, widths=c(4,1.4), heights=c(4))', sep='')))
    makeTimeStamp(timeStamp = Sys.time(), author='Post Market Surveillance')
    dev.off()
  } else {
    
    png(file=imgName, width=1200, height=800, units='px')
    print(eval(parse(text = plots.alt[i])))
    makeTimeStamp(timeStamp = Sys.time(), author='Post Market Surveillance')
    dev.off()
  }
}

# Create the pdf
setwd(pdfDir)
pdf("CustomerComplaints.pdf", width=11, height=8)
for(i in 1:length(plots.alt)) {
  
  if(plots.alt[i] %in% plots.combo) {
    
    plot1 <- plots.alt[i]
    plot2 <- paste(plot1, 'hist', sep='.') 
    eval(parse(text = paste('grid.arrange(',plot1,',',plot2,', ncol=2, nrow=1, widths=c(4,1.4), heights=c(4))', sep='')))
  } else {
    
    print(eval(parse(text = plots.alt[i])))
  }
}
dev.off()

rm(list = ls())
workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_ComplaintInvestigation/'
pdfDir <- '~/WebHub/pdfs/'

setwd(workDir)

# Load needed libraries
library(ggplot2)
library(scales)
library(zoo)
library(devtools)
library(lubridate)
install_github('BioAimie/dateManip')
library(dateManip)

# load the data from SQL
source('Portfolios/R_CI_load.R')
source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/makeTimeStamp.R')

# establish some properties used throughout the code- these are kept up top to facilitate changes
periods <- 4
weeks <- 53
lagPeriods <- 4
validateDate <- '2016-04'

# make a calendar that matches the weeks from SQL DATEPART function and find a start date such that charts show one year
startYear <- year(Sys.Date()) - 3
calendar.df <- createCalendarLikeMicrosoft(startYear, 'Week')
startDate <- findStartDate(calendar.df, 'Week', weeks, periods, keepPeriods=53)
plot.startDate.week <- findStartDate(calendar.df, 'Week', weeks, periods, keepPeriods=0)
# set theme for line charts ------------------------------------------------------------------------------------------------------------------
seqBreak <- 12
dateBreaks <- as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= plot.startDate.week,'DateGroup']))[order(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= plot.startDate.week,'DateGroup'])))][seq(periods,length(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= plot.startDate.week,'DateGroup']))), seqBreak)]
fontSize <- 20
fontFace <- 'bold'
theme_set(theme_gray() + theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)))

# set theme for line charts ------------------------------------------------------------------------------------------------------------------

# Rate of Escalated Complaints per All Complaints 
complaints.all <- data.frame(Year = complaints.df[,'Year'], Week = complaints.df[,'Week'], Key = 'complaints', Record = complaints.df[,'Record'])
complaints.all <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', complaints.all, c('Key'), startDate, 'Record', 'sum', 1)
escalated.all <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(complaints.df, Key == 1), c('Key'), startDate, 'Record', 'sum', 0)
escalated.rate <- mergeCalSparseFrames(escalated.all, complaints.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
escalated.lims <- addStatsToSparseHandledData(escalated.rate, c('Key'), lagPeriods, TRUE, 3, 'upper', 0, keepPeriods=53)
x.val <- which(as.character(unique(escalated.lims[,'DateGroup']))==validateDate)
p.escalated <- ggplot(escalated.lims, aes(x=DateGroup, y=Rate, group=Key, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('blue','red'), guide=FALSE) + geom_line(aes(y=UL), color='red', lty=2) + scale_y_continuous(labels=percent) + expand_limits(y=0) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Rate of Escalated Complaints per All Complaints', subtitle = 'Limit = +3 standard deviations', x='Date\n(Year-Week)', y='Rolling 4-week Average Rate') 

# Rate of Qty Affected in Erroeneous Result Complaints per All Complaints
erroneous.version <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', erroneous.df, c('Version'), startDate, 'Record', 'sum', 0)
erroneous.version.type <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', erroneous.df, c('Version','RecordedValue'), startDate, 'Record', 'sum', 0)
erroneous.version.rate <- mergeCalSparseFrames(erroneous.version, complaints.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
erroneous.version.lims <- addStatsToSparseHandledData(erroneous.version.rate, c('Version'), lagPeriods, TRUE, 3, 'upper', 0.05, keepPeriods=53)
erroneous.version.type.rate <- mergeCalSparseFrames(erroneous.version.type, complaints.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
erroneous.version.type.lims <- addStatsToSparseHandledData(erroneous.version.type.rate, c('Version','RecordedValue'), lagPeriods, TRUE, 3, 'upper', 0.05, keepPeriods=53)
p.erroneous.version <- ggplot(erroneous.version.lims, aes(x=DateGroup, y=Rate, group=Version, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('blue','red'), guide=FALSE) + facet_wrap(~Version, scale='free_y') + geom_line(aes(y=UL), color='red', lty=2) + scale_y_continuous(labels=percent) + expand_limits(y=0) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Quantity Affected in Erroneous Result Complaints per All Complaints\nLimit = 3 standard deviations or 5%', x='Date\n(Year-Week)', y='Rolling 4-week Average Rate') 
p.erroneous.version.chemistry <- ggplot(subset(erroneous.version.type.lims,Version == 'Chemistry'), aes(x=DateGroup, y=Rate, group=RecordedValue, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + facet_wrap(~RecordedValue, scale='free_y') + geom_line(aes(y=UL), color='blue', lty=2, data=subset(erroneous.version.type.lims,Version == 'Chemistry')) + scale_y_continuous(labels=percent) + expand_limits(y=0) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Quantity Affected in Erroneous Result Chemistry Complaints per All Complaints\nFYI Limit = 3 standard deviations or 5%', x='Date\n(Year-Week)', y='Rolling 4-week Average Rate') 
p.erroneous.version.instrument <- ggplot(subset(erroneous.version.type.lims,Version == 'Instrument'), aes(x=DateGroup, y=Rate, group=RecordedValue, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + facet_wrap(~RecordedValue, scale='free_y') + geom_line(aes(y=UL), color='blue', lty=2, data=subset(erroneous.version.type.lims,Version == 'Instrument')) + scale_y_continuous(labels=percent) + expand_limits(y=0) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Quantity Affected in Erroneous Result Instrument Complaints per All Complaints\nFYI Limit = 3 standard deviations or 5%', x='Date\n(Year-Week)', y='Rolling 4-week Average Rate') 
if(nrow(subset(erroneous.version.type.lims,Version == 'Software')) > 0) {
  p.erroneous.version.software <- ggplot(subset(erroneous.version.type.lims,Version == 'Software'), aes(x=DateGroup, y=Rate, group=RecordedValue, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + facet_wrap(~RecordedValue, scale='free_y') + geom_line(aes(y=UL), color='blue', lty=2, data=subset(erroneous.version.type.lims,Version == 'Software')) + scale_y_continuous(labels=percent) + expand_limits(y=0) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Quantity Affected in Erroneous Result Software Complaints per All Complaints\nFYI Limit = 3 standard deviations or 5%', x='Date\n(Year-Week)', y='Rolling 4-week Average Rate') 
} else {
  emptyplot <- data.frame(DateGroup = as.character(unique(erroneous.version.lims$DateGroup)), Version = 'Software', RecordedValue = 'No Data', Rate = 0)
  p.erroneous.version.software <- ggplot(emptyplot, aes(x=DateGroup, y=Rate, group=RecordedValue)) + geom_line(color='black') + geom_point() + facet_wrap(~RecordedValue, scale='free_y') + scale_y_continuous(labels=percent) + expand_limits(y=0) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Quantity Affected in Erroneous Result Software Complaints per All Complaints\nFYI Limit = 3 standard deviations or 5%', x='Date\n(Year-Week)', y='Rolling 4-week Average Rate') 
}

# Rate of BFDx Products by Type in Escalated Complaints per All Complaints

relevent.versions <- as.character(unique(subset(overview.df, paste(Year, Week, sep="-") >= plot.startDate.week)$Version))

bfdxProd.df <- unique(overview.df[,c('bug_id','Year','Week','Version','Record')])[,c('Year','Week','Version','Record')]
bfdxProd.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', bfdxProd.df, c('Version'), startDate, 'Record', 'sum', 0)
bfdxProd.rate <- mergeCalSparseFrames(bfdxProd.fill, complaints.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
bfdxProd.df[,'statParam'] <- 'bfdx'
bfdxProd.all <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', bfdxProd.df, c('statParam'), startDate, 'Record', 'sum', 0)
bfdxProd.all <- mergeCalSparseFrames(bfdxProd.all, complaints.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
bfdxProd.all <- addStatsToSparseHandledData(bfdxProd.all, c('statParam'), lagPeriods, TRUE, 3, 'upper', 0, keepPeriods=53)
bfdxProd.lims <- merge(bfdxProd.rate, bfdxProd.all[,c('DateGroup','UL')], by=c('DateGroup'))
pal.prod <- createPaletteOfVariableLength(bfdxProd.lims, 'Version')
p.product <- ggplot(bfdxProd.lims, aes(x=DateGroup, y=Rate, fill=Version)) + geom_bar(stat='identity') + geom_line(aes(y=UL), color='blue', lty=2, group=1) + scale_fill_manual(values=pal.prod) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + expand_limits(y=0) + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, hjust=1), axis.text=element_text(color='black',face=fontFace,size=fontSize), legend.position='bottom', legend.title=element_blank()) + labs(title='BFDx Product in Escalated Complaints/All Complaints:\nFYI Limit = + 3 standard deviations', x='Date\n(Year-Week)', y='Rolling 4-week Average Rate')

# Rate of Complaint Cause by Summary in Escalated Complaints per All Complaints
ccSummary.df <- unique(overview.df[,c('bug_id','Year','Week','RecordedValue','Record')])[,c('Year','Week','RecordedValue','Record')]
ccSummary.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', ccSummary.df, c('RecordedValue'), startDate, 'Record', 'sum', 0)
ccSummary.rate <- mergeCalSparseFrames(ccSummary.fill, complaints.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
ccSummary.df[,'statParam'] <- 'bfdx'
ccSummary.all <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', ccSummary.df, c('statParam'), startDate, 'Record', 'sum', 0)
ccSummary.all <- mergeCalSparseFrames(ccSummary.all, complaints.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
ccSummary.all <- addStatsToSparseHandledData(ccSummary.all, c('statParam'), lagPeriods, TRUE, 3, 'upper', 0, keepPeriods=53)
ccSummary.lims <- merge(ccSummary.rate, ccSummary.all[,c('DateGroup','UL')], by=c('DateGroup'))
pal.summary <- createPaletteOfVariableLength(ccSummary.lims, 'RecordedValue')
p.summary <- ggplot(ccSummary.lims, aes(x=DateGroup, y=Rate, fill=RecordedValue)) + geom_bar(stat='identity') + geom_line(aes(y=UL), color='blue', lty=2, group=1) + scale_fill_manual(values=pal.summary) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + expand_limits(y=0) + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, hjust=1), axis.text=element_text(color='black',face=fontFace,size=fontSize), legend.position='bottom', legend.title=element_blank()) + guides(fill=guide_legend(ncol=3, bycol=TRUE)) + labs(title='Cause of Complaint in Escalated Complaints/All Complaints:\nFYI Limit = + 3 standard deviations', x='Date\n(Year-Week)', y='Rolling 4-week Average Rate')

# Rate of Complaint Cause by Summary in Escalated Complaints per all BCID-related escalated complaints (i.e. denom = all CIs where the Version = BCID Panel)
# NOTE: IF DANA WANTS THE DENOM TO BE ALL COMPLAINTS (NOT JUST ESCALATED) THIS WILL BE HARDER TO DO, BUT WE CAN TRY- WOULD IT BE A COUNT OF COMPLAINTS OR THE QTY AFFECTED??
# BCID
bfdxBCID.df <- with(unique(overview.df[overview.df$Version=='BCID Panel', c('bug_id','Year','Week','Version','RecordedValue','Record')]), aggregate(Record~Year+Week+Version, FUN=sum))
bfdxBCID.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', bfdxBCID.df, c('Version'), plot.startDate.week, 'Record', 'sum', 0)
ccBCID.df <- unique(overview.df[overview.df$Version=='BCID Panel', c('bug_id','Year','Week','RecordedValue','Record')])[,c('Year','Week','RecordedValue','Record')]
ccBCID.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', ccBCID.df, c('RecordedValue'), plot.startDate.week, 'Record', 'sum', 0)
ccBCID.rate <- mergeCalSparseFrames(ccBCID.fill, bfdxBCID.fill, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, 0)
bfdxBCID.fill$yval <- 1
p.ccBCID <- ggplot(ccBCID.rate, aes(x=DateGroup, y=Rate, fill=RecordedValue)) + geom_bar(stat='identity') + scale_x_discrete(breaks=dateBreaks) + scale_fill_manual(values=createPaletteOfVariableLength(ccBCID.rate, 'RecordedValue'), name='') + scale_y_continuous(labels=percent) + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, hjust=1), axis.text=element_text(color='black',face=fontFace,size=fontSize), legend.position='bottom', legend.title=element_blank()) + labs(title='Cause of Complaint Ratio for BCID-Related CIs', subtitle = 'Number of Complaint Investigations Above', x='Date\n(Year-Week)', y='Ratio') + guides(fill=guide_legend(ncol=3, byrow=TRUE)) + geom_text(data=bfdxBCID.fill, aes(x=DateGroup, y=yval, label=Record), inherit.aes = FALSE, fontface='bold', size=5, vjust=-0.5)
# GI
bfdxGI.df <- with(unique(overview.df[overview.df$Version=='GI Panel', c('bug_id','Year','Week','Version','RecordedValue','Record')]), aggregate(Record~Year+Week+Version, FUN=sum))
bfdxGI.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', bfdxGI.df, c('Version'), plot.startDate.week, 'Record', 'sum', 0)
ccGI.df <- unique(overview.df[overview.df$Version=='GI Panel', c('bug_id','Year','Week','RecordedValue','Record')])[,c('Year','Week','RecordedValue','Record')]
ccGI.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', ccGI.df, c('RecordedValue'), plot.startDate.week, 'Record', 'sum', 0)
ccGI.rate <- mergeCalSparseFrames(ccGI.fill, bfdxGI.fill, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, 0)
bfdxGI.fill$yval <- 1
p.ccGI <- ggplot(ccGI.rate, aes(x=DateGroup, y=Rate, fill=RecordedValue)) + geom_bar(stat='identity') + scale_x_discrete(breaks=dateBreaks) + scale_fill_manual(values=createPaletteOfVariableLength(ccGI.rate, 'RecordedValue'), name='') + scale_y_continuous(labels=percent) + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, hjust=1), axis.text=element_text(color='black',face=fontFace,size=fontSize), legend.position='bottom', legend.title=element_blank()) + labs(title='Cause of Complaint Ratio for GI-Related CIs', subtitle = 'Number of Complaint Investigations Above', x='Date\n(Year-Week)', y='Ratio') + guides(fill=guide_legend(ncol=3, byrow=TRUE)) + geom_text(data=bfdxGI.fill, aes(x=DateGroup, y=yval, label=Record), inherit.aes = FALSE, fontface='bold', size=5, vjust=-0.5)
# ME
bfdxME.df <- with(unique(overview.df[overview.df$Version=='ME Panel', c('bug_id','Year','Week','Version','RecordedValue','Record')]), aggregate(Record~Year+Week+Version, FUN=sum))
bfdxME.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', bfdxME.df, c('Version'), plot.startDate.week, 'Record', 'sum', 0)
ccME.df <- unique(overview.df[overview.df$Version=='ME Panel', c('bug_id','Year','Week','RecordedValue','Record')])[,c('Year','Week','RecordedValue','Record')]
ccME.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', ccME.df, c('RecordedValue'), plot.startDate.week, 'Record', 'sum', 0)
ccME.rate <- mergeCalSparseFrames(ccME.fill, bfdxME.fill, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, 0)
bfdxME.fill$yval <- 1
p.ccME <- ggplot(ccME.rate, aes(x=DateGroup, y=Rate, fill=RecordedValue)) + geom_bar(stat='identity') + scale_x_discrete(breaks=dateBreaks) + scale_fill_manual(values=createPaletteOfVariableLength(ccME.rate, 'RecordedValue'), name='') + scale_y_continuous(labels=percent) + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, hjust=1), axis.text=element_text(color='black',face=fontFace,size=fontSize), legend.position='bottom', legend.title=element_blank()) + labs(title='Cause of Complaint Ratio for ME-Related CIs', subtitle = 'Number of Complaint Investigations Above', x='Date\n(Year-Week)', y='Ratio') + guides(fill=guide_legend(ncol=3, byrow=TRUE)) + geom_text(data=bfdxME.fill, aes(x=DateGroup, y=yval, label=Record), inherit.aes = FALSE, fontface='bold', size=5, vjust=-0.5)
# RP
bfdxRP.df <- with(unique(overview.df[overview.df$Version=='Respiratory Panel', c('bug_id','Year','Week','Version','RecordedValue','Record')]), aggregate(Record~Year+Week+Version, FUN=sum))
bfdxRP.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', bfdxRP.df, c('Version'), plot.startDate.week, 'Record', 'sum', 0)
ccRP.df <- unique(overview.df[overview.df$Version=='Respiratory Panel', c('bug_id','Year','Week','RecordedValue','Record')])[,c('Year','Week','RecordedValue','Record')]
ccRP.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', ccRP.df, c('RecordedValue'), plot.startDate.week, 'Record', 'sum', 0)
ccRP.rate <- mergeCalSparseFrames(ccRP.fill, bfdxRP.fill, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, 0)
bfdxRP.fill$yval <- 1
p.ccRP <- ggplot(ccRP.rate, aes(x=DateGroup, y=Rate, fill=RecordedValue)) + geom_bar(stat='identity') + scale_x_discrete(breaks=dateBreaks) + scale_fill_manual(values=createPaletteOfVariableLength(ccRP.rate, 'RecordedValue'), name='') + scale_y_continuous(labels=percent) + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, hjust=1), axis.text=element_text(color='black',face=fontFace,size=fontSize), legend.position='bottom', legend.title=element_blank()) + labs(title='Cause of Complaint Ratio for RP-Related CIs', subtitle = 'Number of Complaint Investigations Above', x='Date\n(Year-Week)', y='Ratio') + guides(fill=guide_legend(ncol=3, byrow=TRUE)) + geom_text(data=bfdxRP.fill, aes(x=DateGroup, y=yval, label=Record), inherit.aes = FALSE, fontface='bold', size=5, vjust=-0.5)

# Rate of Affected Assay in Escalated Complaints per All Complaints - requires that assays be partitioned into the proper panel
caAssay.df <- unique(overview.df[,c('bug_id','Year','Week','Key','Record')])[,c('Year','Week','Key','Record')]
caAssay.df[,'Key'] <- as.character(caAssay.df[,'Key'])
caAssay.df[,'nChars'] <- nchar(caAssay.df[,'Key'])
caAssay.df[grep('ME-',caAssay.df[,'Key']),'Version'] <- 'ME'; caAssay.df[grep('ME-',caAssay.df[,'Key']),'Key'] <- substr(caAssay.df[grep('ME-',caAssay.df[,'Key']),'Key'], 4, caAssay.df[grep('ME-',caAssay.df[,'Key']),'nChars'])
caAssay.df[grep('BCID-',caAssay.df[,'Key']),'Version'] <- 'BCID'; caAssay.df[grep('BCID-',caAssay.df[,'Key']),'Key'] <- substr(caAssay.df[grep('BCID-',caAssay.df[,'Key']),'Key'], 6, caAssay.df[grep('BCID-',caAssay.df[,'Key']),'nChars'])
caAssay.df[grep('RP-',caAssay.df[,'Key']),'Version'] <- 'RP'; caAssay.df[grep('RP-',caAssay.df[,'Key']),'Key'] <- substr(caAssay.df[grep('RP-',caAssay.df[,'Key']),'Key'], 4, caAssay.df[grep('RP-',caAssay.df[,'Key']),'nChars'])
caAssay.df[grep('GI-',caAssay.df[,'Key']),'Version'] <- 'GI'; caAssay.df[grep('GI-',caAssay.df[,'Key']),'Key'] <- substr(caAssay.df[grep('GI-',caAssay.df[,'Key']),'Key'], 4, caAssay.df[grep('GI-',caAssay.df[,'Key']),'nChars'])
caAssay.df <- caAssay.df[,c('Year', 'Week', 'Version','Key','Record')]
caAssay.df <- caAssay.df[!(is.na(caAssay.df[,'Version'])), ]
caAssay.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', caAssay.df, c('Version','Key'), startDate, 'Record', 'sum', 0)
caAssay.rate <- mergeCalSparseFrames(caAssay.fill, complaints.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
caAssay.allPanel <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', caAssay.df, c('Version'), startDate, 'Record', 'sum', 0)
caAssay.all <- mergeCalSparseFrames(caAssay.allPanel, complaints.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
caAssay.all <- addStatsToSparseHandledData(caAssay.all, c('Version'), lagPeriods, TRUE, 3, 'upper', 0, keepPeriods=53)
caAssay.lims <- merge(caAssay.rate, caAssay.all[,c('DateGroup','Version','UL')], by=c('DateGroup','Version'))
pal.bcid <- createPaletteOfVariableLength(subset(caAssay.lims, Version=='BCID'), 'Key')
p.assay.bcid <- ggplot(subset(caAssay.lims, Version=='BCID'), aes(x=DateGroup, y=Rate, fill=Key)) + geom_bar(stat='identity') + geom_line(aes(y=UL), color='blue', lty=2, data=subset(caAssay.lims, Version=='BCID'), group=1) + scale_fill_manual(values=pal.bcid) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + expand_limits(y=0) + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, hjust=1), axis.text=element_text(color='black',face=fontFace,size=fontSize), legend.position='bottom', legend.title=element_blank()) + labs(title='BCID - Affected Assay in Escalated Complaints/All Complaints:\nFYI Limit = + 3 standard deviations', x='Date\n(Year-Week)', y='Rolling 4-week Average Rate') + guides(fill=guide_legend(ncol=7, byrow=TRUE))
pal.gi <- createPaletteOfVariableLength(subset(caAssay.lims, Version=='GI'), 'Key')
p.assay.gi <- ggplot(subset(caAssay.lims, Version=='GI'), aes(x=DateGroup, y=Rate, fill=Key)) + geom_bar(stat='identity') + geom_line(aes(y=UL), color='blue', lty=2, data=subset(caAssay.lims, Version=='GI'), group=1) + scale_fill_manual(values=pal.gi) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + expand_limits(y=0) + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, hjust=1), axis.text=element_text(color='black',face=fontFace,size=fontSize), legend.position='bottom', legend.title=element_blank()) + labs(title='GI - Affected Assay in Escalated Complaints/All Complaints:\nFYI Limit = + 3 standard deviations', x='Date\n(Year-Week)', y='Rolling 4-week Average Rate') + guides(fill=guide_legend(ncol=7, byrow=TRUE))
pal.me <- createPaletteOfVariableLength(subset(caAssay.lims, Version=='ME'), 'Key')
p.assay.me <- ggplot(subset(caAssay.lims, Version=='ME'), aes(x=DateGroup, y=Rate, fill=Key)) + geom_bar(stat='identity') + geom_line(aes(y=UL), color='blue', lty=2, data=subset(caAssay.lims, Version=='ME'), group=1) + scale_fill_manual(values=pal.me) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + expand_limits(y=0) + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, hjust=1), axis.text=element_text(color='black',face=fontFace,size=fontSize), legend.position='bottom', legend.title=element_blank()) + labs(title='ME - Affected Assay in Escalated Complaints/All Complaints:\nFYI Limit = + 3 standard deviations', x='Date\n(Year-Week)', y='Rolling 4-week Average Rate') + guides(fill=guide_legend(ncol=7, byrow=TRUE))
pal.rp <- createPaletteOfVariableLength(subset(caAssay.lims, Version=='RP'), 'Key')
p.assay.rp <- ggplot(subset(caAssay.lims, Version=='RP'), aes(x=DateGroup, y=Rate, fill=Key)) + geom_bar(stat='identity') + geom_line(aes(y=UL), color='blue', lty=2, data=subset(caAssay.lims, Version=='RP'), group=1) + scale_fill_manual(values=pal.rp) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + expand_limits(y=0) + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, hjust=1), axis.text=element_text(color='black',face=fontFace,size=fontSize), legend.position='bottom', legend.title=element_blank()) + labs(title='RP - Affected Assay in Escalated Complaints/All Complaints:\nFYI Limit = + 3 standard deviations', x='Date\n(Year-Week)', y='Rolling 4-week Average Rate') + guides(fill=guide_legend(ncol=7, byrow=TRUE))

#top 10 affected assays per every 2 weeks for each panel
weeks <- sort(as.character(unique(caAssay.fill$DateGroup)), decreasing = TRUE)[seq(2, 12, 2)]
caAssay.weeks <- data.frame(Week = '2 Weeks', with(subset(caAssay.fill, DateGroup >= weeks[1]), aggregate(Record~Version+Key, FUN=sum)))
for(i in 2:length(weeks)) {
  temp <- data.frame(Week = paste(i*2, 'Weeks (net)'), with(subset(caAssay.fill, DateGroup >= weeks[i] & DateGroup < weeks[i-1]), aggregate(Record~Version+Key, FUN=sum)))
  caAssay.weeks <- rbind(caAssay.weeks, temp)
}
# find top 10 per panel for last 12 weeks
caAssay.weeksAgg <- with(caAssay.weeks, aggregate(Record~Version+Key, FUN=sum))
topRP <- as.character(subset(caAssay.weeksAgg, Version == 'RP')[order(subset(caAssay.weeksAgg, Version == 'RP')[,'Record'], decreasing = TRUE),'Key'])[1:10]
topBCID <- as.character(subset(caAssay.weeksAgg, Version == 'BCID')[order(subset(caAssay.weeksAgg, Version == 'BCID')[,'Record'], decreasing = TRUE),'Key'])[1:10]
topGI <- as.character(subset(caAssay.weeksAgg, Version == 'GI')[order(subset(caAssay.weeksAgg, Version == 'GI')[,'Record'], decreasing = TRUE),'Key'])[1:10]
topME <- as.character(subset(caAssay.weeksAgg, Version == 'ME')[order(subset(caAssay.weeksAgg, Version == 'ME')[,'Record'], decreasing = TRUE),'Key'])[1:10]
caAssay.RP <- subset(caAssay.weeks, Version == 'RP' & Key %in% topRP)
caAssay.RP$Key <- factor(caAssay.RP$Key, levels = topRP)
p.TopAssays.RP <- ggplot(caAssay.RP, aes(x=Key, y=Record, fill=Week)) + geom_bar(stat='identity', position='dodge') + scale_fill_manual(name = '', values = createPaletteOfVariableLength(caAssay.weeks, 'Week')) + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=45, hjust=1), axis.text=element_text(color='black',face=fontFace,size=fontSize)) + labs(title = 'Top 10 Affected Assays in Last 12 Weeks', subtitle = 'RP', x='Affected Assay', y='Count')
caAssay.BCID <- subset(caAssay.weeks, Version == 'BCID' & Key %in% topBCID)
caAssay.BCID$Key <- factor(caAssay.BCID$Key, levels = topBCID)
p.TopAssays.BCID <- ggplot(caAssay.BCID, aes(x=Key, y=Record, fill=Week)) + geom_bar(stat='identity', position='dodge') + scale_fill_manual(name = '', values = createPaletteOfVariableLength(caAssay.weeks, 'Week')) + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=45, hjust=1), axis.text=element_text(color='black',face=fontFace,size=fontSize)) + labs(title = 'Top 10 Affected Assays in Last 12 Weeks', subtitle = 'BCID', x='Affected Assay', y='Count')
caAssay.GI <- subset(caAssay.weeks, Version == 'GI' & Key %in% topGI)
caAssay.GI$Key <- factor(caAssay.GI$Key, levels = topGI)
p.TopAssays.GI <- ggplot(caAssay.GI, aes(x=Key, y=Record, fill=Week)) + geom_bar(stat='identity', position='dodge') + scale_fill_manual(name = '', values = createPaletteOfVariableLength(caAssay.weeks, 'Week')) + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=45, hjust=1), axis.text=element_text(color='black',face=fontFace,size=fontSize)) + labs(title = 'Top 10 Affected Assays in Last 12 Weeks', subtitle = 'GI', x='Affected Assay', y='Count')
caAssay.ME <- subset(caAssay.weeks, Version == 'ME' & Key %in% topME)
caAssay.ME$Key <- factor(caAssay.ME$Key, levels = topME)
p.TopAssays.ME <- ggplot(caAssay.ME, aes(x=Key, y=Record, fill=Week)) + geom_bar(stat='identity', position='dodge') + scale_fill_manual(name = '', values = createPaletteOfVariableLength(caAssay.weeks, 'Week')) + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=45, hjust=1), axis.text=element_text(color='black',face=fontFace,size=fontSize)) + labs(title = 'Top 10 Affected Assays in Last 12 Weeks', subtitle = 'ME', x='Affected Assay', y='Count')

# Rate of Specimen Types per All Complaints
specimens.df <- unique(observations.df[,c('bug_id','SerialNo','Year','Week','Version')])[,c('Year','Week','Version')]
specimens.df[,'Record'] <- 1
specimens.df <- specimens.df[specimens.df[,'Version']!='N/A', ]
specimens.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', specimens.df, c('Version'), startDate, 'Record', 'sum', 0)
specimens.rate <- mergeCalSparseFrames(specimens.fill, complaints.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
specimens.df[,'statParam'] <- 'bfdx'
specimens.all <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', specimens.df, c('statParam'), startDate, 'Record', 'sum', 0)
specimens.all <- mergeCalSparseFrames(specimens.all, complaints.all, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
specimens.all <- addStatsToSparseHandledData(specimens.all, c('statParam'), lagPeriods, TRUE, 3, 'upper', 0, keepPeriods=53)
specimens.lims <- merge(specimens.rate, specimens.all[,c('DateGroup','UL')], by=c('DateGroup'))
pal.specimens <- createPaletteOfVariableLength(specimens.lims, 'Version')
p.specimens <- ggplot(specimens.lims, aes(x=DateGroup, y=Rate, fill=Version)) + geom_bar(stat='identity') + geom_line(aes(y=UL), color='blue', lty=2, group=1) + scale_fill_manual(values=pal.specimens) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + expand_limits(y=0) + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, hjust=1), axis.text=element_text(color='black',face=fontFace,size=fontSize), legend.position='bottom', legend.title=element_blank()) + guides(fill=guide_legend(ncol=4, byrow=TRUE)) + labs(title='Specimen Types in Escalated Complaints/All Complaints:\nFYI Limit = +3 standard deviations', x='Date\n(Year-Week)', y='Rolling 4-week Average Rate')

# establish some properties to make a monthly bar chart
bigGroup <- 'Year'
smallGroup <- 'Month'
months <- 13
lagPeriods <- 0

# make a calendar that matches the weeks from SQL DATEPART function and find a start date such that charts show one year
startYear <- year(Sys.Date()) - 2
calendar.df <- createCalendarLikeMicrosoft(startYear, 'Month')
startDate <- findStartDate(calendar.df, 'Month', months, lagPeriods, keepPeriods=0)
# set theme for line charts ------------------------------------------------------------------------------------------------------------------
seqBreak <- 1
dateBreaks <- as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup']))[order(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup'])))][seq(periods,length(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup']))), seqBreak)]
# set theme for line charts ------------------------------------------------------------------------------------------------------------------

# Bar Chart for CI/All Complaints from Complaint Tracker
countCI.all <- aggregateAndFillDateGroupGaps(calendar.df, 'Month', countCI.df, c('Key'), startDate, 'Record', 'sum', 1)
countComplaint.all <- aggregateAndFillDateGroupGaps(calendar.df, 'Month', countComplaint.df, c('Key'), startDate, 'Record', 'sum', 0)
complaintCI.count <- rbind(countComplaint.all, countCI.all)
myPalCount <- createPaletteOfVariableLength(complaintCI.count, 'Key')
p.complaintCI <- ggplot(complaintCI.count, aes(x=DateGroup, y=Record, group=1, fill=Key)) + geom_bar(stat="identity") + scale_fill_manual(values=myPalCount, name='') + geom_text(aes(label=Record), vjust=1.5, color="white",position="stack", fontface="bold") + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Total Count of Complaints and CIs by Month', x='Date(Year-Month)', y='Count of Complaints and CIs')

# Pouches shipped for last 30 days and last 365 days
l30d <- subset(productShipped.df, Last30Days == 1)
l30d$Key <- 'Last 30 Days'
pouches.shipped <- rbind(subset(productShipped.df, select = c('Version', 'Key', 'Record')), subset(l30d, select = c('Version', 'Key', 'Record')))
pouches.shipped$Total <- 'Total'
l30d$Total <- l30d$Version
productShipped.df$Total <- productShipped.df$Version
pouches.total <- rbind(pouches.shipped, subset(productShipped.df, select = c('Version', 'Key', 'Total', 'Record')), subset(l30d, select = c('Version', 'Key', 'Total', 'Record')))
labels <- c()
versions <- as.character(unique(pouches.total$Total))
for(i in 1:length(versions)) {
  temp <- pouches.total[pouches.total[, 'Total'] == versions[i],]
  temp2 <- data.frame(Version = versions[i], Key = c('Last 365 Days', 'Last 30 Days'), Record = c(sum(temp[temp[,'Key'] == 'Last 365 Days', 'Record']), sum(temp[temp[,'Key'] == 'Last 30 Days', 'Record'])))
  labels <- rbind(labels, temp2)
}
p.PouchesShipped <- ggplot(pouches.total, aes(x=Total, y=Record, fill = Version)) + geom_bar(stat='identity') + facet_wrap(~Key, scales = 'free_y', ncol=1) + labs(title='Pouches Shipped', x='Panel', y='Pouches Shipped') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(color='black',face=fontFace,size=fontSize), legend.position='none') + scale_fill_manual(values=createPaletteOfVariableLength(pouches.shipped, 'Version')) + scale_y_continuous(label=comma) + geom_text(data = labels, inherit.aes = FALSE, aes(x=Version, y=Record, label=Record), vjust= -0.5, fontface='bold')

# export images for web hub
setwd(imgDir)
plots <- ls()[grep('^p\\.', ls())]
for(i in 1:length(plots)) {
  
  imgName <- paste(substring(plots[i],3),'.png',sep='')

  png(file=imgName, width=1200, height=800, units='px')
  print(eval(parse(text = plots[i])))
  makeTimeStamp(author='Data Science')
  dev.off()
}

# Make pdf report for the web hub
setwd(pdfDir)
pdf("ComplaintInvestigation.pdf", width = 11, height = 8)
for(i in 1:length(plots)) {
  
  print(eval(parse(text = plots[i])))
}
dev.off()

rm(list = ls())
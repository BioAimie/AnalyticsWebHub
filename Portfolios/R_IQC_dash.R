# set working directory
workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_InstrumentQC/'
pdfDir <- '~/WebHub/pdfs/'
setwd(workDir)

# load neccessary libraries
library(ggplot2)
library(grid)
library(scales)
library(zoo)
library(lubridate)
library(devtools)
install_github('BioAimie/dateManip')
library(dateManip)

# get the data needed
source('Portfolios/R_IQC_load.R')

# load user-created functions
source('Rfunctions/getBaselineFluorescence.R')
source('Rfunctions/getMaximumFluorescence.R')
source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/makeTimeStamp.R')

# establish some properties used throughout the code- these are kept up top to facilitate changes
bigGroup <- 'Year'
smallGroup <- 'Week'
periods <- 4
weeks <- 53
lagPeriods <- 4
# validateDate <- '2015-40'

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

# ------------------------------------------------ Make 4-Week Rolling Average Charts - Review Rates --------------------------------------------------
IQC.df[,'DateGroup'] <- with(IQC.df, ifelse(Week < 10, paste(Year, Week, sep='-0'), paste(Year, Week, sep='-')))
runs.all <- IQC.df[,c(bigGroup,smallGroup,'Key','Version','Record')]
runs.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', runs.all, c('Key','Version'), startDate, 'Record', 'sum', NA)

run.review.fill <- aggregateAndFillDateGroupGaps(calendar.df,'Week', subset(IQC.df, PouchResult %in% c('Review','Fail')), c('Key','Version'), startDate, 'Record', 'sum', 0)
run.review.rate <- mergeCalSparseFrames(run.review.fill, runs.fill, c('DateGroup','Version','Key'), c('DateGroup','Version','Key'), 'Record', 'Record', NA, periods)
run.review.lims <- addStatsToSparseHandledData(run.review.rate, c('Version','Key'), periods, TRUE, 3, 'upper')
p.run.review <- ggplot(subset(run.review.lims,Key != 'PouchQC'), aes(x=DateGroup, y=Rate, color=Color, group=1)) + geom_line(color='black') + geom_point() + facet_grid(Key~Version, scale='free_y') + scale_color_manual(values=c('blue','red'), guide=FALSE) + scale_y_continuous(labels=percent, limits=c(0,1)) + scale_x_discrete(breaks=dateBreaks) + geom_hline(aes(yintercept=UL), color='red', lty=2) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + labs(x='Date', y='4 Week Rolling Average', title='Pouch Review Rates:\nLimit = mean + 3sdev   (Torch limits not actionable)')

rna.review.fill <- aggregateAndFillDateGroupGaps(calendar.df,'Week', subset(IQC.df, RNA %in% c('Review','Fail')), c('Key','Version'), startDate, 'Record', 'sum', 0)
rna.review.rate <- mergeCalSparseFrames(rna.review.fill, runs.fill, c('DateGroup','Version','Key'), c('DateGroup','Version','Key'), 'Record', 'Record', NA, periods)
rna.review.lims <- addStatsToSparseHandledData(rna.review.rate, c('Version','Key'), periods, TRUE, 3, 'upper')
rna.review.lims <- rna.review.lims[!(rna.review.lims$Version=='FA1.5' & rna.review.lims$Key=='Production'), ]
x_positions <- c('2016-17')
annotations <- c('Evaluated for\nCAPA 13259')
y_positions <- 0.10
p.rna.review <- ggplot(subset(rna.review.lims,Key != 'PouchQC'), aes(x=DateGroup, y=Rate, color=Color, group=1)) + geom_line(color='black') + geom_point() + facet_grid(Key~Version, scale='free_y') + scale_color_manual(values=c('blue','red'), guide=FALSE) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + geom_hline(aes(yintercept=UL), color='red', lty=2) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + labs(x='Date', y='4 Week Rolling Average', title='Yeast Control Review Rates:\nLimit = mean + 3sdev   (Torch limits not actionable)') + annotate(geom='text', x=x_positions, y=y_positions, label=annotations)

mp.review.fill <- aggregateAndFillDateGroupGaps(calendar.df,'Week', IQC.df[IQC.df[,'60TmRange'] %in% c('Review','Fail'),], c('Key','Version'), startDate, 'Record', 'sum', 0)
mp.review.rate <- mergeCalSparseFrames(mp.review.fill, runs.fill, c('DateGroup','Version','Key'), c('DateGroup','Version','Key'), 'Record', 'Record', NA, periods)
mp.review.lims <- addStatsToSparseHandledData(mp.review.rate, c('Version','Key'), periods, TRUE, 3, 'upper')
p.mp.tm.review <- ggplot(subset(mp.review.lims,Key != 'PouchQC'), aes(x=DateGroup, y=Rate, color=Color, group=1)) + geom_line(color='black') + geom_point() + facet_grid(Key~Version, scale='free_y') + scale_color_manual(values=c('blue','red'), guide=FALSE) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + geom_hline(aes(yintercept=UL), color='red', lty=2) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + labs(x='Date', y='4 Week Rolling Average', title='60D Melt Probe Tm Range Review Rates:\nLimit = mean + 3sdev   (Torch limits not actionable)')
mp.review.fill <- aggregateAndFillDateGroupGaps(calendar.df,'Week', IQC.df[IQC.df[,'60DFMed'] %in% c('Review','Fail'),], c('Key','Version'), startDate, 'Record', 'sum', 0)
mp.review.rate <- mergeCalSparseFrames(mp.review.fill, runs.fill, c('DateGroup','Version','Key'), c('DateGroup','Version','Key'), 'Record', 'Record', NA, periods)
mp.review.lims <- addStatsToSparseHandledData(mp.review.rate, c('Version','Key'), periods, TRUE, 3, 'upper')
mp.review.lims <- mp.review.lims[!(mp.review.lims$Version=='FA1.5' & mp.review.lims$Key=='Production'), ]
y_positions <- 0.12
p.mp.df.review <- ggplot(subset(mp.review.lims,Key != 'PouchQC'), aes(x=DateGroup, y=Rate, color=Color, group=1)) + geom_line(color='black') + geom_point() + facet_grid(Key~Version) + scale_color_manual(values=c('blue','red'), guide=FALSE) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + geom_hline(aes(yintercept=UL), color='red', lty=2) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + labs(x='Date', y='4 Week Rolling Average', title='60D Melt Probe Median dF Review Rates:\nLimit = mean + 3sdev   (Torch limits not actionable)')

noise.review.fill <- aggregateAndFillDateGroupGaps(calendar.df,'Week', IQC.df[IQC.df[,'Noise'] %in% c('Review','Fail'),], c('Key','Version'), startDate, 'Record', 'sum', 0)
noise.review.rate <- mergeCalSparseFrames(noise.review.fill, runs.fill, c('DateGroup','Version','Key'), c('DateGroup','Version','Key'), 'Record', 'Record', NA, periods)
noise.review.lims <- addStatsToSparseHandledData(noise.review.rate, c('Version','Key'), periods, TRUE, 3, 'upper')
p.noise.review <- ggplot(subset(noise.review.lims,Key != 'PouchQC'), aes(x=DateGroup, y=Rate, color=Color, group=1)) + geom_line(color='black') + geom_point() + facet_grid(Key~Version, scale='free_y') + scale_color_manual(values=c('blue','red'), guide=FALSE) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + geom_hline(aes(yintercept=UL), color='red', lty=2) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + labs(x='Date', y='4 Week Rolling Average', title='Noise Review Rates:\nLimit = mean + 3sdev')

# ------------------------------------------------ Make 4-Week Rolling Average Charts - Moving Average --------------------------------------------------
rna.Cp.denom <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', IQC.df[!(is.na(IQC.df[,'Cp_RNA'])), ], c('Key','Version'), startDate, 'Record', 'sum', NA)
rna.Cp <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', IQC.df, c('Key','Version'), startDate, 'Cp_RNA', 'sum', NA)
rna.Cp.rate <- mergeCalSparseFrames(rna.Cp, rna.Cp.denom, c('DateGroup','Version','Key'), c('DateGroup','Version','Key'), 'Cp_RNA', 'Record', NA, periods)
rna.Cp.lims <- addStatsToSparseHandledData(rna.Cp.rate, c('Version','Key'), periods, TRUE, 3, 'two.sided', 1, 100)
rna.Tm.denom <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', IQC.df[!(is.na(IQC.df[,'Tm_RNA'])), ], c('Key','Version'), startDate, 'Record', 'sum', NA)
rna.Tm <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', IQC.df, c('Key','Version'), startDate, 'Tm_RNA', 'sum', NA)
rna.Tm.rate <- mergeCalSparseFrames(rna.Tm, rna.Tm.denom, c('DateGroup','Version','Key'), c('DateGroup','Version','Key'), 'Tm_RNA', 'Record', NA, periods)
rna.Tm.lims <- addStatsToSparseHandledData(rna.Tm.rate, c('Version','Key'), periods, TRUE, 4, 'two.sided', 1, 100)
rna.Tm.lims <- rna.Tm.lims[!(rna.Tm.lims$Version=='FA1.5' & rna.Tm.lims$Key=='Production'), ]
rna.Cp.lims <- rna.Cp.lims[!(rna.Cp.lims$Version=='FA1.5' & rna.Cp.lims$Key=='Production'), ]
p.rna.Cp <- ggplot(subset(IQC.df, Key != 'PouchQC' & DateGroup >= startDate), aes(x=DateGroup, y=Cp_RNA)) + geom_point(color='lightskyblue', size=1) + geom_line(aes(x=DateGroup, y=Rate, group=1), data=subset(rna.Cp.lims,Key != 'PouchQC'), color='black') + geom_point(aes(x=DateGroup, y=Rate, color=Color), data=subset(rna.Cp.lims,Key != 'PouchQC')) + facet_grid(Key~Version) + scale_color_manual(values = c('blue','red'), guide=FALSE) + scale_x_discrete(breaks = dateBreaks) + geom_hline(aes(yintercept=UL), data=subset(rna.Cp.lims,Key != 'PouchQC'), color='red', lty=2) + geom_hline(aes(yintercept=LL), data=subset(rna.Cp.lims,Key != 'PouchQC'), color='red', lty=2) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + ylim(c(12.0,25.0)) + labs(x='Date', y='4 Week Rolling Average', title='Yeast Control Cp:\nLimit = mean +/- 3sdev   (Torch limits not actionable)')
p.rna.Tm <- ggplot(subset(IQC.df, Key != 'PouchQC' & DateGroup >= startDate), aes(x=DateGroup, y=Tm_RNA)) + geom_point(color='lightskyblue', size=1) + geom_line(aes(x=DateGroup, y=Rate, group=1), data=subset(rna.Tm.lims,Key != 'PouchQC'), color='black') + geom_point(aes(x=DateGroup, y=Rate, color=Color), data=subset(rna.Tm.lims,Key != 'PouchQC')) + facet_grid(Key~Version) + scale_color_manual(values = c('blue','red'), guide=FALSE) + scale_x_discrete(breaks = dateBreaks) + geom_hline(aes(yintercept=UL), data=subset(rna.Tm.lims,Key != 'PouchQC'), color='red', lty=2) + geom_hline(aes(yintercept=LL), data=subset(rna.Tm.lims,Key != 'PouchQC'), color='red', lty=2) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + ylim(c(77.3,82.3)) + labs(x='Date', y='4 Week Rolling Average', title='Yeast Control Tm:\nLimit = mean +/- 4sdev   (Torch limits not actionable)')

mp.dT.denom <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', IQC.df[!(is.na(IQC.df[,'TmRange_60'])), ], c('Key','Version'), startDate, 'Record', 'sum', NA)
mp.dT <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', IQC.df, c('Key','Version'), startDate, 'TmRange_60', 'sum', NA)
mp.dT.rate <- mergeCalSparseFrames(mp.dT, mp.dT.denom, c('DateGroup','Version','Key'), c('DateGroup','Version','Key'), 'TmRange_60', 'Record', NA, periods)
mp.dT.lims <- addStatsToSparseHandledData(mp.dT.rate, c('Version','Key'), periods, TRUE, 3, 'two.sided', 0, 100)
mp.dF.denom <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', IQC.df[!(is.na(IQC.df[,'medianDeltaRFU_60'])), ], c('Key','Version'), startDate, 'Record', 'sum', NA)
mp.dF <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', IQC.df, c('Key','Version'), startDate, 'medianDeltaRFU_60', 'sum', NA)
mp.dF.rate <- mergeCalSparseFrames(mp.dF, mp.dF.denom, c('DateGroup','Version','Key'), c('DateGroup','Version','Key'), 'medianDeltaRFU_60', 'Record', NA, periods)
mp.dF.lims <- addStatsToSparseHandledData(mp.dF.rate, c('Version','Key'), periods, TRUE, 3, 'two.sided', 0, 100)
mp.dT.lims <- mp.dT.lims[!(mp.dT.lims$Version=='FA1.5' & mp.dT.lims$Key=='Production'), ]
mp.dF.lims <- mp.dF.lims[!(mp.dF.lims$Version=='FA1.5' & mp.dF.lims$Key=='Production'), ]
p.mp.dT <- ggplot(subset(IQC.df, Key != 'PouchQC' & DateGroup >= startDate), aes(x=DateGroup, y=TmRange_60)) + geom_point(color='lightskyblue', size=1) + geom_line(aes(x=DateGroup, y=Rate, group=1), data=subset(mp.dT.lims,Key != 'PouchQC'), color='black') + geom_point(aes(x=DateGroup, y=Rate, color=Color), data=subset(mp.dT.lims,Key != 'PouchQC')) + facet_grid(Key~Version) + scale_color_manual(values = c('blue','red'), guide=FALSE) + scale_x_discrete(breaks = dateBreaks) + geom_hline(aes(yintercept=UL), data=subset(mp.dT.lims,Key != 'PouchQC'), color='red', lty=2) + geom_hline(aes(yintercept=LL), data=subset(mp.dT.lims,Key != 'PouchQC'), color='red', lty=2) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + ylim(c(0,1)) + labs(x='Date', y='4 Week Rolling Average', title='60D Melt Probe Tm Range:\nLimit = mean +/- 3sdev   (Torch limits not actionable)')
p.mp.dF <- ggplot(subset(IQC.df, Key != 'PouchQC' & DateGroup >= startDate), aes(x=DateGroup, y=medianDeltaRFU_60)) + geom_point(color='lightskyblue', size=1) + geom_line(aes(x=DateGroup, y=Rate, group=1), data=subset(mp.dF.lims,Key != 'PouchQC'), color='black') + geom_point(aes(x=DateGroup, y=Rate, color=Color), data=subset(mp.dF.lims,Key != 'PouchQC')) + facet_grid(Key~Version) + scale_color_manual(values = c('blue','red'), guide=FALSE) + scale_x_discrete(breaks = dateBreaks) + geom_hline(aes(yintercept=UL), data=subset(mp.dF.lims,Key != 'PouchQC'), color='red', lty=2) + geom_hline(aes(yintercept=LL), data=subset(mp.dF.lims,Key != 'PouchQC'), color='red', lty=2) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + ylim(c(0,27.5)) + labs(x='Date', y='4 Week Rolling Average', title='60D Melt Probe Median dF:\nLimit = mean +/- 3sdev   (Torch limits not actionable)') + annotate("text",x=x_positions,y=20,label=annotations, size=3)

noise.denom <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', IQC.df[!(is.na(IQC.df[,'Noise_med'])), ], c('Key','Version'), startDate, 'Record', 'sum', NA)
noise <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', IQC.df, c('Key','Version'), startDate, 'Noise_med', 'sum', NA)
noise.rate <- mergeCalSparseFrames(noise, noise.denom, c('DateGroup','Version','Key'), c('DateGroup','Version','Key'), 'Noise_med', 'Record', NA, periods)
noise.lims <- addStatsToSparseHandledData(noise.rate, c('Version','Key'), periods, TRUE, 3, 'two.sided', 0, 100)
noise.lims <- noise.lims[!(noise.lims$Version=='FA1.5' & noise.lims$Key=='Production'), ]
p.noise <- ggplot(subset(IQC.df, Key != 'PouchQC' & DateGroup >= startDate), aes(x=DateGroup, y=Noise_med)) + geom_point(color='lightskyblue', size=1) + geom_line(aes(x=DateGroup, y=Rate, group=1), data=subset(noise.lims,Key != 'PouchQC'), color='black') + geom_point(aes(x=DateGroup, y=Rate, color=Color), data=subset(noise.lims,Key != 'PouchQC')) + facet_grid(Key~Version) + scale_color_manual(values = c('blue','red'), guide=FALSE) + scale_x_discrete(breaks = dateBreaks) + geom_hline(aes(yintercept=UL), data=subset(noise.lims,Key != 'PouchQC'), color='red', lty=2) + geom_hline(aes(yintercept=LL), data=subset(noise.lims,Key != 'PouchQC'), color='red', lty=2) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + ylim(c(0,0.1)) + labs(x='Date', y='4 Week Rolling Average', title='Noise dF/dT:\nLimit = mean +/- 3sdev   (Torch limits not actionable)')

# ---------------------------------------------- Make Charts by Pouch Lot - Tm, Cp, DF, etc. ------------------------------------------------
# remove any lots that exist in service or production but have no QC data... I don't know why this happens, but sometimes it does
keepLots <- as.character(unique(IQC.df[IQC.df[,'Key'] == 'PouchQC','LotNo']))
# yeast Cp
frame.lot <- IQC.df[IQC.df[,'LotNo'] %in% keepLots,c('LotNo','Version','Key','Cp_RNA')]; colnames(frame.lot) <- c('PouchLot','Version','Key','Record')
lots <- unique(frame.lot$PouchLot)[order(unique(frame.lot$PouchLot))]
lots <- lots[(length(lots)-12):length(lots)]
frame.lot <- frame.lot[frame.lot$PouchLot %in% lots, ]
frame.lot <- merge(merge(frame.lot, with(frame.lot, aggregate(Record~Version+Key, FUN=mean)) , by=c('Version','Key')), with(frame.lot, aggregate(Record~Version+Key, FUN=sd)) , by=c('Version','Key'))
colnames(frame.lot) <- c('Version','Key','PouchLot','Record','average','sdev')
p.RNA_Cp_lot <- ggplot(frame.lot, aes(x=as.factor(PouchLot), y=Record, color=Key)) + geom_point() + scale_color_manual(values=c('dodgerblue','darkgreen','purple'), name='') + geom_line(aes(x=as.factor(PouchLot), y=average, group=Version), color='black') + geom_line(aes(x=as.factor(PouchLot), y=average+3*sdev, group=Version), color='black', lty=2) + geom_line(aes(x=as.factor(PouchLot), y=average-3*sdev, group=Version), color='black', lty=2) + facet_grid(Version~Key) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + labs(x='Pouch Lot', y='Yeast Control Cp', title='Yeast Control Cp by Lot:\nLimit = mean +/- 3sdev')
# yeast Tm
frame.lot <- IQC.df[IQC.df[,'LotNo'] %in% keepLots,c('LotNo','Version','Key','Tm_RNA')]; colnames(frame.lot) <- c('PouchLot','Version','Key','Record')
frame.lot <- frame.lot[frame.lot$PouchLot %in% lots, ]
frame.lot <- merge(merge(frame.lot, with(frame.lot, aggregate(Record~Version+Key, FUN=mean)) , by=c('Version','Key')), with(frame.lot, aggregate(Record~Version+Key, FUN=sd)) , by=c('Version','Key'))
colnames(frame.lot) <- c('Version','Key','PouchLot','Record','average','sdev')
p.RNA_Tm_lot <- ggplot(frame.lot, aes(x=as.factor(PouchLot), y=Record, color=Key)) + geom_point() + scale_color_manual(values=c('dodgerblue','darkgreen','purple'), name='') + geom_line(aes(x=as.factor(PouchLot), y=average, group=Version), color='black') + geom_line(aes(x=as.factor(PouchLot), y=average+3*sdev, group=Version), color='black', lty=2) + geom_line(aes(x=as.factor(PouchLot), y=average-3*sdev, group=Version), color='black', lty=2) + facet_grid(Version~Key) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + ylim(c(77.3,82.3)) + labs(x='Pouch Lot', y='Yeast Control Tm', title='Yeast Control Tm by Lot:\nLimit = mean +/- 3sdev')
# 60MP Tm Range
frame.lot <- IQC.df[IQC.df[,'LotNo'] %in% keepLots,c('LotNo','Version','Key','TmRange_60')]; colnames(frame.lot) <- c('PouchLot','Version','Key','Record')
frame.lot <- frame.lot[frame.lot$PouchLot %in% lots, ]
frame.lot <- merge(merge(frame.lot, with(frame.lot, aggregate(Record~Version+Key, FUN=mean)) , by=c('Version','Key')), with(frame.lot, aggregate(Record~Version+Key, FUN=sd)) , by=c('Version','Key'))
colnames(frame.lot) <- c('Version','Key','PouchLot','Record','average','sdev')
p.MP_Tm_lot <- ggplot(frame.lot, aes(x=as.factor(PouchLot), y=Record, color=Key)) + geom_point() + scale_color_manual(values=c('dodgerblue','darkgreen','purple'), name='') + geom_line(aes(x=as.factor(PouchLot), y=average, group=Version), color='black') + geom_line(aes(x=as.factor(PouchLot), y=average+3*sdev, group=Version), color='black', lty=2) + geom_line(aes(x=as.factor(PouchLot), y=average-3*sdev, group=Version), color='black', lty=2) + facet_grid(Version~Key) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + ylim(c(0,1)) + labs(x='Pouch Lot', y='60D Melt Probe Tm Range', title='60D Melt Probe Tm Range by Lot:\nLimit = mean +/- 3sdev')
# 60MP Delta F Median
frame.lot <- IQC.df[IQC.df[,'LotNo'] %in% keepLots,c('LotNo','Version','Key','medianDeltaRFU_60')]; colnames(frame.lot) <- c('PouchLot','Version','Key','Record')
frame.lot <- frame.lot[frame.lot$PouchLot %in% lots, ]
frame.lot <- merge(merge(frame.lot, with(frame.lot, aggregate(Record~Version+Key, FUN=mean)) , by=c('Version','Key')), with(frame.lot, aggregate(Record~Version+Key, FUN=sd)) , by=c('Version','Key'))
colnames(frame.lot) <- c('Version','Key','PouchLot','Record','average','sdev')
p.MP_DF_lot <- ggplot(frame.lot, aes(x=as.factor(PouchLot), y=Record, color=Key)) + geom_point() + scale_color_manual(values=c('dodgerblue','darkgreen','purple'), name='') + geom_line(aes(x=as.factor(PouchLot), y=average, group=Version), color='black') + geom_line(aes(x=as.factor(PouchLot), y=average+3*sdev, group=Version), color='black', lty=2) + geom_line(aes(x=as.factor(PouchLot), y=average-3*sdev, group=Version), color='black', lty=2) + facet_grid(Version~Key) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + ylim(c(0,27.5)) + geom_hline(aes(yintercept=7), color='blue') + labs(x='Pouch Lot', y='60D Melt Probe Median Delta F', title='60D Melt Probe Median Delta F by Lot:\nLimit = mean +/- 3sdev')
# Noise
frame.lot <- IQC.df[IQC.df[,'LotNo'] %in% keepLots,c('LotNo','Version','Key','Noise_med')]; colnames(frame.lot) <- c('PouchLot','Version','Key','Record')
frame.lot <- frame.lot[frame.lot$PouchLot %in% lots, ]
frame.lot <- merge(merge(frame.lot, with(frame.lot, aggregate(Record~Version+Key, FUN=mean)) , by=c('Version','Key')), with(frame.lot, aggregate(Record~Version+Key, FUN=sd)) , by=c('Version','Key'))
colnames(frame.lot) <- c('Version','Key','PouchLot','Record','average','sdev')
p.Noise_lot <- ggplot(frame.lot, aes(x=as.factor(PouchLot), y=Record, color=Key)) + geom_point() + scale_color_manual(values=c('dodgerblue','darkgreen','purple'), name='') + geom_line(aes(x=as.factor(PouchLot), y=average, group=Version), color='black') + geom_line(aes(x=as.factor(PouchLot), y=average+3*sdev, group=Version), color='black', lty=2) + geom_line(aes(x=as.factor(PouchLot), y=average-3*sdev, group=Version), color='black', lty=2) + facet_grid(Version~Key) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + ylim(c(0,0.1)) + labs(x='Pouch Lot', y='Median Noise (-dF/dT)', title='Median Noise (-dF/dT) by Lot:\nLimit = mean +/- 3sdev')

# --------------------------- ADDED: Fluorescence Monitoring --------------------------------
# use some sapply magic in conjunction with the user defined functions to get the average fluorescence of Yeast (max in melt) and empties (baseline in pcr2) 
allRows <- length(fluor.df[,1])
baseline <- sapply(1:allRows, function(x) getBaselineFluorescence(x))
signal <- sapply(1:allRows, function(x) getMaximumFluorescence(x))
sd.baseline <- sapply(1:allRows, function(x) sd(strsplit(as.character(fluor.df[x,'BaselineFluorArray']),',')[[1]]))
# make a new data frame that has the useful information that we want to monitor for trending
baseCols <- colnames(fluor.df)[!(colnames(fluor.df) %in% colnames(fluor.df)[grep('Fluor',colnames(fluor.df))])]
fluor.processed <- cbind(fluor.df[,baseCols], baseline, signal, sd.baseline)
# break fluor.processed into two frames
baseline.fluor <- fluor.processed[,c(bigGroup, smallGroup, 'Department', 'InstVersion','baseline')]; colnames(baseline.fluor) <- c(bigGroup, smallGroup, 'Key','Version','Record')
max.fluor <- fluor.processed[,c(bigGroup, smallGroup, 'Department', 'InstVersion','signal')]; colnames(max.fluor) <- c(bigGroup, smallGroup, 'Key','Version','Record')
spread.fluor <- fluor.processed[,c(bigGroup, smallGroup, 'Department', 'InstVersion','sd.baseline')]; colnames(spread.fluor) <- c(bigGroup, smallGroup, 'Key','Version','Record')
fluor.all <- fluor.processed[,c(bigGroup, smallGroup, 'Department','InstVersion')]; colnames(fluor.all) <- c(bigGroup, smallGroup, 'Key','Version')
fluor.all$Record <- 1 
# find the rates
fluor.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', fluor.all, c('Version','Key'), startDate, 'Record', 'sum', NA)
baseline.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', baseline.fluor, c('Version','Key'), startDate, 'Record', 'sum', NA)
max.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', max.fluor, c('Version','Key'), startDate, 'Record', 'sum', NA)
spread.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', spread.fluor, c('Version','Key'), startDate, 'Record', 'sum', NA)
baseline.rate <- mergeCalSparseFrames(baseline.fill, fluor.fill, c('DateGroup','Version','Key'), c('DateGroup','Version','Key'), 'Record', 'Record', NA, periods)
max.rate <- mergeCalSparseFrames(max.fill, fluor.fill, c('DateGroup','Version','Key'), c('DateGroup','Version','Key'), 'Record', 'Record', NA, periods)
spread.rate <- mergeCalSparseFrames(spread.fill, fluor.fill, c('DateGroup','Version','Key'), c('DateGroup','Version','Key'), 'Record', 'Record', NA, periods)
baseline.lims <- addStatsToSparseHandledData(baseline.rate, c('Version','Key'), periods, TRUE, 3, 'two.sided', 0, 500)
max.lims <- addStatsToSparseHandledData(max.rate, c('Version','Key'), periods, TRUE, 3, 'two.sided', 0, 500)
spread.lims <- addStatsToSparseHandledData(spread.rate, c('Version','Key'), periods, TRUE, 3, 'two.sided', 0, 500)
# make the charts
baseline.fluor[,'DateGroup'] <- with(baseline.fluor, ifelse(Week < 10, paste(Year, Week, sep='-0'), paste(Year, Week, sep='-')))
max.fluor[,'DateGroup'] <- with(max.fluor, ifelse(Week < 10, paste(Year, Week, sep='-0'), paste(Year, Week, sep='-')))
spread.fluor[,'DateGroup'] <- with(spread.fluor, ifelse(Week < 10, paste(Year, Week, sep='-0'), paste(Year, Week, sep='-')))
p.baseline <- ggplot(subset(baseline.fluor,Key!='PouchQC'), aes(x=DateGroup, y=Record)) + geom_point(color='lightskyblue') + geom_line(aes(x=DateGroup, y=Rate, group=Version), data=subset(baseline.lims,Key!='PouchQC')) + geom_point(aes(x=DateGroup, y=Rate, color=Color), data=subset(baseline.lims,Key!='PouchQC')) + facet_grid(Key~Version) + scale_color_manual(values=c('blue','blue','black'), guide=FALSE) + geom_hline(aes(yintercept=UL), data=subset(baseline.lims,Key!='PouchQC'), color='black', lty=2) + geom_hline(aes(yintercept=LL), data=subset(baseline.lims,Key!='PouchQC'), color='black', lty=2) + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + labs(x='Date',y='4 Week Rolling Average',title='Average Minimum Fluorescence (Empty Wells) - PCR')
p.signal <- ggplot(subset(max.fluor,Key!='PouchQC'), aes(x=DateGroup, y=Record)) + geom_point(color='lightskyblue') + geom_line(aes(x=DateGroup, y=Rate, group=Version), data=subset(max.lims,Key!='PouchQC')) + geom_point(aes(x=DateGroup, y=Rate, color=Color), data=subset(max.lims,Key!='PouchQC')) + facet_grid(Key~Version) + scale_color_manual(values=c('blue','blue','black'), guide=FALSE) + geom_hline(aes(yintercept=UL), data=subset(max.lims,Key!='PouchQC'), color='black', lty=2) + geom_hline(aes(yintercept=LL), data=subset(max.lims,Key!='PouchQC'), color='black', lty=2) + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + labs(x='Date',y='4 Week Rolling Average',title='Average Maximum Fluorescence (Yeast Wells) - Melt')
#fixed scale due to outliers in weeks 2016-13, 2016-14, & 2016-15, removed outliers from graph
remove.dategroup <- c('2016-13','2016-14','2016-15')
removed.points <- subset(spread.fluor,Key!='PouchQC' & (DateGroup %in% remove.dategroup & Record > 47))
removed.points$Record <- 19
p.spread <- ggplot(subset(spread.fluor,Key!='PouchQC' & !(DateGroup %in% remove.dategroup & Record > 47)), aes(x=DateGroup, y=Record)) + geom_point(color='lightskyblue') + geom_line(aes(x=DateGroup, y=Rate, group=Version), data=subset(spread.lims,Key!='PouchQC')) + geom_point(aes(x=DateGroup, y=Rate, color=Color), data=subset(spread.lims,Key!='PouchQC')) + geom_point(data=removed.points, aes(x=DateGroup, y=Record), shape=4) + facet_grid(Key~Version, scales='free_y') + scale_color_manual(values=c('blue','blue','black'), guide=FALSE) + geom_hline(aes(yintercept=UL), data=subset(spread.lims,Key!='PouchQC'), color='black', lty=2) + geom_hline(aes(yintercept=LL), data=subset(spread.lims,Key!='PouchQC'), color='black', lty=2) + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + labs(x='Date',y='4 Week Rolling Average',title='Standard Deviation of Baseline Fluorescence in all Array Wells\nx indicates data points not visible')

 # -------------------------- ADDED: INSTRUMENT ERROR RATES BY TYPE -----------------------------
errors.num <- errors.df[errors.df[,'RunError'] == 1, ]
errors.denom <- errors.df; errors.denom[,'RunError'] <- 1
errors.num <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', errors.num, c('Version','Key','RecordedValue'), startDate, 'RunError', 'sum', 0)
errors.denom <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', errors.denom, c('Version','Key'), startDate, 'RunError', 'sum', 1)
errors.rate <- mergeCalSparseFrames(errors.num, errors.denom, c('DateGroup','Version','Key'), c('DateGroup','Version','Key'), 'RunError','RunError', 0)
errors.all.num <- with(errors.num, aggregate(RunError~DateGroup+Key, FUN=sum))
errors.all.denom <- with(errors.denom, aggregate(RunError~DateGroup+Key, FUN=sum))
errors.all.rate <- mergeCalSparseFrames(errors.all.num, errors.all.denom, c('DateGroup','Key'), c('DateGroup','Key'), 'RunError', 'RunError', 0, 4)
colnames(errors.all.rate)[colnames(errors.all.rate) == 'Rate'] <- 'OverallRate'
myPal <- createPaletteOfVariableLength(errors.rate, 'RecordedValue')
errors.fix.x <- errors.rate[errors.rate$Rate > 0.1, 'DateGroup']
errors.fix.y <- errors.rate[errors.rate$Rate > 0.1, 'Rate']
errors.rate[errors.rate$Rate > 0.1, 'Rate'] <- NA
errors.rate[is.na(errors.rate$Rate), 'Annotation'] <- paste(round(100*errors.fix.y,0), '%', sep='')
errors.rate[is.na(errors.rate$Annotation), 'Annotation'] <- ''
p.errormessages <- ggplot(errors.rate, aes(x=DateGroup, y=Rate, fill=RecordedValue, label=Annotation)) + geom_bar(stat='identity', aes(label=Annotation), data=errors.rate) + geom_line(data=errors.all.rate, inherit.aes=FALSE, aes(x=DateGroup, y=OverallRate, group = 1)) + geom_point(data=errors.all.rate, inherit.aes=FALSE, aes(x=DateGroup, y=OverallRate)) + geom_text() + facet_grid(Key~Version, scales='free_y') + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace), legend.position='bottom') + scale_y_continuous(label=percent) + labs(x='Date', y='Errors/Number of Runs', title='Instrument Error Rate in Final QC by Type') + scale_fill_manual(values = myPal, name='') + guides(fill=guide_legend(nrow=3, byrow=TRUE)) + geom_text(aes(x=DateGroup, y=0.1, label=Annotation), data=errors.rate)
p.errormessages.count <- ggplot(errors.num, aes(x=DateGroup, y=RunError, fill=RecordedValue)) + geom_bar(stat='identity') + facet_grid(Key~Version, scales='free_y') + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace), legend.position='bottom') + labs(x='Date', y='Errors', title='Instrument Error Count in Final QC by Type') + scale_fill_manual(values = myPal, name='') + guides(fill=guide_legend(nrow=3, byrow=TRUE))

# add a first-pass yield chart
firstPass.runs <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(firstPass.df, TestNo==1), 'Key', startDate, 'Record', 'sum', 0)
firstPass.pass <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(firstPass.df, TestNo==1 & Result=='Pass'), 'Key', startDate, 'Record', 'sum', 0)
firstPass.rate <- mergeCalSparseFrames(firstPass.pass, firstPass.runs, c('DateGroup','Key'), c('DateGroup','Key'), 'Record', 'Record', NA, 4)
p.production.firstpass <- ggplot(subset(firstPass.rate, Key == 'Production'), aes(x=DateGroup, y=Rate, group=Key)) + geom_line() + geom_point() + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + labs(x='Date\n(Year-Week)', y='First Pass Yield (4-week moving average)', title='Instrument First Pass Yield in Final QC', subtitle = 'Production') + geom_hline(aes(yintercept=0.9), color='mediumseagreen', lty='dashed') + scale_y_continuous(labels=percent) + expand_limits(y=0.5)
p.service.firstpass <- ggplot(subset(firstPass.rate, Key == 'Service'), aes(x=DateGroup, y=Rate, group=Key)) + geom_line() + geom_point() + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + labs(x='Date\n(Year-Week)', y='First Pass Yield (4-week moving average)', title='Instrument First Pass Yield in Final QC', subtitle = 'Service') + geom_hline(aes(yintercept=0.9), color='mediumseagreen', lty='dashed') + scale_y_continuous(labels=percent) + expand_limits(y=0.5)
firstPass.fail <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(firstPass.df, Result!='Pass'), c('Key','Result'), startDate, 'Record', 'sum', 0)
firstPass.fail.rate <- mergeCalSparseFrames(firstPass.fail, firstPass.runs, c('DateGroup','Key'), c('DateGroup','Key'), 'Record', 'Record', NA, 0)
p.first.fail <- ggplot(firstPass.fail.rate, aes(x=DateGroup, y=Rate, group=Key, fill=Result)) + geom_bar(stat='identity') + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace), legend.position='bottom') + labs(x='Date\n(Year-Week)', y='First Pass Failure Rate', title='First Pass Failures in Final QC by Type') + facet_wrap(~Key, ncol=1)+ scale_y_continuous(labels=percent) + scale_fill_manual(values=createPaletteOfVariableLength(firstPass.fail.rate, 'Result'), name='') + guides(fill=guide_legend(ncol=3, bycol=TRUE))
# secondPass.runs <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(firstPass.df, TestNo==2), 'Key', startDate, 'Record', 'sum', 0)
# secondPass.pass <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(firstPass.df, TestNo==2 & Result=='Pass'), 'Key', startDate, 'Record', 'sum', 0)
# secondPass.rate <- mergeCalSparseFrames(secondPass.pass, secondPass.runs, c('DateGroup','Key'), c('DateGroup','Key'), 'Record', 'Record', NA, 4)
# thirdPass.runs <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(firstPass.df, TestNo==3), 'Key', startDate, 'Record', 'sum', 0)
# thirdPass.pass <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(firstPass.df, TestNo==3 & Result=='Pass'), 'Key', startDate, 'Record', 'sum', 0)
# thirdPass.rate <- mergeCalSparseFrames(thirdPass.pass, thirdPass.runs, c('DateGroup','Key'), c('DateGroup','Key'), 'Record', 'Record', NA, 4)
# pass.yeilds <- rbind(data.frame(firstPass.rate, Round = 'First'), data.frame(secondPass.rate, Round = 'Second'), data.frame(thirdPass.rate, Round = 'Third'))
# p.production.yeilds <- ggplot(subset(pass.yeilds, Key=='Production'), aes(x=DateGroup, y=Rate, group=Round, color=Round)) + geom_line() + geom_point() + scale_y_continuous(label=percent, limits=c(0, 1)) + scale_color_manual(values=c('black','grey47','grey62'), name='Test') + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + labs(x='Date\n(Year-Week)', y='First Pass Yield (4-week moving average)', title='Instrument Pass Yield in Production Final QC') + geom_hline(aes(yintercept=0.9), color='mediumseagreen', lty='dashed')
# p.service.yeilds <- ggplot(subset(pass.yeilds, Key=='Service'), aes(x=DateGroup, y=Rate, group=Round, color=Round)) + geom_line() + geom_point() + scale_y_continuous(label=percent, limits=c(0, 1)) + scale_color_manual(values=c('black','grey47','grey62'), name='Test') + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + labs(x='Date\n(Year-Week)', y='First Pass Yield (4-week moving average)', title='Instrument Pass Yield in Service Final QC') + geom_hline(aes(yintercept=0.9), color='mediumseagreen', lty='dashed')

# denominator charts
# IQC runs by Service, Production and Version??
p.denom.runs <- ggplot(subset(runs.fill, Key!='PouchQC'), aes(x=DateGroup, y=Record, fill=Version)) + geom_bar(stat='identity') + facet_wrap(~Key, ncol=1) + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + labs(x='Date\n(Year-Week)', y='Count of Runs in Final QC',title='Count of Runs Performed in QC by Week') + scale_fill_manual(values=createPaletteOfVariableLength(subset(runs.fill, Key!='PouchQC'), 'Version'))
p.denom.first <- ggplot(firstPass.runs, aes(x=DateGroup, y=Record, fill='Fill')) + geom_bar(stat='identity') + facet_wrap(~Key, ncol=1) + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5, size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + labs(x='Date\n(Year-Week)', y='Count of Distinct Instruments to Final QC',title='Count of Distinct Instruments going to QC by Week') + scale_fill_manual(values=createPaletteOfVariableLength(data.frame(Fill='Fill'),'Fill'), guide=FALSE)

# Make images for the web hub
setwd(imgDir)
plots <- ls()[grep('^p\\.', ls())]
for(i in 1:length(plots)) {
  
  imgName <- paste(substring(plots[i],3),'.png',sep='')
  
  png(file=imgName, width=1200, height=800, units='px')
  print(eval(parse(text = plots[i])))
  makeTimeStamp(timeStamp = Sys.time(), author='Data Science')
  dev.off()
}

# Make pdf report for the web hub
setwd(pdfDir)
pdf("InstrumentQC.pdf", width=11, height=8)
for(i in 1:length(plots)) {
  
  print(eval(parse(text = plots[i])))
}
dev.off()

rm(list = ls())
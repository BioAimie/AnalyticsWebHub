workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_InternalReliability/'
pdfDir <- '~/WebHub/pdfs/'

setwd(workDir)

# Load needed libraries
library(RODBC)
library(ggplot2)
library(scales)
library(zoo)
library(lubridate)
library(devtools)
library(xlsx)
install_github('BioAimie/dateManip')
library(dateManip)

# load the data from SQL
source('Portfolios/R_IRM_load.R')
dungInsts <- read.xlsx('\\\\Filer01/Data/Departments/BioChem/BioChem1_Shared/Lab Management/Instruments/FA Instruments.xlsx', sheetName = 'FA Instruments', colIndex = c(1, 4, 10))
dungInsts <- dungInsts[as.character(dungInsts$Owner)=='IDATEC', ] 

# load user-defined functions necessary to produce the metrics, limits, and charts for the WebHub
source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/capacityUtilized.R')
source('Rfunctions/findRunsToKeep.R')
source('Rfunctions/makeTimeStamp.R')

# establish some properties used throughout the code- these are kept up top to facilitate changes
periods <- 4
weeks <- 53
lagPeriods <- 4

# make a calendar that matches the weeks from SQL DATEPART function and find a start date such that charts show one year
startYear <- year(Sys.Date()) - 2
calendar.df <- createCalendarLikeMicrosoft(startYear, 'Week')
startDate <- findStartDate(calendar.df, 'Week', weeks, periods)
# set theme for line charts ------------------------------------------------------------------------------------------------------------------
seqBreak <- 12
dateBreaks <- as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup']))[order(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup'])))][seq(4,length(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup']))), seqBreak)]
fontSize <- 20
fontFace <- 'bold'
theme_set(theme_gray() + theme(plot.title = element_text(hjust = 0.5)))

# set theme for line charts ------------------------------------------------------------------------------------------------------------------

# Consolidate data from FA1.0 AND FA2.0 DBs, then find the runs to keep using the list of instruments provided by Shane and the findRunsToKeep function
# a) consolidate runs in FADB1 and FADB2, making sure to eliminate runs that exist in both places
inTwo <- unique(fa2_runs.df$PouchSerialNumber)
fa1_runs.df <- fa1_runs.df[!(fa1_runs.df$PouchSerialNumber %in% inTwo), ]
runs.df <- rbind(fa1_runs.df, fa2_runs.df)
# b) consolidate control values from FADB1 into one frame, then bind to FADB2 all controls
fa1_all.df <- rbind(fa1_pcr1.df, fa1_pcr2.df, fa1_yeast.df)
inTwo <- unique(fa2_all.df$PouchSerialNumber)
fa1_all.df <- fa1_all.df[!(fa1_all.df$PouchSerialNumber %in% inTwo), ]
controls.df <- rbind(fa1_all.df, fa2_all.df)
# c) free up some memory now that the data have been consolidated
rm(fa1_all.df, fa2_all.df, fa1_runs.df, fa2_runs.df, fa1_pcr1.df, fa1_pcr2.df, fa1_yeast.df)
# d) pass the compact frames through a cleaner to find runs that should be kept for evaluation
clean.runs <- findRunsToKeep(runs.df, dungInsts$Instrument)
clean.controls <- controls.df[controls.df$PouchSerialNumber %in% clean.runs$PouchSerialNumber, ]

# ALERT ----- THERE ARE NO TORCH RUNS BECAUSE THE SERIAL NUMBERS SUPPLIED BY SHANE FOR DUNGEON INSTRUMENTS ARE NOT REAL!!!!----------

# 4-Week Rolling Average Rate of Run Errors per All Runs
runs.trim <- clean.runs[!(clean.runs[,'RunStatus'] %in% c('In Progress','Aborted')), c('Year','Week','Version','Key','Record')]
runs.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', runs.trim, c('Version','Key'), startDate, 'Record', 'sum', 0)
runs.err.df <- clean.runs[!(clean.runs[,'RunStatus'] %in% c('In Progress','Aborted','Completed')), c('Year','Week','Version','Key','RunStatus','Record')]
runs.err.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', runs.err.df, c('Version','Key','RunStatus'), startDate, 'Record', 'sum', 0)
runs.err.rate <- mergeCalSparseFrames(runs.err.fill, runs.fill, c('DateGroup','Version','Key'), c('DateGroup','Version','Key'), 'Record', 'Record', 0, periods)
runs.err.lims <- addStatsToSparseHandledData(runs.err.rate, c('Version','Key'), lagPeriods, TRUE, 3, 'upper', 0)
pal.err <- createPaletteOfVariableLength(runs.err.lims, 'RunStatus')
p.instrument.errors <- ggplot(runs.err.lims, aes(x=DateGroup, y=Rate, fill=RunStatus)) + geom_bar(stat='identity') + scale_fill_manual(values=pal.err, name='') + facet_grid(Version~Key, scales='free_y') + geom_hline(aes(yintercept=UL), color='black', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom') + labs(title='Run Errors per Total Runs:\nFYI Limit = +3 standard deviations', x='Date\n(Year-Week)', y='Rolling 4-Week Average Rate')

# 4-Week Rolling Average of Aborted Runs per Total Runs
runs.trim.abort <- clean.runs[clean.runs[,'RunStatus'] == 'Aborted', c('Year','Week','Version','Key','Record')]
runs.fill.abort <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', runs.trim.abort, c('Version','Key'), startDate, 'Record', 'sum', 0)
runs.abort.rate <- mergeCalSparseFrames(runs.fill.abort, runs.fill, c('DateGroup','Version','Key'), c('DateGroup','Version','Key'), 'Record', 'Record', 0, periods)
runs.abort.lims <- addStatsToSparseHandledData(runs.abort.rate, c('Version','Key'), lagPeriods, TRUE, 3, 'upper', 0)
p.aborted.runs <- ggplot(runs.abort.lims, aes(x=DateGroup, y=Rate, group=Key)) + geom_line(color='black') + geom_point(color='black') + facet_grid(Version~Key, scales='free_y') + geom_hline(aes(yintercept=UL), color='blue', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom') + labs(title='Runs Aborted per Total Runs:\nFYI Limit = +3 standard deviations', x='Date\n(Year-Week)', y='Rolling 4-Week Average Rate')

# Average capacity utilized by hour
capacityByDay <- capacityUtilized(runs.df, 12, TRUE)
capacityByHour <- capacityUtilized(runs.df, 12, FALSE)
p.capacity.day <- ggplot(capacityByDay, aes(x=Date, y=RollingRate, group='1')) + geom_line() + geom_point() + facet_wrap(~Key, ncol=1) + scale_y_continuous(label=percent) + theme(text=element_text(size=fontSize, face=fontFace),axis.text=element_text(color='black',size=fontSize, face=fontFace)) + labs(title='Average Capacity Utilized:\nActual Runs/Theoretical Capacity',x='Date',y='Rolling 5-Day Average')
p.capacity.hour <- ggplot(capacityByHour, aes(x=Hour, y=CapacityUtilized, group='1')) + geom_line() + geom_point() + facet_wrap(~Key, ncol=1) + scale_y_continuous(label=percent) + theme(text=element_text(size=fontSize, face=fontFace),axis.text=element_text(color='black',size=fontSize, face=fontFace)) + labs(title='Average Capacity Utilized by Hour:\nInstruments Used/Instruments in Area',x='Hour',y='Capacity Utilized (3 week average)')

# Average capacity utilized by day for the last month in the Dungeon by version




# Average Runs per Week as a Rolling 4-Week Trend
denom.one <- data.frame(DateGroup = as.character(unique(runs.fill[,'DateGroup'])), Record = 1)
runs.weekly.rate <- mergeCalSparseFrames(runs.fill, denom.one, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
pal.weekly <- createPaletteOfVariableLength(runs.weekly.rate, 'Version')
p.weekly.rate <- ggplot(runs.weekly.rate, aes(x=DateGroup, y=Rate, group=Version, color=Version)) + geom_line() + geom_point() + scale_color_manual(values=pal.weekly) + facet_wrap(~Key, ncol=1) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Average Run Count per Week', x='Date\n(Year-Week)', y='Rolling 4-Week Average Rate')

# Show how an instrument has been performing on control testing for the last year
# --------------------------------------------------------------------------------------------------------
# a) merge the cleaned control and run data together by the serial number of the pouch in the run
perf <- merge(clean.runs, clean.controls, by='PouchSerialNumber')
# b) change anything that says 'yeastRNA' or 'yeastDNA' to 'Yeast'
perf$Name <- as.character(perf$Name)
perf[grep('yeast',perf$Name),'Name'] <- 'Yeast'
# c) make charts showing the variation of control behavior by instrument
# Cp
perf_cp <- perf[,c('InstrumentSerialNumber','Key','Panel','Name','AvgCp')]
perf_cp_stat <- merge(with(perf_cp, aggregate(AvgCp~Key, FUN=mean)), with(perf_cp, aggregate(AvgCp~Key, FUN=sd)), by='Key')
colnames(perf_cp_stat) <- c('Key','average','sdev')
perf_cp <- merge(perf_cp, perf_cp_stat, by='Key')
p.cp.dungeon <- ggplot(subset(perf_cp,Key=='Dungeon'), aes(x=InstrumentSerialNumber, y=AvgCp, color=Name)) + geom_point() + scale_color_manual(values=c('dodgerblue','darkgreen','darkgrey'), name='Control') + facet_wrap(~Panel,ncol=1) + geom_hline(aes(yintercept=average+3*sdev), lty='dashed', color='black') + geom_hline(aes(yintercept=average-3*sdev), lty='dashed', color='black') + theme(text=element_text(size=fontSize, face=fontFace),axis.text.x=element_text(color='black',size=10,angle=90, hjust=1),axis.text.y=element_text(color='black',size=fontSize, face=fontFace), legend.position='bottom', legend.title=element_blank()) + labs(title='Average Cp in Dungeon Runs',x='Instrument',y='Average Cp of Control')
p.cp.qc <- ggplot(subset(perf_cp,Key=='QC'), aes(x=InstrumentSerialNumber, y=AvgCp, color=Name)) + geom_point() + scale_color_manual(values=c('dodgerblue','darkgreen','darkgrey'), name='Control') + facet_wrap(~Panel,ncol=1) + geom_hline(aes(yintercept=average+3*sdev), lty='dashed', color='black') + geom_hline(aes(yintercept=average-3*sdev), lty='dashed', color='black') + theme(text=element_text(size=fontSize, face=fontFace),axis.text.x=element_text(color='black',size=10,angle=90, hjust=1),axis.text.y=element_text(color='black',size=fontSize, face=fontFace), legend.position='bottom', legend.title=element_blank()) + labs(title='Average Cp in Pouch QC Runs',x='Instrument',y='Average Cp of Control')
# Tm1
perf_tm <- perf[,c('InstrumentSerialNumber','Key','Panel','Name','AvgTm1')]
perf_tm_stat <- merge(with(perf_tm, aggregate(AvgTm1~Key, FUN=mean)), with(perf_tm, aggregate(AvgTm1~Key, FUN=sd)), by='Key')
colnames(perf_tm_stat) <- c('Key','average','sdev')
perf_tm <- merge(perf_tm, perf_tm_stat, by='Key')
p.tm.dungeon <- ggplot(subset(perf_tm,Key=='Dungeon'), aes(x=InstrumentSerialNumber, y=AvgTm1, color=Name)) + geom_point() + scale_color_manual(values=c('dodgerblue','darkgreen','darkgrey'), name='Control') + facet_wrap(~Panel,ncol=1) + geom_hline(aes(yintercept=average+3*sdev), lty='dashed', color='black') + geom_hline(aes(yintercept=average-3*sdev), lty='dashed', color='black') + theme(text=element_text(size=fontSize, face=fontFace),axis.text.x=element_text(color='black',size=10,angle=90, hjust=1),axis.text.y=element_text(color='black',size=fontSize, face=fontFace), legend.position='bottom', legend.title=element_blank()) + labs(title='Average Tm1 in Dungeon Runs',x='Instrument',y='Average Tm1 of Control')
p.tm.qc <- ggplot(subset(perf_tm,Key=='QC'), aes(x=InstrumentSerialNumber, y=AvgTm1, color=Name)) + geom_point() + scale_color_manual(values=c('dodgerblue','darkgreen','darkgrey'), name='Control') + facet_wrap(~Panel,ncol=1) + geom_hline(aes(yintercept=average+3*sdev), lty='dashed', color='black') + geom_hline(aes(yintercept=average-3*sdev), lty='dashed', color='black') + theme(text=element_text(size=fontSize, face=fontFace),axis.text.x=element_text(color='black',size=10,angle=90, hjust=1),axis.text.y=element_text(color='black',size=fontSize, face=fontFace), legend.position='bottom', legend.title=element_blank()) + labs(title='Average Tm1 in Pouch QC Runs',x='Instrument',y='Average Tm1 of Control')
# Fluor
perf_fluor <- perf[,c('InstrumentSerialNumber','Key','Panel','Name','AvgFluor')]
perf_fluor_stat <- merge(with(perf_fluor, aggregate(AvgFluor~Key, FUN=mean)), with(perf_fluor, aggregate(AvgFluor~Key, FUN=sd)), by='Key')
colnames(perf_fluor_stat) <- c('Key','average','sdev')
perf_fluor <- merge(perf_fluor, perf_fluor_stat, by='Key')
p.fluor.dungeon <- ggplot(subset(perf_fluor,Key=='Dungeon'), aes(x=InstrumentSerialNumber, y=AvgFluor, color=Name)) + geom_point() + scale_color_manual(values=c('dodgerblue','darkgreen','darkgrey'), name='Control') + facet_wrap(~Panel,ncol=1) + geom_hline(aes(yintercept=average+3*sdev), lty='dashed', color='black') + geom_hline(aes(yintercept=average-3*sdev), lty='dashed', color='black') + theme(text=element_text(size=fontSize, face=fontFace),axis.text.x=element_text(color='black',size=10,angle=90, hjust=1),axis.text.y=element_text(color='black',size=fontSize, face=fontFace), legend.position='bottom', legend.title=element_blank()) + labs(title='Average Maximum Normalized Fluorescence in Dungeon Runs',x='Instrument',y='Average Max Fluorescence of Control')
p.fluor.qc <- ggplot(subset(perf_fluor,Key=='QC'), aes(x=InstrumentSerialNumber, y=AvgFluor, color=Name)) + geom_point() + scale_color_manual(values=c('dodgerblue','darkgreen','darkgrey'), name='Control') + facet_wrap(~Panel,ncol=1) + geom_hline(aes(yintercept=average+3*sdev), lty='dashed', color='black') + geom_hline(aes(yintercept=average-3*sdev), lty='dashed', color='black') + theme(text=element_text(size=fontSize, face=fontFace),axis.text.x=element_text(color='black',size=10,angle=90, hjust=1),axis.text.y=element_text(color='black',size=fontSize, face=fontFace), legend.position='bottom', legend.title=element_blank()) + labs(title='Average Maximum Normalized Fluorescence in Pouch QC Runs',x='Instrument',y='Average Max Fluorescence of Control')

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
pdf("InternalReliability.pdf", width = 11, height = 8)
for(i in 1:length(plots)) {
  
  print(eval(parse(text = plots[i])))
}
dev.off()

rm(list=ls())
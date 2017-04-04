workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_InstrumentCalibration/'
pdfDir <- '~/WebHub/pdfs/'

setwd(workDir)

# load the necessary libraries
library(ggplot2)
library(scales)
library(lubridate)
library(devtools)
install_github('BioAimie/dateManip')
library(dateManip)

# load the data and user-defined functions
source('Portfolios/Q_ICS_load.R')
source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/makeTimeStamp.R')

# establish some properties used throughout the code- these are kept up top to facilitate changes
periods <- 4
lagPeriods <- 4
weeks <- 53
startYear <- year(Sys.Date()) - 2

# create a calendar so values can be displayed for the last year
calendar.df <- createCalendarLikeMicrosoft(startYear, 'Week')
startDate <- findStartDate(calendar.df, 'Week', weeks, periods)

# set theme for line charts ------------------------------------------------------------------------------------------------------------------
seqBreak <- 12
dateBreaks <- as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup']))[order(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup'])))][seq(1,length(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup']))), seqBreak)]
fontSize <- 20
fontFace <- 'bold'
theme_set(theme_gray() + theme(plot.title = element_text(hjust = 0.5)))

# set theme for line charts ------------------------------------------------------------------------------------------------------------------

# Optics Calibration ------------------------------------------------------------------------------------------------
optics.ind <- data.frame(cbind(optics.df, DateGroup = ifelse(optics.df$Week < 10, paste(optics.df$Year, optics.df$Week, sep='-0'), paste(optics.df$Year, optics.df$Week, sep='-'))))
optics.lp65.avg <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', optics.ind, c('Location','Version'), startDate, 'LP65', 'mean', NA)
p.optics.lp <- ggplot(optics.ind, aes(x=DateGroup, y=LP65, color=LPResult)) + geom_point(color='grey') + geom_line(aes(x=DateGroup, y=LP65, group=Location), color='black', data=optics.lp65.avg) + geom_point(aes(x=DateGroup, y=LP65, group=Location), color='blue', data=optics.lp65.avg) + labs(title='Optics Calibration in Instrument Production:\nLP65 Value', x='Date\n(Year-Week)', y='Individual Values, Weekly Average') + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + facet_grid(Version~Location)

# Seal Bar Calibration ----------------------------------------------------------------------------------------------------
sealbar.ind <- data.frame(cbind(sealbar.df, DateGroup = ifelse(sealbar.df$Week < 10, paste(sealbar.df$Year, sealbar.df$Week, sep='-0'), paste(sealbar.df$Year, sealbar.df$Week, sep='-'))))
sealbar.fluke <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', sealbar.ind, c('Location','Version'), startDate, 'flukeTemp', 'mean', NA)
sealbar.intercept <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', sealbar.ind, c('Location','Version'), startDate, 'intercept', 'mean', NA)
sealbar.slope <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', sealbar.ind, c('Location','Version'), startDate, 'slope', 'mean', NA)
sealbar.adc <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', sealbar.ind, c('Location','Version'), startDate, 'ADC', 'mean', NA)
p.sealbar.fluke <- ggplot(sealbar.ind, aes(x=DateGroup, y=flukeTemp, color=LPResult)) + geom_point(color='grey') + geom_line(aes(x=DateGroup, y=flukeTemp, group=Location), color='black', data=sealbar.fluke) + geom_point(aes(x=DateGroup, y=flukeTemp, group=Location), color='blue', data=sealbar.fluke) + labs(title='Sealbar Calibration in Instrument Production:\nFluke Temperature', x='Date\n(Year-Week)', y='Individual Values, Weekly Average') + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + facet_grid(Version~Location)
p.sealbar.intercept <- ggplot(sealbar.ind, aes(x=DateGroup, y=intercept, color=LPResult)) + geom_point(color='grey') + geom_line(aes(x=DateGroup, y=intercept, group=Location), color='black', data=sealbar.intercept) + geom_point(aes(x=DateGroup, y=intercept, group=Location), color='blue', data=sealbar.intercept) + labs(title='Sealbar Calibration in Instrument Production:\nThermocouple Intercept', x='Date\n(Year-Week)', y='Individual Values, Weekly Average') + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + facet_grid(Version~Location)
p.sealbar.slope <- ggplot(sealbar.ind, aes(x=DateGroup, y=slope, color=LPResult)) + geom_point(color='grey') + geom_line(aes(x=DateGroup, y=slope, group=Location), color='black', data=sealbar.slope) + geom_point(aes(x=DateGroup, y=slope, group=Location), color='blue', data=sealbar.slope) + labs(title='Sealbar Calibration in Instrument Production:\nThermocouple Slope', x='Date\n(Year-Week)', y='Individual Values, Weekly Average') + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + facet_grid(Version~Location)
p.sealbar.adc <- ggplot(sealbar.ind, aes(x=DateGroup, y=ADC, color=LPResult)) + geom_point(color='grey') + geom_line(aes(x=DateGroup, y=ADC, group=Location), color='black', data=sealbar.adc) + geom_point(aes(x=DateGroup, y=ADC, group=Location), color='blue', data=sealbar.adc) + labs(title='Sealbar Calibration in Instrument Production:\nActual ADC Value', x='Date\n(Year-Week)', y='Individual Values, Weekly Average') + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + facet_grid(Version~Location)

# Temperature Calibration ----------------------------------------------------------------------------------------------
  # because there are a whole lot of tests involved and they are all stacked by Test name, iterate to make a calendar
tests <- as.character(unique(temp.df[,'Test']))
temp.fill <- c()
for(i in 1:length(tests)) {
  
  test <- tests[i]
  target <- as.numeric(as.character(unique(temp.df[temp.df[,'Test'] == test, 'Target'])))
  temp <- temp.df[temp.df[,'Test'] == test, ]
  temp <- merge(calendar.df[calendar.df[,'DateGroup'] >= startDate, ], temp, by=c('Year','Week'), all.x =TRUE)
  temp[is.na(temp[,'Test']),'Test'] <- test
  temp[is.na(temp[,'Target']),'Target'] <- target
  temp.fill <- rbind(temp.fill, temp)
}
temp.inst <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', temp.fill, c('Test','Location','Version'), startDate, 'Instrument', 'mean', NA)
temp.err <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', temp.fill, c('Test','Location','Version'), startDate, 'Error', 'mean', NA)
temp.fill <- merge(merge(temp.fill, temp.inst, by=c('DateGroup','Test','Location','Version'), all.x=TRUE), temp.err, by=c('DateGroup','Test','Location','Version'), all.x=TRUE)
temp.fill[,'TestType'] <- substr(temp.fill[,'Test'], 1, 4)
temp.fill <- temp.fill[!(is.na(temp.fill[,'Location'])), ]

# make charts for individual tests... maybe this could be consolidated if Greg is cool with it
# there are some charts where the temperature is abnormally low and it messes up the charts, so take out those entries
temp.fill <- temp.fill[!(temp.fill$Error.x > 2), ]
  # PCR1 - 50
pcr1.50.inst <- subset(temp.fill, Test=='PCR1_50')[,c('DateGroup','Location','Version','Target','Instrument.x','Instrument.y')]; pcr1.50.inst$Key <- 'Instrument Temperature'; colnames(pcr1.50.inst) <- c('DateGroup','Location','Version','Target','Value','Average','Key')
pcr1.50.err <- subset(temp.fill, Test=='PCR1_50')[,c('DateGroup','Location','Version','Target','Error.x','Error.y')]; pcr1.50.err$Key <- 'Temperature Error'; colnames(pcr1.50.err) <- c('DateGroup','Location','Version','Target','Value','Average','Key')
pcr1.50 <- rbind(pcr1.50.inst, pcr1.50.err)
pcr1.50[,'Target'] <- with(pcr1.50, ifelse(Key=='Temperature Error', NA, Target))
p.pcr1.50 <- ggplot(pcr1.50, aes(x=DateGroup, y=Value)) + geom_point(color='darkgrey') + geom_point(aes(x=DateGroup, y=Average), data=pcr1.50, color='blue', size=2) + geom_line(aes(x=DateGroup, y=Average, group=1), data=pcr1.50, color='black') + geom_hline(aes(yintercept=Target), color='black', data=pcr1.50, size=1.5) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Temperature Calibration in Instrument Production\nPCR 1 at 50 Degrees', x='Year-Week', y='Individual Values, Weekly Average') + facet_grid(Key~Location+Version, scale='free_y')
# PCR1 - 60
pcr1.60.inst <- subset(temp.fill, Test=='PCR1_60')[,c('DateGroup','Location','Version','Target','Instrument.x','Instrument.y')]; pcr1.60.inst$Key <- 'Instrument Temperature'; colnames(pcr1.60.inst) <- c('DateGroup','Location','Version','Target','Value','Average','Key')
pcr1.60.err <- subset(temp.fill, Test=='PCR1_60')[,c('DateGroup','Location','Version','Target','Error.x','Error.y')]; pcr1.60.err$Key <- 'Temperature Error'; colnames(pcr1.60.err) <- c('DateGroup','Location','Version','Target','Value','Average','Key')
pcr1.60 <- rbind(pcr1.60.inst, pcr1.60.err)
pcr1.60[,'Target'] <- with(pcr1.60, ifelse(Key=='Temperature Error', NA, Target))
p.pcr1.60 <- ggplot(pcr1.60, aes(x=DateGroup, y=Value)) + geom_point(color='darkgrey') + geom_point(aes(x=DateGroup, y=Average), data=pcr1.60, color='blue', size=2) + geom_line(aes(x=DateGroup, y=Average, group=1), data=pcr1.60, color='black') + geom_hline(aes(yintercept=Target), color='black', data=pcr1.60, size=1.5) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Temperature Calibration in Instrument Production\nPCR 1 at 60 Degrees', x='Year-Week', y='Individual Values, Weekly Average') + facet_grid(Key~Location+Version, scale='free_y')
# PCR1 - 70
pcr1.70.inst <- subset(temp.fill, Test=='PCR1_70')[,c('DateGroup','Location','Version','Target','Instrument.x','Instrument.y')]; pcr1.70.inst$Key <- 'Instrument Temperature'; colnames(pcr1.70.inst) <- c('DateGroup','Location','Version','Target','Value','Average','Key')
pcr1.70.err <- subset(temp.fill, Test=='PCR1_70')[,c('DateGroup','Location','Version','Target','Error.x','Error.y')]; pcr1.70.err$Key <- 'Temperature Error'; colnames(pcr1.70.err) <- c('DateGroup','Location','Version','Target','Value','Average','Key')
pcr1.70 <- rbind(pcr1.70.inst, pcr1.70.err)
pcr1.70[,'Target'] <- with(pcr1.70, ifelse(Key=='Temperature Error', NA, Target))
p.pcr1.70 <- ggplot(pcr1.70, aes(x=DateGroup, y=Value)) + geom_point(color='darkgrey') + geom_point(aes(x=DateGroup, y=Average), data=pcr1.70, color='blue', size=2) + geom_line(aes(x=DateGroup, y=Average, group=1), data=pcr1.70, color='black') + geom_hline(aes(yintercept=Target), color='black', data=pcr1.70, size=1.5) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Temperature Calibration in Instrument Production\nPCR 1 at 70 Degrees', x='Year-Week', y='Individual Values, Weekly Average') + facet_grid(Key~Location+Version, scale='free_y')
# PCR1 - 80
pcr1.80.inst <- subset(temp.fill, Test=='PCR1_80')[,c('DateGroup','Location','Version','Target','Instrument.x','Instrument.y')]; pcr1.80.inst$Key <- 'Instrument Temperature'; colnames(pcr1.80.inst) <- c('DateGroup','Location','Version','Target','Value','Average','Key')
pcr1.80.err <- subset(temp.fill, Test=='PCR1_80')[,c('DateGroup','Location','Version','Target','Error.x','Error.y')]; pcr1.80.err$Key <- 'Temperature Error'; colnames(pcr1.80.err) <- c('DateGroup','Location','Version','Target','Value','Average','Key')
pcr1.80 <- rbind(pcr1.80.inst, pcr1.80.err)
pcr1.80[,'Target'] <- with(pcr1.80, ifelse(Key=='Temperature Error', NA, Target))
p.pcr1.80 <- ggplot(pcr1.80, aes(x=DateGroup, y=Value)) + geom_point(color='darkgrey') + geom_point(aes(x=DateGroup, y=Average), data=pcr1.80, color='blue', size=2) + geom_line(aes(x=DateGroup, y=Average, group=1), data=pcr1.80, color='black') + geom_hline(aes(yintercept=Target), color='black', data=pcr1.80, size=1.5) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Temperature Calibration in Instrument Production\nPCR 1 at 80 Degrees', x='Year-Week', y='Individual Values, Weekly Average') + facet_grid(Key~Location+Version, scale='free_y')
# PCR1 - 90
pcr1.90.inst <- subset(temp.fill, Test=='PCR1_90')[,c('DateGroup','Location','Version','Target','Instrument.x','Instrument.y')]; pcr1.90.inst$Key <- 'Instrument Temperature'; colnames(pcr1.90.inst) <- c('DateGroup','Location','Version','Target','Value','Average','Key')
pcr1.90.err <- subset(temp.fill, Test=='PCR1_90')[,c('DateGroup','Location','Version','Target','Error.x','Error.y')]; pcr1.90.err$Key <- 'Temperature Error'; colnames(pcr1.90.err) <- c('DateGroup','Location','Version','Target','Value','Average','Key')
pcr1.90 <- rbind(pcr1.90.inst, pcr1.90.err)
pcr1.90[,'Target'] <- with(pcr1.90, ifelse(Key=='Temperature Error', NA, Target))
p.pcr1.90 <- ggplot(pcr1.90, aes(x=DateGroup, y=Value)) + geom_point(color='darkgrey') + geom_point(aes(x=DateGroup, y=Average), data=pcr1.90, color='blue', size=2) + geom_line(aes(x=DateGroup, y=Average, group=1), data=pcr1.90, color='black') + geom_hline(aes(yintercept=Target), color='black', data=pcr1.90, size=1.5) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Temperature Calibration in Instrument Production\nPCR 1 at 90 Degrees', x='Year-Week', y='Individual Values, Weekly Average') + facet_grid(Key~Location+Version, scale='free_y')
  # PCR2 - 50
PCR2.50.inst <- subset(temp.fill, Test=='PCR2_50')[,c('DateGroup','Location','Version','Target','Instrument.x','Instrument.y')]; PCR2.50.inst$Key <- 'Instrument Temperature'; colnames(PCR2.50.inst) <- c('DateGroup','Location','Version','Target','Value','Average','Key')
PCR2.50.err <- subset(temp.fill, Test=='PCR2_50')[,c('DateGroup','Location','Version','Target','Error.x','Error.y')]; PCR2.50.err$Key <- 'Temperature Error'; colnames(PCR2.50.err) <- c('DateGroup','Location','Version','Target','Value','Average','Key')
PCR2.50 <- rbind(PCR2.50.inst, PCR2.50.err)
PCR2.50[,'Target'] <- with(PCR2.50, ifelse(Key=='Temperature Error', NA, Target))
p.pcr2.50 <- ggplot(PCR2.50, aes(x=DateGroup, y=Value)) + geom_point(color='darkgrey') + geom_point(aes(x=DateGroup, y=Average), data=PCR2.50, color='blue', size=2) + geom_line(aes(x=DateGroup, y=Average, group=1), data=PCR2.50, color='black') + geom_hline(aes(yintercept=Target), color='black', data=PCR2.50, size=1.5) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Temperature Calibration\nPCR 2 at 50 Degrees', x='Year-Week', y='Individual Values, Weekly Average') + facet_grid(Key~Location+Version, scale ='free_y')
# PCR2 - 60
PCR2.60.inst <- subset(temp.fill, Test=='PCR2_60')[,c('DateGroup','Location','Version','Target','Instrument.x','Instrument.y')]; PCR2.60.inst$Key <- 'Instrument Temperature'; colnames(PCR2.60.inst) <- c('DateGroup','Location','Version','Target','Value','Average','Key')
PCR2.60.err <- subset(temp.fill, Test=='PCR2_60')[,c('DateGroup','Location','Version','Target','Error.x','Error.y')]; PCR2.60.err$Key <- 'Temperature Error'; colnames(PCR2.60.err) <- c('DateGroup','Location','Version','Target','Value','Average','Key')
PCR2.60 <- rbind(PCR2.60.inst, PCR2.60.err)
PCR2.60[,'Target'] <- with(PCR2.60, ifelse(Key=='Temperature Error', NA, Target))
p.pcr2.60 <- ggplot(PCR2.60, aes(x=DateGroup, y=Value)) + geom_point(color='darkgrey') + geom_point(aes(x=DateGroup, y=Average), data=PCR2.60, color='blue', size=2) + geom_line(aes(x=DateGroup, y=Average, group=1), data=PCR2.60, color='black') + geom_hline(aes(yintercept=Target), color='black', data=PCR2.60, size=1.5) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Temperature Calibration\nPCR 2 at 60 Degrees', x='Year-Week', y='Individual Values, Weekly Average') + facet_grid(Key~Location+Version, scale ='free_y')
# PCR2 - 70
PCR2.70.inst <- subset(temp.fill, Test=='PCR2_70')[,c('DateGroup','Location','Version','Target','Instrument.x','Instrument.y')]; PCR2.70.inst$Key <- 'Instrument Temperature'; colnames(PCR2.70.inst) <- c('DateGroup','Location','Version','Target','Value','Average','Key')
PCR2.70.err <- subset(temp.fill, Test=='PCR2_70')[,c('DateGroup','Location','Version','Target','Error.x','Error.y')]; PCR2.70.err$Key <- 'Temperature Error'; colnames(PCR2.70.err) <- c('DateGroup','Location','Version','Target','Value','Average','Key')
PCR2.70 <- rbind(PCR2.70.inst, PCR2.70.err)
PCR2.70[,'Target'] <- with(PCR2.70, ifelse(Key=='Temperature Error', NA, Target))
p.pcr2.70 <- ggplot(PCR2.70, aes(x=DateGroup, y=Value)) + geom_point(color='darkgrey') + geom_point(aes(x=DateGroup, y=Average), data=PCR2.70, color='blue', size=2) + geom_line(aes(x=DateGroup, y=Average, group=1), data=PCR2.70, color='black') + geom_hline(aes(yintercept=Target), color='black', data=PCR2.70, size=1.5) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Temperature Calibration\nPCR 2 at 70 Degrees', x='Year-Week', y='Individual Values, Weekly Average') + facet_grid(Key~Location+Version, scale ='free_y')
# PCR2 - 80
PCR2.80.inst <- subset(temp.fill, Test=='PCR2_80')[,c('DateGroup','Location','Version','Target','Instrument.x','Instrument.y')]; PCR2.80.inst$Key <- 'Instrument Temperature'; colnames(PCR2.80.inst) <- c('DateGroup','Location','Version','Target','Value','Average','Key')
PCR2.80.err <- subset(temp.fill, Test=='PCR2_80')[,c('DateGroup','Location','Version','Target','Error.x','Error.y')]; PCR2.80.err$Key <- 'Temperature Error'; colnames(PCR2.80.err) <- c('DateGroup','Location','Version','Target','Value','Average','Key')
PCR2.80 <- rbind(PCR2.80.inst, PCR2.80.err)
PCR2.80[,'Target'] <- with(PCR2.80, ifelse(Key=='Temperature Error', NA, Target))
p.pcr2.80 <- ggplot(PCR2.80, aes(x=DateGroup, y=Value)) + geom_point(color='darkgrey') + geom_point(aes(x=DateGroup, y=Average), data=PCR2.80, color='blue', size=2) + geom_line(aes(x=DateGroup, y=Average, group=1), data=PCR2.80, color='black') + geom_hline(aes(yintercept=Target), color='black', data=PCR2.80, size=1.5) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Temperature Calibration\nPCR 2 at 80 Degrees', x='Year-Week', y='Individual Values, Weekly Average') + facet_grid(Key~Location+Version, scale ='free_y')
# PCR2 - 90
PCR2.90.inst <- subset(temp.fill, Test=='PCR2_90')[,c('DateGroup','Location','Version','Target','Instrument.x','Instrument.y')]; PCR2.90.inst$Key <- 'Instrument Temperature'; colnames(PCR2.90.inst) <- c('DateGroup','Location','Version','Target','Value','Average','Key')
PCR2.90.err <- subset(temp.fill, Test=='PCR2_90')[,c('DateGroup','Location','Version','Target','Error.x','Error.y')]; PCR2.90.err$Key <- 'Temperature Error'; colnames(PCR2.90.err) <- c('DateGroup','Location','Version','Target','Value','Average','Key')
PCR2.90 <- rbind(PCR2.90.inst, PCR2.90.err)
PCR2.90[,'Target'] <- with(PCR2.90, ifelse(Key=='Temperature Error', NA, Target))
p.pcr2.90 <- ggplot(PCR2.90, aes(x=DateGroup, y=Value)) + geom_point(color='darkgrey') + geom_point(aes(x=DateGroup, y=Average), data=PCR2.90, color='blue', size=2) + geom_line(aes(x=DateGroup, y=Average, group=1), data=PCR2.90, color='black') + geom_hline(aes(yintercept=Target), color='black', data=PCR2.90, size=1.5) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Temperature Calibration\nPCR 2 at 90 Degrees', x='Year-Week', y='Individual Values, Weekly Average') + facet_grid(Key~Location+Version, scale ='free_y')

# create images for the Web Hub
setwd(imgDir)
plots <- ls()[grep('^p\\.', ls())]
for(i in 1:length(plots)) {
  
  imgName <- paste(substring(plots[i],3),'.png',sep='')
  
  png(file=imgName, width=1200, height=800, units='px')
  print(eval(parse(text = plots[i])))
  makeTimeStamp(author='Data Science', size=1)
  dev.off()
}

# Create the pdf
setwd(pdfDir)
pdf("InstrumentCalibration.pdf", width=11, height=8)
for(i in 1:length(plots)) {
  
  print(eval(parse(text = plots[i])))
}
dev.off()

rm(list=ls())
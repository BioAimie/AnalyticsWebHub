# set the working directory
workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_BioReagentNCR/'
pdfDir <- '~/WebHub/pdfs/'
setwd(workDir)

# load the necessary libraries
library(ggplot2)
library(zoo)
library(scales)
library(lubridate)
library(RColorBrewer)
library(devtools)
install_github('BioAimie/dateManip')
library(dateManip)

# load the necessary files and functions that are user-created
source('Portfolios/R_BNCR_load.R')
source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/makeTimeStamp.R')

# establish some properties used throughout the code- these are kept up top to facilitate changes
periods <- 4
weeks <- 53
lagPeriods <- 4
validateDate <- '2015-40'

# make a calendar that matches the weeks from SQL DATEPART function and find a start date such that charts show one year
startYear <- year(Sys.Date()) - 3
calendar.df <- createCalendarLikeMicrosoft(startYear, 'Week')
startDate <- findStartDate(calendar.df, 'Week', weeks, periods, keepPeriods=53)
plot.startDate.week <- findStartDate(calendar.df, 'Week', weeks, periods, keepPeriods=0)
# set theme for line charts ------------------------------------------------------------------------------------------------------------------
seqBreak <- 12
dateBreaks <- as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= plot.startDate.week,'DateGroup']))[order(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= plot.startDate.week,'DateGroup'])))][seq(4,length(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= plot.startDate.week,'DateGroup']))), seqBreak)]
fontSize <- 20
fontFace <- 'bold'
theme_set(theme_gray() + theme(plot.title = element_text(hjust = 0.5)))
# set theme for line charts ------------------------------------------------------------------------------------------------------------------

# All BioReagent NCRs per Pouches Manufactured (final pouch product)
ncrs.df <- pouchWPFS[pouchWPFS[,'Key'] == 'Where Found', c('Year','Week','Record')]
ncrs.df[,'Key'] <- 'BioReagentNCR'
prod.df <- pouchProd[pouchProd[,'Key'] == 'Final', ]
ncrs.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', ncrs.df, c('Key'), startDate, 'Record', 'sum', 0)
prod.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', prod.df, c('Key'), startDate, 'Record', 'sum', 1)
ncrs.rate <- mergeCalSparseFrames(ncrs.fill, prod.fill, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
ncrs.lims <- addStatsToSparseHandledData(ncrs.rate, c('Key'), lagPeriods, TRUE, 3, 'upper', 0, keepPeriods=53)
p.ncrs.all <- ggplot(ncrs.lims, aes(x=DateGroup, y=Rate, group=Key, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + geom_line(aes(y=UL), color='blue', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='BioReagent NCRs per Pouches Manufactured\nFYI Limits = +3 standard deviations', x='Date\n(Year-Week)', y='Rolling 4-week Average Rate')

# BioReagent NCRs by Where Found
ncrs.version.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', pouchWPFS, c('Key','RecordedValue'), startDate, 'Record', 'sum', 0)
prod.version.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', pouchProd, c('Key'), startDate, 'Record', 'sum', 1)
wherefound.fill <- subset(ncrs.version.fill, Key == 'Where Found')
wherefound.count <- with(wherefound.fill[wherefound.fill[,'DateGroup'] >= findStartDate(calendar.df, 'Week', 8, keepPeriods=0), ], aggregate(Record~RecordedValue, FUN=sum))
wherefound.count <- wherefound.count[with(wherefound.count, order(Record, decreasing = TRUE)), ]
wherefound.count[,'Total'] <- sapply(1:length(wherefound.count[,'Record']), function(x) sum(wherefound.count[1:x,'Record'])) 
wherefound.count <- wherefound.count[wherefound.count[,'Record'] > 0, ]
wherefound.count[,'RecordedValue'] <- factor(wherefound.count[,'RecordedValue'], levels = wherefound.count[with(wherefound.count, order(Record, decreasing = TRUE)), 'RecordedValue'])
if(min(which(wherefound.count[,'Total']/max(wherefound.count[,'Total']) > 0.8)) <= 10) {
  
  wherefound.count <- wherefound.count[1:10, ]
} else {
  
  index <- min(which(wherefound.count[,'Total']/max(wherefound.count[,'Total']) > 0.8))
  wherefound.count <- wherefound.count[1:index, ]
}
p.pareto.wherefound <- ggplot(wherefound.count, aes(x=RecordedValue, y=Record)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=70, hjust=1)) + labs(title='BioReagent NCRs: Where Found\n(last 8 weeks)', x='Where Found', y='Count of Occurrences')
wherefound.fill[grep('Array', wherefound.fill[,'RecordedValue']),'DenomKey'] <- 'Array'
wherefound.fill[grep('Oligo', wherefound.fill[,'RecordedValue']),'DenomKey'] <- 'Oligo'
wherefound.fill[grep('QC|Sniffing', wherefound.fill[,'RecordedValue']),'DenomKey'] <- 'Final'
wherefound.fill[is.na(wherefound.fill[,'DenomKey']),'DenomKey'] <- 'Pouch'
wherefound.rate <- mergeCalSparseFrames(wherefound.fill, prod.version.fill, c('DateGroup','DenomKey'), c('DateGroup','Key'), 'Record', 'Record', 0, periods)
wherefound.lims <- addStatsToSparseHandledData(wherefound.rate, c('RecordedValue'), lagPeriods, TRUE, 3, 'upper', 0, keepPeriods=53)
p.wherefound <- ggplot(subset(wherefound.lims, RecordedValue %in% wherefound.count[,'RecordedValue']), aes(x=DateGroup, y=Rate, group=RecordedValue)) + geom_line(color='black') + geom_point() + facet_wrap(~RecordedValue, scale='free_y') + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + geom_line(aes(y=UL), color='blue', lty=2) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Top Occurring Where Found Categories per Product Manufactured\nFYI Limit = +3 standarad deviations')

# BioReagent NCRs by Where Found
problemarea.fill <- subset(ncrs.version.fill, Key == 'Problem Area')
problemarea.count <- with(problemarea.fill[problemarea.fill[,'DateGroup'] >= findStartDate(calendar.df, 'Week', 8, keepPeriods=0), ], aggregate(Record~RecordedValue, FUN=sum))
problemarea.count <- problemarea.count[with(problemarea.count, order(Record, decreasing = TRUE)), ]
problemarea.count[,'Total'] <- sapply(1:length(problemarea.count[,'Record']), function(x) sum(problemarea.count[1:x,'Record'])) 
problemarea.count <- problemarea.count[problemarea.count[,'Record'] > 0, ]
problemarea.count[,'RecordedValue'] <- factor(problemarea.count[,'RecordedValue'], levels = problemarea.count[with(problemarea.count, order(Record, decreasing = TRUE)), 'RecordedValue'])
if(min(which(problemarea.count[,'Total']/max(problemarea.count[,'Total']) > 0.8)) <= 10) {
  
  problemarea.count <- problemarea.count[1:10, ]
} else {
  
  index <- min(which(problemarea.count[,'Total']/max(problemarea.count[,'Total']) > 0.8))
  problemarea.count <- problemarea.count[1:index, ]
}
p.pareto.problemarea <- ggplot(problemarea.count, aes(x=RecordedValue, y=Record)) + geom_bar(stat='identity') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=70, hjust=1)) + labs(title='BioReagent NCRs: Problem Area\n(last 8 weeks)', x='Problem Area', y='Count of Occurrences')
problemarea.fill[grep('Array', problemarea.fill[,'RecordedValue']),'DenomKey'] <- 'Array'
problemarea.fill[grep('Oligo|Biomek|HPLC|Detritylation', problemarea.fill[,'RecordedValue']),'DenomKey'] <- 'Oligo'
problemarea.fill[grep('QC|Packaging', problemarea.fill[,'RecordedValue']),'DenomKey'] <- 'Final'
problemarea.fill[is.na(problemarea.fill[,'DenomKey']),'DenomKey'] <- 'Pouch'
problemarea.rate <- mergeCalSparseFrames(problemarea.fill, prod.version.fill, c('DateGroup','DenomKey'), c('DateGroup','Key'), 'Record', 'Record', 0, periods)
problemarea.lims <- addStatsToSparseHandledData(problemarea.rate, c('RecordedValue'), lagPeriods, TRUE, 3, 'upper', 0, keepPeriods=53)
p.problemarea <- ggplot(subset(problemarea.lims, RecordedValue %in% problemarea.count[,'RecordedValue']), aes(x=DateGroup, y=Rate, group=RecordedValue)) + geom_line(color='black') + geom_point() + facet_wrap(~RecordedValue, scale='free_y') + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + geom_line(aes(y=UL), color='blue', lty=2) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Top Occurring Problem Area Categories per Product Manufactured\nFYI Limit = +3 standarad deviations')

# make charts for web hub
setwd(imgDir)
plots <- ls()[grep('^p\\.', ls())]
for(i in 1:length(plots)) {
  
  imgName <- paste(substring(plots[i],3),'.png',sep='')
  
  png(file=imgName, width=1200, height=800, units='px')
  print(eval(parse(text = plots[i])))
  makeTimeStamp(author='Data Science')
  dev.off()
}

# make a .pdf file of the charts
setwd(pdfDir)
pdf('BioReagentNCR.pdf', width = 11, height = 8)
for(i in 1:length(plots)) {
  
  print(eval(parse(text = plots[i])))
}
dev.off()

rm(list = ls())
# Set the environment
workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <-  '~/WebHub/images/Dashboard_InstrumentRMA/'
pdfDir <- '~/WebHub/pdfs/'

setwd(workDir)

# Load needed libraries
library(tidyverse)
library(zoo)
library(scales)
library(lubridate)
library(RColorBrewer)
library(devtools)
library(sendmailR)
library(gtable)
library(grid)
#install_github('BioAimie/dateManip')
#library(dateManip)
source('~/WebHub/dateManipV1/addStatsToSparseHandledData.R')
source('~/WebHub/dateManipV1/aggregateAndFillDateGroupGaps.R')
source('~/WebHub/dateManipV1/createCalendarLikeMicrosoft.R')
source('~/WebHub/dateManipV1/createEvenWeeks.R')
source('~/WebHub/dateManipV1/findStartDate.R')
source('~/WebHub/dateManipV1/mergeCalSparseFrames.R')
source('~/WebHub/dateManipV1/transformToEpiWeeks.R')

source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/makeTimeStamp.R')
source('Rfunctions/loadSQL.r')

# load the data from SQL
#*note: to set DB paths go to Control Panel/Systems & Security/Administrative Tools/Data Sources (ODBC)
PMScxn = odbcConnect("PMS_PROD")
loadSQL(PMScxn, "SQL/R_CC_CustPouchesShippedDetailed.sql", 'pouches.df')
loadSQL(PMScxn, "SQL/R_IRMA_ComplaintRMAs.sql", 'complaints.df')
loadSQL(PMScxn, "SQL/R_IRMA_PartsUsedExcludingPreventativeMaintenance.sql", 'parts.df')
loadSQL(PMScxn, "SQL/R_IRMA_ServiceCodes.sql", 'codes.df')
loadSQL(PMScxn, "SQL/R_IRMA_RMAsShippedByInstrumentVersion.sql", 'rmasShip.df')
loadSQL(PMScxn, "SQL/R_IRMA_CustEarlyFailByVersion.sql", 'failures.df')
loadSQL(PMScxn, "SQL/R_IRMA_NewInstShipByVersion.sql", 'instShip.df')
loadSQL(PMScxn, "SQL/R_IRMA_RootCauseFailedPart3090.sql", 'rootCause.df')
loadSQL(PMScxn, 'SQL/R_IRMA_HoursAtFailures.sql', 'hours.df')
loadSQL(PMScxn, 'SQL/R_IRMA_EarlyFailuresByCodeFromField.sql', 'leadingEF.df')
loadSQL(PMScxn, 'SQL/R_IRMA_LeadingIndicatorEarlyFailureByManfDate.sql', 'leadEFmanf.df')
loadSQL(PMScxn, 'SQL/R_INCR_InstrumentsProduced_denom.sql', 'instBuilt.df')
loadSQL(PMScxn, 'SQL/R_IRMA_InstrumentsQCDate_denom.sql', 'instQCDate.df')
loadSQL(PMScxn, 'SQL/R_IRMA_LeadingIndicatorEarlyFailureByServDate.sql', 'leadEFserv.df')
loadSQL(PMScxn, 'SQL/R_IRMA_serialShipAndReturnByDate.sql', 'track.df')
loadSQL(PMScxn, "SQL/R_IRMA_FieldInstallBase.sql", 'installed.df')
loadSQL(PMScxn, "SQL/R_IRMA_NewCompShip.sql", 'compShip.df')
loadSQL(PMScxn, "SQL/R_IRMA_ComputerEarlyFailure.sql", 'computerEF.df')
codeDescript.df <- read.csv('SQL/serviceCodeDescriptions.csv', header=TRUE, sep = ',')
odbcClose(PMScxn)

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
calendar.df.month <- createCalendarLikeMicrosoft(startYear, 'Month')
calendar.df.quarter <- createCalendarLikeMicrosoft(startYear, 'Quarter')
startDate <- findStartDate(calendar.df, 'Week', weeks, periods, keepPeriods=53)
startMonth.plot <- findStartDate(calendar.df.month, 'Month', 12, 0, keepPeriods=0)
startMonth.2 <- findStartDate(calendar.df.month, 'Month', 12, 0, keepPeriods=12)
plot.startDate.week <- findStartDate(calendar.df, 'Week', weeks, periods, keepPeriods=0)
plot.startDate.month <- findStartDate(calendar.df.month, 'Month', 12, periods, keepPeriods=0)
plot.startDate.quarter <- findStartDate(calendar.df.quarter, 'Quarter', 4, periods, keepPeriods=0)


# set theme for line charts ------------------------------------------------------------------------------------------------------------------
seqBreak <- 12
dateBreaks <- as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= plot.startDate.week,'DateGroup']))[order(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= plot.startDate.week,'DateGroup'])))][seq(4,length(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= plot.startDate.week,'DateGroup']))), seqBreak)]
fontSize <- 20
fontFace <- 'bold'
theme_set(theme_grey()+theme(plot.title=element_text(hjust=0.5),
                             text=element_text(size=fontSize, face=fontFace), 
                             axis.text=element_text(color='black',size=fontSize,face=fontFace)));

# create a chart for pouches shipped per complaint RMA
pouches.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', pouches.df, c('Key'), startDate, 'Record', 'sum', 0)
complaints.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', complaints.df, c('Key'), startDate, 'Record', 'sum', 1)
reliability.rate <- mergeCalSparseFrames(pouches.fill, complaints.fill, c('DateGroup'), c('DateGroup'), 'Record', 'Record', NA, periods)
#reliability.rate <- reliability.rate[which(reliability.rate$DateGroup  >= plot.startDate.week), ]
reliability.lim <- addStatsToSparseHandledData(reliability.rate, c('Key'), lagPeriods, TRUE, 2, 'lower', NULL, 100000, keepPeriods=53)
x.val <- which(as.character(unique(reliability.lim[,'DateGroup'])) == validateDate)
# annotations for pouches shipped per complaint RMA
# x_positions <- c('2015-37')
# reliability.annotations <- c('Heat\nPress\nFix')
# y_positions <- reliability.lim[as.character(reliability.lim[,'DateGroup']) %in% x_positions, 'Rate'] - 140

p.reliability <- ggplot(reliability.lim, aes(x=DateGroup, y=Rate, group=Key, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('blue','red'), name='Key', guide=FALSE) + expand_limits(y=0) + geom_line(aes(y=LL), color='red', lty='dashed') + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, hjust=1), axis.text=element_text(color='black',size=fontSize,face=fontFace)) + scale_x_discrete(breaks=dateBreaks) + labs(title='Pouches Shipped per Complaint RMA:\nLimit = -2 standard deviations', x='Date\n(Year-Week)', y='4-week Rolling Average')

# remake this reliability chart, but lag the pouches shipped by 4 weeks (i.e. use pouches shipped 4 weeks ago per complaints this week)
startDate.lag <- findStartDate(calendar.df, 'Week', weeks+4, periods, keepPeriods=53)
pouches.fill.lag <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', pouches.df, c('Key'), startDate.lag, 'Record', 'sum', 0)
total.length <- nrow(pouches.fill.lag)
pouches.fill.lag <- data.frame(DateGroup = pouches.fill.lag$DateGroup[periods:total.length], Key = pouches.fill.lag$Key[1:(total.length-periods+1)], Record = pouches.fill.lag$Record[1:(total.length-periods+1)])
reliability.rate.lag <- mergeCalSparseFrames(pouches.fill.lag, complaints.fill, c('DateGroup'), c('DateGroup'), 'Record', 'Record', NA, periods)
reliability.lim.lag <- addStatsToSparseHandledData(reliability.rate.lag, c('Key'), lagPeriods, TRUE, 2, 'lower', NULL, 100000, keepPeriods=53)
p.reliability.lag <- ggplot(reliability.lim.lag, aes(x=DateGroup, y=Rate, group=Key, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('blue','red'), name='Key', guide=FALSE) + expand_limits(y=0) + geom_line(aes(y=LL, group=1), color='black', lty='dashed') + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, hjust=1), axis.text=element_text(color='black',size=fontSize,face=fontFace)) + scale_x_discrete(breaks=dateBreaks) + labs(title='Pouches Shipped per Complaint RMA Adjusted for Ship Time:\nFYI Limit = -2 standard deviations', x='Date\n(Year-Week)', y='4-week Rolling Average')
# so this has the weihrd huge peak and drop off, which is caused by the wierdness of week 1 in 2016... the pouches shipped and complaints were both zero in week 1,
# but because the pouches are shifted, the zero occurs in week 4 instead. This causes the peak at week 1 and the downward plunge in week 4

# create a chart for part replacements by version per RMAs shipped
rmasShip.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', rmasShip.df, c('Version','Key'), startDate, 'Record', 'sum', NA)
parts.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', parts.df, c('Version','Key'), startDate, 'Record', 'sum', NA)

#add dategroup
parts.dg <- parts.df 
parts.dg$DateGroup <- ifelse(parts.dg$Week < 10,
                            paste(parts.dg$Year, paste0('0', parts.dg$Week), sep='-'),
                            paste(parts.dg$Year, parts.dg$Week, sep='-')) 

parts.visit <- subset(parts.dg, DateGroup >= startDate, select = c('DateGroup', 'SerialNo','VisitNo','Version', 'Key', 'HoursRun', 'Record'))

#find hours run on each part replaced
parts.hours <- c()
partsReplaced <- unique(parts.visit$Key)
for(i in 1:length(partsReplaced)) {
  #subset for each part replaced
  p <- as.character(partsReplaced[i])
  t <- subset(parts.visit, as.character(Key) == p)
  t$PartHours <- t$HoursRun
  serials <- as.character(unique(t$SerialNo))
  #subset for each serial no  
  for(j in 1:length(serials)) {
    inSerial <- serials[j]  
    t2 <- subset(t, as.character(SerialNo) == inSerial)
    if(nrow(t2) > 1) {
      t2$PartHours <- c(t2$PartHours[1], diff(t2$HoursRun))
      for(k in 1:nrow(t2)) {
        if(is.na(t2$PartHours[k]) | t2$PartHours[k] < 1) {
          t2$PartHours[k] <- t2$HoursRun[k]
        } #end if statement
      } #end k loop
    } #end if statement
    parts.hours <- rbind(parts.hours, subset(t2, select = c('DateGroup', 'Version', 'Key', 'PartHours', 'Record')))
  } #end j loop
} #end i loop

#find average lifespan for each part within time period for each version
parts.out <- c()
versions <- as.character(unique(parts.hours$Version))
#for every version
for(k in 1:length(versions)) {
  temp3 <- subset(parts.hours, as.character(Version) == versions[k])
  dateGroups <- unique(temp3$DateGroup)
  #for every dategroup
  for(i in 1:length(dateGroups)){
    dg <- dateGroups[i]
    temp <- subset(temp3, DateGroup == dg)
    #find each part included in dategroup
    for(j in 1:length(unique(temp$Key))){
      part <- as.character(unique(temp$Key)[j])
      temp2 <- subset(temp, Key == part)
      #multiply hoursrun by record
      temp2$Hours <- as.numeric(as.character(temp2$PartHours)) * temp2$Record
      temp2$TotalHours <- ifelse(is.na(temp2$Hours),
                                 0,
                                 temp2$Hours)
      temp2$TotalRecord <- ifelse(is.na(temp2$Hours),
                                  0,
                                  temp2$Record)
      #average number of hours run
      #total hours run / total record of part  
      temp2$AvgHours <- sum(temp2$TotalHours) / sum(temp2$TotalRecord)
      parts.out <- rbind(parts.out, subset(temp2, select=c('DateGroup', 'Version', 'Key', 'Record', 'AvgHours'))) 
    }
  }
}
  
parts.out <- with(parts.out, aggregate(Record~DateGroup+Version+Key+AvgHours, FUN=sum))

parts.rate <- mergeCalSparseFrames(parts.fill, rmasShip.fill, c('DateGroup','Version'), c('DateGroup','Version'), 'Record', 'Record', NA, periods)
parts.lim <- addStatsToSparseHandledData(parts.rate, c('Version','Key'), lagPeriods, TRUE, 2, 'upper', keepPeriods=53)
parts.lim[parts.lim[,'Rate'] > 1 & !(is.na(parts.lim[,'Rate'])), 'Rate'] <- 1
parts.lim[parts.lim[,'UL'] > 1 & !(is.na(parts.lim[,'UL'])), 'UL'] <- 1

#merge limits df with average hours df
parts.merge <- merge(parts.out, parts.lim, by=c('DateGroup','Version', 'Key'), all.y=TRUE)

#color points
parts.merge$PointColor <- 'Unknown'
for(i in 1:nrow(parts.merge)) {
  if(is.na(parts.merge$AvgHours[i])) {
    parts.merge$PointColor[i] <- 'Unknown'
  } else if(parts.merge$AvgHours[i] >= 0 & parts.merge$AvgHours[i] < 100) {
    parts.merge$PointColor[i] <- '0 hr - 99 hr'
  } else if(parts.merge$AvgHours[i] >= 100 & parts.merge$AvgHours[i] < 500) {
    parts.merge$PointColor[i] <- '100 hr - 499 hr'
  } else if(parts.merge$AvgHours[i] >= 500 & parts.merge$AvgHours[i] < 1000) {
    parts.merge$PointColor[i] <- '500 hr - 999 hr'
  } else if(parts.merge$AvgHours[i] >= 1000 & parts.merge$AvgHours[i] < 1500) {
    parts.merge$PointColor[i] <- '1000 hr - 1499 hr'
  } else if(parts.merge$AvgHours[i] >= 1500 & parts.merge$AvgHours[i] < 2000) {
    parts.merge$PointColor[i] <- '1500 hr - 1999 hr'
  } else if(parts.merge$AvgHours[i] >= 2000) {
    parts.merge$PointColor[i] <- '2000 hr +'
  } 
}

PointColorOrder <- c('0 hr - 99 hr','100 hr - 499 hr','500 hr - 999 hr','1000 hr - 1499 hr','1500 hr - 1999 hr','2000 hr +','Unknown')
pal.points <- c('red','darkorange','gold','forestgreen','blue','purple','black')
names(pal.points) <- PointColorOrder
parts.merge$PointColor <- factor(parts.merge$PointColor, levels = PointColorOrder, ordered = TRUE)
parts.merge <- parts.merge[with(parts.merge, order(PointColor)), ]

p.parts.onefive <- ggplot(subset(parts.merge, Version == 'FA1.5'), aes(x=DateGroup, y=Rate, group=Version, color=PointColor)) + geom_line(color='black') + geom_point() + scale_color_manual(name = 'Lifespan of Part', values = pal.points) + geom_line(aes(y=UL), color='blue', lty='dashed') + facet_wrap(~Key, scale='free_y') + scale_y_continuous(labels=percent) + labs(title='Part Replacement Rate per RMAs Shipped - FA 1.5:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks)
p.parts.two <- ggplot(subset(parts.merge, Version == 'FA2.0'), aes(x=DateGroup, y=Rate, group=Version, color=PointColor)) + geom_line(color='black') + geom_point() + scale_color_manual(name = 'Lifespan of Part', values = pal.points) + geom_line(aes(y=UL), color='blue', lty='dashed') + facet_wrap(~Key, scale='free_y') + scale_y_continuous(labels=percent) + labs(title='Part Replacement Rate per RMAs Shipped - FA 2.0:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks)
if(length(subset(parts.merge, Version == 'Torch')[,1]) > 0) {
  
  p.parts.torch <- ggplot(subset(parts.merge, Version == 'Torch'), aes(x=DateGroup, y=Rate, group=Version, color=PointColor)) + geom_line(color='black') + geom_point() + scale_color_manual(name = 'Lifespan of Part', values = pal.points) + geom_line(aes(y=UL), color='blue', lty='dashed') + facet_wrap(~Key, scale='free_y') + scale_y_continuous(labels=percent) + labs(title='Part Replacement Rate per RMAs Shipped - Torch:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks)  
} else {
  
  p.parts.torch <- ggplot() + labs(title='Part Replacement Rate per RMAs Shipped - Torch:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks)
}

#create 15 charts for service codes by category (per service WID 105) per RMAs shipped
codes.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', codes.df, c('Version','Key'), startDate, 'Record', 'sum', NA)
codes.merged <- merge(codes.fill, codeDescript.df, by.x='Key', by.y='Code')
codes.rate <- mergeCalSparseFrames(codes.merged, rmasShip.fill, c('DateGroup', 'Version'), c('DateGroup', 'Version'), 'Record', 'Record', NA, periods)
codes.lim <- addStatsToSparseHandledData(codes.rate, c('Version', 'Key'), lagPeriods, TRUE, 3, 'upper', keepPeriods=53)
codes.lim[,'Key'] <- as.integer(as.character(codes.lim[,'Key']))
codes.lim[codes.lim[,'Rate'] > 1 & !(is.na(codes.lim[,'Rate'])), 'Rate'] <- 1
codes.lim[codes.lim[,'UL'] > 1 & !(is.na(codes.lim[,'UL'])), 'UL'] <- 1
codes.lim[,'Code'] <- do.call(paste, c(codes.lim[,c('Key', 'Description')], sep='-'))
#FA1.5 codes
p.codes.15.1 <- ggplot(subset(codes.lim, Version == 'FA1.5' & Category == 'General Codes'), aes(x=DateGroup, y=Rate, group=Category, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + geom_line(aes(y=UL), color='blue', lty='dashed') + facet_wrap(~Code, scale='free_y') + scale_y_continuous(labels=percent) + labs(title='Code Usage Rate per RMAs Shipped - FA 1.5:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks) 
p.codes.15.2 <- ggplot(subset(codes.lim, Version == 'FA1.5' & (Category == 'Plunger block' | Category == 'Manifold')), aes(x=DateGroup, y=Rate, group=Category, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + geom_line(aes(y=UL), color='blue', lty='dashed') + facet_wrap(~Code, scale='free_y') + scale_y_continuous(labels=percent) + labs(title='Code Usage Rate per RMAs Shipped - FA 1.5:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks) 
p.codes.15.3 <- ggplot(subset(codes.lim, Version == 'FA1.5' & (Category == 'Optics' | Category == 'Window Bladder')), aes(x=DateGroup, y=Rate, group=Category, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + geom_line(aes(y=UL), color='blue', lty='dashed') + facet_wrap(~Code, scale='free_y') + scale_y_continuous(labels=percent) + labs(title='Code Usage Rate per RMAs Shipped - FA 1.5:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks) 
p.codes.15.4 <- ggplot(subset(codes.lim, Version == 'FA1.5' & (Category == 'Lid latch' | Category == 'Reservoir and tubing' | Category == 'Firmware' | Category == 'Laptop')), aes(x=DateGroup, y=Rate, group=Category, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + geom_line(aes(y=UL), color='blue', lty='dashed') + facet_wrap(~Code, scale='free_y') + scale_y_continuous(labels=percent) + labs(title='Code Usage Rate per RMAs Shipped - FA 1.5:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks) 
p.codes.15.5 <- ggplot(subset(codes.lim, Version == 'FA1.5' & (Category == 'Compressor' | Category == 'Mag bead' | Category == 'Bead beater')), aes(x=DateGroup, y=Rate, group=Category, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + geom_line(aes(y=UL), color='blue', lty='dashed') + facet_wrap(~Code, scale='free_y') + scale_y_continuous(labels=percent) + labs(title='Code Usage Rate per RMAs Shipped - FA 1.5:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks) 
p.codes.15.6 <- ggplot(subset(codes.lim, Version == 'FA1.5' & (Category == 'Boards and power supply' | Category == 'Chassis and general mechanical')), aes(x=DateGroup, y=Rate, group=Category, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + geom_line(aes(y=UL), color='blue', lty='dashed') + facet_wrap(~Code, scale='free_y') + scale_y_continuous(labels=percent) + labs(title='Code Usage Rate per RMAs Shipped - FA 1.5:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks) 
p.codes.15.7 <- ggplot(subset(codes.lim, Version == 'FA1.5' & (Category == 'Peltier' | Category == 'Seal bar')), aes(x=DateGroup, y=Rate, group=Category, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + geom_line(aes(y=UL), color='blue', lty='dashed') + facet_wrap(~Code, scale='free_y') + scale_y_continuous(labels=percent) + labs(title='Code Usage Rate per RMAs Shipped - FA 1.5:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks) 
#F2.0 codes
p.codes.20.1 <- ggplot(subset(codes.lim, Version == 'FA2.0' & Category == 'General Codes'), aes(x=DateGroup, y=Rate, group=Category, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + geom_line(aes(y=UL), color='blue', lty='dashed') + facet_wrap(~Code, scale='free_y') + scale_y_continuous(labels=percent) + labs(title='Code Usage Rate per RMAs Shipped - FA 2.0:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks) 
p.codes.20.2 <- ggplot(subset(codes.lim, Version == 'FA2.0' & (Category == 'Plunger block' | Category == 'Manifold')), aes(x=DateGroup, y=Rate, group=Category, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + geom_line(aes(y=UL), color='blue', lty='dashed') + facet_wrap(~Code, scale='free_y') + scale_y_continuous(labels=percent) + labs(title='Code Usage Rate per RMAs Shipped - FA 2.0:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks) 
p.codes.20.3 <- ggplot(subset(codes.lim, Version == 'FA2.0' & (Category == 'Optics' | Category == 'Window Bladder')), aes(x=DateGroup, y=Rate, group=Category, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + geom_line(aes(y=UL), color='blue', lty='dashed') + facet_wrap(~Code, scale='free_y') + scale_y_continuous(labels=percent) + labs(title='Code Usage Rate per RMAs Shipped - FA 2.0:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks) 
p.codes.20.4 <- ggplot(subset(codes.lim, Version == 'FA2.0' & (Category == 'Lid latch' | Category == 'Reservoir and tubing' | Category == 'Firmware' | Category == 'Laptop')), aes(x=DateGroup, y=Rate, group=Category, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + geom_line(aes(y=UL), color='blue', lty='dashed') + facet_wrap(~Code, scale='free_y') + scale_y_continuous(labels=percent) + labs(title='Code Usage Rate per RMAs Shipped - FA 2.0:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks) 
p.codes.20.5 <- ggplot(subset(codes.lim, Version == 'FA2.0' & (Category == 'Compressor' | Category == 'Mag bead' | Category == 'Bead beater')), aes(x=DateGroup, y=Rate, group=Category, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + geom_line(aes(y=UL), color='blue', lty='dashed') + facet_wrap(~Code, scale='free_y') + scale_y_continuous(labels=percent) + labs(title='Code Usage Rate per RMAs Shipped - FA 2.0:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks) 
p.codes.20.6 <- ggplot(subset(codes.lim, Version == 'FA2.0' & (Category == 'Boards and power supply' | Category == 'Chassis and general mechanical')), aes(x=DateGroup, y=Rate, group=Category, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + geom_line(aes(y=UL), color='blue', lty='dashed') + facet_wrap(~Code, scale='free_y') + scale_y_continuous(labels=percent) + labs(title='Code Usage Rate per RMAs Shipped - FA 2.0:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks) 
p.codes.20.7 <- ggplot(subset(codes.lim, Version == 'FA2.0' & (Category == 'Peltier' | Category == 'Seal bar')), aes(x=DateGroup, y=Rate, group=Category, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + geom_line(aes(y=UL), color='blue', lty='dashed') + facet_wrap(~Code, scale='free_y') + scale_y_continuous(labels=percent) + labs(title='Code Usage Rate per RMAs Shipped - FA 2.0:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks) 
#Torch codes - can expand out to more charts later
p.codes.torch.1 <- ggplot(subset(codes.lim, Version == 'Torch' & (Category == 'General Codes' | Category == 'Bead beater')), aes(x=DateGroup, y=Rate, group=Category, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + geom_line(aes(y=UL), color='blue', lty='dashed') + facet_wrap(~Code, scale='free_y') + scale_y_continuous(labels=percent) + labs(title='Code Usage Rate per RMAs Shipped - Torch:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks) 
p.codes.torch.2 <- ggplot(subset(codes.lim, Version == 'Torch' & (Category == 'Window Bladder' | Category == 'Manifold' | Category == 'Optics')), aes(x=DateGroup, y=Rate, group=Category, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + geom_line(aes(y=UL), color='blue', lty='dashed') + facet_wrap(~Code, scale='free_y') + scale_y_continuous(labels=percent) + labs(title='Code Usage Rate per RMAs Shipped - Torch:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks) 
p.codes.torch.3 <- ggplot(subset(codes.lim, Version == 'Torch' & (Category == 'Seal bar' | Category == 'Reservoir and tubing' | Category == 'Compressor' | Category == 'Peltier' | Category == 'Boards and power supply')), aes(x=DateGroup, y=Rate, group=Category, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + geom_line(aes(y=UL), color='blue', lty='dashed') + facet_wrap(~Code, scale='free_y') + scale_y_continuous(labels=percent) + labs(title='Code Usage Rate per RMAs Shipped - Torch:\nFYI Limit = +2 standard deviations',x='Date\n(Year-Week)', y='4-week Rolling Average Rate') + theme(axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks) 

# create charts for early failures per instruments shipped - total, not by version
ships.fill =
  rbind(instShip.df %>% mutate(Department = 'Production'), 
        rmasShip.df %>% mutate(Department = 'Service')) %>%
  inner_join(calendar.df, by = 'Date') %>%
  group_by(DateGroup, Department) %>% summarize(Shipments = sum(Record)) %>% ungroup() %>%
  complete(DateGroup = unique(calendar.df$DateGroup), Department, fill = list(Shipments = 0))
failures.fill = failures.df %>%
  inner_join(calendar.df, by = 'Date') %>%
  group_by(DateGroup, Key) %>% summarize(Failures = sum(Record)) %>% ungroup() %>%
  complete(DateGroup = unique(calendar.df$DateGroup), Key, fill = list(Failures = 0))
failures.rate = failures.fill %>%
  mutate(Department = ifelse(Key %in% c('DOA', 'ELF'), 'Production', 'Service')) %>%
  inner_join(ships.fill, by = c('DateGroup', 'Department')) %>%
  group_by(Key) %>% arrange(DateGroup) %>%
  mutate(Num = rollapplyr(Failures, periods, sum, fill = NA),
         Denom = rollapplyr(Shipments, periods, sum, fill = NA),
         Rate = Num / Denom)
failures.lim = failures.rate %>%
  group_by(Department, DateGroup) %>% 
  summarize(TotalNum = sum(Num), TotalRate = sum(Rate)) %>% 
  mutate(Mean = rollapplyr(lag(TotalRate, lagPeriods), 50, mean, fill = NA),
         SD = rollapplyr(lag(TotalRate, lagPeriods), 50, sd, fill = NA),
         UL = Mean + 3*SD) %>% ungroup() %>%
  inner_join(failures.rate, by=c('Department', 'DateGroup'))
# annotations for early failure rate
#x_positions <- c('2016-08')
#fail.annotations <- c('CAPA-13226')
#y_positions <- max(failures.lim[as.character(failures.lim[,'DateGroup']) %in% x_positions, 'UL']) + 0.02
pal.fail <- createPaletteOfVariableLength(as.data.frame(failures.lim), 'Key')
p.failures.all <- failures.lim %>%
  filter(DateGroup >= dateBreaks[1]) %>%
  ggplot(aes(x=DateGroup, y=Rate, fill=Key)) + 
  geom_bar(stat='identity') + 
  facet_wrap(~Department, ncol=1) + 
  scale_fill_manual(values=pal.fail) + 
  scale_y_continuous(labels=percent) + 
  labs(title='Early Failures per Instruments Shipped:\nLimit = +3 standard deviations',
       x='Date\n(Year-Week)', 
       y='4-week Rolling Average Rate') + 
  theme(axis.text.x=element_text(angle=90, hjust=1)) + 
  scale_x_discrete(breaks = dateBreaks) + 
  geom_line(aes(y = UL, group = 1), color='red', lty=2) +
  geom_text(aes(y = TotalRate, label = TotalNum), nudge_y = .005, size = 5) +
  geom_text(aes(y = 0, label = Denom), nudge_y = -.005, size = 3)#+ annotate("text",x=x_positions,y=y_positions,label=fail.annotations, size=4)

# early failures by version and department and type
ships.fill.version =
  rbind(instShip.df %>% mutate(Department = 'Production'), 
        rmasShip.df %>% mutate(Department = 'Service')) %>%
  inner_join(calendar.df, by = 'Date') %>%
  group_by(DateGroup, Department, Version) %>% summarize(Shipments = sum(Record)) %>% ungroup() %>%
  complete(DateGroup = unique(calendar.df$DateGroup), Department, Version, fill = list(Shipments = 0))
failures.fill.version = failures.df %>%
  inner_join(calendar.df, by = 'Date') %>%
  group_by(DateGroup, Key, Version) %>% summarize(Failures = sum(Record)) %>% ungroup() %>%
  complete(DateGroup = unique(calendar.df$DateGroup), Key, Version, fill = list(Failures = 0))
failures.rate.version = failures.fill.version %>%
  mutate(Department = ifelse(Key %in% c('DOA', 'ELF'), 'Production', 'Service')) %>%
  inner_join(ships.fill.version, by = c('DateGroup', 'Department', 'Version')) %>%
  filter(!(Department == 'Production' & Version == 'FA1.5')) %>%
  group_by(Key, Version) %>% arrange(DateGroup) %>%
  mutate(RollingNum = rollapplyr(Failures, periods, sum, fill = NA),
         RollingDenom = rollapplyr(Shipments, periods, sum, fill = NA),
         RollingRate = RollingNum / RollingDenom,
         Rate = Failures / Shipments)
failures.ytd.version = failures.rate.version %>%
  filter(DateGroup >= '2017-01', !(Department == 'Production' & Version == 'FA1.5')) %>%
  group_by(DateGroup, Department, Version) %>% 
  summarize(Failures = sum(Failures), Shipments = mean(Shipments)) %>% ungroup() %>%
  group_by(Department, Version) %>% arrange(DateGroup) %>%
  mutate(YTDNum = cumsum(Failures), 
         YTDDenom = cumsum(Shipments),
         YTDRate = YTDNum / YTDDenom) 
p.earlyfailures <- failures.rate.version %>%
  filter(DateGroup >= dateBreaks[1]) %>%
  ggplot(aes(x=DateGroup, y=RollingRate, fill=Key)) + 
  geom_col() + 
  geom_line(data = failures.ytd.version, aes(x=DateGroup, y=YTDRate, group=1), 
            inherit.aes = FALSE, size=1.25, linetype=2, colour="black") +
  facet_grid(Department~Version) + 
  scale_fill_manual(values=createPaletteOfVariableLength(as.data.frame(failures.rate.version), 'Key'), name='') + 
  scale_y_continuous(labels=percent) + 
  labs(title='Early Failures per Instruments Shipped:\nGoal = 3.5% of Instruments Shipped',
       x='Date\n(Year-Week)', 
       y='4-week Rolling Average Rate') + 
  theme(axis.text.x=element_text(angle=90, hjust=1)) + 
  scale_x_discrete(breaks = dateBreaks) + 
  geom_hline(aes(yintercept=0.035), color='darkgreen', lty=2)
p.earlyfailures.count <- failures.rate.version %>%
  filter(DateGroup >= dateBreaks[1]) %>%
  ggplot(aes(x=DateGroup, y=Failures, fill=Key)) + 
  geom_bar(stat='identity') + 
  facet_grid(Department~Version) + 
  scale_fill_manual(values=createPaletteOfVariableLength(as.data.frame(failures.rate.version), 'Key'), name='') + 
  labs(title='Count of Early Failures',x='Reported Date\n(Year-Week)', y='Count') + 
  theme(axis.text.x=element_text(angle=90, hjust=1)) + 
  scale_x_discrete(breaks = dateBreaks)

# create the charts for early failures per instruments shipped in a month (non-rolling) for each instrument version
# rmasShip.month <- aggregateAndFillDateGroupGaps(calendar.df.month, 'Month', rmasShip.df, c('Version'), startMonth.plot, 'Record', 'sum', 0)
# newShip.month <- aggregateAndFillDateGroupGaps(calendar.df.month, 'Month', instShip.df, c('Version'), startMonth.plot, 'Record', 'sum', 0)
# failures.month <- aggregateAndFillDateGroupGaps(calendar.df.month, 'Month', failures.df, c('Version','Key','Department'), startMonth.plot, 'Record', 'sum', 0)
# prod.fail.month <- mergeCalSparseFrames(subset(failures.month, Department=='Production' & Version != 'FA1.5'), newShip.month, c('DateGroup','Version'), c('DateGroup','Version'), 'Record', 'Record', 0, 0)
# prod.fail.month <- prod.fail.month[!(prod.fail.month$Version == 'Torch' & prod.fail.month$DateGroup < '2016-07'), ]
# serv.fail.month <- mergeCalSparseFrames(subset(failures.month, Department=='Service'), rmasShip.month, c('DateGroup','Version'), c('DateGroup','Version'), 'Record', 'Record', 0, 0)
# failures.month[,'ComboCat'] <- do.call(paste, c(failures.month[,c('Version','Key','Department')], sep=','))
# failures.month.cum <- do.call(rbind, lapply(1:length(unique(failures.month$ComboCat)), function(x) data.frame(DateGroup =  failures.month[failures.month$ComboCat == unique(failures.month$ComboCat)[x], 'DateGroup'], ComboCat = unique(failures.month$ComboCat)[x], CumFail = sapply(1:length(failures.month[failures.month$ComboCat == unique(failures.month$ComboCat)[x], 'DateGroup']), function(y) sum(failures.month[failures.month$ComboCat == unique(failures.month$ComboCat)[x], 'Record'][1:y], na.rm = TRUE)))))
# failures.month.cum <- data.frame(DateGroup = failures.month.cum$DateGroup, Version = do.call(rbind, strsplit(as.character(failures.month.cum[,'ComboCat']), split=','))[,1], Key = do.call(rbind, strsplit(as.character(failures.month.cum[,'ComboCat']), split=','))[,2], Department = do.call(rbind, strsplit(as.character(failures.month.cum[,'ComboCat']), split=','))[,3], Record = failures.month.cum$CumFail)
# rmasShip.month.cum <- do.call(rbind, lapply(1:length(unique(rmasShip.month$Version)), function(x) data.frame(DateGroup = rmasShip.month[rmasShip.month$Version == unique(rmasShip.month$Version)[x], 'DateGroup'], Version = unique(rmasShip.month$Version)[x], Record = sapply(1:length(rmasShip.month[rmasShip.month$Version == unique(rmasShip.month$Version)[x], 'DateGroup']), function(y) sum(rmasShip.month[rmasShip.month$Version == unique(rmasShip.month$Version)[x],'Record'][1:y])))))
# rmasShip.month.cum <- rmasShip.month.cum[!(rmasShip.month.cum$Version == 'Torch' & as.character(rmasShip.month.cum$DateGroup) < '2016-07'), ] 
# newShip.month.cum <- do.call(rbind, lapply(1:length(unique(newShip.month$Version)), function(x) data.frame(DateGroup = newShip.month[newShip.month$Version == unique(newShip.month$Version)[x], 'DateGroup'], Version = unique(newShip.month$Version)[x], Record = sapply(1:length(newShip.month[newShip.month$Version == unique(newShip.month$Version)[x], 'DateGroup']), function(y) sum(newShip.month[newShip.month$Version == unique(newShip.month$Version)[x],'Record'][1:y])))))
# newShip.month.cum <- newShip.month.cum[!(newShip.month.cum$Version == 'Torch' & as.character(newShip.month.cum$DateGroup) < '2016-07'), ] 
# prod.fail.month.cum <- merge(subset(failures.month.cum, Department=='Production'), newShip.month.cum, by=c('DateGroup','Version'))
# prod.fail.month.cum$CumulativeRate <- with(prod.fail.month.cum, Record.x/Record.y)
# serv.fail.month.cum <- merge(subset(failures.month.cum, Department=='Service'), rmasShip.month.cum, by=c('DateGroup','Version'))
# serv.fail.month.cum$CumulativeRate <- with(serv.fail.month.cum, Record.x/Record.y)
# prod.fail.month <- merge(prod.fail.month, prod.fail.month.cum[,c('DateGroup','Version','Key','Department','CumulativeRate')], by=c('DateGroup','Version','Key','Department'))
# serv.fail.month <- merge(serv.fail.month, serv.fail.month.cum[,c('DateGroup','Version','Key','Department','CumulativeRate')], by=c('DateGroup','Version','Key','Department'))
startDateGroup = (tibble(Date = today() - months(11)) %>% left_join(calendar.df.month))$DateGroup
ships.fill.month =
  rbind(instShip.df %>% mutate(Department = 'Production'), 
        rmasShip.df %>% mutate(Department = 'Service')) %>%
  inner_join(calendar.df.month, by = 'Date') %>%
  group_by(DateGroup, Department, Version) %>% summarize(Shipments = sum(Record)) %>% ungroup() %>%
  complete(DateGroup = unique(calendar.df.month$DateGroup), Department, Version, fill = list(Shipments = 0))
failures.fill.month = failures.df %>%
  inner_join(calendar.df.month, by = 'Date') %>%
  group_by(DateGroup, Key, Version) %>% summarize(Failures = sum(Record)) %>% ungroup() %>%
  complete(DateGroup = unique(calendar.df.month$DateGroup), Key, Version, fill = list(Failures = 0))
failures.rate.month = failures.fill.month %>%
  mutate(Department = ifelse(Key %in% c('DOA', 'ELF'), 'Production', 'Service')) %>%
  inner_join(ships.fill.month, by = c('DateGroup', 'Department', 'Version')) %>%
  filter(!(Department == 'Production' & Version == 'FA1.5'), DateGroup >= startDateGroup) %>%
  group_by(Key, Version) %>% arrange(DateGroup) %>%
  mutate(Rate = Failures / Shipments,
         CumulativeRate = cumsum(Failures) / cumsum(Shipments))
pal.prod = createPaletteOfVariableLength(as.data.frame(filter(failures.rate.month, 
                                                              Department == 'Production')), 'Key')
p.prod.fail.month <- failures.rate.month %>%
  filter(Department == 'Production') %>%
  ggplot(aes(x=DateGroup, y=Rate, fill=Key)) + 
  geom_col() + 
  scale_fill_manual(values=pal.prod, name='') + 
  facet_wrap(~Version, ncol=1, scale='free_y') + 
  geom_line(aes(x=DateGroup, y=CumulativeRate, group=Key, color=Key), lwd=1.5, lty='dashed') + 
  scale_color_manual(values=c('darkblue', 'chocolate4'), guide=FALSE) + 
  scale_y_continuous(label=percent) + 
  theme(axis.text.x=element_text(angle=90, hjust=1)) + 
  labs(title='Early Failure Rates by Month: New Instruments\n(12 Month Cumulative Rate Overlay)', 
       x='Date\n(Year-Month)', 
       y='Failures/New Instruments Shipped')
pal.serv = createPaletteOfVariableLength(as.data.frame(filter(failures.rate.month, 
                                                              Department == 'Service')), 'Key')
p.serv.fail.month <- failures.rate.month %>%
  filter(Department == 'Service') %>%
  ggplot(aes(x=DateGroup, y=Rate, fill=Key)) + 
  geom_col() + 
  scale_fill_manual(values=pal.serv, name='') + 
  facet_wrap(~Version, ncol=1, scale='free_y') + 
  geom_line(aes(x=DateGroup, y=CumulativeRate, group=Key, color=Key), lwd=1.5, lty='dashed') + 
  scale_color_manual(values=c('darkblue', 'chocolate4'), guide=FALSE) +
  scale_y_continuous(label=percent) + 
  theme(axis.text.x=element_text(angle=90, hjust=1)) + 
  labs(title='Early Failure Rates by Month: Serviced Instruments\n(12 Month Cumulative Rate Overlay)', 
       x='Date\n(Year-Month)', 
       y='Failures/RMA Instruments Shipped')

# create the charts for early failures of computers per instruments shipped in a month (non-rolling) for each instrument version
computerEF.month <- aggregateAndFillDateGroupGaps(calendar.df.month, 'Month', computerEF.df, c('Version','Key'), startMonth.2, 'Record', 'sum', 0)
newShip.month <- aggregateAndFillDateGroupGaps(calendar.df.month, 'Month', compShip.df, c('Version'), startMonth.2, 'Record', 'sum', 0)
computerEF.fail.month <- mergeCalSparseFrames(subset(computerEF.month, Version!='FA1.5'), newShip.month, c('DateGroup','Version'), c('DateGroup','Version'), 'Record', 'Record', 0, 0)
#computerEF.fail.merge = merge(computerEF.fail.month, computerEF.month, by=c('DateGroup','Version','Key'))
computerEF.textShiftFA2 = max(filter(computerEF.fail.month, Version == 'FA2.0')$Rate)*.05;
computerEF.textShift = max(computerEF.fail.month$Rate)*.05;
computerEF.agg = aggregateAndFillDateGroupGaps(calendar.df.month, 'Month', computerEF.df, c('Version'), startMonth.2, 'Record', 'sum', 0)
computerEF.agg.rate = mergeCalSparseFrames(subset(computerEF.agg, Version!='FA1.5'), newShip.month, c('DateGroup','Version'), c('DateGroup','Version'), 'Record', 'Record', 0, 0)
computerEF.agg.merge = merge(computerEF.agg.rate, computerEF.agg, by=c('DateGroup','Version'))
p.computerEF.month <- 
  ggplot(computerEF.fail.month, aes(x=DateGroup, y=Rate, fill=Key)) + 
  geom_bar(stat='identity') + 
  scale_fill_manual(values=createPaletteOfVariableLength(computerEF.fail.month, 'Key'), name='') + 
  facet_wrap(~Version, ncol=1, scale='free_y') + 
  scale_y_continuous(label=percent) + 
  theme(text=element_text(size=20, face='bold'), 
        axis.text=element_text(size=20, face='bold', color='black'), 
        axis.text.x=element_text(angle=90, hjust=1)) + 
  labs(title='Computer Early Failure Rates by Month', 
       x='Date\n(Year-Month)', 
       y='Failures/New Computers Shipped (Count shown above)') + 
  geom_text(data=subset(computerEF.agg.merge,Record>0), 
            aes(x=DateGroup, y=Rate+ifelse(Version=='FA2.0', computerEF.textShiftFA2, computerEF.textShift), 
                label=Record), 
            inherit.aes=FALSE) 

# create the chart of top ten failed parts in the last 90 days
rootCause.agg <- with(rootCause.df, aggregate(cbind(thirtyDay, netSixtyDay, netNinetyDay, Record)~FailedPartDesc, FUN=sum))
rootCause.agg[,'FailedPartDesc'] <- factor(rootCause.agg[,'FailedPartDesc'], levels=unique(rootCause.agg[with(rootCause.agg, order(Record, decreasing = TRUE)), 'FailedPartDesc']))
rootCause.trim <- rootCause.agg[with(rootCause.agg, order(Record, decreasing = TRUE)), ][1:10, ]
rootCause.trim.30 <- rootCause.trim[,c('FailedPartDesc','thirtyDay')]; rootCause.trim.30[,'Key'] <- 'Thirty Day'
rootCause.trim.60 <- rootCause.trim[,c('FailedPartDesc','netSixtyDay')]; rootCause.trim.60[,'Key'] <- 'Sixty Day (net)'
rootCause.trim.90 <- rootCause.trim[,c('FailedPartDesc','netNinetyDay')]; rootCause.trim.90[,'Key'] <- 'Ninety Day (net)'
colnames(rootCause.trim.30)[grep('Day', colnames(rootCause.trim.30))] <- 'Record'
colnames(rootCause.trim.60)[grep('Day', colnames(rootCause.trim.60))] <- 'Record'
colnames(rootCause.trim.90)[grep('Day', colnames(rootCause.trim.90))] <- 'Record'
rootCause.trim <- rbind(rootCause.trim.30, rootCause.trim.60, rootCause.trim.90)
rootCause.trim <- merge(rootCause.trim, with(rootCause.trim, aggregate(Record~FailedPartDesc, FUN=sum)), by='FailedPartDesc')
rootCause.trim[,'FailedPartDesc'] <- factor(rootCause.trim[,'FailedPartDesc'], levels=unique(rootCause.trim[with(rootCause.trim, order(Record.y)), 'FailedPartDesc']))
pal.rootCause <- createPaletteOfVariableLength(rootCause.trim, 'Key')
p.rootcause <- ggplot(rootCause.trim[with(rootCause.trim, order(Key)), ], aes(x=FailedPartDesc, y=Record.x, fill=Key)) + geom_bar(stat='identity') + labs(title='Last 90 Days: Top Ten Failed Parts', x='Failed Part', y='Count of Occurrences') + coord_flip() + scale_fill_manual(values = pal.rootCause)

# need to add the leading indicator chart and the cumulative hours run chart here ......
ef.report.lead.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', leadingEF.df, c('Key','RecordedValue'), plot.startDate.week, 'Record', 'sum', 0)
ef.manf.lead.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', leadEFmanf.df, c('Key','RecordedValue'), plot.startDate.week, 'Record', 'sum', 0)
ef.manf.denom.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', instBuilt.df, c('Key'), plot.startDate.week, 'Record', 'sum', NA)
ef.report.lead.rate <- mergeCalSparseFrames(ef.report.lead.fill, complaints.fill, c('DateGroup'), c('DateGroup'), 'Record', 'Record', NA)
ef.manf.lead.rate <- mergeCalSparseFrames(ef.manf.lead.fill, ef.manf.denom.fill, c('DateGroup'), c('DateGroup'), 'Record', 'Record', NA)
pal.ef <- createPaletteOfVariableLength(ef.report.lead.rate,'RecordedValue')
# p.indicator <- ggplot(ef.report.lead.rate, aes(x=DateGroup, y=Rate, fill=RecordedValue)) + geom_bar(stat='identity') + facet_wrap(~Key) + scale_y_continuous(label=percent) + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, hjust=1), axis.text=element_text(color='black',size=fontSize,face=fontFace), legend.position='bottom') + scale_x_discrete(breaks=dateBreaks) + guides(fill=guide_legend(nrow=3, byrow=TRUE)) + labs(title='Customer Reported Failure Mode in Early Failure RMAs:\nBy Customer Reported Date of Failure ', x='Report Date\n(Year-Week)', y='Failures/Complaint RMAs Opened') + scale_fill_manual(values = pal.ef, name='')
p.indicator <- ggplot(ef.report.lead.fill, aes(x=DateGroup, y=Record, fill=RecordedValue)) + geom_bar(stat='identity') + facet_wrap(~Key) + theme(axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom') + scale_x_discrete(breaks=dateBreaks) + guides(fill=guide_legend(nrow=3, byrow=TRUE)) + labs(title='Customer Reported Failure Mode in Early Failure RMAs:\nBy Customer Reported Date of Failure ', x='Report Date\n(Year-Week)', y='Failures') + scale_fill_manual(values = pal.ef, name='')
p.badmanf <- ggplot(subset(ef.manf.lead.rate, Key %in% c('DOA','ELF')), aes(x=DateGroup, y=Rate, fill=RecordedValue)) + geom_bar(stat='identity') + facet_wrap(~Key) + scale_y_continuous(label=percent) + theme(axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom') + scale_x_discrete(breaks=dateBreaks) + guides(fill=guide_legend(nrow=3, byrow=TRUE)) + labs(title='Customer Reported Failure Mode in Early Life Failures:\nBy Manufacturing Date of Instrument', x='Maufacturing Date\n(Year-Week)', y='Failures/Instruments Built') + scale_fill_manual(values=pal.ef, name='')

#leading indicator chart for service
refurbServiced <- subset(instQCDate.df, Version == 'FA1.5R' | Version == 'FA2.0R')
refurbServiced.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', refurbServiced, c('Version'), plot.startDate.week, 'Record', 'sum', 0)
refurbServiced.agg <- with(refurbServiced.fill, aggregate(Record~DateGroup, FUN=sum))
ef.serv.lead.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', leadEFserv.df, c('Key', 'RecordedValue'), plot.startDate.week, 'Record', 'sum', 0)
ef.serv.lead.rate <- mergeCalSparseFrames(ef.serv.lead.fill, refurbServiced.agg, c('DateGroup'), c('DateGroup'), 'Record', 'Record', NA)
p.badservice <- ggplot(ef.serv.lead.rate, aes(x=DateGroup, y=Rate, fill=RecordedValue)) + geom_bar(stat='identity') + facet_wrap(~Key) + scale_y_continuous(label=percent) + theme(axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom') + scale_x_discrete(breaks=dateBreaks) + guides(fill=guide_legend(nrow=3, byrow=TRUE)) + labs(title='Customer Reported Failure Mode in Early Life Failures:\nBy Prior Service Date of Instrument', x='Prior Service Date\n(Year-Week)', y='Failures/Refurb Instruments Serviced') + scale_fill_manual(values=pal.ef, name='')

# field install base
install.base <- with(installed.df, aggregate(Record~Version+Region, FUN=sum))
p.fieldinstallbase <- ggplot(install.base, aes(x=Region, y=Record, fill=Region)) + geom_bar(stat='identity') + scale_fill_manual(name='', values=createPaletteOfVariableLength(install.base, 'Region')) + facet_wrap(~Version, scales = 'free_y') + theme(axis.text.x=element_text(vjust=0.5,color='black',size=fontSize), axis.text.y=element_text(hjust=1, color='black', size=fontSize)) + labs(title = 'Field Installed Base of Instruments', x = 'Geographic Region', y ='Instruments')
p.fieldinstallbase.pouch <- ggplot(subset(install.base, Version != 'Torch Base'), aes(x=Region, y=Record, fill=Version)) + geom_bar(stat='identity') + scale_fill_manual(name='', values=createPaletteOfVariableLength(install.base, 'Version')) + theme(axis.text.y=element_text(hjust=1, color='black', size=fontSize)) + labs(title = 'Field Installed Base of Pouch Running Units', x = 'Geographic Region', y ='Instruments')

# add code to plot the cumulative average hours run between failures in the install base
hours.df[,'YearMonth'] <- with(hours.df, ifelse(Month < 10, paste(Year,'-0',Month,sep=''), paste(Year,'-',Month,sep='')))
yearMonths <- unique(hours.df[,c('YearMonth')])
yearMonths <- yearMonths[order(yearMonths)]

x <- seq(1,length(hours.df$MTBF),1)
y <- hours.df$MTBF
y <- y[order(y)]
fit <- lm(y~x)
hoursBad <- cbind(y, dfbetas(fit))
hoursBad <- hoursBad[abs(hoursBad[,'x']) > 1,'y']
failures.clean <- hours.df[!(hours.df$MTBF %in% hoursBad), ]
failures.cleanfirst <- subset(failures.clean, VisitNo == 1)

avgMTBF <- c()
for (i in 1:length(yearMonths)) {
  
  periodFail <- failures.clean[failures.clean[,'YearMonth'] <= yearMonths[i], ]
  periodMTBF <- data.frame(YearMonth = yearMonths[i], MTBF_cum=mean(periodFail$MTBF))
  avgMTBF <- rbind(avgMTBF, periodMTBF)
}
# strip out MTBFs that are less than 100 hours
avgMTBF.strip <- c()
for (i in 1:length(yearMonths)) {
  
  periodFail.strip <- failures.clean[failures.clean[,'YearMonth'] <= yearMonths[i] & failures.clean$MTBF > 100, ]
  periodMTBF.strip <- data.frame(YearMonth = yearMonths[i], MTBF_cum=mean(periodFail.strip$MTBF))
  avgMTBF.strip <- rbind(avgMTBF.strip, periodMTBF.strip)
}
#strip out MTBFs less than 100 hours and only use first time failures
avgMTBF.first <- c()
for (i in 1:length(yearMonths)) {
  
  periodFail.first <- failures.cleanfirst[failures.cleanfirst[,'YearMonth'] <= yearMonths[i] & failures.cleanfirst$MTBF > 100, ]
  periodMTBF.first <- data.frame(YearMonth = yearMonths[i], MTBF_cum=mean(periodFail.first$MTBF))
  avgMTBF.first <- rbind(avgMTBF.first, periodMTBF.first)
}

# make the chart... add bars with average hours by month under the line chart
qtrBreaks <- yearMonths[seq(1,i,3)]
exclude <- ifelse(month(Sys.Date()) < 10, paste(year(Sys.Date()),month(Sys.Date()),sep='-0'), paste(year(Sys.Date()),month(Sys.Date()),sep='-'))
barMTBF <- with(failures.clean, aggregate(MTBF~YearMonth, FUN=mean))
barMTBF <- barMTBF[barMTBF[,'YearMonth'] != exclude, ]
p <- ggplot(barMTBF, aes(x=YearMonth, y=MTBF)) + geom_bar(stat='identity', fill='dodgerblue') + geom_line(aes(x=YearMonth, y=MTBF_cum, group=1), color='blue', data = avgMTBF) + geom_point(aes(x=YearMonth, y=MTBF_cum), color='blue', data = avgMTBF)
p <- p + theme(axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom') + scale_x_discrete(breaks=qtrBreaks)
p.mtbf <- p + labs(title='Average Hours Run Between Failures:\nCumulative Field Population', x='Date', y='Average Hours Between Failures')
# stripped version
barMTBF.strip <- with(failures.clean[failures.clean$MTBF > 100,], aggregate(MTBF~YearMonth, FUN=mean))
barMTBF.strip <- barMTBF.strip[barMTBF.strip[,'YearMonth'] != exclude, ]
pstripped <- ggplot(barMTBF.strip, aes(x=YearMonth, y=MTBF)) + geom_bar(stat='identity', fill='dodgerblue') + geom_line(aes(x=YearMonth, y=MTBF_cum, group=1), color='blue', data = avgMTBF.strip) + geom_point(aes(x=YearMonth, y=MTBF_cum), color='blue', data = avgMTBF.strip)
pstripped <- pstripped + theme(axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom') + scale_x_discrete(breaks=qtrBreaks)
p.mtbf.stripped <- pstripped + labs(title='Average Hours Run Between Failures:\nCumulative Field Population with Early Failures Removed', x='Date', y='Average Hours Between Failures')
# first failures only, no early failures
barMTBF.first <- with(failures.cleanfirst[failures.cleanfirst$MTBF > 100,], aggregate(MTBF~YearMonth, FUN=mean))
barMTBF.first <- barMTBF.first[barMTBF.first[,'YearMonth'] != exclude, ]
pfirst <- ggplot(barMTBF.first, aes(x=YearMonth, y=MTBF)) + geom_bar(stat='identity', fill='dodgerblue') + geom_line(aes(x=YearMonth, y=MTBF_cum, group=1), color='blue', data = avgMTBF.first) + geom_point(aes(x=YearMonth, y=MTBF_cum), color='blue', data = avgMTBF.first)
pfirst <- pfirst + theme(axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom') + scale_x_discrete(breaks=qtrBreaks)
p.mtbf.first <- pfirst + labs(title='Average Hours Run To First Failure:\nCumulative Field Population with Early Failures Removed', x='Date', y='Average Hours To Failure')

# make the denominator charts
instShip.ver.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', instShip.df, c('Version','Key'), plot.startDate.week, 'Record', 'sum', 0)
rmasShip.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', rmasShip.df, c('Version','Key'), plot.startDate.week, 'Record', 'sum', NA)
p.denom.rmasShipped <- ggplot(rmasShip.fill, aes(x=DateGroup, y=Record, fill=Version)) + geom_bar(stat='identity') + scale_fill_manual(values=createPaletteOfVariableLength(rmasShip.fill, 'Version')) + theme(axis.text.x=element_text(angle=90, hjust=1), plot.subtitle=element_text(hjust=0.5)) + scale_x_discrete(breaks = dateBreaks) + labs(title='RMAs Shipped by Version', subtitle = 'QC Date used', y='Instruments Shipped', x='Ship Date\n(Year-Week)')
p.denom.newInstShipped <- ggplot(instShip.ver.fill, aes(x=DateGroup, y=Record, fill=Version)) + geom_bar(stat='identity') + scale_fill_manual(values=createPaletteOfVariableLength(instShip.ver.fill, 'Version')) + theme(axis.text.x=element_text(angle=90, hjust=1)) + scale_x_discrete(breaks = dateBreaks) + labs(title='New Instruments Shipped by Version', y='New Instruments Shipped', x='Ship Date\n(Year-Week)')

# Send alert to DJ Holden if new computer ELF/DOA received
computerEFFilename = '../lastComputerEFTicket.rda'
if(file.exists(computerEFFilename)){
  lastComputerEFTicket = readRDS(computerEFFilename)
}else{
  lastComputerEFTicket = 61178;
}
newComputerEFTickets = subset(computerEF.df,Received==1 & TicketId>lastComputerEFTicket);
if(nrow(newComputerEFTickets)>0){
  from <- 'brent.kerby@biofiredx.com'
  to <- 'DJ.Holden@biofiredx.com'
  subject <- paste('Automated alert: Computer early failure received');
  body <- paste(newComputerEFTickets$Version,
                'computer',newComputerEFTickets$LotSerialNumber,'has been recorded as received in',newComputerEFTickets$TicketString,collapse='\n')
  mailControl <- list(smtpServer="webmail.biofiredx.com")
  maxTicket = max(newComputerEFTickets$TicketId)
  sendmail(from=from,to=to,subject=subject,msg=body,control=mailControl)
  saveRDS(maxTicket,file=computerEFFilename)
}

# Special chart - Return and Failure Percentage by Shipment Month of Instrument
# find a rate of Returned/Shipped in the month as well as a rate of Failures/Shipped
track.df[,'PercentReturned'] <- with(track.df, Returned/Shipments)
track.df[,'PercentFailures'] <- with(track.df, FailCount/Shipments)
track.df[,'DateGroup'] <- with(track.df, ifelse(Month < 10, paste(Year, Month, sep='-0'), paste(Year, Month, sep='-')))
track.df[,'Date'] <- as.Date(paste(track.df$DateGroup,'-01', sep=''))
# make 3 charts
p1.shipments <- ggplot(subset(track.df, DateGroup >= startMonth.2), aes(x=DateGroup, y=Shipments, fill='Instrument Shipments')) + geom_bar(stat='identity') + scale_fill_manual(name='', values='lightskyblue2') + theme(panel.background = element_blank(), panel.grid.major.y = element_blank(), panel.grid.minor.y = element_blank(),axis.text.x=element_blank(), axis.title.x=element_blank(), axis.ticks.x = element_blank(), legend.position = 'bottom', legend.justification = 'right') + labs(title='', x = '', y='New Instrument Shipments')
p2.percents <- ggplot(subset(track.df, DateGroup >= startMonth.2), aes(x=DateGroup, y=PercentReturned, group=1, colour='Percent Returned')) + geom_line() + geom_point() + geom_line(aes(x=DateGroup, y=PercentFailures, group=1, color='Failures/Instrument Shipments')) + geom_point(aes(x=DateGroup, y=PercentFailures, group=1, colour='Failures/Instrument Shipments')) + scale_color_manual(name='', values = c('black', 'blue')) + scale_y_continuous(limits = c(0,1.5), labels = percent, minor_breaks = seq(0.1,1.5,0.1)) + theme(panel.background = element_blank(), panel.grid.major = element_blank(), panel.grid.minor = element_blank(), axis.text.x=element_blank(), axis.title.x=element_blank(), axis.ticks.x = element_blank(), legend.position = 'bottom', legend.justification = 'left') + labs(title = '', x='', y='Failures/Instrument Shipments,\nReturned/Instrument Shipments')
p3.panel <- ggplot(subset(track.df, DateGroup >= startMonth.2), aes(x=DateGroup, y=PercentReturned, group=1, colour='Percent Returned')) + geom_line() + geom_point() + geom_line(aes(x=DateGroup, y=PercentFailures, group=1, color='Failures/Instrument Shipments')) + geom_point(aes(x=DateGroup, y=PercentFailures, group=1, colour='Failures/Instrument Shipments')) + scale_color_manual(name='', values = c('black', 'blue')) + scale_y_continuous(limits = c(0,1.5), labels = percent, minor_breaks = seq(0.1,1.5,0.1)) + theme(panel.grid.major.x = element_blank(), panel.grid.minor.x = element_blank(), panel.grid.major.y = element_line(color='grey'), panel.grid.minor.y = element_line(color='grey'), legend.position = 'bottom', legend.justification = 'left', axis.text.x=element_text(angle=90, hjust=1), plot.margin = margin(0.5,0.5,2,0.5,'cm')) + labs(title = 'Return and Failure Percentage by Shipment Month of Instrument', x='Date\n(Year-Month)', y='Failures/Instrument Shipments,\nReturned/Instrument Shipments')
# function to invert 2nd y axis
hinvert_title_grob <- function(grob){
  # Swap the widths
  widths <- grob$widths
  grob$widths[1] <- widths[3]
  grob$widths[3] <- widths[1]
  grob$vp[[1]]$layout$widths[1] <- widths[3]
  grob$vp[[1]]$layout$widths[3] <- widths[1]
  # Fix the justification
  grob$children[[1]]$hjust <- 1 - grob$children[[1]]$hjust
  grob$children[[1]]$vjust <- 1 - grob$children[[1]]$vjust
  grob$children[[1]]$x <- unit(1, "npc") - grob$children[[1]]$x
  grob
}
# Get the ggplot grobs
g1 <- ggplotGrob(p1.shipments)
g2 <- ggplotGrob(p2.percents)
g3 <- ggplotGrob(p3.panel)
# Get the location of the plot panel and legend in g1
pp <- c(subset(g1$layout, name == "panel", se = t:r))
pp2 <- c(subset(g1$layout, name == "guide-box", se = t:r))
# Overlap panel for first plot on top of third plot and then second plot on that
g4 <- gtable_add_grob(g3, g1$grobs[[which(g1$layout$name == "panel")]], pp$t, pp$l, pp$b, pp$l, name='c')
g4 <- gtable_add_grob(g4, g2$grobs[[which(g2$layout$name == "panel")]], pp$t, pp$l, pp$b, pp$l, name='a')
# Add legend from g1
g4 <- gtable_add_grob(g4, g1$grobs[[which(g1$layout$name == "guide-box")]], pp2$t, pp2$l, pp2$b, pp2$l, name='b')
# Get the y axis title from g1
index <- which(g1$layout$name == "ylab-l") # Which grob contains the y axis title?
ylab <- g1$grobs[[index]]                # Extract that grob
ylab <- hinvert_title_grob(ylab)         # Swap margins and fix justifications
# Put the transformed label on the right side of g4
g4 <- gtable_add_cols(g4, g1$widths[g1$layout[index, ]$l], pp$r)
g4 <- gtable_add_grob(g4, ylab, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "ylab-r")
# Get the y axis from g1 (axis line, tick marks, and tick mark labels)
index <- which(g1$layout$name == "axis-l")  # Which grob
yaxis <- g1$grobs[[index]]                  # Extract the grob
yaxis$children[[1]]$x <- unit.c(unit(0, "npc"), unit(0, "npc"))
ticks <- yaxis$children[[2]]
ticks$widths <- rev(ticks$widths)
ticks$grobs <- rev(ticks$grobs)
ticks$grobs[[1]]$x <- ticks$grobs[[1]]$x - unit(1, "npc") + unit(3, "pt")
ticks$grobs[[2]] <- hinvert_title_grob(ticks$grobs[[2]])
yaxis$children[[2]] <- ticks
# Put the transformed yaxis on the right side of g4
g4 <- gtable_add_cols(g4, g1$widths[g1$layout[index, ]$l], pp$r)
g4 <- gtable_add_grob(g4, yaxis, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "axis-r")
g4a <- g4
# grid.draw(g4)

# Special chart - Return and Failure Percentage by Shipment Month of Instrument (Domestic shipments only)
# find a rate of Returned/Shipped in the month as well as a rate of Failures/Shipped
track.df[,'PercentDomesticReturned'] <- with(track.df, DomesticReturned/DomesticShipments)
track.df[,'PercentDomesticFailures'] <- with(track.df, DomesticFailCount/DomesticShipments)
track.df[,'DateGroup'] <- with(track.df, ifelse(Month < 10, paste(Year, Month, sep='-0'), paste(Year, Month, sep='-')))
track.df[,'Date'] <- as.Date(paste(track.df$DateGroup,'-01', sep=''))
# make 3 charts
p1.shipments <- ggplot(subset(track.df, DateGroup >= startMonth.2), aes(x=DateGroup, y=DomesticShipments, fill='Instrument Domestic Shipments')) + geom_bar(stat='identity') + scale_fill_manual(name='', values='lightskyblue2') + theme(panel.background = element_blank(), panel.grid.major.y = element_blank(), panel.grid.minor.y = element_blank(),axis.text.x=element_blank(), axis.title.x=element_blank(), axis.ticks.x = element_blank(), legend.position = 'bottom', legend.justification = 'right') + labs(title='', x = '', y='New Instrument Domestic Shipments')
p2.percents <- ggplot(subset(track.df, DateGroup >= startMonth.2), aes(x=DateGroup, y=PercentDomesticReturned, group=1, colour='Percent Returned')) + geom_line() + geom_point() + geom_line(aes(x=DateGroup, y=PercentDomesticFailures, group=1, color='Failures/Instrument Domestic Shipments')) + geom_point(aes(x=DateGroup, y=PercentDomesticFailures, group=1, colour='Failures/Instrument Domestic Shipments')) + scale_color_manual(name='', values = c('black', 'blue')) + scale_y_continuous(limits = c(0,1.5), labels = percent, minor_breaks = seq(0.1,1.5,0.1)) + theme(panel.background = element_blank(), panel.grid.major = element_blank(), panel.grid.minor = element_blank(), axis.text.x=element_blank(), axis.title.x=element_blank(), axis.ticks.x = element_blank(), legend.position = 'bottom', legend.justification = 'left') + labs(title = '', x='', y='Failures/Instrument Domestic Shipments,\nReturned/Instrument Domestic Shipments')
p3.panel <- ggplot(subset(track.df, DateGroup >= startMonth.2), aes(x=DateGroup, y=PercentDomesticReturned, group=1, colour='Percent Returned')) + geom_line() + geom_point() + geom_line(aes(x=DateGroup, y=PercentDomesticFailures, group=1, color='Failures/Instrument Shipments')) + geom_point(aes(x=DateGroup, y=PercentDomesticFailures, group=1, colour='Failures/Instrument Shipments')) + scale_color_manual(name='', values = c('black', 'blue')) + scale_y_continuous(limits = c(0,1.5), labels = percent, minor_breaks = seq(0.1,1.5,0.1)) + theme(panel.grid.major.x = element_blank(), panel.grid.minor.x = element_blank(), panel.grid.major.y = element_line(color='grey'), panel.grid.minor.y = element_line(color='grey'), legend.position = 'bottom', legend.justification = 'left', axis.text.x=element_text(angle=90, hjust=1), plot.margin = margin(0.5,0.5,2,0.5,'cm')) + labs(title = 'Domestic Return and Failure Percentage by Shipment Month of Instrument', x='Date\n(Year-Month)', y='Failures/Instrument Domestic Shipments,\nReturned/Instrument Domestic Shipments')
# function to invert 2nd y axis
hinvert_title_grob <- function(grob){
  # Swap the widths
  widths <- grob$widths
  grob$widths[1] <- widths[3]
  grob$widths[3] <- widths[1]
  grob$vp[[1]]$layout$widths[1] <- widths[3]
  grob$vp[[1]]$layout$widths[3] <- widths[1]
  # Fix the justification
  grob$children[[1]]$hjust <- 1 - grob$children[[1]]$hjust
  grob$children[[1]]$vjust <- 1 - grob$children[[1]]$vjust
  grob$children[[1]]$x <- unit(1, "npc") - grob$children[[1]]$x
  grob
}
# Get the ggplot grobs
g1 <- ggplotGrob(p1.shipments)
g2 <- ggplotGrob(p2.percents)
g3 <- ggplotGrob(p3.panel)
# Get the location of the plot panel and legend in g1
pp <- c(subset(g1$layout, name == "panel", se = t:r))
pp2 <- c(subset(g1$layout, name == "guide-box", se = t:r))
# Overlap panel for first plot on top of third plot and then second plot on that
g4 <- gtable_add_grob(g3, g1$grobs[[which(g1$layout$name == "panel")]], pp$t, pp$l, pp$b, pp$l, name='c')
g4 <- gtable_add_grob(g4, g2$grobs[[which(g2$layout$name == "panel")]], pp$t, pp$l, pp$b, pp$l, name='a')
# Add legend from g1
g4 <- gtable_add_grob(g4, g1$grobs[[which(g1$layout$name == "guide-box")]], pp2$t, pp2$l, pp2$b, pp2$l, name='b')
# Get the y axis title from g1
index <- which(g1$layout$name == "ylab-l") # Which grob contains the y axis title?
ylab <- g1$grobs[[index]]                # Extract that grob
ylab <- hinvert_title_grob(ylab)         # Swap margins and fix justifications
# Put the transformed label on the right side of g4
g4 <- gtable_add_cols(g4, g1$widths[g1$layout[index, ]$l], pp$r)
g4 <- gtable_add_grob(g4, ylab, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "ylab-r")
# Get the y axis from g1 (axis line, tick marks, and tick mark labels)
index <- which(g1$layout$name == "axis-l")  # Which grob
yaxis <- g1$grobs[[index]]                  # Extract the grob
yaxis$children[[1]]$x <- unit.c(unit(0, "npc"), unit(0, "npc"))
ticks <- yaxis$children[[2]]
ticks$widths <- rev(ticks$widths)
ticks$grobs <- rev(ticks$grobs)
ticks$grobs[[1]]$x <- ticks$grobs[[1]]$x - unit(1, "npc") + unit(3, "pt")
ticks$grobs[[2]] <- hinvert_title_grob(ticks$grobs[[2]])
yaxis$children[[2]] <- ticks
# Put the transformed yaxis on the right side of g4
g4 <- gtable_add_cols(g4, g1$widths[g1$layout[index, ]$l], pp$r)
g4 <- gtable_add_grob(g4, yaxis, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "axis-r")
# grid.draw(g4)


# export images for web hub
setwd(imgDir)
plots <- ls()[grep('^p\\.', ls())]
for(i in 1:length(plots)) {
  imgName <- paste(substring(plots[i],3),'.png',sep='')
  cat(paste0("Saving ", imgName, "\n"));
  png(file=imgName, width=1200, height=800, units='px')
  print(eval(parse(text = plots[i])))
  makeTimeStamp(timeStamp = Sys.time(), author='Data Science')
  dev.off()
}
png(file='trend.png', width=1200, height=800, units='px')
grid.draw(g4a)
makeTimeStamp(timeStamp = Sys.time(), author='Data Science')
dev.off()
png(file='trend.domestic.png', width=1200, height=800, units='px')
grid.draw(g4)
makeTimeStamp(timeStamp = Sys.time(), author='Data Science')
dev.off()

# Make pdf report for the web hub
setwd(pdfDir)
pdf("InstrumentRMA.pdf", width = 11, height = 8)
for(i in 1:length(plots)) {
  
  print(eval(parse(text = plots[i])))
}
grid.draw(g4)
dev.off()

#rm(list=ls())

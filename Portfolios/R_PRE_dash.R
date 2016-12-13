# Set the environment
workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_PRE'
pdfDir <- '~/WebHub/pdfs/'

setwd(workDir)

# load neccessary libraries
library(ggplot2)
library(grid)
library(ggrepel)
library(scales)
library(zoo)
library(lubridate)
library(dateManip)
library(gridExtra)
library(reshape2)

# load user-created functions
source('Portfolios/R_PRE_load.R')
source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/makeTimeStamp.R')

# establish some properties used throughout the code- these are kept up top to facilitate changes
bigGroup <- 'Year'
smallGroup <- 'Month'
periods <- 3
weeks <- 53
months <- 13
lagPeriods <- 0
validateDate <- '2015-30'

# make a calendar that matches the weeks from SQL DATEPART function and find a start date such that charts show one year
startYear <- year(Sys.Date()) - 1
calendar.df <- createCalendarLikeMicrosoft(startYear, smallGroup)
startDate <- findStartDate(calendar.df, 'Month', 6, 0)
# set theme for line charts ------------------------------------------------------------------------------------------------------------------
seqBreak <- 1
dateBreaks <- as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup']))[order(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup'])))][seq(4,length(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup']))), seqBreak)]
fontSize <- 20
fontFace <- 'bold'

# use the makeDateGorupAndFillGaps function to properly format data that was read in from SQL
pouches.week <- pouches.df
startYear.week <- year(Sys.Date())-2
calendar.week <- createCalendarLikeMicrosoft(startYear.week, 'Week')
startDate.week <- findStartDate(calendar.week, 'Week', 53, 0)
pouches.week <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', pouches.week, 'Version', startDate.week, 'Record', 'sum', 0)
# pouches.df <- aggregateAndFillDateGroupGaps(calendar.df, 'Month', pouches.df, c('Key'), startDate, 'Record', 'sum', 0)
# closureRate.df <- aggregateAndFillDateGroupGaps(calendar.df, 'Month', closureRate.df,c('Key'), startDate, 'Record', 'sum', 0)

#get stats
# closureRate.df.agg <- mergeCalSparseFrames(closureRate.df,pouches.df, 'DateGroup','DateGroup','Record','Record',0,0)

#set color palette
myPalPanel <- createPaletteOfVariableLength(pouches.week, 'Version')
myPalCodes <- createPaletteOfVariableLength(codes.df, 'Code')
myPalTeam <- createPaletteOfVariableLength(needsPre.df,'assigned_to')

p.becameAwarePRE <- ggplot(becameAware.df, x=BugId, y=Days)

#team close Time 120 days
# p.teamCloseTime <- ggplot() + geom_line(data=teamCloseTime.df, aes(x=CreatedDate, y=AvgDaysProcess, group=1)) +
#   geom_point(data=teamCloseTime.df,aes(x=CreatedDate, y=AvgDaysProcess, group=1) ,color='blue') +
#   geom_point(data=needsPre.df,aes(x=CreatedDate, y=daysSinceCreated, group=1), color='dark gray') +
#   theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Days to Close Past 120 Days ', y='Average Days', x='Date\n(Year-Month)')

#team close Time Year
#team close Time Year Table
closeTimeTable <- teamCloseTimeYear.df
p.teamCloseTimeYear <- ggplot(teamCloseTimeYear.df, aes(x=CreatedDate, y=AvgDaysProcess, group=1)) + geom_line() + geom_point(color='blue') +
  theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Days to Close Past Year ', y='Average Days', x='Date\n(Year-Month)') +
  annotation_custom(tableGrob(closeTimeTable), ymin=30, xmin=11)
#this could still be prettier. Try to make it spiffier in next rev.

# #closureRate by Pouches Shipped
# x_positions <- c('2016-07')
# y_positions <- max(closureRate.df.agg[, 'Rate'])
# indices <- which(unique(as.character(closureRate.df.agg[,'DateGroup']))==x_positions)
# p.closureRate <- ggplot(closureRate.df.agg, aes(x=DateGroup, y=Rate, group=Key, color=Key)) + geom_line(color='black') + geom_point(color='blue') + scale_y_continuous(label=percent) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + scale_x_discrete(breaks=dateBreaks) + labs(title='PMS CI Closures per Pouches Shipped', x='Date (Year-Week)', y='Rolling 4-Week Average')

#Days until PRE Review since bug created date for last 120 days
p.preBugs <- ggplot(preBugs.df, aes(x=bug_id, y=DaysUntilPRE)) + geom_point(color='dodgerblue', size=2) + 
 geom_text_repel(data= subset(preBugs.df,DaysUntilPRE>30),aes(label=bug_id), size=4) +
  geom_hline(aes(yintercept=30),color="blue", linetype="dashed") +
  geom_vline(aes(xintercept=14906),color="seagreen", size=1) +
  theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) +
  labs(title='CI: PRE Assessment\n Based on Created Date', x='Bug Id', y='Days Until PRE Review')

#complaints that need PRE Review and days since created
p.needsPre <- ggplot(needsPre.df, aes(x=CreatedDate, y=daysSinceCreated)) + geom_point(aes(color=factor(assigned_to)),size=4) + 
  geom_text_repel(data=subset(needsPre.df,daysSinceCreated>0),aes(label=bug_id), size=4)+
  geom_hline(aes(yintercept=30),color="blue", linetype="dashed") +
  labs(title='CI: Complaints That Need PRE Review & Days Since Created', x='Date\n(Year-Month)', y='Days Since Created')+
  theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90))
p.needsPre <- p.needsPre + scale_color_manual(values = myPalTeam, name="Assigned")

# count of Pouches Shipped by Panel for last 53 weeks
dateBreaks.week <- as.character(unique(pouches.week$DateGroup))[order(as.character(unique(pouches.week$DateGroup)))][seq(1, 53, 4)]
p.pouch2016 <- ggplot(pouches.week, aes(x=DateGroup, y=Record, fill=Version)) + geom_bar(stat='identity') + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + scale_x_discrete(breaks=dateBreaks.week) + scale_fill_manual(values=myPalPanel, name='') + labs(title='Pouches Shipped by Panel Type', y='Quantity Shipped', x='Date\n(Year-Week)')

p.becameAware <- ggplot(becameAware.df, aes(x=BugId, y=Days, group=Note, fill=Note)) + geom_line(aes(color=Note), size=1) + geom_point(aes(color=Note), size=2)+
theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) +
  labs(title='Became Aware Date Until PRE vs CI Created Date Until PRE', x='Bug ID', y='Days') +
  geom_hline(aes(yintercept=30),color="green", linetype="dashed") +
  geom_text_repel(data=subset(becameAware.df,Days>30),aes(label=BugId), size=5,  arrow= arrow(length = unit(0.01,'npc')), force=1, segment.size=0.5, box.padding=unit(0.5,'lines'), point.padding=unit(1, 'lines'))

#count of unique z codes created by CI Team
p.codes <- ggplot(codes.df, aes(x=CreatedDate, y=Record, group=Code, fill=Code)) +
  geom_bar(stat="identity") +
  theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) +
  labs(title='CI: Count of Team Codes by Month', x='Date\n(Year-Month)', y='Count')
p.codes <- p.codes + scale_fill_manual(values = myPalCodes)

#export images for web hub
setwd(imgDir)
# png(file="image0.png",width=1200,height=800,units='px')
# print(p.teamCloseTime)
# dev.off()
png(file="image1.png",width=1200,height=800,units='px')
print(p.teamCloseTimeYear)
makeTimeStamp(timeStamp = Sys.time(), author='Post Market Surveillance')
dev.off()
# png(file="image2.png",width=1200,height=800,units='px')
# print(p.closureRate)
# dev.off()
png(file="image3.png",width=1200,height=800,units='px')
print(p.preBugs)
makeTimeStamp(timeStamp = Sys.time(), author='Post Market Surveillance')
dev.off()
png(file="image4.png",width=1200,height=800,units='px')
print(p.needsPre)
makeTimeStamp(timeStamp = Sys.time(), author='Post Market Surveillance')
dev.off()
png(file="image5.png",width=1200,height=800,units='px')
print(p.pouch2016)
makeTimeStamp(timeStamp = Sys.time(), author='Post Market Surveillance')
dev.off()
png(file="image6.png",width=1200,height=800,units='px')
print(p.codes)
makeTimeStamp(timeStamp = Sys.time(), author='Post Market Surveillance')
dev.off()

#Make pdf report for the web hub
setwd(pdfDir)
pdf("ComplaintPRE.pdf", width = 11, height = 8)
  # print(p.teamCloseTime)
  print(p.teamCloseTimeYear)
  # print(p.closureRate)
  print(p.preBugs)
  print(p.needsPre)
  print(p.pouch2016)
  print(p.codes)
dev.off()

#set work directory to the CI folder on the G to publishe the Became Aware vs CI Created Date
#the CI team does not want this on the WebHub
setwd("\\\\filer01/Data/Departments/PostMarket/CI GROUP/")
png(file="DaysUntilPRE_BecameAware_CiCreated.png",width=1300,height=700,units='px')
print(p.becameAware)
dev.off()

rm(list=ls())
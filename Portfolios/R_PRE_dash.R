# Set the environment
workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_PRE'
pdfDir <- '~/WebHub/pdfs/'

setwd(workDir)

# load neccessary libraries
library(ggplot2)
library(ggrepel)
library(scales)
library(zoo)
library(lubridate)
library(dateManip)
library(plyr)

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
limit <- 15

# make a calendar that matches the weeks from SQL DATEPART function and find a start date such that charts show one year
startYear <- year(Sys.Date()) - 3
calendar.df <- createCalendarLikeMicrosoft(startYear, smallGroup)
startDate <- findStartDate(calendar.df, 'Month', 13, 0, keepPeriods=0)
calendar.week <- createCalendarLikeMicrosoft(startYear, 'Week')
startDate.week <- findStartDate(calendar.week, 'Week', 53, 0, keepPeriods=0)
# set theme for line charts ------------------------------------------------------------------------------------------------------------------
seqBreak <- 12
dateBreaks <- as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= startDate.week,'DateGroup']))[order(as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= startDate.week,'DateGroup'])))][seq(1,length(as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= startDate.week,'DateGroup']))), seqBreak)]
fontSize <- 20
fontFace <- 'bold'
theme_set(theme_grey()+theme(plot.title=element_text(hjust=0.5), plot.subtitle=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(color='black',size=fontSize,face=fontFace)))

# Cumulative Average Days to Close
daysToClose.df$DateGroup <- with(daysToClose.df, ifelse(Month < 10, paste0(Year, '-0', Month), paste0(Year,'-', Month)))
daystoclose.year <- subset(daysToClose.df, DateGroup >= startDate)
dategroups <- sort(as.character(unique(daystoclose.year$DateGroup)))
daystoclose.cum<- c()
for(i in 1:length(dategroups)) {
  temp <- subset(daystoclose.year, DateGroup <= dategroups[i])
  daystoclose.cum <- rbind(daystoclose.cum, data.frame(DateGroup = dategroups[i], CumAvg = with(temp, mean(DaysToClose)), Avg = with(subset(temp, DateGroup == dategroups[i]), mean(DaysToClose))))
}
p.AvgDaysToClose <- ggplot(daystoclose.cum, aes(x=DateGroup, y=CumAvg, group = 1)) + geom_line() + geom_point() + theme(axis.text.x = element_text(angle = 90)) + labs(title = 'Average Days to Close', subtitle = '13 Month Cumulative Average', x = 'Date\n(Year-Month)', y = 'Average Days') + geom_text(aes(label=format(CumAvg, digits=3)), fontface = 'bold', vjust = -1)

# CI PRE Review, Last 120 Days
preBugs.df$Color <- with(preBugs.df, ifelse(DaysToPRE > 30, 'fail', ifelse(DaysToPRE <= 30 & DaysToPRE > 15, 'review', 'pass')))
preBugs.df$Color <- factor(preBugs.df$Color, levels = c('pass', 'review', 'fail'))
p.DaysToPREreview <- ggplot(preBugs.df, aes(x=Bug, y=DaysToPRE, group=Color, color=Color)) + geom_point() + geom_hline(aes(yintercept = limit), color = 'forestgreen', linetype = 'dashed') + geom_hline(aes(yintercept = 30), color = 'blue', linetype = 'dashed') + scale_color_manual(name='', values=c('forestgreen','blue','darkorange')) + theme(legend.position = 'none') + labs(title = 'Days Until PRE Review', subtitle = 'Last 120 Days', x = 'Bug Id', y = 'Days Until PRE Review') + geom_text_repel(data= subset(preBugs.df, DateOpened >= Sys.Date()-30 & Color == 'review'),aes(label=Bug), size=5) + scale_x_continuous(breaks = pretty_breaks()) + geom_text_repel(data = subset(preBugs.df, DaysToPRE > 30), aes(label=Bug), size=4, show.legend = FALSE) 

# CI that needs PRE review
needsPre.df$DateGroup <- with(needsPre.df, ifelse(Month < 10, paste0(Year,'-0', Month), paste0(Year,'-', Month)))
p.NeedsPREreview <- ggplot(needsPre.df, aes(x=Bug, y=DaysSinceOpen, color=AssignedTo)) + geom_point() + geom_hline(aes(yintercept = limit), color = 'blue', linetype = 'dashed') + scale_color_manual(name = 'Assigned', values = createPaletteOfVariableLength(needsPre.df, 'AssignedTo')) + labs(title = 'Open Complaint Investigations that Need PRE Review', x = 'Bug Id', y = 'Days Since Opened') + geom_text_repel(data= subset(needsPre.df, DaysSinceOpen > limit),aes(label=Bug), size=4, show.legend = FALSE) + scale_x_continuous(breaks = pretty_breaks())

# Opened vs Closed CIs per week
openedvclosed <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', closedVopened.df, 'Key', startDate.week, 'Record', 'sum', 0)
#switch closed to negative numbers for purpose of graph
openedvclosed[openedvclosed$Key == 'Closed', 'Record'] <- with(subset(openedvclosed, Key == 'Closed'), Record * -1)
openedvclosed$Key <- factor(openedvclosed$Key, levels = c('Opened', 'Closed'))
p.OpenedVClosed <- ggplot(openedvclosed, aes(x=DateGroup, y=Record, fill=Key)) + geom_bar(stat='identity') + scale_y_continuous(labels = abs) + scale_fill_manual(name = '', values = createPaletteOfVariableLength(openedvclosed, 'Key')) + theme(axis.text.x = element_text(angle=90)) + labs(title = 'Opened vs Closed Complaint Investigations', x = 'Date\n(Year-Week)', y='Count of CIs') + scale_x_discrete(breaks=dateBreaks) + geom_text(aes(label=abs(Record)), size = 4, position = position_stack(vjust = 0.5), fontface = fontFace, color="lightgoldenrod1")

# All Opened CIs and who they are assigned to
opened <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', allopened.df, 'AssignedTo', startDate.week, 'Record', 'sum', 0) 
opened$AssignedTo <- factor(opened$AssignedTo, levels = c('CI Team','Other'))
p.AllOpenedCIs <- ggplot(opened, aes(x=DateGroup, y=Record, fill=AssignedTo)) + geom_bar(stat='identity') + scale_fill_manual(name = 'Assigned', values = createPaletteOfVariableLength(opened, 'AssignedTo')) + theme(axis.text.x = element_text(angle=90)) + labs(title = 'All Opened Complaint Investigations', x = 'Date\n(Year-Week)', y='Count of CIs') + scale_x_discrete(breaks=dateBreaks) + geom_text(aes(label=Record), size = 4, position = position_stack(vjust = 0.5), fontface = fontFace, color="lightgoldenrod1")

# Invest Start to Close vs Invest Start to PRE
investStarttoPRE.df$DateGroup <- with(investStarttoPRE.df, ifelse(Month < 10, paste0(Year, '-0', Month), paste0(Year, '-', Month)))
investStarttoPRE.year <- subset(investStarttoPRE.df, DateGroup >= findStartDate(calendar.df, 'Month', 12, 0, keepPeriods=0))
dategroups <- sort(unique(investStarttoPRE.year$DateGroup))
avgDays.investtopre <- c()
for(i in 1:length(dategroups)) {
  temp <- subset(investStarttoPRE.year, DateGroup == dategroups[i])
  avgDays.investtopre <- rbind(avgDays.investtopre, data.frame(DateGroup = dategroups[i], Key = 'Days Between Investigation Start and Close Date', AvgDays = mean(subset(temp, Key == 'InvestStartToClose')[,'Record'], na.rm=TRUE)), data.frame(DateGroup = dategroups[i], Key = 'Days Between Investigation Start and PRE Date', AvgDays = mean(subset(temp, Key == 'InvestStartToPRE')[,'Record'], na.rm=TRUE)))
}
p.InvestStartVsClose.PRE <- ggplot(avgDays.investtopre, aes(x=DateGroup, y=AvgDays, color=Key, group=Key)) + geom_line() + geom_point() + scale_color_manual(name='', values=createPaletteOfVariableLength(avgDays.investtopre, 'Key')) + theme(legend.position = 'bottom', axis.text.x = element_text(angle = 90, vjust=0.5)) + labs(title = 'Days Between Investigation Start Date to Close Date vs\nDays Between Investigation Start Date to PRE Review', x='Date\n(Year-Month)', y='Average Days') + geom_text_repel(aes(label=format(AvgDays, digits=3)), fontface='bold') 

# Became Aware vs CI Created, Last 120 Days - not on Web Hub
exceedLimit <- subset(becameAware.df, Record > 30)
exceedLimit <- exceedLimit[with(exceedLimit, order(Bug, -Record)),]
exceedLimit <- ddply(exceedLimit, .(Bug), mutate, Id = seq_along(Record))
exceedLimit <- subset(exceedLimit, Id == 1)
p1.BecameAware <- ggplot(subset(becameAware.df, DateOpened <= Sys.Date()-15), aes(x=Bug, y=Record, color=Key, group=Key)) + geom_point() + geom_hline(aes(yintercept = limit), color='blue', linetype='dashed') + geom_hline(aes(yintercept = 30), color='red', linetype='dashed') + scale_color_manual(name='', values=createPaletteOfVariableLength(becameAware.df, 'Key')) + theme(legend.position = 'bottom') + scale_x_continuous(breaks = pretty_breaks()) + labs(title = 'Became Aware Date Until PRE vs CI Created Date Until PRE', subtitle = 'Last 120 Days', x='Bug Id', y= 'Days') + geom_text_repel(data = exceedLimit, inherit.aes=FALSE, aes(x=Bug, y=Record, color=Key, label=Bug), size=4, show.legend = FALSE)

# CI created to Investigation start vs Became aware to investigation start vs investigation start to closure - not on web hub
exceedLimit.1 <- subset(investStarttoClose.df, Record > 30)
exceedLimit.1 <- exceedLimit.1[with(exceedLimit.1, order(Bug, -Record)),]
exceedLimit.1 <- ddply(exceedLimit.1, .(Bug), mutate, Id = seq_along(Record))
exceedLimit.1 <- subset(exceedLimit.1, Id == 1)
pal.invest <- c('darkgreen', 'purple', 'deepskyblue2')
p2.InvestigationStartBugs <- ggplot(subset(investStarttoClose.df, DateOpened <= Sys.Date()-15), aes(x=Bug, y=Record, color=Key, group=Key)) + geom_point() + geom_hline(aes(yintercept = limit), color='blue', linetype='dashed') + geom_hline(aes(yintercept = 30), color='red', linetype='dashed') + scale_color_manual(name='', values=pal.invest, guide = guide_legend(nrow=3, byrow=FALSE)) + theme(legend.position = 'bottom') + scale_x_continuous(breaks = pretty_breaks()) + labs(title = 'Became Aware Date and CI Created Date to Investigation Start\nand Investigation Start Date to Close', subtitle = 'Last 120 Days', x='Bug Id', y= 'Days') + geom_text_repel(data = exceedLimit.1, inherit.aes=FALSE,aes(x=Bug, y=Record, color = Key, label=Bug), size=4, show.legend = FALSE) 

#export images for web hub
setwd(imgDir)
plots <- ls()[grep('^p\\.', ls())]
for(i in 1:length(plots)) {
  imgName <- paste(substring(plots[i],3),'.png',sep='')
  png(file=imgName, width=1200, height=800, units='px')
  print(get(plots[i]))
  makeTimeStamp(author='Data Science')
  dev.off()
}

#Make pdf report for the web hub
setwd(pdfDir)
pdf("ComplaintPRE.pdf", width = 11, height = 8)
for(i in 1:length(plots)) {
  print(get(plots[i]))
}
dev.off()

#set work directory to the CI folder on the G to publish non-webhub charts
#the CI team does not want this on the WebHub
setwd("\\\\filer01/Data/Departments/PostMarket/CI GROUP/")
png(file="DaysUntilPRE_BecameAware_CiCreated.png",width=1300,height=700,units='px')
print(p1.BecameAware)
makeTimeStamp(author='Data Science')
dev.off()

png(file="DaysUntilInvestStart_Close_BecameAware.png",width=1300,height=700,units='px')
print(p2.InvestigationStartBugs)
makeTimeStamp(author='Data Science')
dev.off()

rm(list=ls())

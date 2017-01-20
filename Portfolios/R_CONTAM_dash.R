# Set the environment
workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_Contamination'
pdfDir <- '~/WebHub/pdfs/'

setwd(workDir)

# load neccessary libraries
library(ggplot2)
library(grid)
library(scales)
library(zoo)
library(plyr)
library(lubridate)
# library(splitstackshape)
library(devtools)
install_github('dateManip','BioAimie')
library(dateManip)

# load user-created functions
source('Portfolios/R_CONTAM_load.R')
source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/makeTimeStamp.R')

# establish some properties used throughout the code- these are kept up top to facilitate changes
bigGroup <- 'Year'
smallGroup <- 'Month'
periods <- 13
weeks <- 53
months <- 13
lagPeriods <- 0
validateDate <- '2016-04'

# make a calendar that matches the weeks from SQL DATEPART function and find a start date such that charts show one year
startYear <- year(Sys.Date()) - 2
calendar.df <- createCalendarLikeMicrosoft(startYear, smallGroup)
startDate <- findStartDate(calendar.df, smallGroup, 12, 0)

# set theme for line charts ------------------------------------------------------------------------------------------------------------------
# dateBreaks <- c("2016-03","2016-04","2016-05","2016-06","2016-07","2016-08")
dateBreaks <- as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup']))[order(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup'])))][seq(1,length(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup']))), 1)]
fontSize <- 20
fontFace <- 'bold'

# use the makeDateGroupAndFillGaps function to properly format data that was read in from SQL
#rates
faEnviro.cal <- aggregateAndFillDateGroupGaps(calendar.df,'Month',faEnviro.df,'Contamination',startDate,'Record','sum',0)
faPersonnel.cal <- aggregateAndFillDateGroupGaps(calendar.df,'Month',faPersonnel.df,'Contamination',startDate,'Record','sum',0)
faPool.cal <- aggregateAndFillDateGroupGaps(calendar.df,'Month',faPool.df,'Contamination',startDate,'Record','sum',0)
#counts
faBldg.cal <- aggregateAndFillDateGroupGaps(calendar.df,'Month',faEnviroCount.df,c('Group','Name'),startDate,'Record','sum',0)
faDept.cal <- aggregateAndFillDateGroupGaps(calendar.df,'Month',faPersonnelCount.df,c('Group','Name'),startDate,'Record','sum',0)
faPoolNum.cal <- aggregateAndFillDateGroupGaps(calendar.df,'Month',faPoolCount.df,c('Group','Name'),startDate,'Record','sum',0)
faEnviroPanel.cal <- aggregateAndFillDateGroupGaps(calendar.df,'Month',faEnviroCount.df,c('PouchTitle','Name'),startDate,'Record','sum',0)
faPersonnelPanel.cal <- aggregateAndFillDateGroupGaps(calendar.df,'Month',faPersonnelCount.df,c('PouchTitle','Name'),startDate,'Record','sum',0)
faPoolPanel.cal <- aggregateAndFillDateGroupGaps(calendar.df,'Month',faPoolCount.df,c('PouchTitle','Name'),startDate,'Record','sum',0)
faPersonnelPouch.cal <- aggregateAndFillDateGroupGaps(calendar.df,'Month',faPersonnelCountPouch.df,'Contamination',startDate,'Record','sum',0)
faPoolPouch.cal <- aggregateAndFillDateGroupGaps(calendar.df,'Month',faPoolCountPouch.df,'Contamination',startDate,'Record','sum',0)

#get rolling rate and stats
faEnviro.agg <- mergeCalSparseFrames(subset(faEnviro.cal,Contamination!='No Contamination'),subset(faEnviro.cal,Contamination=='No Contamination'),'DateGroup','DateGroup','Record','Record',0,0)
faPersonnel.agg <- mergeCalSparseFrames(subset(faPersonnel.cal,Contamination!='No Contamination'),subset(faPersonnel.cal,Contamination=='No Contamination'),'DateGroup','DateGroup','Record','Record',0,0)
faPool.agg <- mergeCalSparseFrames(subset(faPool.cal,Contamination=='Contamination'),subset(faPool.cal,Contamination=='No Contamination'),'DateGroup','DateGroup','Record','Record',0,0)

# set color theme for charts ------------------------------------------------------------------------------------------------------------------
myPalVpAppYes_bar <- createPaletteOfVariableLength(vpAppYesBar.df,'Key')
myPalBldg <- createPaletteOfVariableLength(faBldg.cal,'Name')
faDept.pal <- createPaletteOfVariableLength(faDept.cal,'Name')
faPoolNum.pal <- createPaletteOfVariableLength(faPoolNum.cal,'Name')
faEnviroPanel.pal <- createPaletteOfVariableLength(faEnviroPanel.cal,'Name')
faPersonnelPanel.pal <- createPaletteOfVariableLength(faPersonnelPanel.cal,'Name')
faPoolPanel.pal <- createPaletteOfVariableLength(faPoolPanel.cal,'Name')
faPersonnelPouch.pal <- createPaletteOfVariableLength(faPersonnelPouch.cal,'Contamination')
faPoolPouch.pal <- createPaletteOfVariableLength(faPoolPouch.cal,'Contamination')
#eventual Master Assay color palette
faAssayPal.pal <-createPaletteOfVariableLength(faAssayPal.df,'Name')

# bldg 400
p.400bldg <- ggplot(subset(faBldg.cal,Group=='400'), aes(x=DateGroup, y=Record, fill=Name)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace , color='black'), axis.text.x=element_text(angle=90), legend.position="bottom") + labs(title='Environmental Contamination in 400', x='Date\n(Year-Month)', y='Count') + scale_fill_manual(values=myPalBldg, name='') + guides(fill=guide_legend(nrow=4, by.row=TRUE))

# bldg
p.bldg <- ggplot(faBldg.cal, aes(x=DateGroup, y=Record, fill=Name)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace , color='black'), axis.text.x=element_text(angle=90), legend.position="bottom") + labs(title='Environmental Contamination by Building', x='Date\n(Year-Month)', y='Count') + scale_fill_manual(values=myPalBldg, name='') + facet_wrap(~Group) + guides(fill=guide_legend(nrow=4, by.row=TRUE))

# dept Personnel
p.dept <- ggplot(faDept.cal, aes(x=DateGroup, y=Record, fill=Name)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace , color='black'), axis.text.x=element_text(angle=90), legend.position="bottom") + labs(title='Personnel Contamination by Department', x='Date\n(Year-Month)', y='Count') + scale_fill_manual(values=faDept.pal, name='') + facet_wrap(~Group) + guides(fill=guide_legend(nrow=4, by.row=TRUE))

#Enviro Swabs
p.faEnviro <- ggplot(faEnviro.agg,aes(x=DateGroup,y=Rate, group=1)) + geom_line(color='black') + geom_point() + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + scale_y_continuous(label=percent) +  labs(x='Date\n(Year-Month)', y='Contamination', title='Environmental Contamination Observation Rates Based on Assay')

# fa Pool Number 
p.poolNum <- ggplot(faPoolNum.cal, aes(x=DateGroup, y=Record, fill=Name)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=10, face=fontFace , color='black'), axis.text.x=element_text(angle=90), legend.position="bottom") + labs(title='Pools Contamination by Pool Number', x='Date\n(Year-Month)', y='Count') + scale_fill_manual(values=faPoolNum.pal, name='') + facet_wrap(~Group) + guides(fill=guide_legend(nrow=4, by.row=TRUE))

#Personnel Swabs
p.faPersonnel <- ggplot(faPersonnel.agg,aes(x=DateGroup,y=Rate, group=1)) + geom_line(color='black') + geom_point() + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + scale_y_continuous(label=percent) + labs(x='Date\n(Year-Month)', y='Contamination', title='Personnel Contamination Observation Rates Based on Assay')

#Pool Swabs
p.faPool <- ggplot(faPool.agg,aes(x=DateGroup,y=Rate, group=1)) + geom_line() + geom_line(color='black') + geom_point() + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + scale_y_continuous(label=percent) +  labs(x='Date\n(Year-Month)', y='Contamination', title='Pool Contamination Observation Rates Based on Assay')

#fa Enviro Panels
p.enviroPanel <- ggplot(faEnviroPanel.cal, aes(x=DateGroup, y=Record, fill=Name)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace , color='black'), axis.text.x=element_text(angle=90), legend.position="bottom") + labs(title='Positive Contamination Counts: Environmental', x='Date\n(Year-Month)', y='Count') + scale_fill_manual(values=faEnviroPanel.pal, name='') + facet_wrap(~PouchTitle)  + guides(fill=guide_legend(nrow=4, by.row=TRUE))

#fa Personnel Panels
p.personnelPanel <- ggplot(faPersonnelPanel.cal, aes(x=DateGroup, y=Record, fill=Name)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace , color='black'), axis.text.x=element_text(angle=90), legend.position="bottom") + labs(title='Positive Contamination Counts: Personnel', x='Date\n(Year-Month)', y='Count') + scale_fill_manual(values=faPersonnelPanel.pal, name='') + facet_wrap(~PouchTitle) + guides(fill=guide_legend(nrow=4, by.row=TRUE))

#fa Pools Panels
p.poolPanel <- ggplot(faPoolPanel.cal, aes(x=DateGroup, y=Record, fill=Name)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace , color='black'), axis.text.x=element_text(angle=90), legend.position="bottom") + labs(title='Positive Contamination Counts: Pool', x='Date\n(Year-Month)', y='Count') + scale_fill_manual(values=faPoolPanel.pal, name='') + facet_wrap(~PouchTitle) + facet_wrap(~PouchTitle) + guides(fill=guide_legend(nrow=4, by.row=TRUE))

#FilmArray Database Contamination Charts Based on SampleId Keywords
# Personnel Swab counts with ddply to get data labels for contam count chart
personnelPouch.df <- ddply(faPersonnelPouch.cal, .(DateGroup, Contamination, Record),mutate, csum=cumsum(Record)-Record/2)
p.personnelPouch <- ggplot(personnelPouch.df, aes(x=DateGroup, y=Record, group=Contamination, fill=Contamination)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, face=fontFace)) + labs(title='Personnel Swabs: Count of All Pouches Run', y='Count', x='Date\n(Year-Month)') + scale_fill_manual(values=faPersonnelPouch.pal, name='') + geom_text(aes(x =DateGroup, y=csum, label=Record, hjust=.5, vjust=-0.1), size=4, color="lightgoldenrod1", fontface="bold")

# Pools Swab counts with ddply to get data labels for contam count chart
poolPouch.df <- ddply(faPoolPouch.cal, .(DateGroup, Contamination, Record),mutate, csum=cumsum(Record)-Record/2)
p.poolPouch <- ggplot(poolPouch.df, aes(x=DateGroup, y=Record, group=Contamination, fill=Contamination)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, face=fontFace)) + labs(title='Pools Swabs: Count of All Pouches Run', y='Count', x='Date\n(Year-Month)') + scale_fill_manual(values=faPoolPouch.pal, name='') + geom_text(aes(x =DateGroup, y=csum, label=Record, hjust=.5, vjust=-0.1), size=4, color="lightgoldenrod1", fontface="bold")

#vpAppYes bar
dfVp <- ddply(vpAppYesBar.df, .(CreatedDate, Key, Record),mutate, csum=cumsum(Record)-Record/2)
sortVp.df <- plyr::arrange(dfVp,CreatedDate,desc(Key),Record, csum)
p.vpAppYes_bar <- ggplot(sortVp.df, aes(x=CreatedDate, y=Record, group=Key, fill=Key)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='VP Approval Count ', y='Count', x='Date\n(Year-Month)') + scale_fill_manual(values= myPalVpAppYes_bar) + geom_text(aes(x =CreatedDate, y=csum, label=Record, hjust=0.5, vjust=-0.1), size=4, color="lightgoldenrod1", fontface="bold")

# -----------------------------------------------------------------------------------------------------------------------
# Make Charts that are based on week and not month
# make a calendar that matches the weeks from SQL DATEPART function and find a start date such that charts show one year
startYear.week <- year(Sys.Date()) - 2
calendar.week <- createCalendarLikeMicrosoft(startYear.week, 'Week')
startDate.week <- findStartDate(calendar.week, 'Week', 53, 0)
# set theme for line charts ------------------------------------------------------------------------------------------------------------------
seqBreak <- 8
dateBreaks.week <- as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= startDate.week,'DateGroup']))[order(as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= startDate.week,'DateGroup'])))][seq(1,length(as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= startDate.week,'DateGroup']))), seqBreak)]

#Make date group and fill calendar
faEnviroCP.cal <- aggregateAndFillDateGroupGaps(calendar.week,'Week',subset(faEnviro.df,Contamination=='Contamination'),c('Contamination','Cp','Name'),startDate.week,'Record','sum',0)
faPersonnelCP.cal <- aggregateAndFillDateGroupGaps(calendar.week,'Week',subset(faPersonnel.df,Contamination=='Contamination'),c('Contamination','Cp','Name'),startDate.week,'Record','sum',0)
faPoolCP.cal <- aggregateAndFillDateGroupGaps(calendar.week,'Week',subset(faPool.df,Contamination=='Contamination'),c('Contamination','Cp','Name'),startDate.week,'Record','sum',0)

#converts CP to numeric datatype so it plots properly
faEnviroCP.cal$Cp <- as.numeric(as.character(faEnviroCP.cal$Cp))
faPersonnelCP.cal$Cp <- as.numeric(as.character(faPersonnelCP.cal$Cp))
faPoolCP.cal$Cp <- as.numeric(as.character(faPoolCP.cal$Cp))

# set color theme for charts ------------------------------------------------------------------------------------------------------------------
assayCpEnviro.pal <- createPaletteOfVariableLength(faEnviroCP.cal,'Name')
assayCpPersonnel.pal <- createPaletteOfVariableLength(faPersonnelCP.cal,'Name')
assayCpPool.pal <- createPaletteOfVariableLength(faPoolCP.cal,'Name')

#faEnviroCP
fa.envir.breaks <- unique(subset(faEnviroCP.cal,Record>1)$DateGroup)[order(unique(subset(faEnviroCP.cal,Record>1)$DateGroup))][seq(1, length(unique(subset(faEnviroCP.cal,Record>1)$DateGroup)), 4)]
p.cpFAEnviro <- ggplot(subset(faEnviroCP.cal,Record>1), aes(x=DateGroup, y=Cp)) + scale_y_continuous(breaks=pretty_breaks()) + geom_point(aes(color=factor(Name)),size=3) + scale_color_manual(values=assayCpEnviro.pal, name="") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90), legend.position = 'bottom') + labs(title='WEEKLY Environmental Contamination Cp', x='Date\n(Year-Week)', y='Cp') + guides(fill=guide_legend(nrow=5, by.row=TRUE)) + scale_x_discrete(breaks=fa.envir.breaks)

#faPersonnelCP
fa.person.breaks <- unique(subset(faPersonnelCP.cal,Record>1)$DateGroup)[order(unique(subset(faPersonnelCP.cal,Record>1)$DateGroup))][seq(1, length(unique(subset(faPersonnelCP.cal,Record>1)$DateGroup)), 4)]
p.cpFAPersonnel <- ggplot(subset(faPersonnelCP.cal,Record>1), aes(x=DateGroup, y=Cp)) + scale_y_continuous(breaks=pretty_breaks()) + geom_point(aes(color=factor(Name)),size=3) + scale_color_manual(values=assayCpPersonnel.pal, name="") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90), legend.position = 'bottom') + labs(title='WEEKLY Personnel Contamination Cp', x='Date\n(Year-Week)', y='Cp') + guides(fill=guide_legend(nrow=5, by.row=TRUE)) + scale_x_discrete(breaks=fa.person.breaks)

#faPoolCP
fa.pool.breaks <- unique(subset(faPoolCP.cal,Record>1)$DateGroup)[order(unique(subset(faPoolCP.cal,Record>1)$DateGroup))][seq(1, length(unique(subset(faPoolCP.cal,Record>1)$DateGroup)), 4)]
p.cpFAPool <- ggplot(subset(faPoolCP.cal,Record>1), aes(x=DateGroup, y=Cp)) + scale_y_continuous(breaks=pretty_breaks()) + geom_point(aes(color=factor(Name)),size=3) + scale_color_manual(values=assayCpPool.pal, name="") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90), legend.position = 'bottom') + labs(title='WEEKLY Pools Contamination Cp', x='Date\n(Year-Week)', y='Cp') + guides(fill=guide_legend(nrow=5, by.row=TRUE)) + scale_x_discrete(breaks=fa.pool.breaks)

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
pdf("Contamination.pdf", width = 11, height = 8)
for(i in 1:length(plots)) {
  
  print(eval(parse(text = plots[i])))
}
dev.off()

rm(list=ls())
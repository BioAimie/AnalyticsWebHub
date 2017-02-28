# Set the environment
workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_Contamination'
pdfDir <- '~/WebHub/pdfs/'

setwd(workDir)

library(ggplot2)
library(scales)
library(dateManip)
library(lubridate)

# load user-created functions
source('Portfolios/R_CONTAM_load.R')
source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/makeTimeStamp.R')

# establish some properties used throughout the code- these are kept up top to facilitate changes
bigGroup <- 'Year'

# make a calendar that matches the weeks from SQL DATEPART function and find a start date such that charts show one year
startYear <- year(Sys.Date()) - 3
calendar.mon <- createCalendarLikeMicrosoft(startYear, 'Month')
startDate.mon <- findStartDate(calendar.mon, 'Month', 13)
calendar.week <- createCalendarLikeMicrosoft(startYear, 'Week')
startDate.week <- findStartDate(calendar.week, 'Week', 54)
# set theme for line charts ------------------------------------------------------------------------------------------------------------------
seqBreak <- 12
dateBreaks <- as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= startDate.week,'DateGroup']))[order(as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= startDate.week,'DateGroup'])))][seq(1,length(as.character(unique(calendar.week[calendar.week[,'DateGroup'] >= startDate.week,'DateGroup']))), seqBreak)]
fontSize <- 20
fontFace <- 'bold'

# Create consistent palette for assays
colVector <- c("#E28FE1","#DCC6ED","#6445A5","#DC7F6D","#A9EA3E","#B2EABB","#E3CB7B","#9F506F","#E9BECB","#E43C8C","#9CE99A","#ABC7E8","#E693AB","#E2E1EA",
               "#93B274","#D234ED","#B254DF","#E8D5C4","#5AA8DF","#60AE4B","#E174B4","#E845B7","#E3EAB9","#658CDF","#E36782","#6077E6","#68EA7A","#B693B9",
               "#772CE8","#E6B33C","#6751E1","#E64154","#A8B344","#E375E4","#E39F60","#63EB47","#BB9DEA","#EAADE3","#ADDDE6","#55E7A3","#617962","#A3ECDE",
               "#AD7DE8","#E5AC99","#D7EA98","#B6EA73","#5CB797","#E646DD","#AA459D","#E2E63E","#E2C698","#A2864E","#5E6A89","#8C6AA7","#D9EFDE","#A5BDA6",
               "#64CEEA","#5EE4E5","#9EAAE4","#E56D36","#68ECCA","#E8E671","#A7A9B2","#AA8580","#60A6B0","#9EB478","#C4ED3F","#B389E5","#C1EE71","#5EAA59",
               "#E6C4C0","#9D4972","#5D88E3","#E8C4E5","#5BE6AA","#E9A4E4","#E4C39A","#E2DFEA","#899ADC","#9DE8E1","#AA8482","#E49C61","#615092","#67ECCE",
               "#E580E7","#5AE4E5","#E33F97","#E6435D","#627A63","#5E6E8A","#E4AE3C","#59E88A","#A97FAF","#81EE39","#D4EB96","#D17061","#C8ADEA","#9EEB8B",
               "#AABDA9","#E2E7B1","#716DE0","#63B798","#E64ACD","#E6DF3B","#E59DB7","#664AD8","#E177BC","#5CAAE0","#A44BA9","#E4CA7B","#802DE8","#DB3AEA",
               "#79C846","#B2BFEA","#E9E470","#A8D3E7","#CFECE7","#61CDE9","#EBE8D1","#E86B36","#E47391","#B85DE4","#61EE66","#A9A5B6","#BDEDC8","#E8A192",
               "#A2854F","#A1E7AA","#A7B246","#62A6AF")
assayNames <- sort(unique(c(as.character(subset(environ.df, ConStatus == 'Contamination')[,'Assay']), as.character(subset(person.df, ConStatus == 'Contamination')[,'Assay']), as.character(subset(pool.df, ConStatus == 'Contamination')[,'Assay']))))
pal <- colVector[1:length(assayNames)]
names(pal) <- assayNames 

# Environmental charts ------------------------------------------------------------------------------------------------------------------------
# building charts
environ.contam <- subset(environ.df, ConStatus == 'Contamination' & Building != 'Other')
environ.count <- with(environ.contam, aggregate(Record~Year+Month+Week+PouchSerial+InstrumentSerial+Panel+Assay+Result+Building+ConStatus+Key, FUN=sum))
environ.count$Record <- 1
building.count <- aggregateAndFillDateGroupGaps(calendar.mon, 'Month', environ.count, c('Building', 'Assay'), startDate.mon, 'Record', 'sum', 0)
building.count <- subset(building.count, Building %in% c('400','410','420','421','515'))
p.building.count <- ggplot(building.count, aes(x=DateGroup, y=Record, fill=Assay)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace , color='black'), axis.text.x=element_text(angle=90), legend.position="bottom") + labs(title='Environmental Contamination by Building', x='Date\n(Year-Month)', y='Count') + scale_fill_manual(values=pal, name='') + facet_wrap(~Building) + guides(fill=guide_legend(nrow=6, by.row=TRUE))
p.400building <- ggplot(subset(building.count, Building == '400'), aes(x=DateGroup, y=Record, fill=Assay)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace , color='black'), axis.text.x=element_text(angle=90), legend.position="bottom") + labs(title='Environmental Contamination in 400 Building', x='Date\n(Year-Month)', y='Count') + scale_fill_manual(values=pal, name='') + guides(fill=guide_legend(nrow=5, by.row=TRUE))
p.515building <- ggplot(subset(building.count, Building == '515'), aes(x=DateGroup, y=Record, fill=Assay)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace , color='black'), axis.text.x=element_text(angle=90), legend.position="bottom") + labs(title='Environmental Contamination in 515 Building', x='Date\n(Year-Month)', y='Count') + scale_fill_manual(values=pal, name='') + guides(fill=guide_legend(nrow=5, by.row=TRUE))

#cp
cps.environ <- subset(environ.contam, select = c('Year', 'Week', 'Assay', 'Cp', 'Record'))
cps.environ$DateGroup <- with(cps.environ, ifelse(Week < 10, paste(Year, Week, sep='-0'), paste(Year, Week, sep='-')))
cps.environ <- merge(data.frame(DateGroup = unique(subset(calendar.week, DateGroup >= startDate.week)[,'DateGroup'])), subset(cps.environ, DateGroup >= startDate.week), all = TRUE)
cps.environ$Cp <- round(as.numeric(as.character(cps.environ$Cp)))
cps.environ$Assay <- ifelse(is.na(cps.environ$Assay), 'HRV', as.character(cps.environ$Assay))
p.cp.environmental <- ggplot(cps.environ, aes(x=DateGroup, y=Cp)) + scale_y_continuous(breaks=pretty_breaks()) + geom_point(aes(color=Assay),size=3) + scale_color_manual(values=pal, name="") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90), legend.position = 'bottom') + labs(title='WEEKLY Environmental Contamination Cp', x='Date\n(Year-Week)', y='Cp') + guides(fill=guide_legend(nrow=5, by.row=TRUE)) + scale_x_discrete(breaks=dateBreaks)

#positive contamination counts
positive.counts.enviro <- aggregateAndFillDateGroupGaps(calendar.mon, 'Month', environ.count, c('Assay', 'Panel'), startDate.mon, 'Record', 'sum', 0)
p.panel.environ <- ggplot(positive.counts.enviro, aes(x=DateGroup, y=Record, fill=Assay)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace , color='black'), axis.text.x=element_text(angle=90), legend.position="bottom") + labs(title='Positive Contamination Counts: Environmental', x='Date\n(Year-Month)', y='Count') + scale_fill_manual(values=pal, name='') + facet_wrap(~Panel)  + guides(fill=guide_legend(nrow=7, by.row=TRUE))

#contamination rates 
environ.agg <- aggregateAndFillDateGroupGaps(calendar.mon, 'Month', environ.df, 'Key', startDate.mon, 'Record', 'sum', 0)
environ.contam.agg <- aggregateAndFillDateGroupGaps(calendar.mon, 'Month', environ.contam, 'ConStatus', startDate.mon, 'Record', 'sum', 0)
environ.rate <- mergeCalSparseFrames(environ.contam.agg, environ.agg, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, 0)
p.environ.rate <- ggplot(environ.rate,aes(x=DateGroup,y=Rate, group=1)) + geom_line(color='black') + geom_point() + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + scale_y_continuous(label=percent) +  labs(x='Date\n(Year-Month)', y='Contamination Rate', title='Environmental Contamination Observation Rates Based on Assay')

#overall environmental contam vs no contam
environ.all <- subset(environ.df, select=c('Year', 'Month', 'PouchSerial', 'ConStatus', 'Key', 'Record'))
environ.all$DateGroup <- with(environ.all, ifelse(Month < 10, paste(Year, Month, sep='-0'), paste(Year, Month, sep='-')))
environ.all <- subset(environ.all, DateGroup >= startDate.mon)
environ.all <- with(environ.all, aggregate(Record~DateGroup+PouchSerial+ConStatus+Key, FUN=sum))
contam.e <- as.character(unique(subset(environ.all, ConStatus == 'Contamination')[,'PouchSerial']))
pouch.environ <- rbind(subset(environ.all, !(PouchSerial %in% contam.e)), subset(environ.all, PouchSerial %in% contam.e & ConStatus == 'Contamination'))
pouch.environ$Record <- 1
pouch.environ <- with(pouch.environ, aggregate(Record~DateGroup+ConStatus+Key, FUN=sum))
pouch.environ$ConStatus <- factor(pouch.environ$ConStatus, levels = c('Contamination', 'No Contamination'))
pouch.environ <- merge(with(subset(calendar.mon, DateGroup >= startDate.mon), aggregate(DateGroup~Year+Month, FUN=max)), pouch.environ, by='DateGroup', all.x=TRUE)
pouch.environ <- aggregateAndFillDateGroupGaps(calendar.mon, 'Month', pouch.environ, c('ConStatus', 'Key'), startDate.mon, 'Record', 'sum', 0)
pouch.environ$DateGroup <- factor(pouch.environ$DateGroup, levels = sort(as.character(unique(pouch.environ$DateGroup))))
percent.pos.e <- mergeCalSparseFrames(subset(pouch.environ, ConStatus == 'Contamination'), with(pouch.environ, aggregate(Record~DateGroup, FUN=sum)), 'DateGroup', 'DateGroup', 'Record', 'Record', 0, 0)
percent.pos.e <- merge(percent.pos.e, with(pouch.environ, aggregate(Record~DateGroup, FUN=sum)))
p.environ.pouch <- ggplot(pouch.environ, aes(x=DateGroup, y=Record, fill=ConStatus, label = Record)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), plot.subtitle=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, face=fontFace)) + labs(title='Environmental Swabs: Count of Unique Pouches Run', subtitle = 'Percent Positive Shown Above Bar', y='Count', x='Date\n(Year-Month)') + scale_fill_manual(values=createPaletteOfVariableLength(pouch.environ, 'ConStatus'), name='') + geom_text(size = 4, position = position_stack(vjust = 0.5), fontface = fontFace, color="lightgoldenrod1") + geom_text(data = percent.pos.e, aes(x=DateGroup, y=Record, label=percent(Rate)), size = 4, fontface = fontFace, vjust = -1.5)

#Personnel Charts----------------------------------------------------------------------------------------------------------------------------------
personnel.contam <- subset(person.df, ConStatus == 'Contamination')
personnel.count <- with(personnel.contam, aggregate(Record~Year+Month+Week+PouchSerial+InstrumentSerial+Panel+Assay+Result+Department+ConStatus+Key, FUN=sum))
personnel.count$Record <- 1

#Cp
cps.person <- subset(personnel.contam, select = c('Year', 'Week', 'Assay', 'Cp', 'Record'))
cps.person$DateGroup <- with(cps.person, ifelse(Week < 10, paste(Year, Week, sep='-0'), paste(Year, Week, sep='-')))
cps.person <- merge(data.frame(DateGroup = unique(subset(calendar.week, DateGroup >= startDate.week)[,'DateGroup'])), subset(cps.person, DateGroup >= startDate.week), all = TRUE)
cps.person$Cp <- round(as.numeric(as.character(cps.person$Cp)))
cps.person$Assay <- ifelse(is.na(cps.person$Assay), 'HRV', as.character(cps.person$Assay))
p.cp.personnel <- ggplot(cps.person, aes(x=DateGroup, y=Cp)) + scale_y_continuous(breaks=pretty_breaks()) + geom_point(aes(color=Assay),size=3) + scale_color_manual(values=pal, name="") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90), legend.position = 'bottom') + labs(title='WEEKLY Personnel Contamination Cp', x='Date\n(Year-Week)', y='Cp') + guides(fill=guide_legend(nrow=5, by.row=TRUE)) + scale_x_discrete(breaks=dateBreaks)

#Personnel Contam by Department
department.count <- aggregateAndFillDateGroupGaps(calendar.mon, 'Month', personnel.count, c('Department', 'Assay'), startDate.mon, 'Record', 'sum', 0)
p.department.count <- ggplot(department.count, aes(x=DateGroup, y=Record, fill=Assay)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace , color='black'), axis.text.x=element_text(angle=90), legend.position="bottom") + labs(title='Personnel Contamination by Department', x='Date\n(Year-Month)', y='Count') + scale_fill_manual(values=pal, name='') + facet_wrap(~Department) + guides(fill=guide_legend(nrow=4, by.row=TRUE))

#personnel contamination rates
person.agg <- aggregateAndFillDateGroupGaps(calendar.mon, 'Month', person.df, 'Key', startDate.mon, 'Record', 'sum', 0)
person.contam.agg <- aggregateAndFillDateGroupGaps(calendar.mon, 'Month', personnel.contam, 'ConStatus', startDate.mon, 'Record', 'sum', 0)
person.rate <- mergeCalSparseFrames(person.contam.agg, person.agg, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, 0)
p.personnel.rate <- ggplot(person.rate,aes(x=DateGroup,y=Rate, group=1)) + geom_line(color='black') + geom_point() + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + scale_y_continuous(label=percent) +  labs(x='Date\n(Year-Month)', y='Contamination Rate', title='Personnel Contamination Observation Rates Based on Assay')

#positive contam counts
positive.counts.person <- aggregateAndFillDateGroupGaps(calendar.mon, 'Month', personnel.count, c('Assay', 'Panel'), startDate.mon, 'Record', 'sum', 0)
p.panel.personnel <- ggplot(positive.counts.person, aes(x=DateGroup, y=Record, fill=Assay)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace , color='black'), axis.text.x=element_text(angle=90), legend.position="bottom") + labs(title='Positive Contamination Counts: Personnel', x='Date\n(Year-Month)', y='Count') + scale_fill_manual(values=pal, name='') + facet_wrap(~Panel)  + guides(fill=guide_legend(nrow=4, by.row=TRUE))

#overall personnel contam vs no contam
#label individual pouch as contamination or no contamination - QUESTION: SHOULD THIS BE BASED ON NUMBER OF UNIQUE POUCHES RUN OR ASSAYS?
person.all <- subset(person.df, select=c('Year', 'Month', 'PouchSerial', 'ConStatus', 'Key', 'Record', 'DB'))
person.all$DateGroup <- with(person.all, ifelse(Month < 10, paste(Year, Month, sep='-0'), paste(Year, Month, sep='-')))
person.all <- subset(person.all, DateGroup >= startDate.mon)
person.all <- with(person.all, aggregate(Record~DateGroup+PouchSerial+ConStatus+Key, FUN=sum))
contam.p <- as.character(unique(subset(person.all, ConStatus == 'Contamination')[,'PouchSerial']))
pouch.person <- rbind(subset(person.all, !(PouchSerial %in% contam.p)), subset(person.all, PouchSerial %in% contam.p & ConStatus == 'Contamination'))
pouch.person$Record <- 1
pouch.person <- with(pouch.person, aggregate(Record~DateGroup+ConStatus+Key, FUN=sum))
pouch.person$ConStatus <- factor(pouch.person$ConStatus, levels = c('Contamination', 'No Contamination'))
pouch.person <- merge(with(subset(calendar.mon, DateGroup >= startDate.mon), aggregate(DateGroup~Year+Month, FUN=max)), pouch.person, by='DateGroup', all.x=TRUE)
pouch.person <- aggregateAndFillDateGroupGaps(calendar.mon, 'Month', pouch.person, c('ConStatus', 'Key'), startDate.mon, 'Record', 'sum', 0)
pouch.person$DateGroup <- factor(pouch.person$DateGroup, levels = sort(as.character(unique(pouch.person$DateGroup))))
percent.pos.p <- mergeCalSparseFrames(subset(pouch.person, ConStatus == 'Contamination'), with(pouch.person, aggregate(Record~DateGroup, FUN=sum)), 'DateGroup', 'DateGroup', 'Record', 'Record', 0, 0)
percent.pos.p <- merge(percent.pos.p, with(pouch.person, aggregate(Record~DateGroup, FUN=sum)))
p.personnel.pouch <- ggplot(pouch.person, aes(x=DateGroup, y=Record, fill=ConStatus, label = Record)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), plot.subtitle=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, face=fontFace)) + labs(title='Personnel Swabs: Count of Unique Pouches Run', subtitle = 'Percent Positive Shown Above Bar', y='Count', x='Date\n(Year-Month)') + scale_fill_manual(values=createPaletteOfVariableLength(pouch.person, 'ConStatus'), name='') + geom_text(size = 4, position = position_stack(vjust = 0.5), fontface = fontFace, color="lightgoldenrod1") + geom_text(data = percent.pos.p, aes(x=DateGroup, y=Record, label=percent(Rate)), size = 4, fontface = fontFace, vjust = -1.5)

#Pool Charts----------------------------------------------------------------------------------------------------------------------------------
pool.contam <- subset(pool.df, ConStatus == 'Contamination')
pool.count <- with(pool.contam, aggregate(Record~Year+Month+Week+PouchSerial+InstrumentSerial+Panel+Assay+Result+Pool+ConStatus+Key, FUN=sum))
pool.count$Record <- 1

#Cp
cps.pool <- subset(pool.contam, select = c('Year', 'Week', 'Assay', 'Cp', 'Record'))
cps.pool$DateGroup <- with(cps.pool, ifelse(Week < 10, paste(Year, Week, sep='-0'), paste(Year, Week, sep='-')))
cps.pool <- merge(data.frame(DateGroup = unique(subset(calendar.week, DateGroup >= startDate.week)[,'DateGroup'])), subset(cps.pool, DateGroup >= startDate.week), all = TRUE)
cps.pool$Cp <- round(as.numeric(as.character(cps.pool$Cp)))
cps.pool$Assay <- ifelse(is.na(cps.pool$Assay), 'HRV', as.character(cps.pool$Assay))
p.cp.pool <- ggplot(cps.pool, aes(x=DateGroup, y=Cp)) + scale_y_continuous(breaks=pretty_breaks()) + geom_point(aes(color=Assay),size=3) + scale_color_manual(values=pal, name="") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90), legend.position = 'bottom') + labs(title='WEEKLY Pool Contamination Cp', x='Date\n(Year-Week)', y='Cp') + guides(fill=guide_legend(nrow=5, by.row=TRUE)) + scale_x_discrete(breaks=dateBreaks)

#Pool Contam rates
pool.agg <- aggregateAndFillDateGroupGaps(calendar.mon, 'Month', pool.df, 'Key', startDate.mon, 'Record', 'sum', 0)
pool.contam.agg <- aggregateAndFillDateGroupGaps(calendar.mon, 'Month', pool.contam, 'ConStatus', startDate.mon, 'Record', 'sum', 0)
pool.rate <- mergeCalSparseFrames(pool.contam.agg, pool.agg, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, 0)
p.pool.rate <- ggplot(pool.rate,aes(x=DateGroup,y=Rate, group=1)) + geom_line(color='black') + geom_point() + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + scale_y_continuous(label=percent) +  labs(x='Date\n(Year-Month)', y='Contamination Rate', title='Pool Contamination Observation Rates Based on Assay')

#Count by Pool Number
poolNumber.count <- aggregateAndFillDateGroupGaps(calendar.mon, 'Month', pool.count, c('Pool', 'Assay'), startDate.mon, 'Record', 'sum', 0)
poolNumber.count <- subset(poolNumber.count, Pool %in% 1:60)
poolNumber.count$Pool <- as.numeric(as.character(poolNumber.count$Pool))
p.pool.count <- ggplot(poolNumber.count, aes(x=DateGroup, y=Record, fill=Assay)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace , color='black'), axis.text.x=element_text(angle=90), legend.position="bottom") + labs(title='Pool Contamination by Pool Number', x='Date\n(Year-Month)', y='Count') + scale_fill_manual(values=pal, name='') + facet_wrap(~Pool) + guides(fill=guide_legend(nrow=4, by.row=TRUE))

#Positive Contam counts
positive.counts.pool <- aggregateAndFillDateGroupGaps(calendar.mon, 'Month', pool.count, c('Assay', 'Panel'), startDate.mon, 'Record', 'sum', 0)
p.panel.pool <- ggplot(positive.counts.pool, aes(x=DateGroup, y=Record, fill=Assay)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace , color='black'), axis.text.x=element_text(angle=90), legend.position="bottom") + labs(title='Positive Contamination Counts: Pool', x='Date\n(Year-Month)', y='Count') + scale_fill_manual(values=pal, name='') + facet_wrap(~Panel)  + guides(fill=guide_legend(nrow=4, by.row=TRUE))

#overall personnel contam vs no contam
#label individual pouch as contamination or no contamination - QUESTION: SHOULD THIS BE BASED ON NUMBER OF UNIQUE POUCHES RUN OR ASSAYS?
pool.all <- subset(pool.df, select=c('Year', 'Month', 'PouchSerial', 'ConStatus', 'Key', 'Record', 'DB'))
pool.all$DateGroup <- with(pool.all, ifelse(Month < 10, paste(Year, Month, sep='-0'), paste(Year, Month, sep='-')))
pool.all <- subset(pool.all, DateGroup >= startDate.mon)
pool.all <- with(pool.all, aggregate(Record~DateGroup+PouchSerial+ConStatus+Key, FUN=sum))
contam.o <- as.character(unique(subset(pool.all, ConStatus == 'Contamination')[,'PouchSerial']))
pouch.pool <- rbind(subset(pool.all, !(PouchSerial %in% contam.o)), subset(pool.all, PouchSerial %in% contam.o & ConStatus == 'Contamination'))
pouch.pool$Record <- 1
pouch.pool <- with(pouch.pool, aggregate(Record~DateGroup+ConStatus+Key, FUN=sum))
pouch.pool$ConStatus <- factor(pouch.pool$ConStatus, levels = c('Contamination', 'No Contamination'))
pouch.pool <- merge(with(subset(calendar.mon, DateGroup >= startDate.mon), aggregate(DateGroup~Year+Month, FUN=max)), pouch.pool, by='DateGroup', all.x=TRUE)
pouch.pool <- aggregateAndFillDateGroupGaps(calendar.mon, 'Month', pouch.pool, c('ConStatus', 'Key'), startDate.mon, 'Record', 'sum', 0)
pouch.pool$DateGroup <- factor(pouch.pool$DateGroup, levels = sort(as.character(unique(pouch.pool$DateGroup))))
percent.pos.o <- mergeCalSparseFrames(subset(pouch.pool, ConStatus == 'Contamination'), with(pouch.pool, aggregate(Record~DateGroup, FUN=sum)), 'DateGroup', 'DateGroup', 'Record', 'Record', 0, 0)
percent.pos.o <- merge(percent.pos.o, with(pouch.pool, aggregate(Record~DateGroup, FUN=sum)))
p.pool.pouch <- ggplot(pouch.pool, aes(x=DateGroup, y=Record, fill=ConStatus, label = Record)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), plot.subtitle=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, face=fontFace)) + labs(title='Pool Swabs: Count of Unique Pouches Run', subtitle = 'Percent Positive Shown Above Bar', y='Count', x='Date\n(Year-Month)') + scale_fill_manual(values=createPaletteOfVariableLength(pouch.pool, 'ConStatus'), name='') + geom_text(size = 4, position = position_stack(vjust = 0.5), fontface = fontFace, color="lightgoldenrod1") + geom_text(data = percent.pos.o, aes(x=DateGroup, y=Record, label=percent(Rate)), size = 4, fontface = fontFace, vjust = -1.5)

#----------------------------------
# chart showing pool, people, and environmental
pouch.all <- rbind(pouch.environ, pouch.person, pouch.pool)
pouch.all <- subset(pouch.all, ConStatus == 'Contamination')
percent.pos.all <- rbind(percent.pos.e, percent.pos.o, percent.pos.p)
percent.pos.all <- merge(pouch.all, percent.pos.all, by=c('DateGroup', 'ConStatus', 'Key'))
p.all.rate <- ggplot(percent.pos.all, aes(x=DateGroup, y=Rate, group=Key, color=Key)) + geom_line() + geom_point() + theme(plot.subtitle=element_text(hjust=0.5), plot.title=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, face=fontFace), axis.text=element_text(size=fontSize, color='black', face=fontFace)) + scale_y_continuous(label=percent) +  labs(x='Date\n(Year-Month)', y='Percent Positive', title='Contamination Rates: Percent Positive per Pouch', subtitle='Amount Positive Labeled') + geom_text(aes(label = Record.x), size = 4, vjust = -1, fontface = fontFace, show.legend=FALSE) + scale_color_manual(name='', values=createPaletteOfVariableLength(percent.pos.all, 'Key')) + expand_limits(y=max(percent.pos.all$Rate) + 0.01) + facet_wrap(~Key, ncol=1) 

#VP approval chart
vpApp <- aggregateAndFillDateGroupGaps(calendar.mon, 'Month', vpAppYesBar.df, 'Key', startDate.mon, 'Record', 'sum', NA)
vpApp$Key <- factor(vpApp$Key, levels = c('Yes', 'No'))
p.vpApproval <- ggplot(vpApp, aes(x=DateGroup, y=Record, fill=Key, label = Record)) + geom_bar(stat="identity") + theme(plot.title=element_text(hjust=0.5), plot.subtitle=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, face=fontFace)) + labs(title='VP Approval Count', y='Count', x='Date\n(Year-Month)') + scale_fill_manual(values=createPaletteOfVariableLength(vpApp, 'Key'), name='') + geom_text(size = 4, position = position_stack(vjust = 0.5), fontface = fontFace, color="lightgoldenrod1")

# Export Images for the Web Hub
setwd(imgDir)
plots <- ls()[grep('^p\\.', ls())]
for(i in 1:length(plots)) {
  imgName <- paste(substring(plots[i],3),'.png',sep='')
  
  png(file=imgName, width=1200, height=800, units='px')
  print(get(plots[i]))
  makeTimeStamp(author='Data Science')
  dev.off()
}

# Export PDF for the Web Hub
setwd(pdfDir)
pdf("Contamination.pdf", width = 11, height = 8)
for(i in 1:length(plots)) {
  print(get(plots[i]))
}
dev.off()

rm(list = ls())
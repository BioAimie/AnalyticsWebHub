workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_ProgramManagement'
pdfDir <- '~/WebHub/pdfs/'

setwd(workDir)

# Load needed libraries
library(ggplot2)
library(scales)
library(zoo)
library(dateManip)

# load the data from SQL
source('Portfolios/O_PMG_load.R')

source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/makeTimeStamp.R')

lagPeriods <- 4

calendar.week <- createCalendarLikeMicrosoft(2015, 'Week')
calendar.month <- createCalendarLikeMicrosoft(2015, 'Month')

theme_set(theme_gray() + theme(plot.title = element_text(hjust = 0.5)))

#--------------------------------Prepare the data------------------------------------------------------------------------------------------------------

MeqNCR.df <- merge(NCR.df,Meq.df, by.x='PartAffected', by.y='ComponentItemID')
MeqNCR.df <- merge(MeqNCR.df, MeqSerials, by.x='SerialNo', by.y='SerialNumber', all.x = TRUE)
MeqNCR.df$BuildYear <- ifelse(is.na(MeqNCR.df$BuildYear),
                              'unknown', 
                              MeqNCR.df$BuildYear
                              )

MeqNCR.df <- with(MeqNCR.df, aggregate(Record~Year+Month+Week+CreatedDate+MEQ+MEQType+Status+SupplierResponsible+WhereFound+Type+BuildYear+FailCat+SubFailCat, FUN=sum))

#60-90-120 day paretos
D120 <- Sys.Date() - 120
D90 <- Sys.Date() - 90
D60 <- Sys.Date() - 60
ltd.ncr.120 <- subset(MeqNCR.df, CreatedDate >= D120 & CreatedDate < D90); ltd.ncr.120 <- with(ltd.ncr.120, aggregate(Record~MEQ+MEQType+Status+Type, FUN=sum)); ltd.ncr.120$Key <- '120 Day (net)'
ltd.ncr.90 <- subset(MeqNCR.df, CreatedDate >= D90 & CreatedDate < D60); ltd.ncr.90 <- with(ltd.ncr.90, aggregate(Record~MEQ+MEQType+Status+Type, FUN=sum)); ltd.ncr.90$Key <- '90 Day (net)'
ltd.ncr.60 <- subset(MeqNCR.df, CreatedDate >= D60); ltd.ncr.60 <- with(ltd.ncr.60, aggregate(Record~MEQ+MEQType+Status+Type, FUN=sum)); ltd.ncr.60$Key <- '60 Day'
ltd.ncr <- rbind(ltd.ncr.120, ltd.ncr.90, ltd.ncr.60)

startstring.week <- findStartDate(calendar.week, 'Week',54, lagPeriods)
#show since beginning of 2016 or 1 year
if(startstring.week < '2015-51') {
  startstring.week <- '2015-51'
}

startstring.month <- findStartDate(calendar.month, 'Month', 13)
#show since beginning of 2016 or 1 year
if(startstring.month < '2016-01') {
  startstring.month <- '2016-01'
}

denom <- subset(MeqNCR.df, select=c('Year','Week','MEQ','MEQType','Record'))
denom <- aggregateAndFillDateGroupGaps(calendar.week, 'Week',denom, c('MEQ'), startstring.week,'Record','sum',0)
denom <- with(denom, aggregate(Record~DateGroup, FUN=sum))

#--------------------------------------------------Pareto of Pouch MEQs-----------------------------------------------------------------------------------
#subset just Pouch MEQs
pouch.pareto <- subset(ltd.ncr, MEQType == 'Pouch')

#order MEQ factors
bottomPouch <- with(pouch.pareto, aggregate(Record~MEQ, FUN=sum))
bottomPouch <- bottomPouch[with(bottomPouch, order(-Record)), ]
bottom <- as.character(bottomPouch$MEQ)
pouch.pareto$MEQ <- factor(pouch.pareto$MEQ, levels = bottom, ordered=TRUE)

pouch.pareto.status <- with(pouch.pareto, aggregate(Record~MEQ+Status+Key, FUN=sum))
paretoOrder <- c('120 Day (net)','90 Day (net)','60 Day')
pouch.pareto.status$Key <- factor(pouch.pareto.status$Key, levels = paretoOrder, ordered=TRUE)
pouch.pareto.status <- pouch.pareto.status[order(pouch.pareto.status$Key, decreasing=TRUE), ]

#Create integer Breaks
intBa <- max(pouch.pareto.status$Record)
if(intBa > 10) {
  intBa <- 10
}

p.Last120Days.pouch <- ggplot(pouch.pareto.status, aes(x=MEQ, y=Record, fill=Key)) + geom_bar(stat='identity') + scale_y_continuous(breaks=pretty_breaks(n=intBa)) +
  facet_wrap(~Status, ncol=1) + xlab('Pouch MEQs with NCRs') + ylab('Count of NCRs') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90,vjust=0.5, color='black',size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Pouch MEQ NCRs') + scale_fill_manual(values=createPaletteOfVariableLength(pouch.pareto.status, 'Key'), name='')

#-------------------------------------------Pareto of Pouch MEQs by NCR Type and Status-----------------------------------------
pouch.pareto.type <- with(subset(pouch.pareto, as.character(Key) != '120 Day (net)'), aggregate(Record~MEQ+Status+Type, FUN=sum))
paretoTypeColors.pouch <- createPaletteOfVariableLength(pouch.pareto.type, 'Type')

p.LastNinetyDaysType.pouch <- ggplot(pouch.pareto.type, aes(x=MEQ, y=Record, fill=Type)) + geom_bar(stat='identity') + scale_y_continuous(breaks=pretty_breaks(n=intBa)) +
  facet_wrap(~Status, ncol=1) + xlab('Pouch MEQs with NCRs') + ylab('Count of NCRs') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90,vjust=0.5, color='black',size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Pouch MEQ NCRs From Last 90 Days\nby NCR Type') + scale_fill_manual(values=paretoTypeColors.pouch, name = 'NCR Type')

#-------------------------------------------Thumbnail chart of each MEQ in Pouch MEQs ----------------------------------------------------------------

#grab only pouch MEQs
pouch.ncr <- subset(MeqNCR.df, as.character(MEQType) == 'Pouch')

#order pouch factors
pouch.order <- with(pouch.ncr, aggregate(Record~MEQ, FUN=sum))
pouch.order <- pouch.order[with(pouch.order,order(-Record)), ]
bottomp <- unique(as.character(pouch.order$MEQ))

pouch.chart1<- aggregateAndFillDateGroupGaps(calendar.week, 'Week', pouch.ncr, c('MEQ'), startstring.week,'Record','sum',0)
pouch.chart1 <- mergeCalSparseFrames(pouch.chart1, denom, c('DateGroup'), c('DateGroup'), 'Record', 'Record', NA, lagPeriods)
pouch.chart1$MEQ <- factor(pouch.chart1$MEQ, levels = bottomp, ordered = TRUE)

p.Average.pouch <- ggplot(pouch.chart1, aes(x=DateGroup, y=Rate, group=MEQ)) + geom_line(color='black') + geom_point(color='black') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, hjust=1,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  labs(title='Pouch MEQ NCRs per Total MEQ NCRs', x='Date\n(Year-Week)', y='4-week Rolling Average') + facet_wrap(~MEQ, scales='free_y') + 
  scale_y_continuous(label=percent) + 
  scale_x_discrete(breaks=as.character(unique(pouch.chart1[,'DateGroup']))[order(as.character(unique(pouch.chart1[,'DateGroup'])))][seq(1,length(as.character(unique(pouch.chart1[,'DateGroup']))), 12)])

#--------------------------------------------Where Found for Pouch MEQs (week) -------------------------------------
pouch.where <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', pouch.ncr, c('MEQ', 'WhereFound'), startstring.week, 'Record', 'sum', 0)
pouch.where <- mergeCalSparseFrames(pouch.where, denom, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, lagPeriods)
pouch.where$MEQ <- factor(pouch.where$MEQ, levels = bottomp, ordered = TRUE)

pouch.where$WhereFound <- factor(pouch.where$WhereFound, levels = as.character(unique(pouch.where$WhereFound)), ordered=TRUE)
pouch.where <- pouch.where[with(pouch.where, order(WhereFound)),]

whereColors <- createPaletteOfVariableLength(pouch.where, 'WhereFound')

p.WhereFoundPerMEQ.pouch <- ggplot(pouch.where, aes(x=DateGroup, y=Rate, group=MEQ, fill=WhereFound)) + geom_bar(stat='identity', position='stack') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, hjust=1,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  labs(title='Pouch MEQ NCRs per Total MEQ NCRs\nBy Where Found', x='Date\n(Year-Week)', y='4-week Rolling Average') + facet_wrap(~MEQ, scales='free_y') + 
  scale_y_continuous(label=percent) + scale_fill_manual(name= 'Where Found', values = whereColors) + 
  scale_x_discrete(breaks=as.character(unique(pouch.chart1[,'DateGroup']))[order(as.character(unique(pouch.chart1[,'DateGroup'])))][seq(1,length(as.character(unique(pouch.chart1[,'DateGroup']))), 12)])

#-----------------------------------------------------Pouch NCRs by Supplier Responsiblity--------------------------------------------------------------------------
pouch.supp <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', pouch.ncr, c('MEQ', 'SupplierResponsible'), startstring.week,'Record','sum',0)
pouch.supp <- mergeCalSparseFrames(pouch.supp, denom, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, lagPeriods)
pouch.supp$MEQ <- factor(pouch.supp$MEQ, levels = bottomp, ordered = TRUE)

#order factors
pouch.supp$SupplierResponsible <- factor(pouch.supp$SupplierResponsible, levels = c('Yes', 'No', 'Unknown', 'N/A'), ordered=TRUE)
pouch.supp <- pouch.supp[with(pouch.supp, order(SupplierResponsible)),]

suppColors <- createPaletteOfVariableLength(pouch.supp, 'SupplierResponsible')

p.SupplierResponsibilityPerMEQ.pouch <- ggplot(pouch.supp, aes(x=DateGroup, y=Rate, group=MEQ, fill=SupplierResponsible)) + geom_bar(stat='identity', position='stack') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, hjust=1,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  labs(title='Pouch MEQ NCRs per Total MEQ NCRs\nBy Supplier Responsiblity', x='Date\n(Year-Week)', y='4-week Rolling Average') + facet_wrap(~MEQ, scales='free_y') + 
  scale_y_continuous(label=percent) + scale_fill_manual(name= 'Supplier Responsible?', values = suppColors) + 
  scale_x_discrete(breaks=as.character(unique(pouch.supp[,'DateGroup']))[order(as.character(unique(pouch.supp[,'DateGroup'])))][seq(1,length(as.character(unique(pouch.supp[,'DateGroup']))), 12)])

#--------------------------------------------------Monthly count of NCRs per Pouch MEQ - IMAGE3------------------------------------------------------------------

pouch.chart2 <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', pouch.ncr, 'MEQ', startstring.month, 'Record','sum',0)

#Create integer Breaks
intBreaks.df <- with(pouch.chart2, aggregate(Record~DateGroup, FUN=sum))
intBreaks.num <- max(intBreaks.df$Record)
if(intBreaks.num > 10) {
  intBreaks.num <- 10
}

pouch.pal <- createPaletteOfVariableLength(pouch.chart2, 'MEQ')

p.MonthlyCountMEQ.pouch <- ggplot(pouch.chart2, aes(x=DateGroup, y=Record, fill=MEQ)) + geom_bar(stat='identity', position='stack') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, hjust=1,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  labs(title='Pouch MEQ NCRs', x='Date\n(Year-Month)', y='Count of NCRs') + scale_y_continuous(breaks=pretty_breaks(n=intBreaks.num)) +
  scale_fill_manual(values=pouch.pal)

#----------------------------------------Monthly count of NCRs per WhereFound--------------------------------------
pouch.where.mon <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', pouch.ncr, 'WhereFound', startstring.month, 'Record','sum',0)

pouch.where.pal <- createPaletteOfVariableLength(pouch.where.mon, 'WhereFound')

p.WhereFound.pouch <- ggplot(pouch.where.mon, aes(x=DateGroup, y=Record, fill=WhereFound)) + geom_bar(stat='identity', position='stack') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, hjust=1,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  labs(title='Pouch MEQ NCRs by Where Found', x='Date\n(Year-Month)', y='Count of NCRs') + scale_y_continuous(breaks=pretty_breaks(n=intBreaks.num)) +
  scale_fill_manual(values=pouch.where.pal)

#----------------------------------------Monthly count of NCRs per BuildYear--------------------------------------
pouch.build.mon <- subset(pouch.ncr, as.character(WhereFound) == 'Pouch Manufacture')
pouch.build.mon <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', pouch.build.mon, 'BuildYear', startstring.month, 'Record','sum',0)

pouch.build.pal <- createPaletteOfVariableLength(pouch.build.mon, 'BuildYear')

p.BuildYear.pouch <- ggplot(pouch.build.mon, aes(x=DateGroup, y=Record, fill=BuildYear)) + geom_bar(stat='identity', position='stack') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, hjust=1,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  labs(title='Pouch MEQ NCRs by Build Year\nFound in Pouch Manufacturing', x='Date\n(Year-Month)', y='Count of NCRs') + scale_y_continuous(breaks=pretty_breaks(n=intBreaks.num)) +
  scale_fill_manual(values=pouch.build.pal)

#----------------------------------------Top Failure + SubFailure Categories in last 90 days Pareto ---------------------------------------------
pouch.fail <- with(subset(pouch.ncr, CreatedDate >= D90), aggregate(Record~FailCat+SubFailCat, FUN=sum))

#select all or bottom 10 (if more than 10)
failCat <- with(pouch.fail, aggregate(Record~FailCat, FUN=sum))
failCat <- failCat[with(failCat, order(Record)), ]
if (length(failCat[ ,'FailCat']) > 10) {
  failCat <- head(failCat,10)
}
pouch.fail <- subset(pouch.fail, FailCat %in% unique(as.character(failCat$FailCat)))

#order fail factors
pouch.fail$FailCat <- factor(pouch.fail$FailCat, levels = unique(as.character(failCat$FailCat)), ordered=TRUE)

pouch.fail.pal <- createPaletteOfVariableLength(pouch.fail, 'SubFailCat')

#Create integer Breaks
intpouch.Fail <- max(pouch.fail$Record)
if(intpouch.Fail > 10) {
  intpouch.Fail <- 10
}

p.FailureCatMEQ.pouch <- ggplot(pouch.fail, aes(x=FailCat, y=Record, fill=SubFailCat)) + geom_bar(stat='identity') + scale_y_continuous(breaks=pretty_breaks(n=intpouch.Fail)) +
  xlab('Failure Category') + ylab('Count') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5, color='black',size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + coord_flip() + ggtitle('Top Pouch MEQ Failure Categories From Last 90 Days') + scale_fill_manual(values=pouch.fail.pal, name = 'Sub-Failure Category')

#--------------------------------------------------Pareto of Array MEQs ------------------------------------------------------------------------------------
#subset just Array MEQs
array.pareto <- subset(ltd.ncr, MEQType == 'Array')

bottomArray <- with(array.pareto, aggregate(Record~MEQ, FUN=sum))
bottomArray <- bottomArray[with(bottomArray, order(-Record)), ]
bottom <- as.character(bottomArray$MEQ)
array.pareto$MEQ <- factor(array.pareto$MEQ, levels = bottom, ordered=TRUE)

array.pareto.status <- with(array.pareto, aggregate(Record~MEQ+Status+Key, FUN=sum))
array.pareto.status$Key <- factor(array.pareto.status$Key, levels = paretoOrder, ordered=TRUE)
array.pareto.status <- array.pareto.status[order(array.pareto.status$Key, decreasing=TRUE), ]

#Create integer Breaks
intBb <- max(array.pareto.status$Record)
if(intBb > 10) {
  intBb <- 10
}

p.Last120Days.array <- ggplot(array.pareto.status, aes(x=MEQ, y=Record, fill=Key)) + geom_bar(stat='identity') + scale_y_continuous(breaks=pretty_breaks(n=intBb)) +
  facet_wrap(~Status, ncol=1) + xlab('Array MEQs with NCRs') + ylab('Count of NCRs') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90,vjust=0.5, color='black',size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Array MEQ NCRs') + scale_fill_manual(values=createPaletteOfVariableLength(array.pareto.status, 'Key'), name='')

#-------------------------------------------Pareto of Array MEQs by NCR Type and Status-----------------------------------------
array.pareto.type <- with(subset(array.pareto, as.character(Key) != '120 Day (net)'), aggregate(Record~MEQ+Status+Type, FUN=sum))
paretoTypeColors.array <- createPaletteOfVariableLength(array.pareto.type, 'Type')

p.LastNinetyDaysType.array <- ggplot(array.pareto.type, aes(x=MEQ, y=Record, fill=Type)) + geom_bar(stat='identity') + scale_y_continuous(breaks=pretty_breaks(n=intBb)) +
  facet_wrap(~Status, ncol=1) + xlab('Array MEQs with NCRs') + ylab('Count of NCRs') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90,vjust=0.5, color='black',size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Array MEQ NCRs From Last 90 Days\nby NCR Type') + scale_fill_manual(values=paretoTypeColors.array, name = 'NCR Type')

#-------------------------------------------Thumbnail chart of each MEQ in Array MEQs --------------------------------------------------------------
#grab only array MEQs
array.ncr <- subset(MeqNCR.df, as.character(MEQType) == 'Array')

#order array factors
array.order <- with(array.ncr, aggregate(Record~MEQ, FUN=sum))
array.order <- array.order[with(array.order,order(-Record)), ]
bottoma <- unique(as.character(array.order$MEQ))

array.chart1<- aggregateAndFillDateGroupGaps(calendar.week, 'Week', array.ncr, c('MEQ'), startstring.week,'Record','sum',0)
array.chart1 <- mergeCalSparseFrames(array.chart1, denom, c('DateGroup'), c('DateGroup'), 'Record', 'Record', NA, lagPeriods)
array.chart1$MEQ <- factor(array.chart1$MEQ, levels = bottoma, ordered = TRUE)

p.Average.array <- ggplot(array.chart1, aes(x=DateGroup, y=Rate, group=MEQ)) + geom_line(color='black') + geom_point(color='black') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, hjust=1,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  labs(title='Array MEQ NCRs per Total MEQ NCRs', x='Date\n(Year-Week)', y='4-week Rolling Average') + facet_wrap(~MEQ) +
  scale_y_continuous(label=percent) + 
  scale_x_discrete(breaks=as.character(unique(array.chart1[,'DateGroup']))[order(as.character(unique(array.chart1[,'DateGroup'])))][seq(1,length(as.character(unique(array.chart1[,'DateGroup']))), 12)])

#--------------------------------------------Where Found for Array MEQs (week) -------------------------------------
array.where <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', array.ncr, c('MEQ', 'WhereFound'), startstring.week, 'Record', 'sum', 0)
array.where <- mergeCalSparseFrames(array.where, denom, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, lagPeriods)
array.where$MEQ <- factor(array.where$MEQ, levels = bottoma, ordered = TRUE)

array.where$WhereFound <- factor(array.where$WhereFound, levels = as.character(unique(array.where$WhereFound)), ordered=TRUE)
array.where <- array.where[with(array.where, order(WhereFound)),]

whereColors.array <- createPaletteOfVariableLength(array.where, 'WhereFound')

p.WhereFoundPerMEQ.array <- ggplot(array.where, aes(x=DateGroup, y=Rate, group=MEQ, fill=WhereFound)) + geom_bar(stat='identity', position='stack') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, hjust=1,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  labs(title='Array MEQ NCRs per Total MEQ NCRs\nBy Where Found', x='Date\n(Year-Week)', y='4-week Rolling Average') + facet_wrap(~MEQ, scales='free_y') + 
  scale_y_continuous(label=percent) + scale_fill_manual(name= 'Where Found', values = whereColors.array) + 
  scale_x_discrete(breaks=as.character(unique(array.chart1[,'DateGroup']))[order(as.character(unique(array.chart1[,'DateGroup'])))][seq(1,length(as.character(unique(array.chart1[,'DateGroup']))), 12)])

#-----------------------------------------------------Array NCRs by Supplier Responsiblity--------------------------------------------------------------------------
array.supp <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', array.ncr, c('MEQ', 'SupplierResponsible'), startstring.week,'Record','sum',0)
array.supp <- mergeCalSparseFrames(array.supp, denom, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, lagPeriods)
array.supp$MEQ <- factor(array.supp$MEQ, levels = bottoma, ordered = TRUE)

#order factors
array.supp$SupplierResponsible <- factor(array.supp$SupplierResponsible, levels = c('Yes', 'No', 'Unknown', 'N/A'), ordered=TRUE)
array.supp <- array.supp[with(array.supp, order(SupplierResponsible)),]

suppColors.a <- createPaletteOfVariableLength(array.supp, 'SupplierResponsible')

p.SupplierResponsibilityPerMEQ.array <- ggplot(array.supp, aes(x=DateGroup, y=Rate, group=MEQ, fill=SupplierResponsible)) + geom_bar(stat='identity', position='stack') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, hjust=1,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  labs(title='Array MEQ NCRs per Total MEQ NCRs\nBy Supplier Responsiblity', x='Date\n(Year-Week)', y='4-week Rolling Average') + facet_wrap(~MEQ, scales='free_y') + 
  scale_y_continuous(label=percent) + scale_fill_manual(name= 'Supplier Responsible?', values = suppColors.a) + 
  scale_x_discrete(breaks=as.character(unique(array.supp[,'DateGroup']))[order(as.character(unique(array.supp[,'DateGroup'])))][seq(1,length(as.character(unique(array.supp[,'DateGroup']))), 12)])

#--------------------------------------------------Monthly count of NCRs per Array MEQ -------------------------------------------------------------------
array.chart2 <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', array.ncr, 'MEQ', startstring.month, 'Record', 'sum',0)

#Create integer Breaks
intB1.df <- with(array.chart2, aggregate(Record~DateGroup, FUN=sum))
intB1.num <- max(intB1.df$Record)
if(intB1.num > 10) {
  intB1.num <- 10
}

array.pal <- createPaletteOfVariableLength(array.chart2, 'MEQ')

p.MonthlyCountMEQ.array <- ggplot(array.chart2, aes(x=DateGroup, y=Record, fill=MEQ)) + geom_bar(stat='identity', position='stack') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, hjust=1,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  labs(title='Array MEQ NCRs', x='Date\n(Year-Month)', y='Count of NCRs') + scale_y_continuous(breaks=pretty_breaks(n=intB1.num)) +
  scale_fill_manual(values=array.pal)

#----------------------------------------Monthly count of NCRs per WhereFound--------------------------------------
array.where.mon <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', array.ncr, 'WhereFound', startstring.month, 'Record','sum',0)

array.where.pal <- createPaletteOfVariableLength(array.where.mon, 'WhereFound')

p.WhereFound.array <- ggplot(array.where.mon, aes(x=DateGroup, y=Record, fill=WhereFound)) + geom_bar(stat='identity', position='stack') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, hjust=1,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  labs(title='Array MEQ NCRs by Where Found', x='Date\n(Year-Month)', y='Count of NCRs') + scale_y_continuous(breaks=pretty_breaks(n=intB1.num)) +
  scale_fill_manual(values=array.where.pal)

#----------------------------------------Monthly count of NCRs per BuildYear--------------------------------------
array.build.mon <- subset(array.ncr, as.character(WhereFound) == 'Pouch Manufacture')
array.build.mon$DateGroup <- with(array.build.mon, ifelse(Month < 10, paste0(Year,'-0', Month), paste0(Year,'-', Month)))
if(nrow(subset(array.build.mon, DateGroup >= startstring.month)) > 0) {
  array.build.mon <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', array.build.mon, 'BuildYear', startstring.month, 'Record','sum',0)
  array.build.pal <- createPaletteOfVariableLength(array.build.mon, 'BuildYear')
  p.BuildYear.array <- ggplot(array.build.mon, aes(x=DateGroup, y=Record, fill=BuildYear)) + geom_bar(stat='identity', position='stack') + 
    theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, hjust=1,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
    labs(title='Array MEQ NCRs by Build Year\nFound in Pouch Manufacturing', x='Date\n(Year-Month)', y='Count of NCRs') + scale_y_continuous(breaks=pretty_breaks(n=intB1.num)) +
    scale_fill_manual(values=array.build.pal)
} else {
  emptyPlot <- data.frame(DateGroup = as.character(unique(subset(calendar.month, DateGroup >= startstring.month)[,'DateGroup'])), Record = 0)
  p.BuildYear.array <- ggplot(emptyPlot, aes(x=DateGroup, y=Record)) + geom_bar(stat='identity') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, hjust=1,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + labs(title='Array MEQ NCRs by Build Year\nFound in Pouch Manufacturing', x='Date\n(Year-Month)', y='Count of NCRs')
}

#----------------------------------------Top Failure + SubFailure Categories in last 60 days Pareto ---------------------------------------------
array.fail <- with(subset(array.ncr, CreatedDate >= D90), aggregate(Record~FailCat+SubFailCat, FUN=sum))

#select all or bottom 10 (if more than 10)
failCat <- with(array.fail, aggregate(Record~FailCat, FUN=sum))
failCat <- failCat[with(failCat, order(Record)), ]
if (length(failCat[ ,'FailCat']) > 10) {
  failCat <- head(failCat,10)
}
array.fail <- subset(array.fail, FailCat %in% unique(as.character(failCat$FailCat)))

#order fail factors
array.fail$FailCat <- factor(array.fail$FailCat, levels = unique(as.character(failCat$FailCat)), ordered=TRUE)

array.fail.pal <- createPaletteOfVariableLength(array.fail, 'SubFailCat')

#Create integer Breaks
intarray.Fail <- max(array.fail$Record)
if(intarray.Fail > 10) {
  intarray.Fail <- 10
}

p.FailureCatMEQ.array <- ggplot(array.fail, aes(x=FailCat, y=Record, fill=SubFailCat)) + geom_bar(stat='identity') + scale_y_continuous(breaks=pretty_breaks(n=intarray.Fail)) +
  xlab('Failure Category') + ylab('Count') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5, color='black',size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + coord_flip() + ggtitle('Top Array MEQ Failure Categories From Last 90 Days') + scale_fill_manual(values=array.fail.pal, name = 'Sub-Failure Category')

#--------------------------------------------------Pareto of Semi-Automated Array MEQs ------------------------------------------------------------------------------------
#subset just Semi-Automated Array MEQs
sarray.pareto <- subset(ltd.ncr, MEQType == 'Semi-Automated Array')
if (nrow(sarray.pareto) > 0) {
  bottomSArray <- with(sarray.pareto, aggregate(Record~MEQ, FUN=sum))
  bottomSArray <- bottomSArray[with(bottomSArray, order(-Record)), ]
  bottom <- as.character(bottomSArray$MEQ)
  sarray.pareto$MEQ <- factor(sarray.pareto$MEQ, levels = bottom, ordered=TRUE)

  sarray.pareto.status <- with(sarray.pareto, aggregate(Record~MEQ+Status+Key, FUN=sum))
  sarray.pareto.status$Key <- factor(sarray.pareto.status$Key, levels = paretoOrder, ordered=TRUE)
  sarray.pareto.status <- sarray.pareto.status[order(sarray.pareto.status$Key, decreasing=TRUE), ]
  
  #Create integer Breaks
  intBc <- max(sarray.pareto.status$Record)
  if(intBc > 10) {
    intBc <- 10
  }
  
  p.Last120Days.saarray <- ggplot(sarray.pareto.status, aes(x=MEQ, y=Record, fill=Key)) + geom_bar(stat='identity') + scale_y_continuous(breaks=pretty_breaks(n=intBc)) +
    facet_wrap(~Status, ncol=1) + xlab('Semi-Automated Array MEQs with NCRs') + ylab('Count of NCRs') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90,vjust=0.5, color='black',size=20), 
    axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Semi-Automated Array MEQ NCRs') + scale_fill_manual(values= createPaletteOfVariableLength(sarray.pareto.status, 'Key'), name='')
  
} else {
  p.Last120Days.saarray <- ggplot() + geom_bar(stat='identity') + xlab('Semi-Automated Array MEQs with NCRs') + ylab('Count of NCRs') + 
    theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90,vjust=0.5, color='black',size=20), 
    axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Semi-Automated Array MEQ NCRs From Last 60 Days')
}

#-------------------------------------------Pareto of Semi-Automated Array MEQs by NCR Type and Status-----------------------------------------
sarray.pareto.type <- with(subset(sarray.pareto, as.character(Key) != '120 Day (net)'), aggregate(Record~MEQ+Status+Type, FUN=sum))
paretoTypeColors.sarray <- createPaletteOfVariableLength(sarray.pareto, 'Type')

p.LastNinetyDaysType.saarray <- ggplot(sarray.pareto.type, aes(x=MEQ, y=Record, fill=Type)) + geom_bar(stat='identity') + scale_y_continuous(breaks=pretty_breaks(n=intBc)) +
  facet_wrap(~Status, ncol=1) + xlab('Semi-Automated Array MEQs with NCRs') + ylab('Count of NCRs') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90,vjust=0.5, color='black',size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Semi-Automated Array MEQ NCRs From Last 90 Days\nby NCR Type') + scale_fill_manual(values=paretoTypeColors.sarray, name = 'NCR Type')

#-------------------------------------------Thumbnail chart of each MEQ in Semi-Automated Array MEQs -----------------------------------------------
#grab only semi-automated array MEQs
sarray.ncr <- subset(MeqNCR.df, as.character(MEQType) == 'Semi-Automated Array')

#order semi-automated array factors
sarray.order <- with(sarray.ncr, aggregate(Record~MEQ, FUN=sum))
sarray.order <- sarray.order[with(sarray.order,order(-Record)), ]
bottoms <- unique(as.character(sarray.order$MEQ))

sarray.chart1<- aggregateAndFillDateGroupGaps(calendar.week, 'Week', sarray.ncr, c('MEQ'), startstring.week,'Record','sum',0)
sarray.chart1 <- mergeCalSparseFrames(sarray.chart1, denom, c('DateGroup'), c('DateGroup'), 'Record', 'Record', NA, lagPeriods)
sarray.chart1$MEQ <- factor(sarray.chart1$MEQ, levels = bottoms, ordered = TRUE)

p.Average.saarray <- ggplot(sarray.chart1, aes(x=DateGroup, y=Rate, group=MEQ)) + geom_line(color='black') + geom_point(color='black') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, hjust=1,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  labs(title='Semi-Automated Array MEQ NCRs per Total  MEQ NCRs', x='Date\n(Year-Week)', y='4-week Rolling Average') + facet_wrap(~MEQ) + 
  scale_y_continuous(label=percent) +
  scale_x_discrete(breaks=as.character(unique(sarray.chart1[,'DateGroup']))[order(as.character(unique(sarray.chart1[,'DateGroup'])))][seq(1,length(as.character(unique(sarray.chart1[,'DateGroup']))), 12)])

#--------------------------------------------Where Found for Semi-Automated Array MEQs (week) -------------------------------------
sarray.where <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', sarray.ncr, c('MEQ', 'WhereFound'), startstring.week, 'Record', 'sum', 0)
sarray.where <- mergeCalSparseFrames(sarray.where, denom, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, lagPeriods)
sarray.where$MEQ <- factor(sarray.where$MEQ, levels = bottoms, ordered = TRUE)

sarray.where$WhereFound <- factor(sarray.where$WhereFound, levels = as.character(unique(sarray.where$WhereFound)), ordered=TRUE)
sarray.where <- sarray.where[with(sarray.where, order(WhereFound)),]

whereColors.sarray <- createPaletteOfVariableLength(sarray.where, 'WhereFound')

p.WhereFoundPerMEQ.saarray <- ggplot(sarray.where, aes(x=DateGroup, y=Rate, group=MEQ, fill=WhereFound)) + geom_bar(stat='identity', position='stack') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, hjust=1,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  labs(title='Semi-Automated Array MEQ NCRs per Total MEQ NCRs\nBy Where Found', x='Date\n(Year-Week)', y='4-week Rolling Average') + facet_wrap(~MEQ, scales='free_y') + 
  scale_y_continuous(label=percent) + scale_fill_manual(name= 'Where Found', values = whereColors.sarray) + 
  scale_x_discrete(breaks=as.character(unique(sarray.chart1[,'DateGroup']))[order(as.character(unique(sarray.chart1[,'DateGroup'])))][seq(1,length(as.character(unique(sarray.chart1[,'DateGroup']))), 12)])

#-----------------------------------------------------Semi-Automated Array NCRs by Supplier Responsiblity--------------------------------------------------------------------------
sarray.supp <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', sarray.ncr, c('MEQ', 'SupplierResponsible'), startstring.week,'Record','sum',0)
sarray.supp <- mergeCalSparseFrames(sarray.supp, denom, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, lagPeriods)
sarray.supp$MEQ <- factor(sarray.supp$MEQ, levels = bottoms, ordered = TRUE)

#order factors
sarray.supp$SupplierResponsible <- factor(sarray.supp$SupplierResponsible, levels = c('Yes', 'No', 'Unknown', 'N/A'), ordered=TRUE)
sarray.supp <- sarray.supp[with(sarray.supp, order(SupplierResponsible)),]

suppColors.s <- createPaletteOfVariableLength(sarray.supp, 'SupplierResponsible')

p.SupplierResponsibilityPerMEQ.saarray <- ggplot(sarray.supp, aes(x=DateGroup, y=Rate, group=MEQ, fill=SupplierResponsible)) + geom_bar(stat='identity', position='stack') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, hjust=1,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  labs(title='Semi-Automated Array MEQ NCRs per Total MEQ NCRs\nBy Supplier Responsiblity', x='Date\n(Year-Week)', y='4-week Rolling Average') + facet_wrap(~MEQ, scales='free_y') + 
  scale_y_continuous(label=percent) + scale_fill_manual(name= 'Supplier Responsible?', values = suppColors.s) + 
  scale_x_discrete(breaks=as.character(unique(sarray.supp[,'DateGroup']))[order(as.character(unique(sarray.supp[,'DateGroup'])))][seq(1,length(as.character(unique(sarray.supp[,'DateGroup']))), 12)])

#--------------------------------------------------Montly count of NCRs per Semi-Automated Array MEQ -------------------------------------------------------------------
sarray.chart2 <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', sarray.ncr, 'MEQ', startstring.month, 'Record', 'sum', 0)

#Create integer Breaks
intB2.df <- with(sarray.chart2, aggregate(Record~DateGroup, FUN=sum))
intB2.num <- max(intB2.df$Record)
if(intB2.num > 10) {
  intB2.num <- 10
}

sarray.pal <- createPaletteOfVariableLength(sarray.chart2, 'MEQ')

p.MonthlyCountMEQ.saarray <- ggplot(sarray.chart2, aes(x=DateGroup, y=Record, fill=MEQ)) + geom_bar(stat='identity', position='stack') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, hjust=1,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  labs(title='Semi-Automated Array MEQ NCRs', x='Date\n(Year-Month)', y='Count of NCRs') + scale_y_continuous(breaks=pretty_breaks(n=intB2.num)) +
  scale_fill_manual(values=sarray.pal)

#----------------------------------------Monthly count of NCRs per WhereFound--------------------------------------
sarray.where.mon <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', sarray.ncr, 'WhereFound', startstring.month, 'Record','sum',0)

sarray.where.pal <- createPaletteOfVariableLength(sarray.where.mon, 'WhereFound')

p.WhereFound.saarray <- ggplot(sarray.where.mon, aes(x=DateGroup, y=Record, fill=WhereFound)) + geom_bar(stat='identity', position='stack') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, hjust=1,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  labs(title='Semi-Automated Array MEQ NCRs by Where Found', x='Date\n(Year-Month)', y='Count of NCRs') + scale_y_continuous(breaks=pretty_breaks(n=intB2.num)) +
  scale_fill_manual(values=sarray.where.pal)

#----------------------------------------Monthly count of NCRs per BuildYear--------------------------------------
sarray.build.mon <- subset(sarray.ncr, as.character(WhereFound) == 'Pouch Manufacture')
if(nrow(sarray.build.mon) > 0) {
  sarray.build.mon <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', sarray.build.mon, 'BuildYear', startstring.month, 'Record','sum',0)
  
  sarray.build.pal <- createPaletteOfVariableLength(sarray.build.mon, 'BuildYear')
  
  p.BuildYear.saarray <- ggplot(sarray.build.mon, aes(x=DateGroup, y=Record, fill=BuildYear)) + geom_bar(stat='identity', position='stack') + 
    theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, hjust=1,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
    labs(title='Semi-Automated Array MEQ NCRs by Build Year\nFound in Pouch Manufacturing', x='Date\n(Year-Month)', y='Count of NCRs') + scale_y_continuous(breaks=pretty_breaks(n=intB2.num)) +
    scale_fill_manual(values=sarray.build.pal)
} else {
  p.BuildYear.saarray <- ggplot() + geom_bar() + annotate('text', x=0, y=0, label='No Data') +
    theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, hjust=1,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
    labs(title='Semi-Automated Array MEQ NCRs by Build Year\nFound in Pouch Manufacturing', x='Date\n(Year-Month)', y='Count of NCRs')
}

#----------------------------------------Top Failure + SubFailure Categories in last 60 days Pareto ---------------------------------------------
sarray.fail <- with(subset(sarray.ncr, CreatedDate >= D90), aggregate(Record~FailCat+SubFailCat, FUN=sum))

#select all or bottom 10 (if more than 10)
failCat <- with(sarray.fail, aggregate(Record~FailCat, FUN=sum))
failCat <- failCat[with(failCat, order(Record)), ]
if (length(failCat[ ,'FailCat']) > 10) {
  failCat <- head(failCat,10)
}
sarray.fail <- subset(sarray.fail, FailCat %in% unique(as.character(failCat$FailCat)))

#order fail factors
sarray.fail$FailCat <- factor(sarray.fail$FailCat, levels = unique(as.character(failCat$FailCat)), ordered=TRUE)

sarray.fail.pal <- createPaletteOfVariableLength(sarray.fail, 'SubFailCat')

#Create integer Breaks
intSarray.Fail <- max(sarray.fail$Record)
if(intSarray.Fail > 10) {
  intSarray.Fail <- 10
}

p.FailureCatMEQ.saarray <- ggplot(sarray.fail, aes(x=FailCat, y=Record, fill=SubFailCat)) + geom_bar(stat='identity') + scale_y_continuous(breaks=pretty_breaks(n=intSarray.Fail)) +
  xlab('Failure Category') + ylab('Count') + theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(vjust=0.5, color='black',size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + coord_flip() + ggtitle('Top semi-Automated Array MEQ Failure Categories From Last 90 Days') + scale_fill_manual(values=sarray.fail.pal, name = 'Sub-Failure Category')

#-----------------------------------------------------------------------------------------------------------------------------

# Export Images for the Web Hub
setwd(imgDir)
plots <- ls()[grep('^p\\.', ls())]
for(i in 1:length(plots)) {
  
  imgName <- paste(substring(plots[i],3),'.png',sep='')
  
  png(file=imgName, width=1200, height=800, units='px')
  print(get(plots[i]))
  makeTimeStamp(author= 'Data Science')
  dev.off()
}

# Export PDF for the Web Hub
setwd(pdfDir)
pdf("ProgramManagement.pdf", width = 11, height = 8)
for(i in 1:length(plots)) {
  print(get(plots[i]))
}
dev.off()

rm(list = ls())
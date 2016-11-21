workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_InstrumentManufacturing'
pdfDir <- '~/WebHub/pdfs/'

setwd(workDir)

# Load needed libraries
library(ggplot2)
library(scales)
library(zoo)
library(lubridate)
library(dateManip)

# load the data from SQL
source('Portfolios/O_IMAN_load.R')

source('Rfunctions/createPaletteOfVariableLength.R')
#source('Rfunctions/makeTimeStamp.R')

# set some environmental variables

calendar.week <- createCalendarLikeMicrosoft(2012, 'Week')
calendar.month <- createCalendarLikeMicrosoft(2012, 'Month')

# Find start date for Year-Month charts
startString.month <- findStartDate(calendar.month, 'Month', 13, 0)

# Find start date for Year-Week charts with rolling rate
startString.week <- findStartDate(calendar.week, 'Week', 54, 4)

# ----------------------------New Instrument Shipments and Refurb Conversions by Sales Source per Month - IMAGE 0-----------------------------------------
shipSource.df <- subset(shipments.inst, Product %in% c('FA1.5','FA2.0','HTFA'), select=c('Product','SalesType','Year','Month','Record'))

# Fill in gaps
shipSource.df <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', shipSource.df, c('SalesType'), startString.month, 'Record', 'sum', 0)
refurb <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', refurbConv.df, c('Key'), startString.month, 'Record', 'sum', 0)

colnames(refurb)[colnames(refurb) == 'Key'] <- 'SalesType'

ship.refurb <- rbind(shipSource.df, refurb)

#Order factors
ship.refurb$SalesType <- factor(ship.refurb$SalesType, levels = c('Domestic Sale','International Sale','Trade-Up','Refurb Conversion','EAP','Replacement','Loaner','Demo','Short Term Rental','Internal','Other'), ordered=TRUE)
ship.refurb<- ship.refurb[with(ship.refurb, order(SalesType)), ]

# Make Chart
ship.Source <- ggplot(ship.refurb, aes(x=DateGroup, y=Record, fill=SalesType)) + geom_bar(stat="identity", position="stack") +
  xlab('Date\n(Year-Month)') + ylab('Shipments') + theme(text=element_text(size=20, face='bold'), 
  axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  ggtitle('New Instrument Shipments by Sales Type\nIncluding Refurb Conversions\nFA 1.5, FA 2.0, and Torch') + 
  scale_fill_manual(values=createPaletteOfVariableLength(ship.refurb, 'SalesType'), name='Sales Type', breaks=rev(levels(ship.refurb$SalesType))) + 
  scale_y_continuous(breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30))

# -----------------------------New Instrument Shipments by Territory per Month - IMAGE 1-------------------------------------------
shipTerr.df <- subset(shipments.inst, Product %in% c('FA1.5','FA2.0','HTFA'), select=c('Product','SalesTerritory','Year','Month','Record')) 

# Fill in gaps
shipTerr.df <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', shipTerr.df, c('SalesTerritory'), startString.month, 'Record', 'sum', 0)

#Order factors
shipTerr.df$SalesTerritory <- factor(shipTerr.df$SalesTerritory, levels = c('Central','Great Lakes','North East','South East','West','International','Defense','House','Other'), ordered=TRUE)
shipTerr.df <- shipTerr.df[with(shipTerr.df, order(SalesTerritory)), ]

# Make Chart
ship.Terr <- ggplot(data=shipTerr.df, aes(x=DateGroup, y=Record, fill=SalesTerritory)) + geom_bar(stat="identity", position="stack") +
  xlab('Date\n(Year-Month)') + ylab('Shipments') + theme(text=element_text(size=20, face='bold'), 
  axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  ggtitle('New Instrument Shipments by Sales Territory\nFA 1.5, FA 2.0, and Torch') + 
  scale_fill_manual(values=createPaletteOfVariableLength(shipTerr.df, 'SalesTerritory'), name='Sales Territory', breaks=rev(levels(shipTerr.df$SalesTerritory))) + 
  scale_y_continuous(breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30))

# -----------NEEDS WORK!----------------------New Inventory per week - -------------------------------------------------------

# #Make DateGroups but do not fill in gaps
# newInven_f.df <- makeDateGroup(calendar.df, newInven.df, bigGroup, smallGroup, c('Version'), startString.week)
# #newInven_f2.df <- makeDateGroupAndFillGaps(calendar.df, newInven.df, bigGroup, smallGroup, c('Version'), startString.week, 'Record')
# 
# #Make Chart
# new.Inven <- ggplot(data=newInven_f.df, aes(x=DateGroup, y=Record, group=Version, colour=Version)) +
#   geom_line() + geom_point(size=1.5) + expand_limits(y=0) + xlab('Date\n(Year-Week)') + ylab('Inventory') + 
#   theme(text=element_text(size=18), axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=14), 
#   axis.text.y=element_text(hjust=1, color='black', size=14)) + ggtitle('New Inventory in Stock') + 
#   scale_colour_manual(values=c("dodgerblue", "forestgreen")) + 
#   scale_x_discrete(breaks = as.character(unique(newInven_f.df[,'DateGroup']))[seq(1,length(as.character(unique(newInven_f.df[,'DateGroup']))),4)])


######################

# newInven.df$RunningQty <- sapply(1:length(newInven.df[,1]), function(x) sum(newInven.df[1:x, 'Qty']))

####################
# --------------------NEEDS WORK!!!!!----Refurbished Inventory per week - -----------------------------------------------

#Make DateGroups but do not fill in gaps
# refurbInven_f.df <- makeDateGroup(calendar.df, refurbInven.df, bigGroup, smallGroup, c('Version'), startString.week)
# 
# #Make Chart
# refurb.Inven <- ggplot(data=refurbInven_f.df, aes(x=DateGroup, y=Record, group=Version, colour=Version)) +
#   geom_line() + geom_point(size=1.5) + expand_limits(y=0) + xlab('Date\n(Year-Week)') + ylab('Inventory') + 
#   theme(text=element_text(size=18), axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=14), 
#   axis.text.y=element_text(hjust=1, color='black', size=14)) + ggtitle('Refurbished Inventory in Stock') +
#   scale_colour_manual(values=c("dodgerblue", "forestgreen")) + 
#   scale_x_discrete(breaks = as.character(unique(newInven_f.df[,'DateGroup']))[seq(1,length(as.character(unique(newInven_f.df[,'DateGroup']))),4)])

#------------------------------New Instruments Transferred to Inventory per month - IMAGE 2-----------------------------------

#Fill the Gaps
transferred_f.df <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', transferred.df, 'Version', startString.month, 'Record', 'sum', 0)

#Order factors
transferred_f.df$Version <- factor(transferred_f.df$Version, levels = c('FA1.5','FA2.0','Torch Module','Torch Base'), ordered=TRUE)
transferred_f.df <- transferred_f.df[with(transferred_f.df, order(Version)), ]

#Make Chart
instr.Trans <- ggplot(data=transferred_f.df, aes(x=DateGroup, y=Record, fill=Version)) + geom_bar(stat="identity", position="stack") +
  xlab('Date\n(Year-Month)') + ylab('Instruments') + theme(text=element_text(size=20, face='bold'), 
  axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  ggtitle('New Instruments Transferred to Inventory') + scale_fill_manual(values=createPaletteOfVariableLength(transferred_f.df, 'Version'), name=' ', breaks=rev(levels(transferred_f.df$Version))) + 
  scale_y_continuous(breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30))

#------------------------------New Instruments Transferred to Inventory per month since beginning of year - IMAGE 3-----------------------------------
beg <- paste(year(Sys.Date()), '01', sep='-')

#Make Chart
instr.Trans.year <- ggplot(subset(transferred_f.df, as.character(DateGroup) >= beg), aes(x=DateGroup, y=Record, fill=Version)) + geom_bar(stat="identity", position="stack") +
  xlab('Date\n(Year-Month)') + ylab('Instruments') + theme(text=element_text(size=20, face='bold'), 
  axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  ggtitle('New Instruments Transferred to Inventory\n Since Beginning of 2016') + scale_fill_manual(values=createPaletteOfVariableLength(transferred_f.df, 'Version'), name=' ', breaks=rev(levels(transferred_f.df$Version))) + 
  scale_y_continuous(breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30))

#------------------------------------------------------------------------------------------------------------------------------------------

#last 3 months
m.df <- tail(calendar.month, n=1L)

mon <- ifelse(m.df[1,3]-2 < 10, 
        paste(m.df[1,2], paste('0', m.df[[1,3]]-2, sep=''), sep='-'),
        paste(m.df[1,2], m.df[[1,3]]-2, sep='-'))

ncr.df$Record <- 1
# ncr.df <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', ncr.df, c('WhereFound','ProblemArea'), startString.month, 'Record', 'sum', 0)
ncr.df$DateGroup <- ifelse(ncr.df$Month < 10,
                           paste(ncr.df$Year, paste('0',ncr.df$Month, sep=''), sep='-'),
                           paste(ncr.df$Year, ncr.df$Month, sep='-'))

denom.df <- with(transferred_f.df, aggregate(as.formula(Record~DateGroup), FUN=sum))

#-----------------------------------------Where Found - IMAGE 4-----------------------------------------------------------------------
where.ncr.df <-subset(ncr.df, ncr.df$DateGroup >= mon, select = c('Year', 'Month', 'WhereFound', 'Record'))
where.ncr.df <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', where.ncr.df, 'WhereFound', mon, 'Record', 'sum', 0)

#grep('State', colnames(sales.map))

where.ncr.df$Where <- as.character(where.ncr.df$WhereFound)
where.ncr.df$Where[grep('Incoming Inspection', where.ncr.df$WhereFound)] <- '1-Incoming Inspection'
where.ncr.df$Where[grep('Assembly$', where.ncr.df$WhereFound)] <- '2-Assembly'
where.ncr.df$Where[grep('Assembly Testing', where.ncr.df$WhereFound)] <- '3-Assembly Testing'
where.ncr.df$Where[grep('Functional Testing', where.ncr.df$WhereFound)] <- '4-Functional Testing'
where.ncr.df$Where[grep('Burn', where.ncr.df$WhereFound)] <- '5-Burn In'
where.ncr.df$Where[grep('Final QC', where.ncr.df$WhereFound)] <- '6-Final QC'

where.df <- with(where.ncr.df, aggregate(as.formula(Record~DateGroup+Where), FUN=sum))
where.df <- merge(where.df, denom.df, by='DateGroup')
where.df$Rate <- where.df$Record.x / where.df$Record.y
where.df <- subset(where.df, Where %in% c('1-Incoming Inspection','2-Assembly','3-Assembly Testing','4-Functional Testing','5-Burn In','6-Final QC'))
  
where <- ggplot(where.df, aes(x=Where, y=Rate, fill=DateGroup)) + geom_bar(stat="identity", position='dodge') + 
  scale_y_continuous(labels=percent, breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30)) +
  scale_fill_manual(values = createPaletteOfVariableLength(where.df, 'DateGroup')) +
  xlab('Where Found') + ylab('Percent of Instruments Released') + theme(text=element_text(size=20, face='bold'), 
  axis.text.x=element_text(angle=90,vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  ggtitle('Instrument NCRs - Where Found')

#----------------------------Problem Area - IMAGE 5-----------------------------------------------------------------------------------
problem.ncr.df <-subset(ncr.df, ncr.df$DateGroup >= mon, select = c('Year', 'Month', 'ProblemArea', 'Record'))
problem.ncr.df <- aggregateAndFillDateGroupGaps(calendar.month, 'Month',problem.ncr.df, 'ProblemArea', mon, 'Record', 'sum', 0)
#find top ten
problemtop.df <- with(problem.ncr.df, aggregate(as.formula(Record~ProblemArea), FUN=sum))
problemtop.df <- problemtop.df[with(problemtop.df, order(-Record)),]
problemtop.df$Row <- 1:nrow(problemtop.df)
problemtop.df <- subset(problemtop.df, problemtop.df$Row <= 10)
topAreas <- as.character(problemtop.df$ProblemArea)

problem.ncr.df <- subset(problem.ncr.df, problem.ncr.df$ProblemArea %in% topAreas)
problem.df <- with(problem.ncr.df, aggregate(as.formula(Record~DateGroup+ProblemArea), FUN=sum))
problem.df <- merge(problem.df, denom.df, by='DateGroup')
problem.df$Rate <- problem.df$Record.x / problem.df$Record.y

#Reorder factors 
problem.df$ProblemArea <- factor(problem.df$ProblemArea, levels = topAreas, ordered=TRUE)
problem.df <- problem.df[with(problem.df, order(ProblemArea)), ]

problem <- ggplot(problem.df, aes(x=ProblemArea, y=Rate, fill=DateGroup)) + geom_bar(stat="identity", position='dodge') + 
  scale_y_continuous(labels=percent, breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30)) +
  scale_fill_manual(values=createPaletteOfVariableLength(problem.df, 'DateGroup')) +
  xlab('Top 10 Problem Areas') + ylab('Percent of Instruments Released') + theme(text=element_text(size=20, face='bold'), 
  axis.text.x=element_text(angle=45, vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  ggtitle('Instrument NCRs - Problem Area')

#-------------------------------------------------Failed Part - IMAGE 6----------------------------------------------------------------
failedParts.df$Record <- 1
failed.ncr.df <- aggregateAndFillDateGroupGaps(calendar.month, 'Month',failedParts.df,'FailedPart',mon,'Record','sum',0)
failed.ncr.df <- merge(failed.ncr.df, partNames.df, by.x = 'FailedPart', by.y = 'PartNumber', all.x = TRUE)
failed.ncr.df <- with(failed.ncr.df, aggregate(Record~Name+DateGroup, FUN=sum))

#find top ten
failedtop.df <- with(failed.ncr.df, aggregate(as.formula(Record~Name), FUN=sum))
failedtop.df <- failedtop.df[with(failedtop.df, order(-Record)),]
failedtop.df$Row <- 1:nrow(failedtop.df)
failedtop.df <- subset(failedtop.df, failedtop.df$Row <= 10)
topAreas <- as.character(failedtop.df$Name)

failed.ncr.df <- subset(failed.ncr.df, failed.ncr.df$Name %in% topAreas)
failed.ncr.df <- merge(failed.ncr.df, denom.df, by='DateGroup')
failed.ncr.df$Rate <- failed.ncr.df$Record.x / failed.ncr.df$Record.y

#Reorder factors 
failed.ncr.df$Name <- factor(failed.ncr.df$Name, levels = topAreas, ordered=TRUE)
failed.ncr.df <- failed.ncr.df[with(failed.ncr.df, order(Name)), ]

failed <- ggplot(failed.ncr.df, aes(x=Name, y=Rate, fill=DateGroup)) + geom_bar(stat="identity", position='dodge') + 
  scale_y_continuous(labels=percent, breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30)) +
  scale_fill_manual(values=createPaletteOfVariableLength(failed.ncr.df, 'DateGroup')) +
  xlab('Top 10 Failed Parts') + ylab('Percent of Instruments Released') + theme(text=element_text(size=20, face='bold'), 
  axis.text.x=element_text(angle=90,vjust=0.5, color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  ggtitle('Instrument NCRs - Failed Part')

#-------------------------------------New Instrument Early Failures - IMAGE 7---------------------------------------------------------------------------------
# smallGroup <- 'Week'
# 
# inst.ship.denom <- makeDateGroupAndFillGaps(calendar.df, shipments.inst, bigGroup, smallGroup, c('Product'), startString.week)
# colnames(inst.ship.denom)[colnames(inst.ship.denom) == 'Product'] <- 'Version'
# 
# early.Fails <- makeDateGroupAndFillGaps(calendar.df, earlyFails.df, bigGroup, smallGroup, c('Version','Key'), startString.week)
# early.Fails.all <- computeRollingRateAndAddStats(inst.ship.denom, early.Fails, c('DateGroup'), c('DateGroup','Key'), c('DateGroup'),4,4,startString.week) 
# 
# dateLabels <- as.character(unique(early.Fails.all[,'DateGroup']))[order(as.character(unique(early.Fails.all[,'DateGroup'])))][seq(1,length(as.character(unique(early.Fails.all[,'DateGroup']))), 12)]
# 
# p.earlyfails <- ggplot(early.Fails.all, aes(x=DateGroup, y=RollingRate, fill=Key)) + geom_bar(stat="identity", position='stack') +
#   xlab('Date\n(Year-Week)') + ylab('4-Week Rolling Average') + theme(text=element_text(size=20, face='bold'), 
#   axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
#   ggtitle('Early Life Failures in New Instruments\n per All Instruments Shipped') + scale_fill_manual(values=brewer.pal(3,'Paired'), name=' ', breaks=rev(levels(early.Fails$Key))) + 
#   scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateLabels)
# 
# #----------------------------------New Instrument Early Failures by Version - IMAGE 8--------------------------------------------------------------------
# 
# inst.ship.denom[inst.ship.denom$Version=='FA1.5R','Version'] <- 'FA1.5'
# inst.ship.denom[inst.ship.denom$Version=='FA2.0R','Version'] <- 'FA2.0'
# early.Fails.version <- computeRollingRateAndAddStats(inst.ship.denom, early.Fails, c('DateGroup','Version'), c('DateGroup','Version','Key'), c('DateGroup','Version'), 4, 4, startString.week)
# early.Fails.version <- na.omit(early.Fails.version)
# 
# p.earlyfails.version <- ggplot(early.Fails.version, aes(x=DateGroup, y=RollingRate, fill=Key)) + geom_bar(stat="identity", position='stack') + facet_wrap(~Version,ncol=1) +
#   xlab('Date\n(Year-Week)') + ylab('4-Week Rolling Average') + theme(text=element_text(size=20, face='bold'), 
#   axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
#   ggtitle('Early Life Failures in New Instruments by Version\n per Instruments Shipped') + scale_fill_manual(values=brewer.pal(3,'Paired'), name=' ', breaks=rev(levels(early.Fails$Key))) + 
#   scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateLabels)
# 
# #-------------------------------------Instrument NCRs per Instruments Transferred -IMAGE 9------------------------------------------------------------------------
# 
# instNCRs.df <- makeDateGroupAndFillGaps(calendar.df, instNCRs.df, bigGroup, smallGroup, c('Key'), startString.week)
# instBuilt.df <- makeDateGroupAndFillGaps(calendar.df, instBuilt.df, bigGroup, smallGroup, c('Key'), startString.week)
# 
# instNCRs.df <- with(instNCRs.df, aggregate(Record~DateGroup+Key, FUN=sum))
# instBuilt.df <- with(instBuilt.df, aggregate(Record~DateGroup+Key, FUN=sum))
# inst.NCRs <- merge(instNCRs.df, instBuilt.df, by=c('DateGroup'))
# inst.NCRs$Rate <- inst.NCRs$Record.x / inst.NCRs$Record.y
# 
# instNCR.straightRate <- ggplot(inst.NCRs, aes(x=DateGroup, y=Rate, group=1)) + geom_line() + geom_point() +  xlab('Date\n(Year-Week)') + 
#   ylab('Rate') + theme(text=element_text(size=20, face='bold'), 
#   axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
#   ggtitle('Instrument NCRs per Instruments Built(not released)') + scale_x_discrete(breaks=dateLabels) +
#   scale_y_continuous(breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30))
#---------------------------------------------------------------------------------------------------------------------------------------


# Export Images for the Web Hub
setwd(imgDir)
png(file="image0.png",width=1200,height=800,units='px')
print(ship.Source)
#makeTimeStamp()
dev.off()
png(file="image1.png",width=1200,height=800,units='px')
print(ship.Terr)
#makeTimeStamp()
dev.off()
png(file="image2.png",width=1200,height=800,units='px')
print(instr.Trans)
dev.off()
png(file="image3.png",width=1200,height=800,units='px')
print(instr.Trans.year)
dev.off()
png(file="image4.png",width=1200,height=800,units='px')
print(where)
dev.off()
png(file="image5.png",width=1200,height=800,units='px')
print(problem)
dev.off()
png(file="image6.png",width=1200,height=800,units='px')
print(failed)
dev.off()
# png(file="image7.png",width=1200,height=800,units='px')
# print(p.earlyfails)
# dev.off()
# png(file="image8.png",width=1200,height=800,units='px')
# print(p.earlyfails.version)
# dev.off()
# png(file="image9.png",width=1200,height=800,units='px')
# print(instNCR.straightRate)
# dev.off()

# Export PDF for the Web Hub
setwd(pdfDir)
pdf("InstrumentManufacturing.pdf", width = 11, height = 8)
print(ship.Source)
print(ship.Terr)
print(instr.Trans)
print(instr.Trans.year)
print(where)
print(problem)
print(failed)
# print(p.earlyfails)
# print(p.earlyfails.version)
# print(instNCR.straightRate)
dev.off()

rm(list = ls())

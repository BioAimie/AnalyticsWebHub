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
source('Rfunctions/makeTimeStamp.R')

# set some environmental variables
calendar.week <- createCalendarLikeMicrosoft(2012, 'Week')
calendar.month <- createCalendarLikeMicrosoft(2012, 'Month')

# Find start date for Year-Month charts
startString.month <- findStartDate(calendar.month, 'Month', 13, 0)

# Find start date for Year-Week charts with rolling rate
startString.week <- findStartDate(calendar.week, 'Week', 54, 4)

# ----------------------------New Instrument Shipments and Refurb Conversions by Sales Source per Month-----------------------------------------
shipSource <- subset(shipments.inst, Product %in% c('FA1.5','FA2.0','Torch Base','Torch Module'), select=c('Product','SalesType','Year','Month','Record'))
shipSource <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', shipSource, c('SalesType'), startString.month, 'Record', 'sum', 0)
refurb <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', refurbConv.df, c('Key'), startString.month, 'Record', 'sum', 0)
colnames(refurb)[colnames(refurb) == 'Key'] <- 'SalesType'
ship.refurb <- rbind(shipSource, refurb)

#Order factors
ship.refurb$SalesType <- factor(ship.refurb$SalesType, levels = c('Domestic Sale','International Sale','Trade-Up','Refurb Conversion','EAP','Replacement','Loaner','Demo','Short Term Rental','Internal','Other'), ordered=TRUE)
ship.refurb<- ship.refurb[with(ship.refurb, order(SalesType)), ]

# Make Chart
p.Ship.SalesType <- ggplot(ship.refurb, aes(x=DateGroup, y=Record, fill=SalesType)) + geom_bar(stat="identity", position="stack") +
  xlab('Date\n(Year-Month)') + ylab('Shipments') + theme(text=element_text(size=20, face='bold'), 
  axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  ggtitle('New Instrument Shipments by Sales Type', subtitle = 'Including Refurb Conversions, FA 1.5, FA 2.0, and Torch') + 
  scale_fill_manual(values=createPaletteOfVariableLength(ship.refurb, 'SalesType'), name='Sales Type') + 
  scale_y_continuous(breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30))

# -----------------------------New Instrument Shipments by Territory per Month-------------------------------------------
shipTerr <- subset(shipments.inst, Product %in% c('FA1.5','FA2.0','Torch Base','Torch Module'), select=c('Product','SalesTerritory','Year','Month','Record')) 
shipTerr <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', shipTerr, c('SalesTerritory'), startString.month, 'Record', 'sum', 0)

#Order factors
shipTerr$SalesTerritory <- factor(shipTerr$SalesTerritory, levels = c('Central','Great Lakes','Mid Atlantic','North East','South East','West','International','Defense','House','Other'), ordered=TRUE)
shipTerr <- shipTerr[with(shipTerr, order(SalesTerritory)), ]

# Make Chart
p.Ship.Territory <- ggplot(data=shipTerr, aes(x=DateGroup, y=Record, fill=SalesTerritory)) + geom_bar(stat="identity", position="stack") +
  xlab('Date\n(Year-Month)') + ylab('Shipments') + theme(text=element_text(size=20, face='bold'), 
  axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  ggtitle('New Instrument Shipments by Sales Territory', subtitle = 'FA 1.5, FA 2.0, and Torch') + 
  scale_fill_manual(values=createPaletteOfVariableLength(shipTerr, 'SalesTerritory'), name='Sales Territory') + 
  scale_y_continuous(breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30))

#----------------------------------New Instrument Shipments by Version------------------------------------------------------------
shipVer <- subset(shipments.inst, Product %in% c('FA1.5','FA2.0','Torch Base','Torch Module'), select=c('Product','Year','Month','Record')) 
shipVer <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', shipVer, c('Product'), startString.month, 'Record', 'sum', 0)

#Order factors
shipVer$Product <- factor(shipVer$Product, levels = c('FA1.5', 'FA2.0', 'Torch Module', 'Torch Base'), ordered=TRUE)
shipVer <- shipVer[with(shipVer, order(Product)), ]

# Make Chart
p.Ship.Version <- ggplot(data=shipVer, aes(x=DateGroup, y=Record, fill=Product)) + geom_bar(stat="identity", position="stack") +
  xlab('Date\n(Year-Month)') + ylab('Shipments') + theme(text=element_text(size=20, face='bold'), 
  axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  ggtitle('New Instrument Shipments by Version', subtitle = 'FA 1.5, FA 2.0, and Torch') + 
  scale_fill_manual(values=createPaletteOfVariableLength(shipVer, 'Product'), name='Version') + 
  scale_y_continuous(breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30))

#------------------------------New Instruments Transferred to Inventory per month-----------------------------------
transferred <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', transferred.df, 'Version', startString.month, 'Record', 'sum', 0)

#Order factors
transferred$Version <- factor(transferred$Version, levels = c('FA1.5','FA2.0','Torch Module','Torch Base'), ordered=TRUE)
transferred <- transferred[with(transferred, order(Version)), ]

#Make Chart
p.Inst.Transferred <- ggplot(data=transferred, aes(x=DateGroup, y=Record, fill=Version)) + geom_bar(stat="identity", position="stack") +
  xlab('Date\n(Year-Month)') + ylab('Instruments') + theme(text=element_text(size=20, face='bold'), 
  axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  ggtitle('New Instruments Transferred to Inventory') + scale_fill_manual(values=createPaletteOfVariableLength(transferred, 'Version'), name=' ') + 
  scale_y_continuous(breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30))

#------------------------------New Instruments Transferred to Inventory per month since beginning of year-----------------------------------
beg <- paste(year(Sys.Date()), '01', sep='-')

#Make Chart
p.Instr.Trans.year <- ggplot(subset(transferred, as.character(DateGroup) >= beg), aes(x=DateGroup, y=Record, fill=Version)) + geom_bar(stat="identity", position="stack") +
  xlab('Date\n(Year-Month)') + ylab('Instruments') + theme(text=element_text(size=20, face='bold'), 
  axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  ggtitle('New Instruments Transferred to Inventory', subtitle = paste0('Since Beginning of ', year(Sys.Date()))) + scale_fill_manual(values=createPaletteOfVariableLength(transferred, 'Version'), name=' ') + 
  scale_y_continuous(breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30))

#------------------------------------------------------------------------------------------------------------------------------------------
#last 3 months
m.df <- tail(calendar.month, n=1L)

mon <- ifelse(m.df[1,3]-2 < 10, 
              paste(m.df[1,2], paste('0', m.df[[1,3]]-2, sep=''), sep='-'),
              paste(m.df[1,2], m.df[[1,3]]-2, sep='-'))

ncr.df$DateGroup <- ifelse(ncr.df$Month < 10,
                           paste(ncr.df$Year, paste('0',ncr.df$Month, sep=''), sep='-'),
                           paste(ncr.df$Year, ncr.df$Month, sep='-'))

denom.df <- with(transferred, aggregate(as.formula(Record~DateGroup), FUN=sum))

#-----------------------------------------Where Found------------------------------------------------------------------------
where.ncr <-subset(ncr.df, ncr.df$DateGroup >= mon, select = c('Year', 'Month', 'WhereFound', 'Record'))
where.ncr <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', where.ncr, 'WhereFound', mon, 'Record', 'sum', 0)

where.ncr$Where <- as.character(where.ncr$WhereFound)
where.ncr$Where[grep('Incoming Inspection', where.ncr$WhereFound)] <- '1-Incoming Inspection'
where.ncr$Where[grep('Assembly$', where.ncr$WhereFound)] <- '2-Assembly'
where.ncr$Where[grep('Assembly Testing', where.ncr$WhereFound)] <- '3-Assembly Testing'
where.ncr$Where[grep('Functional Testing', where.ncr$WhereFound)] <- '4-Functional Testing'
where.ncr$Where[grep('Burn', where.ncr$WhereFound)] <- '5-Burn In'
where.ncr$Where[grep('Final QC', where.ncr$WhereFound)] <- '6-Final QC'

where.ncr <- with(where.ncr, aggregate(as.formula(Record~DateGroup+Where), FUN=sum))
where.ncr <- merge(where.ncr, denom.df, by='DateGroup')
where.ncr$Rate <- where.ncr$Record.x / where.ncr$Record.y
where.ncr <- subset(where.ncr, Where %in% c('1-Incoming Inspection','2-Assembly','3-Assembly Testing','4-Functional Testing','5-Burn In','6-Final QC'))

p.WhereFound <- ggplot(where.ncr, aes(x=Where, y=Rate, fill=DateGroup)) + geom_bar(stat="identity", position='dodge') + 
  scale_y_continuous(labels=percent, breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30)) +
  scale_fill_manual(values = createPaletteOfVariableLength(where.ncr, 'DateGroup')) +
  xlab('Where Found') + ylab('Percent of Instruments Released') + theme(text=element_text(size=20, face='bold'), 
  axis.text.x=element_text(angle=90,vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  ggtitle('Instrument NCRs - Where Found')

#----------------------------Problem Area------------------------------------------------------------------------------------
problem.ncr <-subset(ncr.df, ncr.df$DateGroup >= mon, select = c('Year', 'Month', 'ProblemArea', 'Record'))
problem.ncr <- aggregateAndFillDateGroupGaps(calendar.month, 'Month',problem.ncr, 'ProblemArea', mon, 'Record', 'sum', 0)
#find top ten
problemtop <- with(problem.ncr, aggregate(as.formula(Record~ProblemArea), FUN=sum))
problemtop <- problemtop[with(problemtop, order(-Record)),]
topAreas <- as.character(head(problemtop, 10)[, 'ProblemArea'])

problem.ncr <- subset(problem.ncr, ProblemArea %in% topAreas)
problem.ncr <- with(problem.ncr, aggregate(as.formula(Record~DateGroup+ProblemArea), FUN=sum))
problem.ncr <- merge(problem.ncr, denom.df, by='DateGroup')
problem.ncr$Rate <- problem.ncr$Record.x / problem.ncr$Record.y

#Reorder factors 
problem.ncr$ProblemArea <- factor(problem.ncr$ProblemArea, levels = topAreas, ordered=TRUE)
problem.ncr <- problem.ncr[with(problem.ncr, order(ProblemArea)), ]

p.ProblemArea <- ggplot(problem.ncr, aes(x=ProblemArea, y=Rate, fill=DateGroup)) + geom_bar(stat="identity", position='dodge') + 
  scale_y_continuous(labels=percent, breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30)) +
  scale_fill_manual(values=createPaletteOfVariableLength(problem.ncr, 'DateGroup')) +
  xlab('Top 10 Problem Areas') + ylab('Percent of Instruments Released') + theme(text=element_text(size=20, face='bold'), 
  axis.text.x=element_text(angle=45, vjust=0.5,color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  ggtitle('Instrument NCRs - Problem Area')

#-------------------------------------------------Failed Part-----------------------------------------------------------------
failed.ncr <- aggregateAndFillDateGroupGaps(calendar.month, 'Month',failedParts.df,'FailedPart',mon,'Record','sum',0)
failed.ncr <- merge(failed.ncr, partNames.df, by.x = 'FailedPart', by.y = 'PartNumber', all.x = TRUE)
failed.ncr <- with(failed.ncr, aggregate(Record~Name+DateGroup, FUN=sum))

#find top ten
failedtop <- with(failed.ncr, aggregate(as.formula(Record~Name), FUN=sum))
failedtop <- failedtop[with(failedtop, order(-Record)),]
topAreas <- as.character(head(failedtop, 10)[,'Name'])

failed.ncr <- subset(failed.ncr, Name %in% topAreas)
failed.ncr <- merge(failed.ncr, denom.df, by='DateGroup')
failed.ncr$Rate <- failed.ncr$Record.x / failed.ncr$Record.y

#Reorder factors 
failed.ncr$Name <- factor(failed.ncr$Name, levels = topAreas, ordered=TRUE)
failed.ncr <- failed.ncr[with(failed.ncr, order(Name)), ]

p.FailedParts <- ggplot(failed.ncr, aes(x=Name, y=Rate, fill=DateGroup)) + geom_bar(stat="identity", position='dodge') + 
  scale_y_continuous(labels=percent, breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30)) +
  scale_fill_manual(values=createPaletteOfVariableLength(failed.ncr, 'DateGroup')) +
  xlab('Top 10 Failed Parts') + ylab('Percent of Instruments Released') + theme(text=element_text(size=20, face='bold'), 
  axis.text.x=element_text(angle=90,vjust=0.5, color='black',size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) + 
  ggtitle('Instrument NCRs - Failed Part')

#----------------------------------------------------------------------------------------------------------------------------------------------
# Export Images for the Web Hub
setwd(imgDir)
plots <- ls()[grep('^p\\.', ls())]
for(i in 1:length(plots)) {
  imgName <- paste(substring(plots[i],3),'.png',sep='')
  
  png(file=imgName, width=1200, height=800, units='px')
  print(get(plots[i]))
  makeTimeStamp(author='Post Market Surveillance')
  dev.off()
}

# Export PDF for the Web Hub
setwd(pdfDir)
pdf("InstrumentManufacturing.pdf", width = 11, height = 8)
for(i in 1:length(plots)) {
  print(get(plots[i]))
}
dev.off()

rm(list = ls())

#Load in data for Pouch SPC app
setwd('~/WebHub/AnalyticsWebHub/Apps/R_PSPC/PSPCApp')
# Open the connection to PMS1
PMScxn <- odbcConnect("PMS1_LOC")

queryText <- readLines("SQL/SummaryAnomalyTable.sql")
query <- paste(queryText,collapse="\n")
summary.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/AllQCRuns.sql")
query <- paste(queryText,collapse="\n")
allruns.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/AllRunObservations.sql")
query <- paste(queryText,collapse="\n")
runobs.df <- sqlQuery(PMScxn,query)

odbcClose(PMScxn)

expouchserials <- read.csv('exclude.csv')

allruns.df <- merge(allruns.df, instversion.df, all.x=TRUE, by.x='InstrumentSerialNumber', by.y='SerialNo')
allruns.df$Version[allruns.df$InstrumentSerialNumber %in% c('AFA07','FA2000','FA2001','FA2002','FA2003','FA2004')] <- 'FA 1.5'


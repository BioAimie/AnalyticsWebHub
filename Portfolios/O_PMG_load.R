library(RODBC)

# Open the connection to PMS1
PMScxn <- odbcConnect("PMS_PROD")

queryText <- readLines("SQL/O_PMG_MeqParts.sql")
query <- paste(queryText,collapse="\n")
Meq.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_PMG_NCRperPart.sql")
query <- paste(queryText,collapse="\n")
NCR.df <- sqlQuery(PMScxn,query)

odbcClose(PMScxn)

MeqSerials <- read.csv('SQL/O_PMG_MEQSerialNumbers.csv')
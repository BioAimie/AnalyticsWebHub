library(RODBC)

# Open the connection to PMS1
PMScxn <- odbcConnect("PMS_PROD")

queryText <- readLines("SQL/O_IMAN_InstShipments.sql")
query <- paste(queryText,collapse="\n")
shipments.inst <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_IMAN_newInstTrans.sql")
query <- paste(queryText,collapse="\n")
transferred.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_IMAN_InstrumentNCRBreakdown.sql")
query <- paste(queryText,collapse="\n")
ncr.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_IMAN_FailureCatsNCRs.sql")
query <- paste(queryText,collapse="\n")
failCats.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_IMAN_refurbConv.sql")
query <- paste(queryText,collapse="\n")
refurbConv.df <- sqlQuery(PMScxn,query)

odbcClose(PMScxn)
library(RODBC)

# Open the connection to PMS1
PMScxn <- odbcConnect("PMS_PROD")

queryText <- readLines("SQL/O_ISERV_InstrumentsThruService.sql")
query <- paste(queryText,collapse="\n")
service.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_ISERV_ConversionsbyQCDate.sql")
query <- paste(queryText,collapse="\n")
conversion.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_ISERV_StockLevels.sql")
query <- paste(queryText,collapse="\n")
stockInv.df <- sqlQuery(PMScxn,query)

odbcClose(PMScxn)
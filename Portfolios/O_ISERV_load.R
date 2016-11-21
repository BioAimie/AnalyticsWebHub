library(RODBC)

# Open the connection to PMS1
PMScxn <- odbcConnect("PMS_PROD")


queryText <- scan("SQL/O_IMAN_InstrumentsThruService.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
service.df <- sqlQuery(PMScxn,query)

queryText <- scan("SQL/O_ISERV_ConversionsbyQCDate.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
conversion.df <- sqlQuery(PMScxn,query)

queryText <- scan("SQL/O_ISERV_StockLevels.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
stockInv.df <- sqlQuery(PMScxn,query)

odbcClose(PMScxn)
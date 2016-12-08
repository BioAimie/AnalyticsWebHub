library(RODBC)

# Open the connection to PMS1
PMScxn <- odbcConnect("PMS_PROD")

queryText <- scan("SQL/O_IMAN_partNames.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
partNames.df <- sqlQuery(PMScxn,query)

queryText <- scan("SQL/O_IMAN_InstShipments.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
shipments.inst <- sqlQuery(PMScxn,query)

queryText <- scan("SQL/O_IMAN_newInstTrans.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
transferred.df <- sqlQuery(PMScxn,query)

queryText <- scan("SQL/O_IMAN_InstrumentNCRBreakdown.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
ncr.df <- sqlQuery(PMScxn,query)

queryText <- scan("SQL/O_IMAN_failedPartsNCRs.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
failedParts.df <- sqlQuery(PMScxn,query)

queryText <- scan("SQL/O_IMAN_refurbConv.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
refurbConv.df <- sqlQuery(PMScxn,query)

odbcClose(PMScxn)
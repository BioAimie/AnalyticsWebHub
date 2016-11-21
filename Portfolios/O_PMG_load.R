library(RODBC)

# Open the connection to PMS1
PMScxn <- odbcConnect("PMS_PROD")

queryText <- scan("SQL/O_PMG_MeqParts.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
Meq.df <- sqlQuery(PMScxn,query)

queryText <- scan("SQL/O_PMG_NCRperPart.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
NCR.df <- sqlQuery(PMScxn,query)

odbcClose(PMScxn)

MeqSerials <- read.csv('SQL/O_PMG_MEQSerialNumbers.csv')
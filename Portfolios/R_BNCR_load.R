library(RODBC)

# Open the connection to PMS1
PMScxn <- odbcConnect("PMS_PROD")

queryText <- scan("SQL/R_BNCR_PouchNCRs_WPFS.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
pouchWPFS <- sqlQuery(PMScxn,query)

queryText <- scan("SQL/R_BNCR_PouchProductsProduced.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
pouchProd <- sqlQuery(PMScxn,query)

odbcClose(PMScxn)

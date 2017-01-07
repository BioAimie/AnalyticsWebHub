library(RODBC)

# Open the connection to PMS1
PMScxn <- odbcConnect("PMS_PROD")

queryText <- readLines("SQL/R_BNCR_PouchNCRs_WPFS.sql")
query <- paste(queryText,collapse="\n")
pouchWPFS <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/R_BNCR_PouchProductsProduced.sql")
query <- paste(queryText,collapse="\n")
pouchProd <- sqlQuery(PMScxn,query)

odbcClose(PMScxn)

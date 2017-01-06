library(RODBC)

# Open the connection to PMS1
PMScxn <- odbcConnect("PMS_PROD")

queryText <- readLines("SQL/S_LIVE_FirstPurchasesByCustomer.sql")
query <- paste(queryText,collapse="\n")
firsts.df <- sqlQuery(PMScxn,query)

odbcClose(PMScxn)

SalesManagers <- read.csv('SQL/S_LIVE_SalesManagers.csv')

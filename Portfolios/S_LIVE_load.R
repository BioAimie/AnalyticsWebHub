library(RODBC)

# Open the connection to PMS1
PMScxn <- odbcConnect("PMS_PROD")

queryText <- scan("SQL/S_LIVE_FirstPurchasesByCustomer.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
firsts.df <- sqlQuery(PMScxn,query)

odbcClose(PMScxn)

SalesManagers <- read.csv('SQL/S_LIVE_SalesManagers.csv')

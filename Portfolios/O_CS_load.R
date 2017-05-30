library(RODBC)

# Open the connection to PMS1
PMScxn <- odbcConnect("PMS_PROD")

queryText <- readLines("SQL/O_CS_StockLevels.sql")
query <- paste(queryText,collapse="\n")
stockInv.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_CS_RefurbShipments.sql")
query <- paste(queryText,collapse="\n")
refurbShip.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_CS_ServiceTier.sql")
query <- paste(queryText,collapse="\n")
tier.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_CS_RMAInfo.sql")
query <- paste(queryText,collapse="\n")
rmas.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_CS_ComplaintsSummary.sql")
query <- paste(queryText,collapse="\n")
complaints.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_CS_LoanerRMA.sql")
query <- paste(queryText,collapse="\n")
loaners.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_CS_CustomerAccounts.sql")
query <- paste(queryText,collapse="\n")
acct.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_CS_ServiceCenterReceived.sql")
query <- paste(queryText,collapse="\n")
serviceCenter.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_CS_LoanerRMAReceived.sql")
query <- paste(queryText,collapse="\n")
loanerReceipt.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_CS_TradeUpRMAReceived.sql")
query <- paste(queryText,collapse="\n")
tradeupReceipt.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_CS_CustPouchesShippedYear.sql")
query <- paste(queryText,collapse="\n")
custPouches.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_CS_CustomerComplaints.sql")
query <- paste(queryText,collapse="\n")
custComplaints.df <- sqlQuery(PMScxn,query)

odbcClose(PMScxn)
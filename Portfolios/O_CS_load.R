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

queryText <- readLines("SQL/O_CS_ServiceCenterReceived.sql")
query <- paste(queryText,collapse="\n")
serviceCenter.df <- sqlQuery(PMScxn,query)

odbcClose(PMScxn)
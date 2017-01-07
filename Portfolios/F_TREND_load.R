# THIS IS THE FILE USED TO PULL ALL DATA NEEDED FOR THE RMA DASHBOARD FROM SQL

# load remote data base connection package
#*note: to set DB paths go to Control Panel/Systems & Security/Administrative Tools/Data Sources (ODBC)
library(RODBC)

FADWcxn <- odbcConnect(dsn = 'FA_DW', uid = 'afaucett', pwd = 'ThisIsAPassword-BAD')
queryVector <- readLines('SQL/F_TREND_Runs.sql')
query <- paste(queryVector,collapse="\n")
runs.df <- sqlQuery(FADWcxn,query)
queryVector <- readLines('SQL/F_TREND_Bugs.sql')
query <- paste(queryVector,collapse="\n")
bugs.df <- sqlQuery(FADWcxn,query)
queryVector <- readLines('SQL/F_TREND_ShortNames.sql')
query <- paste(queryVector,collapse="\n")
shortnames.df <- sqlQuery(FADWcxn,query)
queryVector <- readLines('SQL/F_TREND_NationalDataILI.sql')
query <- paste(queryVector,collapse="\n")
ili.df <- sqlQuery(FADWcxn,query)
odbcClose(FADWcxn)

PMScxn <- odbcConnect('PMS_PROD')
queryVector <- readLines('SQL/F_TREND_AllSitesRegionKey.sql')
query <- paste(queryVector,collapse="\n")
regions.df <- sqlQuery(PMScxn,query)
odbcClose(PMScxn)
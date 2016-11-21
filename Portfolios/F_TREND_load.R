# THIS IS THE FILE USED TO PULL ALL DATA NEEDED FOR THE RMA DASHBOARD FROM SQL

# load remote data base connection package
#*note: to set DB paths go to Control Panel/Systems & Security/Administrative Tools/Data Sources (ODBC)
library(RODBC)

FADWcxn <- odbcConnect(dsn = 'FA_DW', uid = 'afaucett', pwd = 'ThisIsAPassword-BAD')
queryVector <- scan('SQL/F_TREND_Runs.txt',what=character(),quote="")
query <- paste(queryVector,collapse=" ")
runs.df <- sqlQuery(FADWcxn,query)
queryVector <- scan('SQL/F_TREND_Bugs.txt',what=character(),quote="")
query <- paste(queryVector,collapse=" ")
bugs.df <- sqlQuery(FADWcxn,query)
queryVector <- scan('SQL/F_TREND_ShortNames.txt',what=character(),quote="")
query <- paste(queryVector,collapse=" ")
shortnames.df <- sqlQuery(FADWcxn,query)
queryVector <- scan('SQL/F_TREND_NationalDataILI.txt',what=character(),quote="")
query <- paste(queryVector,collapse=" ")
ili.df <- sqlQuery(FADWcxn,query)
odbcClose(FADWcxn)

PMScxn <- odbcConnect('PMS_PROD')
queryVector <- scan('SQL/F_TREND_AllSitesRegionKey.txt',what=character(),quote="")
query <- paste(queryVector,collapse=" ")
regions.df <- sqlQuery(PMScxn,query)
odbcClose(PMScxn)
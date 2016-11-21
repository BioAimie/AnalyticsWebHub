# THIS IS THE FILE USED TO PULL ALL DATA NEEDED FOR THE RMA DASHBOARD FROM SQL
setwd('~/WebHub/AnalyticsWebHub/')
# load remote data base connection package
#*note: to set DB paths go to Control Panel/Systems & Security/Administrative Tools/Data Sources (ODBC)
library(RODBC)
# open database connection 
#*note: to set DB paths go to Control Panel/Systems & Security/Administrative Tools/Data Sources (ODBC)
PMScxn = odbcConnect("PMS_PROD")

# run the query to get root cause data
query.charVec = scan("SQL/R_INCR_wpfs_app.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
rootCause.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)
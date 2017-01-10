# THIS IS THE FILE USED TO PULL ALL DATA NEEDED FOR THE CONTAMINATION DASHBOARD FROM SQL
# Set the environment

# load remote data base connection package
#*note: to set DB paths go to Control Panel/Systems & Security/Administrative Tools/Data Sources (ODBC)
library(RODBC)
# open database connection 
PSTMRKTcxn = odbcConnect("PMS1_LOC")

# # run the query to get a calendar since 2013-12-16 (chosen so that 2014 week 1 will be first when rolling by 4 weeks)
# query.charVec = readLines("SQL/Calendar.sql")
# query = paste(query.charVec,collapse="\n")
# calendar.df = sqlQuery(PMScxn,query)

# timeUntilPre_bugs
query.charVec = readLines("SQL/R_PRE_timeUntilPre_bugs.sql")
query = paste(query.charVec,collapse="\n")
preBugs.df = sqlQuery(PSTMRKTcxn,query)

# # team Close Time 120 days
# query.charVec = readLines("SQL/R_PRE_teamCloseTime.sql")
# query = paste(query.charVec,collapse="\n")
# teamCloseTime.df = sqlQuery(PSTMRKTcxn,query)

# team Close Time for Year
query.charVec = readLines("SQL/R_PRE_teamCloseTimeYear.sql")
query = paste(query.charVec,collapse="\n")
teamCloseTimeYear.df = sqlQuery(PSTMRKTcxn,query)

# needs PRE
query.charVec = readLines("SQL/R_PRE_needsPRE.sql")
query = paste(query.charVec,collapse="\n")
needsPre.df = sqlQuery(PSTMRKTcxn,query)

# team Closure Rate based on Became Aware Date
query.charVec = readLines("SQL/R_PRE_BecameAwareCiCreated_PRE.sql")
query = paste(query.charVec,collapse="\n")
becameAware.df = sqlQuery(PSTMRKTcxn,query)

# CI z codes
query.charVec = readLines("SQL/R_PRE_codes.sql")
query = paste(query.charVec,collapse="\n")
codes.df = sqlQuery(PSTMRKTcxn,query)

# # team Closure Rate
# query.charVec = readLines("SQL/R_PRE_teamClosureRate.sql")
# query = paste(query.charVec,collapse="\n")
# closureRate.df = sqlQuery(PSTMRKTcxn,query)
close(PSTMRKTcxn)

PMScxn = odbcConnect("PMS_PROD")

# get pouches shipped
query.charVec = readLines("SQL/R_CC_CustPouchesShippedDetailed.sql")
query = paste(query.charVec,collapse="\n")
pouches.df = sqlQuery(PMScxn,query)

# # pouch Shipped by Panel bar chart
# query.charVec = readLines("SQL/R_PRE_pouchShip2016.sql")
# query = paste(query.charVec,collapse="\n")
# pouch2016.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)
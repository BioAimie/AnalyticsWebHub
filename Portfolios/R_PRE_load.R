# THIS IS THE FILE USED TO PULL ALL DATA NEEDED FOR THE CONTAMINATION DASHBOARD FROM SQL
# Set the environment

# load remote data base connection package
#*note: to set DB paths go to Control Panel/Systems & Security/Administrative Tools/Data Sources (ODBC)
library(RODBC)
# open database connection 
PSTMRKTcxn = odbcConnect("PMS1_LOC")

# # run the query to get a calendar since 2013-12-16 (chosen so that 2014 week 1 will be first when rolling by 4 weeks)
# query.charVec = scan("SQL/Calendar.txt", what=character(),quote="")
# query = paste(query.charVec,collapse=" ")
# calendar.df = sqlQuery(PMScxn,query)

# timeUntilPre_bugs
query.charVec = scan("SQL/R_PRE_timeUntilPre_bugs.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
preBugs.df = sqlQuery(PSTMRKTcxn,query)

# # team Close Time 120 days
# query.charVec = scan("SQL/R_PRE_teamCloseTime.txt", what=character(),quote="")
# query = paste(query.charVec,collapse=" ")
# teamCloseTime.df = sqlQuery(PSTMRKTcxn,query)

# team Close Time for Year
query.charVec = scan("SQL/R_PRE_teamCloseTimeYear.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
teamCloseTimeYear.df = sqlQuery(PSTMRKTcxn,query)

# needs PRE
query.charVec = scan("SQL/R_PRE_needsPRE.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
needsPre.df = sqlQuery(PSTMRKTcxn,query)

# team Closure Rate based on Became Aware Date
query.charVec = scan("SQL/R_PRE_BecameAwareCiCreated_PRE.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
becameAware.df = sqlQuery(PSTMRKTcxn,query)

# CI z codes
query.charVec = scan("SQL/R_PRE_codes.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
codes.df = sqlQuery(PSTMRKTcxn,query)

# # team Closure Rate
# query.charVec = scan("SQL/R_PRE_teamClosureRate.txt", what=character(),quote="")
# query = paste(query.charVec,collapse=" ")
# closureRate.df = sqlQuery(PSTMRKTcxn,query)
close(PSTMRKTcxn)

PMScxn = odbcConnect("PMS_PROD")

# get pouches shipped
query.charVec = scan("SQL/R_CC_CustPouchesShippedDetailed.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
pouches.df = sqlQuery(PMScxn,query)

# # pouch Shipped by Panel bar chart
# query.charVec = scan("SQL/R_PRE_pouchShip2016.txt", what=character(),quote="")
# query = paste(query.charVec,collapse=" ")
# pouch2016.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)
# THIS IS THE FILE USED TO PULL ALL DATA NEEDED FOR THE CONTAMINATION DASHBOARD FROM SQL
# Set the environment

# load remote data base connection package
#*note: to set DB paths go to Control Panel/Systems & Security/Administrative Tools/Data Sources (ODBC)
library(RODBC)
# open database connection 
PSTMRKTcxn = odbcConnect("PMS1_LOC")

query.charVec = readLines("SQL/R_PRE_teamCloseTimeYear.sql")
query = paste(query.charVec,collapse="\n")
daysToClose.df = sqlQuery(PSTMRKTcxn,query)

query.charVec = readLines("SQL/R_PRE_timeUntilPre_bugs.sql")
query = paste(query.charVec,collapse="\n")
preBugs.df = sqlQuery(PSTMRKTcxn,query)

query.charVec = readLines("SQL/R_PRE_needsPRE.sql")
query = paste(query.charVec,collapse="\n")
needsPre.df = sqlQuery(PSTMRKTcxn,query)

query.charVec = readLines("SQL/R_PRE_closedvopened.sql")
query = paste(query.charVec,collapse="\n")
closedVopened.df = sqlQuery(PSTMRKTcxn,query)

query.charVec = readLines("SQL/R_PRE_OpenedCIs.sql")
query = paste(query.charVec,collapse="\n")
allopened.df = sqlQuery(PSTMRKTcxn,query)

query.charVec = readLines("SQL/R_PRE_BecameAwareCiCreated_PRE.sql")
query = paste(query.charVec,collapse="\n")
becameAware.df = sqlQuery(PSTMRKTcxn,query)

query.charVec = readLines("SQL/R_PRE_InvestStartToCloseBecameAware.sql")
query = paste(query.charVec,collapse="\n")
investStarttoClose.df = sqlQuery(PSTMRKTcxn,query)

query.charVec = readLines("SQL/R_PRE_InvestStartToClosePRE.sql")
query = paste(query.charVec,collapse="\n")
investStarttoPRE.df = sqlQuery(PSTMRKTcxn,query)

close(PSTMRKTcxn)

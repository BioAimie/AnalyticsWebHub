# THIS IS THE FILE USED TO PULL ALL DATA NEEDED FOR THE CONTAMINATION DASHBOARD FROM SQL
# Set the environment

# load remote data base connection package
#*note: to set DB paths go to Control Panel/Systems & Security/Administrative Tools/Data Sources (ODBC)
library(RODBC)
# open database connection 
PMScxn <- odbcConnect("PMS_PROD")

query.charVec = readLines("SQL/R_CONTAM_EnvironmentalSwabs.sql")
query = paste(query.charVec,collapse="\n")
environ.df = sqlQuery(PMScxn,query)

query.charVec = readLines("SQL/R_CONTAM_PersonnelSwabs.sql")
query = paste(query.charVec,collapse="\n")
person.df = sqlQuery(PMScxn,query)

query.charVec = readLines("SQL/R_CONTAM_PoolSwabs.sql")
query = paste(query.charVec,collapse="\n")
pool.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)

#vpYesBar
BFDXcxn = odbcConnect("Datamart")

query.charVec = readLines("SQL/R_CONTAM_vpAppYesBar_QA.sql")
query = paste(query.charVec,collapse="\n")
vpAppYesBar.df = sqlQuery(BFDXcxn,query)

close(BFDXcxn)

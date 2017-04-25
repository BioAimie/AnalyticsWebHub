library(RODBC)
# open database connection 
PMScxn = odbcConnect("PMS_PROD")

# run the query to grab pouches shipped to customers
query.charVec = readLines("SQL/R_CC_CustPouchesShippedDetailed.sql")
query = paste(query.charVec,collapse="\n")
pouches.df = sqlQuery(PMScxn,query)

# run the query to grab failures by location
query.charVec = readLines("SQL/R_CC_LocationLevelFailures.sql")
query = paste(query.charVec,collapse="\n")
complaints.df = sqlQuery(PMScxn,query)

# run the query to grab high-level failure data (i.e. for all products, not pouch/chemistry-specific)
query.charVec = readLines("SQL/R_CC_HighLevelFailures.sql")
query = paste(query.charVec,collapse="\n")
failures.df = sqlQuery(PMScxn,query)

# run the query to get the field instrument install base by version
query.charVec = readLines("SQL/R_CC_FieldInstallBase.sql")
query = paste(query.charVec,collapse="\n")
installed.df = sqlQuery(PMScxn,query)

# run the query to get count of complaints
query.charVec = readLines("SQL/R_CC_CountComplaints.sql")
query = paste(query.charVec,collapse="\n")
complaintsCount.df = sqlQuery(PMScxn,query)

# run the query to get BioThreat Failures
query.charVec = readLines("SQL/R_CC_BioThreatFailures.sql")
query = paste(query.charVec,collapse="\n")
biothreat.df = sqlQuery(PMScxn,query)

# close remote connection
odbcCloseAll()
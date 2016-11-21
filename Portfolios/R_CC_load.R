library(RODBC)
# open database connection 
PMScxn = odbcConnect("PMS_PROD")

# run the query to grab pouches shipped to customers
query.charVec = scan("SQL/R_CC_CustPouchesShippedDetailed.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
pouches.df = sqlQuery(PMScxn,query)

# run the query to grab failures by location
query.charVec = scan("SQL/R_CC_LocationLevelFailures.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
complaints.df = sqlQuery(PMScxn,query)

# run the query to grab high-level failure data (i.e. for all products, not pouch/chemistry-specific)
query.charVec = scan("SQL/R_CC_HighLevelFailures.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
failures.df = sqlQuery(PMScxn,query)

# run the query to get the field instrument install base by version
query.charVec = scan("SQL/R_CC_FieldInstallBase.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
installed.df = sqlQuery(PMScxn,query)

# run the query to get BioThreat Failures
query.charVec = scan("SQL/R_CC_BioThreatFailures.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
biothreat.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)
# open database connection 
PMScxn = odbcConnect("PMS_PROD")

# run the queries to get control failures in pouch qc 
query.charVec = readLines("SQL/Q_PQC_FilmArray1ControlFailures.sql")
query = paste(query.charVec,collapse="\n")
fa1.cf.df = sqlQuery(PMScxn,query)

query.charVec = readLines("SQL/Q_PQC_FilmArray2ControlFailures.sql")
query = paste(query.charVec,collapse="\n")
fa2.cf.df = sqlQuery(PMScxn,query)

# get some field data
query.charVec = readLines("SQL/Q_PQC_FieldFailures.sql")
query = paste(query.charVec,collapse="\n")
field.df = sqlQuery(PMScxn,query)

# # get pouches shipped so that the control failures per pouches shipped rate can be checked vs. Jay's results
# query.charVec = readLines("SQL/R_CC_CustPouchesShippedDetailed.sql")
# query = paste(query.charVec,collapse="\n")
# pouches.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)

# open database connection 
PTcxn = odbcConnect("PouchTracker")

# run the query to get the failure data from PouchTracker DB
query.charVec = readLines("SQL/Q_PQC_leakAndHydrationFailuresPouchTracker.sql")
query = paste(query.charVec,collapse="\n")
ptRuns.df = sqlQuery(PTcxn,query)

# close remote connection
close(PTcxn)

# open database connection 
PQcxn = odbcConnect("PouchQC")

# run the query to get the delta weight
query.charVec = readLines("SQL/Q_PQC_rehydrationWeight.sql")
query = paste(query.charVec,collapse="\n")
rehydration.df = sqlQuery(PQcxn,query)

# run the query to get the failure data from PouchQC DB
query.charVec = readLines("SQL/Q_PQC_leakAndHydrationFailuresPouchQC.sql")
query = paste(query.charVec,collapse="\n")
pqcRuns.df = sqlQuery(PQcxn,query)

# close remote connection
close(PQcxn)
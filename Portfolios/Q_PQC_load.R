# open database connection 
PMScxn = odbcConnect("PMS_PROD")

# run the query to get the delta weight
query.charVec = scan("SQL/Q_PQC_rehydrationWeight.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
rehydration.df = sqlQuery(PMScxn,query)

# run the query to get the failure data from PouchQC DB
query.charVec = scan("SQL/Q_PQC_leakAndHydrationFailuresPouchQC.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
pqcRuns.df = sqlQuery(PMScxn,query)

# run the queries to get control failures in pouch qc 
query.charVec = scan("SQL/Q_PQC_FilmArray1ControlFailures.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
fa1.cf.df = sqlQuery(PMScxn,query)

query.charVec = scan("SQL/Q_PQC_FilmArray2ControlFailures.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
fa2.cf.df = sqlQuery(PMScxn,query)

# get some field data
query.charVec = scan("SQL/Q_PQC_FeildFailures.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
field.df = sqlQuery(PMScxn,query)

# # get pouches shipped so that the control failures per pouches shipped rate can be checked vs. Jay's results
# query.charVec = scan("SQL/R_CC_CustPouchesShippedDetailed.txt", what=character(),quote="")
# query = paste(query.charVec,collapse=" ")
# pouches.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)

# open database connection 
PTcxn = odbcConnect("PouchTracker")

# run the query to get the failure data from PouchTracker DB
query.charVec = scan("SQL/Q_PQC_leakAndHydrationFailuresPouchTracker.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
ptRuns.df = sqlQuery(PTcxn,query)

# close remote connection
close(PTcxn)
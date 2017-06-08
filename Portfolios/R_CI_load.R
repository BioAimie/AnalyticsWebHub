library(RODBC)
# open database connection 
PMScxn = odbcConnect("PMS_PROD")

# run the query to get escalated complaints per complaints
query.charVec = readLines("SQL/R_CI_EscalatedComplaintsPerComplaint.sql")
query = paste(query.charVec,collapse="\n")
complaints.df = sqlQuery(PMScxn,query)

# run the query to get erroneous results complaints
query.charVec = readLines("SQL/R_CI_ErroneousResultComplaints.sql")
query = paste(query.charVec,collapse="\n")
erroneous.df = sqlQuery(PMScxn,query)

#run the query to get the pouches shipped totals by product
query.charVec = readLines("SQL/R_CI_productShipped.sql")
query = paste(query.charVec,collapse="\n")
productShipped.df = sqlQuery(PMScxn,query)

# run the query to get the total count of CIs only
query.charVec = readLines("SQL/R_CI_countComplaints.sql")
query = paste(query.charVec,collapse="\n")
countComplaint.df = sqlQuery(PMScxn,query)

query.charVec = readLines("SQL/R_CC_CustPouchesShippedDetailed.sql")
query = paste(query.charVec,collapse="\n")
pouches.3yr.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)

# open database connection 
PMScxn = odbcConnect("PMS1_LOC")

# run the query to get the total count of CIs only
query.charVec = readLines("SQL/R_CI_countCI.sql")
query = paste(query.charVec,collapse="\n")
countCI.df = sqlQuery(PMScxn,query)

# run the query to get data for the Product, Assay and Summary fields in CI Tickets
query.charVec = readLines("SQL/R_CI_Product_Assay_Summary.sql")
query = paste(query.charVec,collapse="\n")
overview.df = sqlQuery(PMScxn,query)

# run the query to get data for the Product, Assay and Summary fields in CI Tickets
query.charVec = readLines("SQL/R_CI_RunFileObservations.sql")
query = paste(query.charVec,collapse="\n")
observations.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)
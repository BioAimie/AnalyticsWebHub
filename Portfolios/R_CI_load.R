library(RODBC)
# open database connection 
PMScxn = odbcConnect("PMS_PROD")

# run the query to get escalated complaints per complaints
query.charVec = scan("SQL/R_CI_EscalatedComplaintsPerComplaint.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
complaints.df = sqlQuery(PMScxn,query)

# run the query to get erroneous results complaints
query.charVec = scan("SQL/R_CI_ErroneousResultComplaints.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
erroneous.df = sqlQuery(PMScxn,query)

#run the query to get the pouches shipped totals by product
query.charVec = scan("SQL/R_CI_productShipped.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
productShipped.df = sqlQuery(PMScxn,query)

# run the query to get the total count of CIs only
query.charVec = scan("SQL/R_CI_countComplaints.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
countComplaint.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)

# open database connection 
PMScxn = odbcConnect("PMS1_LOC")

# run the query to get the total count of CIs only
query.charVec = scan("SQL/R_CI_countCI.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
countCI.df = sqlQuery(PMScxn,query)

# run the query to get data for the Product, Assay and Summary fields in CI Tickets
query.charVec = scan("SQL/R_CI_Product_Assay_Summary.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
overview.df = sqlQuery(PMScxn,query)

# run the query to get data for the Product, Assay and Summary fields in CI Tickets
query.charVec = scan("SQL/R_CI_RunFileObservations.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
observations.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)
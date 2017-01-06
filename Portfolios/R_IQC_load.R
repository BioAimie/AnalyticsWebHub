library(RODBC)
#---------------------------------------DATA GRABBING AND UPDATING -------------------------------------#
PMScxn = odbcConnect("PMS_PROD")

queryGrabIQC.charVec = readLines("SQL/R_IQC_Overview.sql")
queryGrabIQC = paste(queryGrabIQC.charVec,collapse="\n")
IQC.df = sqlQuery(PMScxn,queryGrabIQC)

query.charVec = readLines("SQL/R_IQC_FirstPassYield.sql")
query = paste(query.charVec,collapse="\n")
firstPass.df = sqlQuery(PMScxn,query)

query.charVec = readLines("SQL/R_IQC_Fluorescence.sql")
query = paste(query.charVec,collapse="\n")
fluor.df = sqlQuery(PMScxn,query)

query.charVec = readLines("SQL/R_IQC_InstrumentErrors.sql")
query = paste(query.charVec,collapse="\n")
errors.df = sqlQuery(PMScxn,query)

close(PMScxn)
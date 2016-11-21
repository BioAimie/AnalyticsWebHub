library(RODBC)
#---------------------------------------DATA GRABBING AND UPDATING -------------------------------------#
PMScxn = odbcConnect("PMS_PROD")

queryGrabIQC.charVec = scan("SQL/R_IQC_Overview.txt",what=character(),quote="")
queryGrabIQC = paste(queryGrabIQC.charVec,collapse=" ")
IQC.df = sqlQuery(PMScxn,queryGrabIQC)

query.charVec = scan("SQL/R_IQC_FirstPassYield.txt",what=character(),quote="")
query = paste(query.charVec,collapse=" ")
firstPass.df = sqlQuery(PMScxn,query)

query.charVec = scan("SQL/R_IQC_Fluorescence.txt",what=character(),quote="")
query = paste(query.charVec,collapse=" ")
fluor.df = sqlQuery(PMScxn,query)

query.charVec = scan("SQL/R_IQC_InstrumentErrors.txt",what=character(),quote="")
query = paste(query.charVec,collapse=" ")
errors.df = sqlQuery(PMScxn,query)

close(PMScxn)
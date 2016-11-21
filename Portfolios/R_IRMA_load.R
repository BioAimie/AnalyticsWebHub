# THIS IS THE FILE USED TO PULL ALL DATA NEEDED FOR THE RMA DASHBOARD FROM SQL

# load remote data base connection package
#*note: to set DB paths go to Control Panel/Systems & Security/Administrative Tools/Data Sources (ODBC)
library(RODBC)
# open database connection 
PMScxn = odbcConnect("PMS_PROD")

# get pouches shipped
query.charVec = scan("SQL/R_IRMA_PouchesShipped.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
pouches.df = sqlQuery(PMScxn,query)

# get complaint rmas
query.charVec = scan("SQL/R_IRMA_ComplaintRMAs.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
complaints.df = sqlQuery(PMScxn,query)

# get parts used excluding preventative maintenance
query.charVec = scan("SQL/R_IRMA_PartsUsedExcludingPreventativeMaintenance.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
parts.df = sqlQuery(PMScxn,query)

# get service codes used
query.charVec = scan("SQL/R_IRMA_ServiceCodes.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
codes.df = sqlQuery(PMScxn,query)

# service code categories and descriptions
codeDescript.df <- read.csv('SQL/serviceCodeDescriptions.csv', header=TRUE, sep = ',')

# get service instruments shipped
query.charVec = scan("SQL/R_IRMA_RMAsShippedByInstrumentVersion.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
rmasShip.df = sqlQuery(PMScxn,query)

# get customer-reported early failures
query.charVec = scan("SQL/R_IRMA_CustEarlyFailByVersion.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
failures.df = sqlQuery(PMScxn,query)

# get new instruments shipped
query.charVec = scan("SQL/R_IRMA_NewInstShipByVersion.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
instShip.df = sqlQuery(PMScxn,query)

# get the root cause of failure for 30/90 days
query.charVec = scan("SQL/R_IRMA_RootCauseFailedPart3090.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
rootCause.df = sqlQuery(PMScxn,query)
 
# get the hours run at failure
query.charVec <- scan('SQL/R_IRMA_HoursAtFailures.txt',what=character(),quote="")
query <- paste(query.charVec,collapse=" ")
hours.df <- sqlQuery(PMScxn,query)

# get earliest early life failure indicator
query.charVec <- scan('SQL/R_IRMA_EarlyFailuresByCodeFromFeild.txt',what=character(),quote="")
query <- paste(query.charVec,collapse=" ")
leadingEF.df <- sqlQuery(PMScxn,query)

# get earliest early life failure indicator and trace to manufacturing date
query.charVec <- scan('SQL/R_IRMA_LeadingIndicatorEarlyFailureByManfDate.txt',what=character(),quote="")
query <- paste(query.charVec,collapse=" ")
leadEFmanf.df <- sqlQuery(PMScxn,query)

# get instruments built by date of manufature
query.charVec <- scan('SQL/R_INCR_InstrumentsProduced_denom.txt',what=character(),quote="")
query <- paste(query.charVec,collapse=" ")
instBuilt.df <- sqlQuery(PMScxn,query)

# get instruments through QC date
query.charVec <- scan('SQL/R_IRMA_InstrumentsQCDate_denom.txt',what=character(),quote="")
query <- paste(query.charVec,collapse=" ")
instQCDate.df <- sqlQuery(PMScxn,query)

# get early life failure indicator and trace to service date
query.charVec <- scan('SQL/R_IRMA_LeadingIndicatorEarlyFailureByServDate.txt',what=character(),quote="")
query <- paste(query.charVec,collapse=" ")
leadEFserv.df <- sqlQuery(PMScxn,query)

# get the data from the Prod server
query.charVec <- scan('SQL/R_IRMA_serialShipAndReturnByDate.txt',what=character(),quote="")
query <- paste(query.charVec,collapse=" ")
track.df <- sqlQuery(PMScxn,query)

# close remote connection
odbcClose(PMScxn)
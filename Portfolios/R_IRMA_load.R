# THIS IS THE FILE USED TO PULL ALL DATA NEEDED FOR THE RMA DASHBOARD FROM SQL

# load remote data base connection package
#*note: to set DB paths go to Control Panel/Systems & Security/Administrative Tools/Data Sources (ODBC)
library(RODBC)
# open database connection
PMScxn = odbcConnect("PMS_PROD")

# get pouches shipped
query.charVec = readLines("SQL/R_CC_CustPouchesShippedDetailed.sql")
query = paste(query.charVec,collapse="\n")
pouches.df = sqlQuery(PMScxn,query)

# get complaint rmas
query.charVec = readLines("SQL/R_IRMA_ComplaintRMAs.sql")
query = paste(query.charVec,collapse="\n")
complaints.df = sqlQuery(PMScxn,query)

# get parts used excluding preventative maintenance
query.charVec = readLines("SQL/R_IRMA_PartsUsedExcludingPreventativeMaintenance.sql")
query = paste(query.charVec,collapse="\n")
parts.df = sqlQuery(PMScxn,query)

# get service codes used
query.charVec = readLines("SQL/R_IRMA_ServiceCodes.sql")
query = paste(query.charVec,collapse="\n")
codes.df = sqlQuery(PMScxn,query)

# service code categories and descriptions
codeDescript.df <- read.csv('SQL/serviceCodeDescriptions.csv', header=TRUE, sep = ',')

# get service instruments shipped
query.charVec = readLines("SQL/R_IRMA_RMAsShippedByInstrumentVersion.sql")
query = paste(query.charVec,collapse="\n")
rmasShip.df = sqlQuery(PMScxn,query)

# get customer-reported early failures
query.charVec = readLines("SQL/R_IRMA_CustEarlyFailByVersion.sql")
query = paste(query.charVec,collapse="\n")
failures.df = sqlQuery(PMScxn,query)

# get new instruments shipped
query.charVec = readLines("SQL/R_IRMA_NewInstShipByVersion.sql")
query = paste(query.charVec,collapse="\n")
instShip.df = sqlQuery(PMScxn,query)

# get the root cause of failure for 30/90 days
query.charVec = readLines("SQL/R_IRMA_RootCauseFailedPart3090.sql")
query = paste(query.charVec,collapse="\n")
rootCause.df = sqlQuery(PMScxn,query)
 
# get the hours run at failure
query.charVec <- readLines('SQL/R_IRMA_HoursAtFailures.sql')
query <- paste(query.charVec,collapse="\n")
hours.df <- sqlQuery(PMScxn,query)

# get earliest early life failure indicator
query.charVec <- readLines('SQL/R_IRMA_EarlyFailuresByCodeFromField.sql')
query <- paste(query.charVec,collapse="\n")
leadingEF.df <- sqlQuery(PMScxn,query)

# get earliest early life failure indicator and trace to manufacturing date
query.charVec <- readLines('SQL/R_IRMA_LeadingIndicatorEarlyFailureByManfDate.sql')
query <- paste(query.charVec,collapse="\n")
leadEFmanf.df <- sqlQuery(PMScxn,query)

# get instruments built by date of manufature
query.charVec <- readLines('SQL/R_INCR_InstrumentsProduced_denom.sql')
query <- paste(query.charVec,collapse="\n")
instBuilt.df <- sqlQuery(PMScxn,query)

# get instruments through QC date
query.charVec <- readLines('SQL/R_IRMA_InstrumentsQCDate_denom.sql')
query <- paste(query.charVec,collapse="\n")
instQCDate.df <- sqlQuery(PMScxn,query)

# get early life failure indicator and trace to service date
query.charVec <- readLines('SQL/R_IRMA_LeadingIndicatorEarlyFailureByServDate.sql')
query <- paste(query.charVec,collapse="\n")
leadEFserv.df <- sqlQuery(PMScxn,query)

# get the data from the Prod server
query.charVec <- readLines('SQL/R_IRMA_serialShipAndReturnByDate.sql')
query <- paste(query.charVec,collapse="\n")
track.df <- sqlQuery(PMScxn,query)

# get install base data from MAS
queryText <- readLines("SQL/R_IRMA_FieldInstallBase.sql")
query <- paste(queryText,collapse="\n")
installed.df <- sqlQuery(PMScxn,query)

# get new computers shipped
query.charVec = readLines("SQL/R_IRMA_NewCompShip.sql")
query = paste(query.charVec,collapse="\n")
compShip.df = sqlQuery(PMScxn,query)

# get early failure RMAs for computers/laptops/Torch base
queryText <- readLines("SQL/R_IRMA_ComputerEarlyFailure.sql")
query <- paste(queryText,collapse="\n")
computerEF.df <- sqlQuery(PMScxn,query)


# close remote connection
odbcClose(PMScxn)
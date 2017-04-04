library(RODBC)

# Open the connection to PMS1
PMScxn <- odbcConnect("PMS_PROD")

queryText <- readLines("SQL/O_IMAN_InstShipments.sql")
query <- paste(queryText,collapse="\n")
shipments.inst <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_IMAN_refurbConv.sql")
query <- paste(queryText,collapse="\n")
refurbConv.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_IMAN_newInstTrans.sql")
query <- paste(queryText,collapse="\n")
transferred.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_IMAN_InstrumentNCRBreakdown.sql")
query <- paste(queryText,collapse="\n")
ncr.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/O_IMAN_FailureCatsNCRs.sql")
query <- paste(queryText,collapse="\n")
failCats.df <- sqlQuery(PMScxn,query)

query.charVec <- readLines('SQL/R_IRMA_EarlyFailuresByCodeFromField.sql')
query <- paste(query.charVec,collapse="\n")
leadingEF.df <- sqlQuery(PMScxn,query)

query.charVec = readLines("SQL/R_IQC_FirstPassYield.sql")
query = paste(query.charVec,collapse="\n")
firstPass.df = sqlQuery(PMScxn,query)

queryText <- readLines("SQL/R_INCR_InstrumentsProduced_denom.sql")
query <- paste(queryText,collapse="\n")
instBuilt.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/R_INCR_InstrumentNCRs.sql")
query <- paste(queryText,collapse="\n")
instNCRs.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/R_INCR_InstrumentNCRs_WPFS.sql")
query <- paste(queryText,collapse="\n")
wpfsNCR.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/E_ID_EarlyFailureWithModes.sql")
query <- paste(queryText,collapse="\n")
fail.modes.df <- sqlQuery(PMScxn,query)

query.charVec = readLines("SQL/R_IRMA_RMAsShippedByInstrumentVersion.sql")
query = paste(query.charVec,collapse="\n")
rmasShip.df = sqlQuery(PMScxn,query)

odbcClose(PMScxn)
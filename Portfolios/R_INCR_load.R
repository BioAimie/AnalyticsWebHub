library(RODBC)

# Open the connection to PMS1
PMScxn <- odbcConnect("PMS_PROD")

# Load the instrument NCRs with Where Found = Final QC
queryText <- readLines("SQL/R_INCR_InstrumentNCR_FinalQC.sql")
query <- paste(queryText,collapse="\n")
finalQC.df <- sqlQuery(PMScxn,query)

# Load the raw material (instrument BOM) NCRs with Where Found = Incoming Inspection
queryText <- readLines("SQL/R_INCR_InstrumentNCRs_Incoming.sql")
query <- paste(queryText,collapse="\n")
incoming.df <- sqlQuery(PMScxn,query)

# Load the instrument NCRs WPFS data
queryText <- readLines("SQL/R_INCR_InstrumentNCRs_WPFS.sql")
query <- paste(queryText,collapse="\n")
wpfsNCR.df <- sqlQuery(PMScxn,query)

# Load the instruments produced according to their manufacturing data in Production Web
queryText <- readLines("SQL/R_INCR_InstrumentsProduced_denom.sql")
query <- paste(queryText,collapse="\n")
instBuilt.df <- sqlQuery(PMScxn,query)

# Load the instrument NCRs created, including Raw Material NCRs with Part Affected matching the FLM1-ASY-0001/FLM2-ASY-0001 BOM
queryText <- readLines("SQL/R_INCR_InstrumentNCRs.sql")
query <- paste(queryText,collapse="\n")
instNCRs.df <- sqlQuery(PMScxn,query)

# Load the instruments produced according to their manufacturing data in Production Web with early failure marked
queryText <- readLines("SQL/R_INCR_ProductionEarlyFailures.sql")
query <- paste(queryText,collapse="\n")
earlyfailures.df <- sqlQuery(PMScxn,query)

# Load the data for early failure annotations
queryText <- readLines("SQL/R_INCR_EarlyFailureAnnotationMaker.sql")
query <- paste(queryText,collapse="\n")
annotations.df <- sqlQuery(PMScxn,query)

# Load the data for early failure annotations
queryText <- readLines("SQL/R_INCR_EarlyFailureAnnotationMakerByCustReport.sql")
query <- paste(queryText,collapse="\n")
annotations.cust.df <- sqlQuery(PMScxn,query)

# Load the data for early failures by serial batch size
queryText <- readLines("SQL/R_INCR_EarlyFailuresBySerialNumberFamily.sql")
query <- paste(queryText,collapse="\n")
serialbatches.df <- sqlQuery(PMScxn,query)

# Load ncr incoming inspection data 
queryText <- readLines("SQL/R_INCR_IncomingInspection.sql")
query <- paste(queryText,collapse="\n")
incomingInspection.df <- sqlQuery(PMScxn,query, stringsAsFactors=FALSE)

queryText <- readLines("SQL/O_IMAN_InstShipments.sql")
query <- paste(queryText,collapse="\n")
instshipments.df <- sqlQuery(PMScxn,query)

odbcClose(PMScxn)
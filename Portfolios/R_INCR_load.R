library(RODBC)

# Open the connection to PMS1
PMScxn <- odbcConnect("PMS_PROD")

# Load the instrument NCRs with Where Found = Final QC
queryText <- scan("SQL/R_INCR_InstrumentNCR_FinalQC.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
finalQC.df <- sqlQuery(PMScxn,query)

# Load the raw material (instrument BOM) NCRs with Where Found = Incoming Inspection
queryText <- scan("SQL/R_INCR_InstrumentNCRs_Incoming.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
incoming.df <- sqlQuery(PMScxn,query)

# Load the instrument NCRs WPFS data
queryText <- scan("SQL/R_INCR_InstrumentNCRs_WPFS.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
wpfsNCR.df <- sqlQuery(PMScxn,query)

# Load the instruments produced according to their manufacturing data in Production Web
queryText <- scan("SQL/R_INCR_InstrumentsProduced_denom.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
instBuilt.df <- sqlQuery(PMScxn,query)

# Load the instrument NCRs created, including Raw Material NCRs with Part Affected matching the FLM1-ASY-0001/FLM2-ASY-0001 BOM
queryText <- scan("SQL/R_INCR_InstrumentNCRs.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
instNCRs.df <- sqlQuery(PMScxn,query)

# Load the instruments produced according to their manufacturing data in Production Web with early failure marked
queryText <- scan("SQL/R_INCR_ProductionEarlyFailures.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
earlyfailures.df <- sqlQuery(PMScxn,query)

# Load the data for early failure annotations
queryText <- scan("SQL/R_INCR_EarlyFailureAnnotationMaker.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
annotations.df <- sqlQuery(PMScxn,query)

# Load the data for early failures by serial batch size
queryText <- scan("SQL/R_INCR_EarlyFailuresBySerialNumberFamily.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
serialbatches.df <- sqlQuery(PMScxn,query)

odbcClose(PMScxn)
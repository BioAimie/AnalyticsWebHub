library(RODBC)

# Open the connection to PMS1
PMScxn <- odbcConnect("PMS_PROD")

queryText <- scan("SQL/O_IMAN_partNames.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
partNames.df <- sqlQuery(PMScxn,query)

queryText <- scan("SQL/O_IMAN_InstShipments.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
shipments.inst <- sqlQuery(PMScxn,query)

# queryText <- scan("SQL/newInventory2.txt",what=character(),quote="")
# query <- paste(queryText,collapse=" ")
# newInven.df <- sqlQuery(PMScxn,query)
# 
# queryText <- scan("SQL/refurbInventory2.txt",what=character(),quote="")
# query <- paste(queryText,collapse=" ")
# refurbInven.df <- sqlQuery(PMScxn,query)

queryText <- scan("SQL/O_IMAN_newInstTrans.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
transferred.df <- sqlQuery(PMScxn,query)

queryText <- scan("SQL/O_IMAN_InstrumentNCRBreakdown.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
ncr.df <- sqlQuery(PMScxn,query)

queryText <- scan("SQL/O_IMAN_failedPartsNCRs.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
failedParts.df <- sqlQuery(PMScxn,query)

queryText <- scan("SQL/O_IMAN_newInstELFandDOA.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
earlyFails.df <- sqlQuery(PMScxn,query)

# Load the instruments produced according to their manufacturing data in Production Web
queryText <- scan("SQL/R_INCR_InstrumentsProduced_denom.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
instBuilt.df <- sqlQuery(PMScxn,query)

# Load the instrument NCRs created, including Raw Material NCRs with Part Affected matching the FLM1-ASY-0001/FLM2-ASY-0001 BOM
queryText <- scan("SQL/R_INCR_InstrumentNCRs.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
instNCRs.df <- sqlQuery(PMScxn,query)

queryText <- scan("SQL/O_IMAN_refurbConv.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
refurbConv.df <- sqlQuery(PMScxn,query)

odbcClose(PMScxn)
library(RODBC)

PMScxn = odbcConnect("PMS_PROD")

query.charVec = readLines("SQL/O_SUPP_ncrPartInfo.sql")
query = paste(query.charVec,collapse="\n")
ncrParts.df = sqlQuery(PMScxn,query)

query.charVec = readLines("SQL/O_SUPP_supplierReciepts.sql")
query = paste(query.charVec,collapse="\n")
receipts.df = sqlQuery(PMScxn,query)

close(PMScxn)
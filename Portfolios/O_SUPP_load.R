library(RODBC)

PMScxn = odbcConnect("PMS_PROD")

query.charVec = scan("SQL/O_SUPP_ncrPartInfo.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
ncrParts.df = sqlQuery(PMScxn,query)

query.charVec = scan("SQL/O_SUPP_supplierReciepts.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
receipts.df = sqlQuery(PMScxn,query)

close(PMScxn)
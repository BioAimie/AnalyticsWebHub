# THIS IS THE FILE USED TO PULL ALL DATA NEEDED FOR THE SUPP DASHBOARD FROM SQL

setwd('~/WebHub/AnalyticsWebHub/')

library(RODBC)

PMScxn = odbcConnect("PMS_PROD")

query.charVec = scan("SQL/O_SUPP_ncrPartInfo.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
ncrParts.df = sqlQuery(PMScxn,query)

query.charVec = scan("SQL/O_SUPP_supplierReciepts.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
receipts.df = sqlQuery(PMScxn,query)

query.charVec = scan("SQL/O_SUPP_ncrFilterData.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
filters.df = sqlQuery(PMScxn,query)

query.charVec = scan("SQL/O_SUPP_masFilters.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
smi.df = sqlQuery(PMScxn,query)

query.charVec = scan("SQL/O_SUPP_ncrMaterialsManagement.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
defects.df = sqlQuery(PMScxn,query)

query.charVec = scan("SQL/O_SUPP_lotYields.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
yields.df = sqlQuery(PMScxn,query)

query.charVec = scan("SQL/O_SUPP_ncrIndex.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
index.df = sqlQuery(PMScxn,query)

close(PMScxn)
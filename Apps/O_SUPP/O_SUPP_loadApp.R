# THIS IS THE FILE USED TO PULL ALL DATA NEEDED FOR THE SUPP DASHBOARD FROM SQL

setwd('~/WebHub/AnalyticsWebHub/')

library(RODBC)

PMScxn = odbcConnect("PMS_PROD")

query.charVec = readLines("SQL/O_SUPP_ncrPartInfo.sql")
query = paste(query.charVec,collapse="\n")
ncrParts.df = sqlQuery(PMScxn,query)

query.charVec = readLines("SQL/O_SUPP_supplierReciepts.sql")
query = paste(query.charVec,collapse="\n")
receipts.df = sqlQuery(PMScxn,query)

query.charVec = readLines("SQL/O_SUPP_ncrFilterData.sql")
query = paste(query.charVec,collapse="\n")
filters.df = sqlQuery(PMScxn,query)

query.charVec = readLines("SQL/O_SUPP_masFilters.sql")
query = paste(query.charVec,collapse="\n")
smi.df = sqlQuery(PMScxn,query)

query.charVec = readLines("SQL/O_SUPP_ncrMaterialsManagement.sql")
query = paste(query.charVec,collapse="\n")
defects.df = sqlQuery(PMScxn,query)

query.charVec = readLines("SQL/O_SUPP_lotYields.sql")
query = paste(query.charVec,collapse="\n")
yields.df = sqlQuery(PMScxn,query)

query.charVec = readLines("SQL/O_SUPP_ncrIndex.sql")
query = paste(query.charVec,collapse="\n")
index.df = sqlQuery(PMScxn,query)

close(PMScxn)
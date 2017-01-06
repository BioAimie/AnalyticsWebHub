# THIS IS THE FILE USED TO PULL ALL DATA NEEDED FOR THE CONTAMINATION DASHBOARD FROM SQL
# Set the environment

# load remote data base connection package
#*note: to set DB paths go to Control Panel/Systems & Security/Administrative Tools/Data Sources (ODBC)
library(RODBC)
# open database connection 
PMScxn <- odbcConnect("PMS_PROD")

#master assay list for RP palette
query.charVec = readLines("SQL/R_CONTAM_masterAssaypalette.sql")
query = paste(query.charVec,collapse="\n")
faAssayPal.df = sqlQuery(PMScxn,query)

#Rates
#swabs from FilmArray Database for Enviro
query.charVec = readLines("SQL/R_CONTAM_Enviro.sql")
query = paste(query.charVec,collapse="\n")
faEnviro.df = sqlQuery(PMScxn,query)

#swabs from FilmArray Database for Personnel
query.charVec = readLines("SQL/R_CONTAM_Personnel.sql")
query = paste(query.charVec,collapse="\n")
faPersonnel.df = sqlQuery(PMScxn,query)

#swabs from FilmArray Database for Pools
query.charVec = readLines("SQL/R_CONTAM_Pool.sql")
query = paste(query.charVec,collapse="\n")
faPool.df = sqlQuery(PMScxn,query)

#Counts
#swabs from FilmArray Database for Enviro Count
query.charVec = readLines("SQL/R_CONTAM_EnviroCount.sql")
query = paste(query.charVec,collapse="\n")
faEnviroCount.df = sqlQuery(PMScxn,query)

#swabs from FilmArray Database for Personnel Count
query.charVec = readLines("SQL/R_CONTAM_PersonnelCount.sql")
query = paste(query.charVec,collapse="\n")
faPersonnelCount.df = sqlQuery(PMScxn,query)

#swabs from FilmArray Database for Personnel Pouch Count
query.charVec = readLines("SQL/R_CONTAM_PersonnelCountPouch.sql")
query = paste(query.charVec,collapse="\n")
faPersonnelCountPouch.df = sqlQuery(PMScxn,query)

#swabs from FilmArray Database for Pools Pouch Count
query.charVec = readLines("SQL/R_CONTAM_PoolCountPouch.sql")
query = paste(query.charVec,collapse="\n")
faPoolCountPouch.df = sqlQuery(PMScxn,query)

#swabs from FilmArray Database for Pools
query.charVec = readLines("SQL/R_CONTAM_PoolCount.sql")
query = paste(query.charVec,collapse="\n")
faPoolCount.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)

#vpYesBar
BFDXcxn = odbcConnect("Datamart")
query.charVec = readLines("SQL/R_CONTAM_vpAppYesBar_QA.sql")
query = paste(query.charVec,collapse="\n")
vpAppYesBar.df = sqlQuery(BFDXcxn,query)
close(BFDXcxn)
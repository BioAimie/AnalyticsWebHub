# THIS IS THE FILE USED TO PULL ALL DATA NEEDED FOR THE CONTAMINATION DASHBOARD FROM SQL
# Set the environment

# load remote data base connection package
#*note: to set DB paths go to Control Panel/Systems & Security/Administrative Tools/Data Sources (ODBC)
library(RODBC)
# open database connection 
BFDXcxn = odbcConnect("Datamart")
PMScxn <- odbcConnect("PMS_PROD")

#master assay list for RP palette
query.charVec = scan("SQL/R_CONTAM_masterAssaypalette.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
faAssayPal.df = sqlQuery(PMScxn,query)


#Rates
#swabs from FilmArray Database for Enviro
query.charVec = scan("SQL/R_CONTAM_Enviro.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
faEnviro.df = sqlQuery(PMScxn,query)


#swabs from FilmArray Database for Personnel
query.charVec = scan("SQL/R_CONTAM_Personnel.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
faPersonnel.df = sqlQuery(PMScxn,query)

#swabs from FilmArray Database for Pools
query.charVec = scan("SQL/R_CONTAM_Pool.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
faPool.df = sqlQuery(PMScxn,query)

#Counts
#swabs from FilmArray Database for Enviro Count
query.charVec = scan("SQL/R_CONTAM_EnviroCount.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
faEnviroCount.df = sqlQuery(PMScxn,query)

#swabs from FilmArray Database for Personnel Count
query.charVec = scan("SQL/R_CONTAM_PersonnelCount.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
faPersonnelCount.df = sqlQuery(PMScxn,query)


#swabs from FilmArray Database for Personnel Pouch Count
query.charVec = scan("SQL/R_CONTAM_PersonnelCountPouch.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
faPersonnelCountPouch.df = sqlQuery(PMScxn,query)


#swabs from FilmArray Database for Pools Pouch Count
query.charVec = scan("SQL/R_CONTAM_PoolCountPouch.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
faPoolCountPouch.df = sqlQuery(PMScxn,query)


#swabs from FilmArray Database for Pools
query.charVec = scan("SQL/R_CONTAM_PoolCount.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
faPoolCount.df = sqlQuery(PMScxn,query)

#vpYesBar
query.charVec = scan("SQL/R_CONTAM_vpAppYesBar_QA.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
vpAppYesBar.df = sqlQuery(BFDXcxn,query)
                        
# close remote connection
close(BFDXcxn)
close(PMScxn)
library(RODBC)
# open database connection 
PMScxn = odbcConnect("PMS_PROD")

# get FilmArray DB v1 runs
query.charVec = readLines("SQL/R_IRM_FilmArrayRuns_1.sql")
query = paste(query.charVec,collapse="\n")
fa1_runs.df = sqlQuery(PMScxn,query)

# get FilmArray DB v2 runs
query.charVec = readLines("SQL/R_IRM_FilmArrayRuns_2.sql")
query = paste(query.charVec,collapse="\n")
fa2_runs.df = sqlQuery(PMScxn,query)

# get user names
query.charVec = readLines("SQL/R_IRM_UserNames.sql")
query = paste(query.charVec,collapse="\n")
users.df = sqlQuery(PMScxn,query)

# get PCR1 control info for FilmArray DB v1 runs
query.charVec = readLines("SQL/R_IRM_FA1_PCR1.sql")
query = paste(query.charVec,collapse="\n")
fa1_pcr1.df = sqlQuery(PMScxn,query)

# get PCR2 control info for FilmArray DB v1 runs
query.charVec = readLines("SQL/R_IRM_FA1_PCR2.sql")
query = paste(query.charVec,collapse="\n")
fa1_pcr2.df = sqlQuery(PMScxn,query)

# get Yeast control info for FilmArray DB v1 runs
query.charVec = readLines("SQL/R_IRM_FA1_yeast.sql")
query = paste(query.charVec,collapse="\n")
fa1_yeast.df = sqlQuery(PMScxn,query)

# get control info for FilmArray DB v2 runs
query.charVec = readLines("SQL/R_IRM_FA2_AllControls.sql")
query = paste(query.charVec,collapse="\n")
fa2_all.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)
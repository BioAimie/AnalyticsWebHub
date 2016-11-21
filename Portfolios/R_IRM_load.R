library(RODBC)
# open database connection 
PMScxn = odbcConnect("PMS_PROD")

# get FilmArray DB v1 runs
query.charVec = scan("SQL/R_IRM_FilmArrayRuns_1.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
fa1_runs.df = sqlQuery(PMScxn,query)

# get FilmArray DB v2 runs
query.charVec = scan("SQL/R_IRM_FilmArrayRuns_2.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
fa2_runs.df = sqlQuery(PMScxn,query)

# get user names
query.charVec = scan("SQL/R_IRM_UserNames.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
users.df = sqlQuery(PMScxn,query)

# get PCR1 control info for FilmArray DB v1 runs
query.charVec = scan("SQL/R_IRM_FA1_PCR1.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
fa1_pcr1.df = sqlQuery(PMScxn,query)

# get PCR2 control info for FilmArray DB v1 runs
query.charVec = scan("SQL/R_IRM_FA1_PCR2.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
fa1_pcr2.df = sqlQuery(PMScxn,query)

# get Yeast control info for FilmArray DB v1 runs
query.charVec = scan("SQL/R_IRM_FA1_yeast.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
fa1_yeast.df = sqlQuery(PMScxn,query)

# get control info for FilmArray DB v2 runs
query.charVec = scan("SQL/R_IRM_FA2_AllControls.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
fa2_all.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)
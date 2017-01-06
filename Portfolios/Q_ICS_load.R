library(RODBC)
# open database connection 
PMScxn = odbcConnect("PMS_PROD")

## RJ OWES US AN EXPLINATION AND LET GREG AND ROD AND LINDSAY KNOW THAT THESE DATA ARE MISSING BECAUSE THE SOFTWARE TEAM DOESN'T HAVE ANY IDEA WHAT IS GOING ON
# # ------------------------------ THESE DATA FROM ICS 1.0 SEEM BAD... THERE ARE NO 2.0 DATA POINTS... THEY DON'T EXIST IN EITHER LINKED SERVER---------------
# query.charVec = readLines("SQL/Q_ICS_ManifoldLeak.sql")
# query = paste(query.charVec,collapse="\n")
# manifold.df = sqlQuery(PMScxn,query)
# 
# query.charVec = readLines("SQL/Q_ICS_PlungerLeak.sql")
# query = paste(query.charVec,collapse="\n")
# plunger.df = sqlQuery(PMScxn,query)
# # ------------------------------ THESE DATA FROM ICS 1.0 SEEM BAD... THERE ARE NO 2.0 DATA POINTS... THEY DON'T EXIST IN EITHER LINKED SERVER---------------

query.charVec = readLines("SQL/Q_ICS_TempCal.sql")
query = paste(query.charVec,collapse="\n")
temp.df = sqlQuery(PMScxn,query)

query.charVec = readLines("SQL/Q_ICS_OpticsCal.sql")
query = paste(query.charVec,collapse="\n")
optics.df = sqlQuery(PMScxn,query)

query.charVec = readLines("SQL/Q_ICS_SealBarCal.sql")
query = paste(query.charVec,collapse="\n")
sealbar.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)
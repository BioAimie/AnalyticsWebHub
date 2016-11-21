library(RODBC)
# open database connection 
PMScxn = odbcConnect("PMS_PROD")

## RJ OWES US AN EXPLINATION AND LET GREG AND ROD AND LINDSAY KNOW THAT THESE DATA ARE MISSING BECAUSE THE SOFTWARE TEAM DOESN'T HAVE ANY IDEA WHAT IS GOING ON
# # ------------------------------ THESE DATA FROM ICS 1.0 SEEM BAD... THERE ARE NO 2.0 DATA POINTS... THEY DON'T EXIST IN EITHER LINKED SERVER---------------
# query.charVec = scan("SQL/Q_ICS_ManifoldLeak.txt", what=character(),quote="")
# query = paste(query.charVec,collapse=" ")
# manifold.df = sqlQuery(PMScxn,query)
# 
# query.charVec = scan("SQL/Q_ICS_PlungerLeak.txt", what=character(),quote="")
# query = paste(query.charVec,collapse=" ")
# plunger.df = sqlQuery(PMScxn,query)
# # ------------------------------ THESE DATA FROM ICS 1.0 SEEM BAD... THERE ARE NO 2.0 DATA POINTS... THEY DON'T EXIST IN EITHER LINKED SERVER---------------

query.charVec = scan("SQL/Q_ICS_TempCal.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
temp.df = sqlQuery(PMScxn,query)

query.charVec = scan("SQL/Q_ICS_OpticsCal.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
optics.df = sqlQuery(PMScxn,query)

query.charVec = scan("SQL/Q_ICS_SealBarCal.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
sealbar.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)
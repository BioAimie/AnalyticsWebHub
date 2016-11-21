library(RODBC)
# open database connection 
PMScxn = odbcConnect("PMS_PROD")

# run the query to get Hydration test results
query.charVec = scan("SQL/Q_PM_HydrationControlData.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
hydration.df = sqlQuery(PMScxn,query)
  # combine hydration and sample hydration times for total hydration time
hydration.df$TotalHydrationTime <- hydration.df$HydrationTime+hydration.df$SampleHydrationTime

# run the query to get Burst test results
query.charVec = scan("SQL/Q_PM_BurstControlData.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
burst.df = sqlQuery(PMScxn,query)


# run the query to get FAIV line cannula test results
query.charVec = scan("SQL/Q_PM_faivLine.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
faivLine.df = sqlQuery(PMScxn,query)

# run the query to get FAIV line water weight test results
query.charVec = scan("SQL/Q_PM_faivLine_WaterWeight.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
faivLineWater.df = sqlQuery(PMScxn,query)

# run the query to get Hydration test results by MEQ
query.charVec = scan("SQL/Q_PM_PolarizedLight.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
polarized.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)
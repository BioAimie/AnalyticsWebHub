library(RODBC)
# open database connection 
PMScxn = odbcConnect("PMS_PROD")

# run the query to get Hydration test results
query.charVec = readLines("SQL/Q_PM_HydrationControlData.sql")
query = paste(query.charVec,collapse="\n")
hydration.df = sqlQuery(PMScxn,query)
  # combine hydration and sample hydration times for total hydration time
hydration.df$TotalHydrationTime <- hydration.df$HydrationTime+hydration.df$SampleHydrationTime

# run the query to get Burst test results
query.charVec = readLines("SQL/Q_PM_BurstControlData.sql")
query = paste(query.charVec,collapse="\n")
burst.df = sqlQuery(PMScxn,query)


# run the query to get FAIV line cannula test results
query.charVec = readLines("SQL/Q_PM_faivLine.sql")
query = paste(query.charVec,collapse="\n")
faivLine.df = sqlQuery(PMScxn,query)

# run the query to get FAIV line water weight test results
query.charVec = readLines("SQL/Q_PM_faivLine_WaterWeight.sql")
query = paste(query.charVec,collapse="\n")
faivLineWater.df = sqlQuery(PMScxn,query)

# run the query to get Hydration test results by MEQ
query.charVec = readLines("SQL/Q_PM_PolarizedLight.sql")
query = paste(query.charVec,collapse="\n")
polarized.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)
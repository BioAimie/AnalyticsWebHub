library(RODBC)
PMScxn <- odbcConnect("PMS_PROD")
cmd <- "EXECUTE [PMS1].[dbo].[bUpdateTrackerTables]";
FailureRMAs <- sqlQuery(PMScxn,cmd)
odbcClose(PMScxn)

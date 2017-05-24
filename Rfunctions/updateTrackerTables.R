library(RODBC)
PMScxn <- odbcConnect("PMS_PROD")
cmd <- "EXECUTE [PMS1].[dbo].[bUpdateTrackerTables]";
result <- sqlQuery(PMScxn,cmd)
odbcClose(PMScxn)
print(result);

# Updates on PMS1: bInstrumentParts, bInstrumentProduced
library(RODBC)
PMScxn <- odbcConnect("PMS_PROD")
cmd <- "EXECUTE [PMS1].[dbo].[bUpdateProductionTables]";
result <- sqlQuery(PMScxn,cmd)
odbcClose(PMScxn)
print(result);

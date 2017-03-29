# THIS IS THE FILE USED TO PULL ALL DATA NEEDED FOR THE RMA DASHBOARD FROM SQL
# Set the environment

# load remote data base connection package
#*note: to set DB paths go to Control Panel/Systems & Security/Administrative Tools/Data Sources (ODBC)
library(RODBC)
# open database connection 
PMScxn = odbcConnect("PMS_PROD")

# get gasket failure RMAs
query.charVec = readLines("SQL/R_IVOE_PlungerGasketCreepByPart.sql")
query = paste(query.charVec,collapse="\n")
gasketCreep.df = sqlQuery(PMScxn,query)

# get window bladder failure info by lot (failing at less than 100 run hours)
query.charVec = readLines("SQL/R_IVOE_WindowBladderFailureByLot.sql")
query = paste(query.charVec,collapse="\n")
bladderLots.df = sqlQuery(PMScxn,query)

# get lid latch failure RMAs
query.charVec = readLines("SQL/R_IVOE_LidFailuresByPart.sql")
query = paste(query.charVec,collapse="\n")
lids.df = sqlQuery(PMScxn,query)

# get number of RMAs shipped
query.charVec = readLines("SQL/R_IRMA_RMAsShippedByInstrumentVersion.sql")
query = paste(query.charVec,collapse="\n")
rmaShipped.df = sqlQuery(PMScxn,query)

# get pouches shipped
query.charVec = readLines("SQL/R_IVOE_PouchesShippedToCustomers.sql")
query = paste(query.charVec,collapse="\n")
pouches.df = sqlQuery(PMScxn,query)

# # get thermoboard failure RMAs
# query.charVec = readLines("SQL/R_IVOE_ThermoboardFailureByLot.sql")
# query = paste(query.charVec,collapse="\n")
# thermoBoard.df = sqlQuery(PMScxn,query)

# get board VoE: Thermoboard
query.charVec = readLines("SQL/R_IVOE_Thermoboard.sql")
query = paste(query.charVec,collapse="\n")
board.thermo.df = sqlQuery(PMScxn,query)

# get board VoE: Valve
query.charVec = readLines("SQL/R_IVOE_ValveBoard.sql")
query = paste(query.charVec,collapse="\n")
board.valve.df = sqlQuery(PMScxn,query)

# get board VoE: Master board
query.charVec = readLines("SQL/R_IVOE_ImageMasterBoard.sql")
query = paste(query.charVec,collapse="\n")
board.image.df = sqlQuery(PMScxn,query)

# get board VoE: Camera board
query.charVec = readLines("SQL/R_IVOE_CameraBoard.sql")
query = paste(query.charVec,collapse="\n")
board.camera.df = sqlQuery(PMScxn,query)

# get LED excitation failures by lot
query.charVec = readLines("SQL/R_IVOE_LEDExcitationError.sql")
query = paste(query.charVec,collapse="\n")
excitation.df = sqlQuery(PMScxn,query)

# get seal bar alignment NCRs
query.charVec = readLines("SQL/R_IVOE_SealBarAlignmentNCR.sql")
query = paste(query.charVec,collapse="\n")
sealBarNCR.df = sqlQuery(PMScxn,query)

# get seal bar alignment RMAs
query.charVec = readLines("SQL/R_IVOE_SealBarAlignmentRMA.sql")
query = paste(query.charVec,collapse="\n")
sealBarRMA.df = sqlQuery(PMScxn,query)

# get wire harness NCRs
query.charVec = readLines("SQL/R_IVOE_WireHarnessNCR.sql")
query = paste(query.charVec,collapse="\n")
wireharnessNCR.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)
# THIS IS THE FILE USED TO PULL ALL DATA NEEDED FOR THE RMA DASHBOARD FROM SQL
# Set the environment

# load remote data base connection package
#*note: to set DB paths go to Control Panel/Systems & Security/Administrative Tools/Data Sources (ODBC)
library(RODBC)
# open database connection 
PMScxn = odbcConnect("PMS_PROD")

# get gasket failure RMAs
query.charVec = scan("SQL/R_IVOE_PlungerGasketCreepByPart.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
gasketCreep.df = sqlQuery(PMScxn,query)

# get window bladder failure info by lot (failing at less than 100 run hours)
query.charVec = scan("SQL/R_IVOE_WindowBladderFailureByLot.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
bladderLots.df = sqlQuery(PMScxn,query)

# get lid latch failure RMAs
query.charVec = scan("SQL/R_IVOE_LidFailuresByPart.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
lids.df = sqlQuery(PMScxn,query)

# get number of RMAs shipped
query.charVec = scan("SQL/R_IVOE_RMAsShipped.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
rmaShipped.df = sqlQuery(PMScxn,query)

# get pouches shipped
query.charVec = scan("SQL/R_IVOE_PouchesShippedToCustomers.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
pouches.df = sqlQuery(PMScxn,query)

# # get thermoboard failure RMAs
# query.charVec = scan("SQL/R_IVOE_ThermoboardFailureByLot.txt", what=character(),quote="")
# query = paste(query.charVec,collapse=" ")
# thermoBoard.df = sqlQuery(PMScxn,query)

# get board VoE: Thermoboard
query.charVec = scan("SQL/R_IVOE_Thermoboard.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
board.thermo.df = sqlQuery(PMScxn,query)

# get board VoE: Thermoboard
query.charVec = scan("SQL/R_IVOE_ValveBoard.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
board.valve.df = sqlQuery(PMScxn,query)

# get board VoE: Thermoboard
query.charVec = scan("SQL/R_IVOE_ImageMasterBoard.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
board.image.df = sqlQuery(PMScxn,query)

# get board VoE: Thermoboard
query.charVec = scan("SQL/R_IVOE_CameraBoard.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
board.camera.df = sqlQuery(PMScxn,query)

# get LED excitation failrues by lot
query.charVec = scan("SQL/R_IVOE_LEDExcitationError.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
excitation.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)
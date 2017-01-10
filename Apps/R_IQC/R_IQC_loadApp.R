# load user-created functions
library(RODBC)
#--------------------------------------DATA GRABBING AND UPDATING -------------------------------------#
PMScxn = odbcConnect("PMS_PROD")

queryGrabIQC.charVec = readLines("SQL/R_IQC_App_Overview.sql")
queryGrabIQC = paste(queryGrabIQC.charVec,collapse="\n")
IQC.df = sqlQuery(PMScxn,queryGrabIQC)

close(PMScxn)

# Get the data that is specifically required for the Instrument QC Dashboard Report on Web Hub
IQC.df$thisYear <- ifelse(as.character(IQC.df$Date) >= Sys.Date()-365, 1, 0)
data <- IQC.df[ , c('Year','thisYear','DateGroup','Key','Version','Record','PouchResult','Tm_RNA','Cp_RNA','RNA',
                    'Tm_PCR1','Cp_PCR1','PCR1','Tm_PCR2','Cp_PCR2','PCR2','TmRange_60','60TmRange',
                    'medianDeltaRFU_60','60DFMed','normalizedRangeRFU_60','60DFRoM','Noise_med','Noise')]
rm(IQC.df)
findRunsToKeep <- function(dataFrame, dung.insts) {
  
  # get rid of runs where the minutes run are negative
  bfdx.runs <- dataFrame
  bfdx.runs <- bfdx.runs[bfdx.runs$MinutesRun >= 0, ]
  
  # get rid of validation runs
  validations <- as.character(unique(bfdx.runs[grep('VAL',toupper(bfdx.runs$SampleId)),'PouchSerialNumber']))
  bfdx.runs <- bfdx.runs[!(bfdx.runs$PouchSerialNumber %in% validations), ]
  
  # get rid of RUO pouch runs
  ruo.runs <- bfdx.runs[grep('RUO',bfdx.runs[,'PouchTitle']),'PouchSerialNumber']
  bfdx.runs <- bfdx.runs[!(bfdx.runs[,'PouchSerialNumber'] %in% ruo.runs), ]
  
  # keep only runs that are with a 'Panel' pouch
  bfdx.runs <- bfdx.runs[grep('Panel',bfdx.runs$PouchTitle), ]
  
  # find users that are explicity matched in MAS and outside of the BioChem group
  bfdx.runs$UserID <- toupper(bfdx.runs$UserID)
  users.df$UserID <- toupper(users.df$UserID)
  run.users <- data.frame('UserID' = as.character(unique(bfdx.runs$UserID)))
  commonUsers <- merge(users.df, run.users, by='UserID')
  removeUsers <- commonUsers[!(commonUsers$UserID %in% commonUsers[grep('BioChem', commonUsers$DivisionName),'UserID']), 'UserID']
  bfdx.runs <- bfdx.runs[!(bfdx.runs$UserID %in% removeUsers),]
  
  # isolate pouch qc runs
  runs.pqc <- bfdx.runs[grep('^QC_|PouchQC',bfdx.runs$SampleId), ]
  runs.pqc$Key <- 'QC'
  
  # use the list provided by Shane to get runs from instruments that are in the Dungeon and remove any qc runs that exist in the runs.pqc set
  runs.dngn  <- bfdx.runs[bfdx.runs$InstrumentSerialNumber %in% dung.insts, ] 
  runs.dngn <- runs.dngn[!(runs.dngn$PouchSerialNumber %in% runs.pqc$PouchSerialNumber), ]
  runs.dngn$Key <- 'Dungeon'
  
  # format the frame nicely
  bfdx.runs <- rbind(runs.pqc, runs.dngn)
  bfdx.runs <- bfdx.runs[,c('PouchSerialNumber','Year','Week','InstrumentSerialNumber','Key','ComputerName','PouchTitle','RunStatus','StartTime')]
  bfdx.runs$Record <- 1
  
  # section into panels, drop runs that don't fit nicely
  bfdx.runs[grep('Respiratory Panel',bfdx.runs$PouchTitle),'Panel'] <- 'RP'
  bfdx.runs[grep('BCID Panel',bfdx.runs$PouchTitle),'Panel'] <- 'BCID'
  bfdx.runs[grep('GI Panel',bfdx.runs$PouchTitle),'Panel'] <- 'GI'
  bfdx.runs[grep('ME Panel',bfdx.runs$PouchTitle),'Panel'] <- 'ME'
  # bfdx.runs[grep('LRTI Panel',bfdx.runs$PouchTitle),'Panel'] <- 'LRTI'
  bfdx.runs[grep('BioThreat Panel|BT Panel|BioThreat',bfdx.runs$PouchTitle),'Panel'] <- 'BT'
  bfdx.runs <- bfdx.runs[!(is.na(bfdx.runs$Panel)), ]
  
  # determine the version of the run by using the computer name
  bfdx.runs[grep('TM|HT',bfdx.runs$InstrumentSerialNumber),'Version'] <- 'Torch'
  bfdx.runs[grep('FA2',bfdx.runs$ComputerName),'Version'] <- 'FA 2.0'
  bfdx.runs[grep('FA_QASERVICE_1', bfdx.runs$ComputerName), 'Version'] <- 'FA 2.0'
  bfdx.runs[is.na(bfdx.runs$Version),'Version'] <- 'FA 1.5'
  
  # return a clean frame
  return(bfdx.runs)
}

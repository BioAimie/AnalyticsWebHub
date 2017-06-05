# Checks the last time that charts were generated for each portfolio on the Web Hub. 
# If the charts haven't been refreshed on schedule, this script should generate an email 
# to the data science developers so that the developer can start working on the bug.

library(sendmailR)

#list of items not updated
itemsNotUpdated <- character(0)

#loop through folders
folders <- list.dirs('../images')
for (i in folders) {
  images <- list.files(i)
  
  #loop through images
  for (j in images){
    if (grepl('.png$', j, ignore.case = TRUE)) {
      #grab timestamp on image
      timeUpdated <- file.mtime(paste(i,'/',j, sep=''))
      
      #verify timestamp is within last hour, except IR dashboard, Instrument Calibration, and Trends
      
      if (grepl('Dashboard_InternalReliability', i, ignore.case = TRUE) || grepl('Dashboard_InstrumentCalibration', i, ignore.case = TRUE) || grepl('Dashboard_Trends', i, ignore.case = TRUE)) {
        if (timeUpdated < (Sys.time()-86400)){
          #add to list of items not updated  
          itemsNotUpdated = c(itemsNotUpdated, paste(i,'/',j, sep=''))
        }
        #all other dashboards
      } else if (timeUpdated < (Sys.time()-3600)){
        #add to list of items not updated  
        itemsNotUpdated = c(itemsNotUpdated, paste(i,'/',j, sep=''))
      }
    }
  }
}

#email aimie if list is not empty
if(length(itemsNotUpdated) != 0) {
  emailList <- character(0)
  for(k in itemsNotUpdated){
    emailList <- paste(emailList, k, sep="     ")
  }
  
  from <- "amber.kiser@biofiredx.com"
  to <- c("amber.kiser@biofiredx.com", "Aimie.Faucett@biofiredx.com", "brent.kerby@biofiredx.com")
  subject <- "WebHub Charts Did Not Update"
  body <- paste("Hello, The following WebHub charts did not update on schedule: ", emailList)                     
  mailControl=list(smtpServer="webmail.biofiredx.com")
  
  sendmail(from=from,to=to,subject=subject,msg=body,control=mailControl)
}

rm(list=ls())
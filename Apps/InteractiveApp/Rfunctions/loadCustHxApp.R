setwd('~/WebHub/AnalyticsWebHub/Apps/InteractiveApp')

library(RODBC)
library(shiny)

# Open the connection to PMS1
PMScxn <- odbcConnect("PMS_PROD")

queryText <- readLines("SQL/RMA_History.sql")
query <- paste(queryText,collapse="\n")
CustHx.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/RMA_CustomerNames.sql")
query <- paste(queryText,collapse="\n")
CustNames.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/RMA_MfgDate.sql")
query <- paste(queryText,collapse="\n")
MfgDate.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/RMA_PartNames.sql")
query <- paste(queryText,collapse="\n")
PartNames.df <- sqlQuery(PMScxn,query)

odbcClose(PMScxn)

#Take out beginning and ending spaces and tabs from customer name
CustHx.df[,'Customer Name'] <- gsub('^\t*  *\t*','',as.character(CustHx.df[,'Customer Name']))
CustHx.df[,'Customer Name'] <- gsub('\t*  *\t*$','',as.character(CustHx.df[,'Customer Name']))
#Take out beginning and ending spaces and tabs from customer ID
CustHx.df[,'Customer Id'] <- gsub('^\t*  *\t*','',as.character(CustHx.df[,'Customer Id']))
CustHx.df[,'Customer Id'] <- gsub('\t*  *\t*$','',as.character(CustHx.df[,'Customer Id']))
#Take out beginning and ending spaces and tabs from serial number
CustHx.df[,'Serial Number'] <- gsub('^\t*  *\t*','',as.character(CustHx.df[,'Serial Number']))
CustHx.df[,'Serial Number'] <- gsub('\t*  *\t*$','',as.character(CustHx.df[,'Serial Number']))

CustHx.Names <- merge(CustHx.df, CustNames.df, by.x = 'Customer Id', by.y = 'CustID', all.x = TRUE)

#if customer name is "No Complaint Data", use CustName or Customer Id if CustName is NA
CustHx.Names[,'Customer Name'][as.character(CustHx.Names[,'Customer Name']) == 'No Complaint Data'] <- as.character(CustHx.Names[,'CustName'])[as.character(CustHx.Names[,'Customer Name']) == 'No Complaint Data']
CustHx.Names[,'Customer Name'][is.na(CustHx.Names[,'Customer Name'])] <- as.character(CustHx.Names[,'Customer Id'])[is.na(CustHx.Names[,'Customer Name'])]

#rearrange customer name to line up correctly alphabetically
CustHx.Names[as.character(CustHx.Names[,'Customer Id']) == 'HUNTEC', 'Customer Name'] <- 'Huntington Technology Finance, Inc. (University of Michigan)'

CustHx.Names <- subset(CustHx.Names, select = c('Customer Id', 'Customer Name', 'Date Created', 'Related Complaint', 'RMA', 'Status', 'Serial Number', 'Complaint Failure Mode', 'RMA Type', 'Disposition', 'Early Failure Type', 'Root Cause Part Number', 'Runs Since Last Failure'))

#merge to get Manufacturing date of instrument
CustHx.Names <- merge(CustHx.Names, MfgDate.df, by = 'Serial Number', all.x = TRUE)

#Root Cause Description
CustHx.Names[,'Root Cause Part Name'] <- NA

for(i in 1:length(CustHx.Names[, 'Root Cause Part Number'])) {
  part <- as.character(CustHx.Names[, 'Root Cause Part Number'][i])
  if(is.na(part) | part == '' | part == 'N/A')
    next
  temp <- do.call(cbind, strsplit(part, split=','))
  temp <- merge(temp, PartNames.df, by.x ='V1', by.y =  'PartNumber')
  CustHx.Names[ , 'Root Cause Part Name'][i] <- paste(as.character(temp$Name), collapse=', ')
}

#Links for RMA
CustHx.Names[,'RMA'] <- paste0("<a href='http://trackers.biofiredx.net/GeneralTicket/LoadTicket?TrackerType=RMA&TicketString=RMA-", CustHx.Names[,'RMA'], "' target='_blank'>", CustHx.Names[,'RMA'], "</a>")

#Links for Complaint
CustHx.Names[,'Related Complaint'] <- as.numeric(as.character(CustHx.Names[,'Related Complaint']))
CustHx.Names[,'Related Complaint'] <- ifelse(is.na(CustHx.Names[,'Related Complaint']),
                                                    NA,
                                                    paste0("<a href='http://trackers.biofiredx.net/GeneralTicket/LoadTicket?TrackerType=COMPLAINT&TicketString=COMPLAINT-", CustHx.Names[,'Related Complaint'], "' target='_blank'>", CustHx.Names[,'Related Complaint'], "</a>"))

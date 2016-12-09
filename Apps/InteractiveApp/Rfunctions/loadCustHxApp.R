setwd('~/WebHub/AnalyticsWebHub/Apps/InteractiveApp')

library(RODBC)
library(shiny)

# Open the connection to PMS1
PMScxn <- odbcConnect("PMS_PROD")

queryText <- scan("SQL/RMA_History.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
CustHx.df <- sqlQuery(PMScxn,query)

queryText <- scan("SQL/RMA_CustomerNames.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
CustNames.df <- sqlQuery(PMScxn,query)

queryText <- scan("SQL/RMA_MfgDate.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
MfgDate.df <- sqlQuery(PMScxn,query)

queryText <- scan("SQL/RMA_PartNames.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
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

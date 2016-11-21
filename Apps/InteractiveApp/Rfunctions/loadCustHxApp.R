setwd('~/WebHub/AnalyticsWebHub/Apps/InteractiveApp')

library(RODBC)
library(shiny)

# Open the connection to PMS1
PMScxn <- odbcConnect("PMS_PROD")

queryText <- scan("SQL/RMA_History.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
CustHx.df <- sqlQuery(PMScxn,query)

odbcClose(PMScxn)

#Take out beginning and ending spaces and tabs from customer name
CustHx.df[,'Customer Name'] <- gsub('^\t*  *\t*','',as.character(CustHx.df[,'Customer Name']))
CustHx.df[,'Customer Name'] <- gsub('\t*  *\t*$','',as.character(CustHx.df[,'Customer Name']))

#rearrange customer name to line up correctly alphabetically
CustHx.df[as.character(CustHx.df[,'Customer Id']) == 'HUNTEC', 'Customer Name'] <- 'Huntington Technology Finance, Inc. (University of Michigan)'

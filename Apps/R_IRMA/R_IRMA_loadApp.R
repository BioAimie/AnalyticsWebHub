# THIS IS THE FILE USED TO PULL ALL DATA NEEDED FOR THE RMA DASHBOARD FROM SQL
setwd('~/WebHub/AnalyticsWebHub/')
# load remote data base connection package
#*note: to set DB paths go to Control Panel/Systems & Security/Administrative Tools/Data Sources (ODBC)
library(RODBC)
# open database connection 
#*note: to set DB paths go to Control Panel/Systems & Security/Administrative Tools/Data Sources (ODBC)
PMScxn = odbcConnect("PMS_PROD")

# # run the query to get all distinct RMAs shipped by date
# query.charVec = readLines("SQL/R_IRMA_RMAsShippedByInstrumentVersion.sql")
# query = paste(query.charVec,collapse="\n")
# rmasShipped.df = sqlQuery(PMScxn,query)
# 
# # run the query to find all the parts replaced as recorded in the RMA tracker
# query.charVec = readLines("SQL/R_IRMA_PartsUsedExcludingPreventativeMaintenance.sql")
# query = paste(query.charVec,collapse="\n")
# partsReplaced.df = sqlQuery(PMScxn,query)
# 
# # run the query to get the service codes recorded in RMA tracker
# query.charVec = readLines("SQL/R_IRMA_ServiceCodes.sql")
# query = paste(query.charVec,collapse="\n")
# serviceCodes.df = sqlQuery(PMScxn,query)
#
# # run the query to get a calendar with all year, month, week since 2012-01-01
# query.charVec = readLines("SQL/Calendar.sql")
# query = paste(query.charVec,collapse="\n")
# calendar.df = sqlQuery(PMScxn,query)

# run the query to get root cause data
query.charVec = readLines("SQL/R_IRMA_rootCause.sql")
query = paste(query.charVec,collapse="\n")
rootCause.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)

# load in neccessary functions
# library(zoo)
# source('Rfunctions/makeDateGroupAndFillGaps.R')
# source('Rfunctions/computeRollingRateAndAddStats.R')
# source('Rfunctions/findStartDate.R')
library(dateManip)

# # set a few variables
# calendar.df <- createCalendarLikeMicrosoft(2014, 'Week')
# startDate <- findStartDate(calendar.df, 'Week', length(unique(calendar.df[calendar.df$Year > 2014, 'DateGroup'])), 4)
# 
# # do work by using the functions above applied to the correct data frames
# rmasShipped.df <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', rmasShipped.df, c('Version','Key'), startDate, 'Record', 'sum', 0)
# codes.df <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', serviceCodes.df, c('Version','Key'), startDate, 'Record', 'sum', 0)
# parts.df <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', partsReplaced.df, c('Version','Key'), startDate, 'Record', 'sum', 0)
# 
# partsReplaced.mrg <- mergeCalSparseFrames(parts.df, rmasShipped.df, c('DateGroup','Version'), c('DateGroup','Version'), 'Record', 'Record', NA, 4)
# serviceCodes.mrg <- mergeCalSparseFrames(codes.df, rmasShipped.df, c('DateGroup','Version'), c('DateGroup','Version'), 'Record', 'Record', NA, 4)
# 
# rmasShipped.df <- makeDateGroupAndFillGaps(calendar.df, rmasShipped.df, bigGroup, smallGroup, c('Key'), startDate)
# codes.df <- makeDateGroupAndFillGaps(calendar.df, serviceCodes.df, bigGroup, smallGroup, c('Key'), startDate)
# parts.df <- makeDateGroupAndFillGaps(calendar.df, partsReplaced.df, bigGroup, smallGroup, c('Key'), startDate)
# partsReplaced.mrg <- computeRollingRateAndAddStats(rmasShipped.df, parts.df, c('DateGroup','Key'), c('DateGroup','Key'), c('DateGroup'), periods, lag, startDate)
# serviceCodes.mrg <- computeRollingRateAndAddStats(rmasShipped.df, codes.df, c('DateGroup','Key'), c('DateGroup','Key'), c('DateGroup'), periods, lag, startDate)

# the failed part is very long and it ruins the chart labels, so try to clean them up
rootCause.df$FailCat <- sapply(1:nrow(rootCause.df), function(x) ifelse(regexpr(' \\- ', as.character(rootCause.df[x, 'FailCat'])) < 0, as.character(rootCause.df[x, 'FailCat']), substring(as.character(rootCause.df[x, 'FailCat']), 1, regexpr(' \\- ', as.character(rootCause.df[x, 'FailCat']))-1)))

# clear up some memory
# rm(serviceCodes.df, codes.df, partsReplaced.df, parts.df, rmasShipped.df, calendar.df)
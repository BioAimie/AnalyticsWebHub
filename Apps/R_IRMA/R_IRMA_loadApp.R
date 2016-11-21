# THIS IS THE FILE USED TO PULL ALL DATA NEEDED FOR THE RMA DASHBOARD FROM SQL
setwd('~/WebHub/AnalyticsWebHub/')
# load remote data base connection package
#*note: to set DB paths go to Control Panel/Systems & Security/Administrative Tools/Data Sources (ODBC)
library(RODBC)
# open database connection 
#*note: to set DB paths go to Control Panel/Systems & Security/Administrative Tools/Data Sources (ODBC)
PMScxn = odbcConnect("PMS_PROD")

# run the query to get all distinct RMAs shipped by date
query.charVec = scan("SQL/R_IRMA_RMAsShippedByInstrumentVersion.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
rmasShipped.df = sqlQuery(PMScxn,query)

# run the query to find all the parts replaced as recorded in the RMA tracker
query.charVec = scan("SQL/R_IRMA_PartsUsedExcludingPreventativeMaintenance.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
partsReplaced.df = sqlQuery(PMScxn,query)

# run the query to get the service codes recorded in RMA tracker
query.charVec = scan("SQL/R_IRMA_ServiceCodes.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
serviceCodes.df = sqlQuery(PMScxn,query)

# run the query to get a calendar with all year, month, week since 2012-01-01
query.charVec = scan("SQL/Calendar.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
calendar.df = sqlQuery(PMScxn,query)

# run the query to get root cause data
query.charVec = scan("SQL/R_IRMA_rootCause.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
rootCause.df = sqlQuery(PMScxn,query)

# close remote connection
close(PMScxn)

# load in neccessary functions
library(zoo)
source('Rfunctions/makeDateGroupAndFillGaps.R')
source('Rfunctions/computeRollingRateAndAddStats.R')
source('Rfunctions/findStartDate.R')

# set a few variables
bigGroup <- 'Year'
smallGroup <- 'Week'
periods <- 4
lagPeriods <- 4
lag <-calendar.df[length(calendar.df[,1])-lagPeriods, ]
lag <- with(lag, ifelse(lag[,smallGroup] < 10, paste(lag[,bigGroup], lag[,smallGroup], sep='-0'), paste(lag[,bigGroup], lag[,smallGroup], sep='-')))
startDate <- findStartDate(calendar.df, bigGroup, smallGroup, 'OneYear')

# do work by using the functions above applied to the correct data frames
rmasShipped.df <- makeDateGroupAndFillGaps(calendar.df, rmasShipped.df, bigGroup, smallGroup, c('Key'), startDate)
codes.df <- makeDateGroupAndFillGaps(calendar.df, serviceCodes.df, bigGroup, smallGroup, c('Key'), startDate)
parts.df <- makeDateGroupAndFillGaps(calendar.df, partsReplaced.df, bigGroup, smallGroup, c('Key'), startDate)
partsReplaced.mrg <- computeRollingRateAndAddStats(rmasShipped.df, parts.df, c('DateGroup','Key'), c('DateGroup','Key'), c('DateGroup'), periods, lag, startDate)
serviceCodes.mrg <- computeRollingRateAndAddStats(rmasShipped.df, codes.df, c('DateGroup','Key'), c('DateGroup','Key'), c('DateGroup'), periods, lag, startDate)

# clear up some memory
rm(bigGroup, smallGroup, periods, lagPeriods, lag, startDate, serviceCodes.df, codes.df, partsReplaced.df, parts.df, rmasShipped.df, calendar.df)
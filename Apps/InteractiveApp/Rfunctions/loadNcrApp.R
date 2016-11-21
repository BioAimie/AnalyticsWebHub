setwd('~/WebHub/AnalyticsWebHub/Apps/InteractiveApp')

library(RODBC)
library(dateManip)
library(rCharts)
library(ggplot2)
library(shiny)
library(scales)

# Open the connection to PMS1
PMScxn <- odbcConnect("PMS_PROD")

queryText <- scan("SQL/NCR_parts.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
NCRParts.df <- sqlQuery(PMScxn,query)

queryText <- scan("SQL/NCR_FailSubFail.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
NCRFail.df <- sqlQuery(PMScxn,query)

queryText <- scan("SQL/NCR_WhereProblem.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
NCRWhereProblem.df <- sqlQuery(PMScxn,query)

odbcClose(PMScxn)

source('Rfunctions/makeDataTable.R')
source('Rfunctions/makeRChartDataSet.R')

calendar.month <- createCalendarLikeMicrosoft(2007, 'Month')
calendar.week <- createCalendarLikeMicrosoft(2007, 'Week')
calendar.quarter <- createCalendarLikeMicrosoft(2007, 'Quarter')

#clean up the dataSet
#NCR parts affected
colnames(NCRParts.df)[colnames(NCRParts.df) == 'Qty'] <- 'Record'
NCRParts.week <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', NCRParts.df, c('PartAffected', 'Type'), '2015-26', 'Record', 'sum', 0)
NCRParts.month <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', NCRParts.df, c('PartAffected', 'Type'), '2015-06', 'Record', 'sum', 0)
NCRParts.quarter <- aggregateAndFillDateGroupGaps(calendar.quarter, 'Quarter', NCRParts.df, c('PartAffected', 'Type'), '2015-02', 'Record', 'sum', 0)

#NCR Where Found/Problem Area
colnames(NCRWhereProblem.df)[colnames(NCRWhereProblem.df) == 'Qty'] <- 'Record'
NCRWhereProblem.df$ProblemArea <- gsub(',','-',NCRWhereProblem.df$ProblemArea)
NCRWhereProblem.week <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', NCRWhereProblem.df, c('WhereFound', 'ProblemArea', 'Type'), '2012-30','Record', 'sum', 0)
NCRWhereProblem.month <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', NCRWhereProblem.df, c('WhereFound', 'ProblemArea', 'Type'), '2012-07','Record', 'sum', 0)
NCRWhereProblem.quarter <- aggregateAndFillDateGroupGaps(calendar.quarter, 'Quarter', NCRWhereProblem.df, c('WhereFound', 'ProblemArea', 'Type'), '2012-03','Record', 'sum', 0)

#NCR Fail/Sub-Fail categories
colnames(NCRFail.df)[colnames(NCRFail.df) == 'Qty'] <- 'Record'
NCRFail.df$FailureCategory <- gsub(',','-',NCRFail.df$FailureCategory)
NCRFail.df$SubFailureCategory <- gsub(',','-',NCRFail.df$SubFailureCategory)
NCRFail.df$ProblemArea <- gsub(',','-',NCRFail.df$ProblemArea)
NCRFail.df$FailureCategory[is.na(NCRFail.df$FailureCategory)] <- 'None'
NCRFail.df$SubFailureCategory[is.na(NCRFail.df$SubFailureCategory)] <- 'None'
NCRFail.week <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', NCRFail.df, c('WhereFound','ProblemArea','FailureCategory', 'SubFailureCategory', 'Type'), '2012-30', 'Record', 'sum', 0)
NCRFail.month <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', NCRFail.df, c('WhereFound','ProblemArea','FailureCategory', 'SubFailureCategory', 'Type'), '2012-07', 'Record', 'sum', 0)
NCRFail.quarter <- aggregateAndFillDateGroupGaps(calendar.quarter, 'Quarter', NCRFail.df, c('WhereFound','ProblemArea','FailureCategory', 'SubFailureCategory', 'Type'), '2012-03', 'Record', 'sum', 0) 

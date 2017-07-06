#Load in data for Pouch SPC app
setwd('~/WebHub/AnalyticsWebHub/Apps/R_PSPC/PSPCApp')

library(RODBC)
library(dateManip)
library(ggplot2)
library(scales)

PMScxn <- odbcConnect("PMS_PROD")

queryText <- readLines("SQL/SummaryAnomalyTable.sql")
query <- paste(queryText,collapse="\n")
summary.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/AllQCRuns.sql")
query <- paste(queryText,collapse="\n")
allruns.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/AllRunObservations.sql")
query <- paste(queryText,collapse="\n")
runobs.df <- sqlQuery(PMScxn,query)

queryText <- readLines("SQL/InstrumentVersions.sql")
query <- paste(queryText,collapse="\n")
instversion.df <- sqlQuery(PMScxn,query)

odbcClose(PMScxn)

expouchserials <- read.csv('C:/Users/pms_user/Documents/WebHub/PouchSPCExclude.csv')

source('createPaletteOfVariableLength.R')

calendar.month <- createCalendarLikeMicrosoft(2011, 'Month')

allruns.df <- merge(allruns.df, instversion.df, all.x=TRUE, by.x='InstrumentSerialNumber', by.y='SerialNo')
allruns.df$Version[allruns.df$InstrumentSerialNumber %in% c('AFA07','FA2000','FA2001','FA2002','FA2003','FA2004')] <- 'FA 1.5'

#exclude all "X-not curated due to instrument error/other" runs
allruns.df <-subset(allruns.df, is.na(RunObservation) | RunObservation != 'X-Not curated due to instrument error/other') 
runobs.df <- subset(runobs.df, RunObservation != 'X-Not curated due to instrument error/other')

colVector <- c("#6445A5","#DC7F6D","#A9EA3E","#B2EABB","#E3CB7B","#9F506F","#E9BECB","#E43C8C","#9CE99A","#ABC7E8","#E693AB","#E2E1EA",
               "#93B274","#D234ED","#B254DF","#E8D5C4","#5AA8DF","#60AE4B","#E174B4","#E845B7","#E3EAB9","#658CDF","#E36782","#6077E6","#68EA7A","#B693B9",
               "#772CE8","#E6B33C","#6751E1","#E64154","#A8B344","#E375E4","#E39F60","#63EB47","#BB9DEA","#EAADE3","#ADDDE6","#55E7A3","#617962","#A3ECDE",
               "#AD7DE8","#E5AC99","#D7EA98","#B6EA73","#5CB797","#E646DD","#AA459D","#E2E63E","#E2C698","#A2864E","#5E6A89","#8C6AA7","#D9EFDE","#A5BDA6",
               "#64CEEA","#5EE4E5","#9EAAE4","#E56D36","#68ECCA","#E8E671","#A7A9B2","#AA8580","#60A6B0","#9EB478","#C4ED3F","#B389E5","#C1EE71","#5EAA59",
               "#E6C4C0","#9D4972","#5D88E3","#E8C4E5","#5BE6AA","#E9A4E4","#E4C39A","#E2DFEA","#899ADC","#9DE8E1","#AA8482","#E49C61","#615092","#67ECCE",
               "#E580E7","#5AE4E5","#E33F97","#E6435D","#627A63","#5E6E8A","#E4AE3C","#59E88A","#A97FAF","#81EE39","#D4EB96","#D17061","#C8ADEA","#9EEB8B",
               "#AABDA9","#E2E7B1","#716DE0","#63B798","#E64ACD","#E6DF3B","#E59DB7","#664AD8","#E177BC","#5CAAE0","#A44BA9","#E4CA7B","#802DE8","#DB3AEA",
               "#79C846","#B2BFEA","#E9E470","#A8D3E7","#CFECE7","#61CDE9","#EBE8D1","#E86B36","#E47391","#B85DE4","#61EE66","#A9A5B6","#BDEDC8","#E8A192",
               "#A2854F","#A1E7AA","#A7B246","#62A6AF")


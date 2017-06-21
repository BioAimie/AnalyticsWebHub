# set the working directory
setwd('~/WebHub/AnalyticsWebHub/Apps/R_IRMA/')
source('R_IRMA_loadApp.R')
library(shiny)
runApp(appDir = 'Apps/R_IRMA/', port = 4034,
       launch.browser = getOption('shiny.launch.browser', interactive()), host = getOption('shiny.host', '172.26.28.96'))
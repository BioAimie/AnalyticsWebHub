# set the working directory
setwd('~/WebHub/AnalyticsWebHub/')
source('Apps/R_IQC/R_IQC_loadApp.R')
library(shiny)
runApp(appDir = 'Apps/R_IQC/', port = 4030, 
       launch.browser = getOption('shiny.launch.browser', interactive()), host = getOption('shiny.host', '10.1.23.96'))
# set the working directory
setwd('~/WebHub/AnalyticsWebHub/')
source('Apps/R_INCR/R_INCR_loadApp.R')
library(shiny)
runApp('Apps/R_INCR/', port = 4048,
       launch.browser = getOption('shiny.launch.browser', interactive()), host = getOption('shiny.host', '10.1.23.96'))
# set the working directory
setwd('~/WebHub/AnalyticsWebHub/')
source('Apps/O_SUPP/O_SUPP_loadApp.R')
library(shiny)
runApp('Apps/O_SUPP/', port = 4052,
       launch.browser = getOption('shiny.launch.browser', interactive()), host = getOption('shiny.host', '10.1.23.96'))
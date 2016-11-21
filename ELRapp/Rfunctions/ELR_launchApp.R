# set the working directory
setwd('~/WebHub/AnalyticsWebHub/ELRapp')
source('Rfunctions/ELR_loadApp.R')
library(shiny)
runApp('app', port = 4028,
       launch.browser = getOption('shiny.launch.browser', interactive()), host = getOption('shiny.host', '10.1.23.96'))
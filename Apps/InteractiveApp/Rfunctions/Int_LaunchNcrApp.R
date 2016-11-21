# set the working directory
setwd('~/WebHub/AnalyticsWebHub/Apps/InteractiveApp')
source('Rfunctions/loadNcrApp.R')
library(shiny)
runApp('NcrApp', port = 4030,
       launch.browser = getOption('shiny.launch.browser', interactive()), host = getOption('shiny.host', '10.1.23.96'))
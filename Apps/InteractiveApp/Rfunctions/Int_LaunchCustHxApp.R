# set the working directory
setwd('~/WebHub/AnalyticsWebHub/Apps/InteractiveApp')
source('Rfunctions/loadCustHxApp.R')
library(shiny)
runApp('CustHxApp', port = 4032,
       launch.browser = getOption('shiny.launch.browser', interactive()), host = getOption('shiny.host', '10.1.23.96'))
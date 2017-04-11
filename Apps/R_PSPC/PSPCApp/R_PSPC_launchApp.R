# set the working directory
setwd('~/WebHub/AnalyticsWebHub/Apps/R_PSPC/PSPCApp')
source('main.R')
library(shiny)

runApp(port = 3030,
       launch.browser = getOption('shiny.launch.browser', interactive()), host = getOption('shiny.host', '10.1.23.96'))
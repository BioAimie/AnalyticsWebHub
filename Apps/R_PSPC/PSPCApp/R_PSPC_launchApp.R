# set the working directory
setwd('~/WebHub/AnalyticsWebHub')
source('Apps/R_PSPC/PSPCApp/main.R')
library(shiny)
runApp('Apps/R_PSPC/PSPCApp/', port = 4040,
       launch.browser = getOption('shiny.launch.browser', interactive()), host = getOption('shiny.host', '10.1.23.96'))
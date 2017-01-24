

library(shiny)

# set the working directory 
setwd('~/WebHub/AnalyticsWebHub/Apps/InteractiveApp')

# load in the data to be displayed
source("Rfunctions\\loadInternalInstrumentApp.R")

# launch the app
runApp('internalInstrumentApp', port = 4038,
       launch.browser = getOption('shiny.launch.browser', interactive()), host = getOption('shiny.host', '10.1.23.96'))

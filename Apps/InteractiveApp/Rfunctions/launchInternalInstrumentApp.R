

library(shiny)

# set the working directory 
setwd('~/WebHub/AnalyticsWebHub/Apps/InteractiveApp')

# remove all the plots from the www/ folder 
file.remove(list.files("\\\\biofirestation/WebHub/WebHub/new_tab_charts/", full.names=TRUE)[which(grepl(".jpg", list.files("\\\\biofirestation/WebHub/WebHub/new_tab_charts/")))])


# load in the data to be displayed
source("Rfunctions\\loadInternalInstrumentApp.R")

# launch the app
runApp('internalInstrumentApp', port = 4038,
       launch.browser = getOption('shiny.launch.browser', interactive()), host = getOption('shiny.host', '10.1.23.96'))

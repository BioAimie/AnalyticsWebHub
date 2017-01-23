

library(shiny)

# set the working directory 
setwd('~/WebHub/AnalyticsWebHub/Apps/InteractiveApp')

# remove all the plots from the www/ folder 
file.remove(list.files("internalInstrumentApp\\www", full.names=TRUE)[which(grepl(".jpg", list.files("internalInstrumentApp\\www")))])


# load in the data to be displayed
source("Rfunctions\\loadInternalInstrumentApp.R")

# launch the app
runApp('internalInstrumentApp', port = 4032,
       launch.browser = getOption('shiny.launch.browser', interactive()), host = getOption('shiny.host', '127.0.0.1'))

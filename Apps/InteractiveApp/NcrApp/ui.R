library(shiny)
library(shinyBS)
library(rCharts)

shinyUI( 
  navbarPage('NCR Interactive App:', 
                    tabPanel('Count Trend Charts',
                             h3('Data Sets'),
                             tags$div(class='DataSets',
                              list(
                                img(id = 'NCRFail', src = "dfNCRFail.png", class = 'dataSetpic', height = 60, width = 150, draggable = 'true', ondragstart = 'drag(event)'),
                                bsTooltip(id = 'NCRFail', title = 'Failure and SubFailure Categories by Where Found and Problem Area', trigger = 'hover'),
                                img(id = 'NCRParts', src = "dfNCRParts.png", class = 'dataSetpic', height = 60, width = 150, draggable = 'true', ondragstart = 'drag(event)'),
                                bsTooltip(id = 'NCRParts', title = 'Part Affected from the Investigation section of each NCR partitioned by NCR Type. Count is based on the quantity of parts affected.', trigger = 'hover'),
                                img(id = 'NCRWhere', src = "dfNCRWhereProblem.png", class = 'dataSetpic', height = 60, width = 150, draggable = 'true', ondragstart = 'drag(event)'),
                                bsTooltip(id = 'NCRWhere', title = 'Where Found from the Reporting section and Problem Area from the Investigation section of each NCR partitioned by NCR Type', trigger = 'hover')
                              ) #end list
                             ), #end div datasets
                             h4('Data set used: '),
                             tags$div(id = 'options',
                               tags$div(id = 'dropData1', ondragover = 'dragOver(event)', ondrop = 'dropData(event)',
                                 img(src = "dropData.png", height = 60, width = 150)
                               ), #end div dropData1
                               dateRangeInput('dateRange', label = 'Date Range:', start = Sys.Date() -365, end = Sys.Date()),
                               radioButtons('chartType', label = 'Chart Type:', choices = c('Bar', 'Line', 'Area'), selected = 'Bar'),
                               radioButtons('dateType', label = 'Date Format:', choices = c('Year-Week', 'Year-Month', 'Year-Quarter'), selected = 'Year-Week')
                             ), #end div Options
                             tags$div(id = 'xfilters',
                               uiOutput('filters')
                             ), #end div xfilters
                             downloadButton('dataTableDownload', 'Download Data Table'),
                             showOutput('chartArea', 'nvd3')
                    ), #end tabPanel
                    tabPanel('Rate Trend Charts',
                             h3('Under Development')
                    ), #end tabPanel 
                    tabPanel('Count Pareto Charts',
                             h3('Under Development')
                    ), #end tabPanel 
             tags$head(tags$script(src="getdata.js"),
                       tags$link(rel = "stylesheet", type = "text/css", href = "mainApp.css"))
  ) # end navbarPage
) #end shinyUI
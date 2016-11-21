library(shiny)
library(shinyBS)
library(DT)

shinyUI( 
  navbarPage('Customer History', 
                    tabPanel('Customer History Tracker',
                             h3('Data Sets'),
                             tags$div(class='DataSets',
                              list(
                                img(id = 'RMAComplaintHx', src = 'dfRMAComplaintHx.png', class = 'dataSetpic', height = 60, width = 150, draggable = 'true', ondragstart = 'drag(event)'),
                                bsTooltip(id = 'RMAComplaintHx', title = 'RMA and related Complaint History by Customer', trigger = 'hover')
                              ) #end list
                             ), #end div datasets
                             tags$div(class='headers', 
                               h4('Data set used:')
                               # ,
                               # h4('Customer Name:')
                             ),
                             tags$div(id = 'options',
                               tags$div(id = 'dropData1', ondragover = 'dragOver(event)', ondrop = 'dropData(event)',
                                 img(src = "dropData.png", height = 60, width = 150)
                               ), #end div dropData1
                               uiOutput('Filters')
                             ), #end div Options
                             dataTableOutput('dataTable'),
                             downloadButton('dataTableDownload', 'Download Data Table')
                    ), #end tabPanel
             tags$head(tags$script(src="getdata.js"),
                       tags$link(rel = "stylesheet", type = "text/css", href = "mainApp.css"))
  ) # end navbarPage
) #end shinyUI
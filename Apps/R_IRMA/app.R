# set the working directory
setwd('~/WebHub/AnalyticsWebHub/Apps/R_IRMA/')

# load necessary libraries
library(shiny)
library(shinydashboard)
library(zoo)
library(ggplot2)

# source the data and functions necessary to create the dashboard
source('R_IRMA_getCodeFromDescrip.R')
source('R_IRMA_makeCodeChart.R')
source('R_IRMA_getPartNumber.R')
source('R_IRMA_makePartChart.R')
source('R_IRMA_subsetBasedOnTimeFrame.R')
source('R_IRMA_getMagnificationCategories.R')
source('R_IRMA_itemsInPareto.R')
source('R_IRMA_makeRootCausePareto.R')

# ui to layout user interface
ui <- dashboardPage(skin = 'red',
                    
                    dashboardHeader(title = 'PostMarket Trending'),
                    
                    # Sidebar content
                    dashboardSidebar(
                      sidebarMenu(
                        menuItem('Service Code Usage', tabName = 'servCodes', icon = icon('cube')),
                        menuItem('Part Replacement Rates', tabName = 'partRep', icon = icon('cube')),
                        menuItem('Root Cause Paretos', tabName = 'rootCause', icon = icon('cube'))
                      )
                    ),
                    
                    dashboardBody(
                      tabItems(
                        # First tab content
                        tabItem(tabName = 'servCodes',
                                fluidRow(
                                  box(
                                    title = 'Input Parameters', width = 3,
                                    selectInput('servCodeArea',
                                                label = 'Instrument Area:',
                                                choices = c('General Mechanical','Manifold','Optics','Peltier','Plunger Block', 'Window Bladder'),
                                                selected = 'General Mechanical'
                                    ),
                                    uiOutput('servCodeSelector'),
                                    selectInput('servCodeDate',
                                                label = 'Select Date Range to View:',
                                                choices = c('2015','52 weeks'),
                                                selected = '52 weeks'
                                    ),
                                    downloadButton('downloadCodeChart','Download a Copy')
                                  ),
                                  box( 
                                    width = 9,
                                    plotOutput('codeChart', height = 600)
                                  )
                                )  
                        ),
                        
                        # Second tab content
                        tabItem(tabName = 'partRep',
                                fluidRow(
                                  box(
                                    title = 'Input Parameters', width = 3,
                                    selectInput('partRepArea',
                                                label = 'Instrument Area:',
                                                choices = c('Manifold','Optics','Peltier','Plunger Block', 'Window Bladder'),
                                                selected = 'Manifold'
                                                ),
                                    uiOutput('partRepSelector'),
                                    selectInput('partRepDate',
                                                label = 'Select Date Range to View:',
                                                choices = c('2015','52 weeks'),
                                                selected = '52 weeks'
                                                ),
                                    downloadButton('downloadPartChart','Download a Copy')
                                    ),
                                  box(
                                    width = 9,
                                    plotOutput('partChart', height = 600)
                                    )
                                )
                        ),
                        
                        # Third tab content
                        tabItem(tabName = 'rootCause',
                                fluidRow(
                                  box(
                                    title = 'Input Parameters', width = 3,
                                    selectInput('timeFrame',
                                                label = 'Time Frame:',
                                                choices = c('This Year','This Month','This Quarter','Last 90 Days','Last 30 Days','52 Weeks'),
                                                selected = 'This Year'
                                    ),
                                    checkboxInput('earlyFail',
                                                  label = 'Show Early Failures Only?',
                                                  value = FALSE
                                    ),
                                    selectInput('rootCauseTopLevel',
                                                label = 'Root Cause Top Level:',
                                                choices = c('Where Found','Problem Area','Failed Part','Suspected Failure Mode'),
                                                selected = 'Where Found'
                                    ),
                                    checkboxInput('drillDown', 
                                                  label = 'Drill Down?',
                                                  value = TRUE
                                    ),
                                    uiOutput('drillCategorySelector'),
                                    uiOutput('rootCauseLowLevelSelector'),
                                    downloadButton('downloadRootCausePareto','Download a Copy')
                                  ),
                                  box( 
                                    width = 9,
                                    plotOutput('rootCausePareto', height = 600)
                                  )
                                )
                        )
                      )
                    )
)

# workhorse to produce content    
server <- (function(input, output) {
  # dynamic selector for service codes
  output$servCodeSelector <- renderUI ({
    switch(input$servCodeArea,
           'General Mechanical' = selectInput('servCode', 
                                              label = 'Code of Interest:',
                                              choices = c('0 - Unable to Reproduce','2 - Customer Abuse/Tampering','3 - Loaner Return','4 - Loose Screw','5 - Communication Error (unable to reproduce)','9 - Pinched/Kinked Hose',
                                                          '10 - Damaged During Shipping','11 - Wire Hareness Disconnected','12 - Fan Inoperable','13 - PM Performed','14 - Defective Wire Harness','17 - Noisy Fan Operation','18 - Wire Harness in Wrong Location'),
                                              selected = '0 - Unable to Reproduce'
           ),
           'Manifold' = selectInput('servCode', 
                                    label = 'Code of Interest:',
                                    choices = c('100 - Hard Seal Gasket Leak','103 - Molded Bladder Leak','109 - Dirty/Damaged Component Affecting Optics','110 - Valve Faulty','115 - General Manifold Failure'),
                                    selected = '100 - Hard Seal Gasket Leak'
           ),
           'Peltier' = selectInput('servCode', 
                                   label = 'Code of Interest:',
                                   choices = c('503 - PCR1 Calibration','504 - PCR2 Calibration','507 - Peltier Delamination','509 - General Peltier Failure'),
                                   selected = '503 - PCR1 Calibration'
           ),
           'Plunger Block' = selectInput('servCode', 
                                         label = 'Code of Interest:',
                                         choices = c('110 - Faulty Valve','203 - Plunger Block Leak (non-valve)','204 - Gasket Creep Affecting Plunge','205 - Plunger Corrosion Affecting Plunge','207 - General Plunger Block Failure'),
                                         selected = '110 - Faulty Valve'
           ),
           'Optics' = selectInput('servCode', 
                                  label = 'Code of Interest:',
                                  choices = c('600 - LED Failure','601 - Photodiode Board Failure','602 - Alignment Needed','604 - Calibration Needed','605 - Defective 1.5 Camera','607 - Defective 2.0 Camera','52 - Window Bladder Affecting Optics','109 - Dity/Damaged Component Affecting Optics'),
                                  selected = '600 - LED Failure'
           ),
           'Window Bladder' = selectInput('servCode', 
                                          label = 'Code of Interest:',
                                          choices = c('51 - Delamination (no leak)','52 - Affecting Optics','53 - Leak'),
                                          selected = '51 - Delamination (no leak)'
           )
    )  
  })
  
  # dynamic selector for parts replaced
  output$partRepSelector <- renderUI ({
    switch(input$partRepArea,
           'Manifold' = selectInput('partRep', 
                                    label = 'Part of Interest:', 
                                    choices = c('FLM1-GAS-0015: Urethane Hard Seal Sheet','FLM1-MOD-0014: Manifold Hard Seal Gasket','FLM1-MOL-0023: Molded Bladder','WIRE-HAR-0554: Crimped Individual Valve'), 
                                    selected = 'FLM1-GAS-0015: Urethane Hard Seal Sheet'
                                    ),
           'Peltier' = selectInput('partRep',
                                   label = 'Part of Interest:',
                                   choices = c('FLM1-SUB-0029: Peltier Subassembly'),
                                   selected = 'FLM1-SUB-0029: Peltier Subassembly'
                                   ),
           'Plunger Block' = selectInput('partRep',
                                         label = 'Part of Interest:',
                                         choices = c('FLM1-GAS-0006: End Plate Gasket','FLM1-GAS-0009: Manifold Gasket','FLM1-MAC-0285: Sample Plunger','WIRE-HAR-0554: Crimped Individual Valve'),
                                         selected = 'FLM1-GAS-0006: End Plate Gasket'
                                         ),
           'Optics' = selectInput('partRep',
                                  label = 'Part of Interest:',
                                  choices = c('WIRE-HAR-0211: 1.5 LED','PCBA-SUB-0856: 2.0 LED'),
                                  selected = 'WIRE-HAR-0211: 1.5 LED'
                                  ),
           'Window Bladder' = selectInput('partRep',
                                          label = 'Part of Interest:',
                                          choices = c('FLM1-SUB-0044: Window Bladder'),
                                          selected = 'FLM1-SUB-0044: Window Bladder'
                                          )
    )
  })
  
  # dynamic selector for drill down - rootCauseDrillCategory
  output$drillCategorySelector <- renderUI ({
    if(input$drillDown) {
      switch(input$rootCauseTopLevel,
             'Where Found' = selectInput('rootCauseDrillCategory',
                                         label = 'Magnify which Category?',
                                         choices = getMagnificationCategories('Where Found',input$timeFrame,0.8),
                                         selected = getMagnificationCategories('Where Found',input$timeFrame,0.8)[1]
             ),
             'Problem Area' = selectInput('rootCauseDrillCategory',
                                          label = 'Magnify which Category?',
                                          choices = getMagnificationCategories('Problem Area',input$timeFrame,0.8),
                                          selected = getMagnificationCategories('Problem Area',input$timeFrame,0.8)[1]
             ),
             'Failed Part' = selectInput('rootCauseDrillCategory',
                                         label = 'Magnify which Category?',
                                         choices = getMagnificationCategories('Failed Part',input$timeFrame,0.8),
                                         selected = getMagnificationCategories('Failed Part',input$timeFrame,0.8)[1]
             )
      )
    }
  })
  
  # dynamic selector for drill down - rootCauseLowLevel
  output$rootCauseLowLevelSelector <- renderUI ({
    if(input$drillDown) {
      switch(input$rootCauseTopLevel,
             'Where Found' = selectInput('rootCauseLowLevel',
                                         label = 'Level to View?',
                                         choices = c('Problem Area','Failed Part','Suspected Failure Mode'),
                                         selected = 'Problem Area'
             ),
             'Problem Area' = selectInput('rootCauseLowLevel',
                                          label = 'Level to View?',
                                          choices = c('Failed Part','Suspected Failure Mode'),
                                          selected = 'Failed Part'
             ),
             'Failed Part' = selectInput('rootCauseLowLevel',
                                         label = 'Level to View?',
                                         choices = c('Suspected Failure Mode'),
                                         selected = 'Suspected Failure Mode'
             ),
             'Suspected Failure Mode' = selectInput('rootCauseLowLevel',
                                                    label = 'Level to View?',
                                                    choices = c('N/A'),
                                                    selected = 'N/A'
             )
      )
    }
    else {selectInput('rootCauseLowLevel', label='Level to View?', choices=c('N/A'), selected='N/A')}
  })
  
  # make service Codes chart
  output$codeChart <- renderPlot ({
    makeCodeChart(serviceCodes.mrg, input$servCodeDate, input$servCode)
  })
  
  # make part Replacement chart
  output$partChart <- renderPlot ({
    makePartChart(partsReplaced.mrg, input$partRepDate, input$partRep)
  })
  
  # make root cause paretos
  output$rootCausePareto <- renderPlot ({
    if(input$drillDown == TRUE & input$rootCauseTopLevel == 'Suspected Failure Mode') {
      makeRootCausePareto(input$rootCauseTopLevel, input$rootCauseLowLevel, input$rootCauseTopLevel, input$timeFrame, input$earlyFail)
    }
    else if (input$drillDown) {
      makeRootCausePareto(input$rootCauseTopLevel, input$rootCauseDrillCategory, input$rootCauseLowLevel, input$timeFrame, input$earlyFail)
    }
    else {
      makeRootCausePareto(input$rootCauseTopLevel, input$rootCauseLowLevel, input$rootCauseTopLevel, input$timeFrame, input$earlyFail)
    }
  })
  
  # handle download of Codes chart
  plotInputCode <- reactive({
    makeCodeChart(serviceCodes.mrg, input$servCodeDate, input$servCode)
  })
  output$downloadCodeChart <- downloadHandler(
    filename = function() {
      paste('code_',getCodeFromDescrip(input$servCode),'_',Sys.Date(),'.png',sep='')
    },
    content = function(file) {
      png(file, height=600, width=800)
      print(
        print(plotInputCode())
        #         makeCodeChart(serviceCodes.mrg, input$servCodeDate, input$servCode)
      )
      dev.off()
    }
  )
  
  # handle download of Parts chart
  plotInputPart <- reactive({
    makePartChart(partsReplaced.mrg, input$partRepDate, input$partRep)
  })
  output$downloadPartChart <- downloadHandler(
    filename = function() {
      paste(getPartNumber(input$partRep),'_',Sys.Date(),'.png',sep='')
    },
    content = function(file) {
      png(file)
      print(
        print(plotInputPart())
      )
      dev.off()
    }
  )
  
  # handle download of Root Cause Pareto
  plotInputPareto <- reactive({
    if(input$drillDown == TRUE & input$rootCauseTopLevel == 'Suspected Failure Mode') {
      makeRootCausePareto(input$rootCauseTopLevel, input$rootCauseLowLevel, input$rootCauseTopLevel, input$timeFrame, input$earlyFail)
    }
    else if (input$drillDown) {
      makeRootCausePareto(input$rootCauseTopLevel, input$rootCauseDrillCategory, input$rootCauseLowLevel, input$timeFrame, input$earlyFail)
    }
    else {
      makeRootCausePareto(input$rootCauseTopLevel, input$rootCauseLowLevel, input$rootCauseTopLevel, input$timeFrame, input$earlyFail)
    }
  })
  output$downloadRootCausePareto <- downloadHandler(
    filename = function() {
      if(input$drillDown) {
        paste(input$rootCauseTopLevel,'_',input$rootCauseDrillCategory,'_',input$rootCauseLowLevel,'_',Sys.Date(),'.png',sep='')
      }
      else {
        paste(input$rootCauseTopLevel,'_',Sys.Date(),'.png',sep='')
      }
    },
    content = function(file) {
      png(file, height=600, width=800)
      print(
        print(plotInputPareto())
      )
      dev.off()
    }
  )

})

app <- shinyApp(ui, server)
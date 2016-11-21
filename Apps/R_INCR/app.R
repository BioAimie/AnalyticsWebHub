# set the working directory
setwd('~/WebHub/AnalyticsWebHub/Apps/R_INCR')
# load necessary libraries
library(shiny)
library(shinydashboard)
library(zoo)
library(ggplot2)

# source the data and functions necessary to create the dashboard
source('R_INCR_subsetBasedOnTimeFrame.R')
source('R_INCR_getMagnificationCategories.R')
source('R_INCR_itemsInPareto.R')
source('R_INCR_makeRootCausePareto.R')

# ui to layout user interface
ui <- dashboardPage(skin = 'red',
                    
                    dashboardHeader(title = 'PostMarket Trending'),
                    
                    # Sidebar content
                    dashboardSidebar(
                      sidebarMenu(
                        menuItem('Root Cause Paretos', tabName = 'rootCause', icon = icon('cube'))
                      )
                    ),
                    
                    dashboardBody(
                      tabItems(
                        # First tab content
                        tabItem(tabName = 'rootCause',
                                fluidRow(
                                  box(
                                    title = 'Input Parameters', width = 3,
                                    selectInput('timeFrame',
                                                label = 'Time Frame:',
                                                choices = c('This Year','This Month','This Quarter','Last 90 Days','Last 30 Days','52 Weeks'),
                                                selected = 'This Year'
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
  
  # make root cause paretos
  output$rootCausePareto <- renderPlot ({
    if(input$drillDown == TRUE & input$rootCauseTopLevel == 'Suspected Failure Mode') {
      makeRootCausePareto(input$rootCauseTopLevel, input$rootCauseLowLevel, input$rootCauseTopLevel, input$timeFrame)
    }
    else if (input$drillDown) {
      makeRootCausePareto(input$rootCauseTopLevel, input$rootCauseDrillCategory, input$rootCauseLowLevel, input$timeFrame)
    }
    else {
      makeRootCausePareto(input$rootCauseTopLevel, input$rootCauseLowLevel, input$rootCauseTopLevel, input$timeFrame)
    }
  })
  
  # handle download of Root Cause Pareto
  plotInputPareto <- reactive({
    if(input$drillDown == TRUE & input$rootCauseTopLevel == 'Suspected Failure Mode') {
      makeRootCausePareto(input$rootCauseTopLevel, input$rootCauseLowLevel, input$rootCauseTopLevel, input$timeFrame)
    }
    else if (input$drillDown) {
      makeRootCausePareto(input$rootCauseTopLevel, input$rootCauseDrillCategory, input$rootCauseLowLevel, input$timeFrame)
    }
    else {
      makeRootCausePareto(input$rootCauseTopLevel, input$rootCauseLowLevel, input$rootCauseTopLevel, input$timeFrame)
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
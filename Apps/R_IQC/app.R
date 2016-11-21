# set the working directory
setwd('~/WebHub/AnalyticsWebHub/Apps/R_IQC/')

# load necessary libraries
library(shiny)
library(shinydashboard)
library(ggplot2)

# source the functions that are necessary to create the dashboard
source('R_IQC_averageOfParameters.R')
source('R_IQC_passRateOne.R')
source('R_IQC_appMakeNiceChart.R')
source('R_IQC_appMakeRateChart.R')

# ui to layout user interface
ui <- dashboardPage(skin = 'red',
                    
                    dashboardHeader(title = 'PostMarket Trending'),
                    
                    # Sidebar content
                    dashboardSidebar(
                      sidebarMenu(
                        menuItem('Run Results', tabName = 'runResults', icon = icon('cube')),
                        menuItem('Run Stats', tabName = 'runStats', icon = icon('cube'))
                      )
                    ),
                    
                    dashboardBody(
                      tabItems(
                        # First tab content
                        tabItem(tabName = 'runResults',
                                fluidRow(
                                  box(
                                    title = 'Input Parameters', width = 3,
                                    selectInput('varRate',
                                                label = 'Select Parameter to view Review Rate:',
                                                choices = c('Pouch','RNA','Noise','60 - Tm Range','60 - Median Delta Fluor','60 - Delta Fluor Range over Median'),
                                                selected = 'Pouch'
                                    ),
                                    selectInput('varRate_date',
                                                label = 'Select Date Range to view:',
                                                choices = c('2012','2013','2014','2015','52 weeks'),
                                                selected = '52 weeks'
                                    ),
                                    downloadButton('downloadRateChart','Download a Copy')
                                  ),
                                  box( 
                                    title = 'Review Rate', width = 9,
                                    plotOutput('reviewRate', height = 600)
                                  )
                                )
                        ),
                        # Second tab content
                        tabItem(tabName = 'runStats',      
                                fluidRow(
                                  box(
                                    title = 'Input Parameters', width = 3,
                                    selectInput('varAverage',
                                                label = 'Select Control:',
                                                choices = c('RNA','Noise','60 Melt Probe'),
                                                selected = 'RNA'
                                    ),
                                    uiOutput('selector'),
                                    selectInput('varAverage_date',
                                                label = 'Select Date Range to view:',
                                                choices = c('2012','2013','2014','2015','52 weeks'),
                                                selected = '52 weeks'
                                    ),
                                    downloadButton('downloadAvgChart','Download a Copy')
                                  ),
                                  box( 
                                    title = 'Control Results', width = 9,
                                    plotOutput('averageResults', height = 600)
                                  )
                                )
                        )
                      )
                    )
)

# workhorse to produce content    
server <- (function(input, output) {
  
  # rate chart 
  output$reviewRate <- renderPlot ({
    switch(input$varRate,
           'Pouch' = appMakeRateChart('PouchResult', input$varRate_date),
           #            'PCR1' = appMakeRateChart('PCR1', input$varRate_date),
           #            'PCR2' = appMakeRateChart('PCR2', input$varRate_date),
           'RNA' = appMakeRateChart('RNA', input$varRate_date),
           'Noise' = appMakeRateChart('Noise', input$varRate_date),
           '60 - Tm Range' = appMakeRateChart('60TmRange', input$varRate_date),
           '60 - Median Delta Fluor' = appMakeRateChart('60DFMed', input$varRate_date),
           '60 - Delta Fluor Range over Median' = appMakeRateChart('60DFRoM', input$varRate_date)
    )
  })
  
  # average chart
  output$averageResults <- renderPlot ({
    appMakeNiceChart(input$varAverage, input$varAvgParam, input$varAverage_date)
  })
  
  # dynamic selecters
  output$selector <- renderUI ({
    switch(input$varAverage,
           'RNA' = selectInput('varAvgParam', 
                               label = 'Parameter of Interest:',
                               choices = c('Cp','Tm'),
                               selected = 'Cp'
           ),
           'Noise' = selectInput('varAvgParam', 
                                 label = 'Parameter of Interest:',
                                 choices = c('Baseline'),
                                 selected = 'Baseline'
           ),
           '60 Melt Probe' = selectInput('varAvgParam', 
                                         label = 'Parameter of Interest:',
                                         choices = c('Tm Range','Median DF','DF Range over Median'),
                                         selected = 'Tm Range'
           )
    )  
  })
  
  output$downloadRateChart <- downloadHandler(
    filename = function() {
      paste('ReviewRate','_',Sys.Date(),'.png',sep='')
    },
    content = function(file) {
      png(file, height=600, width=800)
      print(
        switch(input$varRate,
               'Pouch' = appMakeRateChart('PouchResult', input$varRate_date),
               'RNA' = appMakeRateChart('RNA', input$varRate_date),
               'Noise' = appMakeRateChart('Noise', input$varRate_date),
               '60 - Tm Range' = appMakeRateChart('60TmRange', input$varRate_date),
               '60 - Median Delta Fluor' = appMakeRateChart('60DFMed', input$varRate_date),
               '60 - Delta Fluor Range over Median' = appMakeRateChart('60DFRoM', input$varRate_date)
        )
      )
      dev.off()
    }
  )
  
  output$downloadAvgChart <- downloadHandler(
    filename = function() {
      paste('AverageResults','_',Sys.Date(),'.png',sep='')
    },
    content = function(file) {
      png(file, height=600, width=800)
      print(appMakeNiceChart(input$varAverage, input$varAvgParam, input$varAverage_date))
      dev.off()
    }
  )
  
})

app <- shinyApp(ui, server)
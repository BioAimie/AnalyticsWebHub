setwd('~/WebHub/AnalyticsWebHub/Apps/O_SUPP')

library(shiny)
library(shinydashboard)
library(ggplot2)
library(scales)
library(zoo)
library(lubridate)
library(RColorBrewer)
library(dateManip)
library(rJava)
library(xlsx)
library(sendmailR)

# source('O_SUPP_loadApp.R')
source('O_SUPP_global.R')

#source('O_SUPP_createPaletteOfVariableLength.R')
source('O_SUPP_makeSupplierbyPartChart.R')
source('O_SUPP_filterPerInput.R')
source('O_SUPP_validateDF.R')
source('O_SUPP_makeSupplierChart.R')
source('O_SUPP_makeSummaryChart.R')
source('O_SUPP_makeSummaryTable.R')
source('O_SUPP_createMatManPareto.R')
# source('O_SUPP_createMatManTable.R')

ui <- dashboardPage(skin = 'red',
                    
                    dashboardHeader(title = 'PostMarket Trending'),
                    
                    dashboardSidebar(
                      sidebarMenu(
                        menuItem('Supplier Performance by Part', tabName = 'perfByPart', icon = icon('cube')),
                        menuItem('Supplier Summary', tabName = 'stckByVendor', icon = icon('cube')),
                        menuItem('Materials Management', tabName = 'matManParetos', icon = icon('cube'))
                      )
                    ),
                    
                    dashboardBody(
                      
                      tabItems(
                        
                        tabItem(tabName = 'perfByPart',
                                fluidRow(
                                  box(
                                    #title = 'Input Parameters', 
                                    width = 3,
                                    dateRangeInput('dateRange',
                                                   label = 'Date Range:',
                                                   start = Sys.Date()-365,
                                                   end = Sys.Date(),
                                                   min = '2014-01-01',
                                                   max = Sys.Date()
                                    ),
                                    selectInput('ncrType',
                                                label = 'NCR Type:',
                                                #choices = c('All NCRs','Raw Material','Instrument Production WIP','BioReagents'),
                                                choices = c('All NCRs','Raw Material','Instrument','BioReagents'),
                                                selected = 'All NCRs'
                                    ),
                                    uiOutput('vendorSelector'),
                                    checkboxInput('allVendorCheck', 'Display summary of all parts associated with selected supplier?', value = FALSE),
                                    uiOutput('partSelector'),
                                    downloadButton('downloadRateChart','Download a Copy')
                                  ),
                                  box(
                                   #title = 'Cumulative Supplier Performance', 
                                    width = 9,
                                    plotOutput('rollingRatePartVendor', height = 600),
                                    uiOutput('validation')
                                  )
                                )
                        ),
                        
                        tabItem(tabName = 'stckByVendor',
                                fluidRow(
                                  column(width = 3,
                                         box(width=NULL,
                                             selectInput('ncrTypeOP',
                                                         label = 'NCR Type',
                                                         #choices = c('All NCRs','Raw Material','Instrument Production WIP','BioReagents'),
                                                         choices = c('All NCRs','Raw Material','Instrument','BioReagents'),
                                                         selected = 'All NCRs'
                                                         ),
                                             uiOutput('vendorSelectorOP'),
                                             downloadButton('downloadBarChart','Download a Copy')
                                             )
                                         ),
                                  column(width=9,
                                         box(width=NULL,
                                             plotOutput('summaryPerformance', height = 600),
                                             uiOutput('validationOP')
                                             ),
                                         box(width=NULL,
                                             tableOutput('partsTable')
                                             )
                                         )
                                  )
                        ),
                        
                        tabItem(tabName = 'matManParetos',
                                fluidRow(
                                  column(width = 3, 
                                         box(width=NULL,
                                             selectInput('paretoType',
                                                         label = 'Display Pareto of:',
                                                         choices = c('Defects','Parts Affected','Supplier Performance - Best','Supplier Performance - Worst','Vendor NCR Summary'),
                                                         selected = 'Defects'
                                             ),
                                             uiOutput('paretoFilter'),
                                             uiOutput('paretoFilterChoices'),
                                             dateRangeInput('paretoDateRange',
                                                            label = 'Date Range:',
                                                            start = Sys.Date()-365,
                                                            end = Sys.Date(),
                                                            min = '2014-01-01',
                                                            max = Sys.Date()
                                             ),
                                             checkboxInput('supplierFault',
                                                           label = 'Only Display NCRs where Supplier was at Fault',
                                                           value = FALSE
                                                           )
                                             )
                                         ),
                                  column(width=9,
                                         box(width=NULL,
                                             plotOutput('paretoChart', height = 600)
                                         ),
                                         box(width=NULL,
                                             tableOutput('vendorTable')
                                         )
                                  )
                                )
                        )
                      )
                    )
)

server <- (function(input, output) {
  
  output$vendorSelector <- renderUI ({ 
     selectInput('investigateVendor',
                label = 'Vendor Name:',
                choices = filterPerInput('ncr',input$ncrType),
                selected = filterPerInput('ncr',input$ncrType)[1])
    
  })

  output$partSelector <- renderUI ({
    if(input$allVendorCheck == FALSE){
      selectInput('partNumber',
                  label = 'Part Number:',
                  choices = filterPerInput('parts',input$ncrType, input$investigateVendor),
                  selected = filterPerInput('parts',input$ncrType, input$investigateVendor)[1]
      )
    }
  })
  
  output$rollingRatePartVendor <- renderPlot ({
    if(input$allVendorCheck == FALSE){
      makeSupplierbyPartChart(input$ncrType, input$investigateVendor, input$dateRange[1], input$dateRange[2], input$partNumber)  
      #produceRatesNew(input$ncrType, input$investigateVendor, as.character(paste(year(input$dateRange[1]), week(input$dateRange[1]), sep = '-')), as.character(paste(year(input$dateRange[2]), week(input$dateRange[2]), sep = '-')), input$partNumber)
    } else{
      makeSupplierChart(input$ncrType, input$investigateVendor, input$dateRange[1], input$dateRange[2])
      #produceRatesNew(input$ncrType, input$investigateVendor, as.character(paste(year(input$dateRange[1]), week(input$dateRange[1]), sep = '-')), as.character(paste(year(input$dateRange[2]), week(input$dateRange[2]), sep = '-')))
    }
  })
  
  output$validation <- renderUI ({
    if(input$allVendorCheck == FALSE) {
      check <- validateDF(input$ncrType, input$investigateVendor, input$partNumber)
      if (check == 0) {
        tags$h4(paste('No supplier receipts found for part: ', input$partNumber))
      } else if (check == 1) {
        tags$h4(paste('No NCRs found for part: ', input$partNumber))
      } 
    } else {
      check <- validateDF(input$ncrType, input$investigateVendor)
      if (check == 0) {
        tags$h4('No supplier receipts found.')
      } else if (check == 1) {
        tags$h4('No NCRs found for supplier.')
      }
    }
  })

  #------------------------------------------------------------------------------------------------------------------------------------------------------------
  
  output$vendorSelectorOP <- renderUI ({  
    selectInput('investigateVendorOP',
                label = 'Vendor Name:',
                choices = filterPerInput('ncr',input$ncrTypeOP),
                selected = filterPerInput('ncr',input$ncrTypeOP)[1])
  })
  
  output$summaryPerformance <- renderPlot ({
    makeSummaryChart(input$ncrTypeOP, input$investigateVendorOP)
  })
  
  output$validationOP <- renderUI ({
      check <- validateDF(input$ncrTypeOP, input$investigateVendorOP)
      if (check == 0) {
        tags$h4('No supplier receipts found.')
      } else if (check == 1) {
        tags$h4('No NCRs found for supplier.')
      }
  })
  
  output$partsTable <- renderUI ({
    check <- validateDF(input$ncrTypeOP, input$investigateVendorOP)
    if (check == 0) {
      tags$h4('No supplier receipts found.')
    } else if (check == 1) {
      tags$h4('No NCRs found for supplier.')
    } else {
      makeSummaryTable(input$ncrTypeOP, input$investigateVendorOP) 
    }
  })
  
  #--------------------------------------------------------------------------------------------------------------------------------------
  output$downloadRateChart <- downloadHandler(
    filename = function() {
      if(input$allVendorCheck == FALSE){
        paste0(input$investigateVendor,'_',input$partNumber,'_',as.character(paste(year(input$dateRange[1]), week(input$dateRange[1]), sep = '-')),'_',as.character(paste(year(input$dateRange[2]), week(input$dateRange[2]), sep = '-')),'.png')
      } else{
        paste0(input$investigateVendor,'_Summary_',as.character(paste(year(input$dateRange[1]), week(input$dateRange[1]), sep = '-')),'_',as.character(paste(year(input$dateRange[2]), week(input$dateRange[2]), sep = '-')),'.png')
        
      }
      
    },
    content = function(file) {
      png(file, height=600, width=800)
      if(input$allVendorCheck == FALSE){
        print(makeSupplierbyPartChart(input$ncrType, input$investigateVendor, input$dateRange[1], input$dateRange[2], input$partNumber))
      } else{
        print(makeSupplierChart(input$ncrType, input$investigateVendor, input$dateRange[1], input$dateRange[2]))
        #print(produceRatesNew(input$ncrType, input$investigateVendor, as.character(paste(year(input$dateRange[1]), week(input$dateRange[1]), sep = '-')), as.character(paste(year(input$dateRange[2]), week(input$dateRange[2]), sep = '-'))))
      }
      dev.off()
    }
  ) 
  
  output$downloadBarChart <- downloadHandler(
    filename = function() {
      paste0(input$investigateVendorOP,'_','byQuarter','.png')
    },
    content = function(file) {
      png(file, height=600, width=800)
      print(makeSummaryChart(input$ncrTypeOP, input$investigateVendorOP))
      #print(produceRatesNew(input$ncrTypeOP, input$investigateVendorOP))
      dev.off()
    }
  )
  
  # Materials Management Section
  #--------------------------------------------------------------------------------------------------------------------------------------
  # input box for the pareto filter... NCR Type, SCAR, Item Class, SMI, etc... based on the paretoType (Parts Afffected, Defects,etc.)
  output$paretoFilter <- renderUI ({
    
    if(input$paretoType=='Defects') {
      selectInput('paretoFilterType',
                  label = 'Filter by:',
                  choices = c('NCR Type','SCAR'),
                  selected = 'NCR Type'
      )
    } else if(input$paretoType=='Vendor NCR Summary') {
        selectInput('paretoFilterType',
                    label = 'Filter by:',
                    choices = c('Vendor Name'),
                    selected = 'Vendor Name'
        )
    } else {
      selectInput('paretoFilterType',
                  label = 'Filter by:',
                  choices = c('NCR Type','Item Class','SCAR','SMI'),
                  selected = 'NCR Type'
      )
    }
  })
  
  output$paretoFilterChoices <- renderUI ({
    
    if(input$paretoFilterType == 'NCR Type') {
      selectInput('paretoFilterValue',
                  label = 'Filter:',
                  choices = as.character(do.call(rbind, lapply(1:length(as.character(unique(filters.df$Type))), function(x) data.frame(Type = as.character(unique(filters.df$Type))[x], LastUsed = max(filters.df[as.character(filters.df$Type)==as.character(unique(filters.df$Type))[x],'Date']))))[order(do.call(rbind, lapply(1:length(as.character(unique(filters.df$Type))), function(x) data.frame(Type = as.character(unique(filters.df$Type))[x], LastUsed = max(filters.df[as.character(filters.df$Type)==as.character(unique(filters.df$Type))[x],'Date']))))$LastUsed, decreasing = TRUE), 'Type']),
                  selected = as.character(do.call(rbind, lapply(1:length(as.character(unique(filters.df$Type))), function(x) data.frame(Type = as.character(unique(filters.df$Type))[x], LastUsed = max(filters.df[as.character(filters.df$Type)==as.character(unique(filters.df$Type))[x],'Date']))))[order(do.call(rbind, lapply(1:length(as.character(unique(filters.df$Type))), function(x) data.frame(Type = as.character(unique(filters.df$Type))[x], LastUsed = max(filters.df[as.character(filters.df$Type)==as.character(unique(filters.df$Type))[x],'Date']))))$LastUsed, decreasing = TRUE), 'Type'])[1]
                  )
    } else if(input$paretoFilterType == 'SCAR') {
      selectInput('paretoFilterValue',
                  label = 'Filter:',
                  choices = as.character(unique(filters.df$SCAR)),
                  selected = as.character(unique(filters.df$SCAR))[1]
      )
    } else if(input$paretoFilterType == 'Item Class') {
      selectInput('paretoFilterValue',
                  label = 'Filter:',
                  choices = as.character(unique(smi.df$ItemClass)),
                  selected = as.character(unique(smi.df$ItemClass))[1]
      )
    } else if(input$paretoFilterType == 'SMI') {
      selectInput('paretoFilterValue',
                  label = 'Filter:',
                  choices = as.character(unique(smi.df$SMI)),
                  selected = as.character(unique(smi.df$SMI))[1]
      )
    } else if(input$paretoFilterType == 'Vendor Name') {
      selectInput('paretoFilterValue',
                  label = 'Filter:',
                  choices = as.character(unique(filters.df$Vendor))[order(as.character(unique(filters.df$Vendor)))],
                  selected = as.character(unique(filters.df$Vendor))[order(as.character(unique(filters.df$Vendor)))][1]
      )
    }
  })
  
  output$paretoChart <- renderPlot({
    
    if(input$supplierFault) {
      
      if(input$paretoType %in% c('Supplier Performance - Best','Supplier Performance - Worst')) {
        
        createMatManPareto(input$paretoType, input$paretoFilterType, input$paretoFilterValue, input$paretoDateRange[1], input$paretoDateRange[2], TRUE, TRUE)
      } else {
        
        createMatManPareto(input$paretoType, input$paretoFilterType, input$paretoFilterValue, input$paretoDateRange[1], input$paretoDateRange[2], FALSE, TRUE)
      }
    } else {
      
      if(input$paretoType %in% c('Supplier Performance - Best','Supplier Performance - Worst')) {
        
        createMatManPareto(input$paretoType, input$paretoFilterType, input$paretoFilterValue, input$paretoDateRange[1], input$paretoDateRange[2], TRUE, FALSE)
      } else {
        
        createMatManPareto(input$paretoType, input$paretoFilterType, input$paretoFilterValue, input$paretoDateRange[1], input$paretoDateRange[2], FALSE, FALSE)
      }
    }
  })
  
  output$vendorTable <- renderUI ({
    
    if(input$paretoType %in% c('Supplier Performance - Best','Supplier Performance - Worst')) {
      
      if(input$supplierFault) {
        
        output$aa <- renderTable(createMatManTable(input$paretoType, input$paretoFilterType, input$paretoFilterValue, input$paretoDateRange[1], input$paretoDateRange[2], TRUE))
        tableOutput('aa')
      } else {
        
        output$aa <- renderTable(createMatManTable(input$paretoType, input$paretoFilterType, input$paretoFilterValue, input$paretoDateRange[1], input$paretoDateRange[2], FALSE))
        tableOutput('aa')
      }
    }
  })
  
})
app <- shinyApp(ui, server)
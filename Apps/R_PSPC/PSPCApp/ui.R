library(shiny)
library(shinydashboard)
library(shinysky)
library(DT)
library(stringr)

dashboardPage( 
  dashboardHeader(title='Pouch SPC Anomaly Dashboard', titleWidth = 350),
  dashboardSidebar(width = 350,
    sidebarMenu(
      menuItem('Summary Data Table', tabName='datatable', icon = icon('table')),
      menuItem('Recent vs Previous Anomaly Rate', tabName = 'recentvprev', icon = icon('bar-chart')),
      menuItem('QC Anomaly Rate', tabName = 'qcanomrate', icon = icon('area-chart')),
      menuItem('QC Pouches Run To Date', tabName = 'qcpouches', icon = icon('bar-chart')),
      menuItem('Real False Positives', tabName = 'fppanel', icon = icon('bar-chart')),
      menuItem('Control Failure Pattern', tabName = 'cfpattern', icon = icon('area-chart')),
      br(),
      br(),
      br(),
      tags$div(actionButton('refresh', 'Refresh Data'), style = "margin-left: 20px;"), 
      br(),
      tags$div(actionButton('curator', 'Pouch SPC Curator'), style = "margin-left: 20px;", onclick ="window.open('http://google.com', '_blank')")
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = 'datatable', 
        fluidRow(
          box(
            title = 'Filters',
            width = 2, 
            checkboxGroupInput('columnsVisible','Columns to Show', choices = colnames(summary.df), selected = colnames(summary.df)),
            actionLink('selectAll', label = 'Select All/Deselect All'),
            br(),
            br(),
            checkboxInput('includeabg', 'Include alpha, beta, and gamma runs', value = FALSE),
            br(),
            br(),
            downloadButton('downloaddt', 'Download Data Table')
          ),
          box(
            title = 'Anomaly Summary Table',
            width = 10,
            dataTableOutput('dataTable')
          ) #end box
        ) #end fluidRow
      ), # end tabItem
      tabItem(tabName = 'recentvprev',
        fluidRow(
          box(
            title = 'Filters',
            width = 2, 
            textInput('pouchserial1', 'Exclude Pouch Serial Number(s):', value ='', placeholder = 'Separate with a comma'),
            br(),
            br(),
            downloadButton('downloadrecentvprev', 'Download Chart')
          ),
          box(
            width = 8,
            busyIndicator(text = 'Making chart...', wait=0),
            plotOutput('recentprevchart', height = '600px')
          )
        )#end fluidrow
      ), #end tabItem
      tabItem(tabName = 'qcanomrate',
              fluidRow(
                box(
                  title = 'Filters',
                  width = 2, 
                  checkboxGroupInput('panel2','Panel:', choices = as.character(unique(allruns.df$Panel)), selected = as.character(unique(allruns.df$Panel)), inline = FALSE),
                  br(),
                  checkboxGroupInput('anomalyfilter', 'Anomaly:', choices = c('False Positive','False Negative','Control Failure'), selected = c('False Positive','False Negative','Control Failure'), inline = FALSE),
                  br(),
                  textInput('pouchserial2', 'Exclude Pouch Serial Number(s):', value ='', placeholder = 'Separate with a comma'),
                  br(),
                  checkboxInput('includeabg2', 'Include alpha, beta, and gamma runs', value = FALSE),
                  br(),
                  br(),
                  downloadButton('downloadqcanomrate', 'Download Chart')
                ),
                box(
                  width = 8,
                  busyIndicator(text = 'Making chart...', wait=0),
                  plotOutput('qcanomratechart', height = '600px')
                )
              )#end fluidrow
      ), #end tabItem
      tabItem(tabName = 'qcpouches',
              fluidRow(
                box(
                  title = 'Filters',
                  width = 2,
                  checkboxInput('includeabg4', 'Include alpha, beta, and gamma runs', value = FALSE),
                  br(),
                  br(),
                  downloadButton('downloadqcpouches', 'Download Chart')
                ),
                box(
                  width = 8,
                  busyIndicator(text = 'Making chart...', wait=0),
                  plotOutput('qcpoucheschart')
                )#end box
              ) #end fluidRow
      ), #end tabItem
      tabItem(tabName = 'fppanel',
              fluidRow(
                box(
                  title = 'Filters',
                  width = 2, 
                  radioButtons('dateBut', 'Date Range:', choices = c('1 Year', 'Historic', 'Custom'), selected = '1 Year'),
                  uiOutput('calendar'),
                  br(),
                  selectizeInput('runOb2', 'Run Observation:', choices = c('All', sort(as.character(runobs.df$RunObservation))), selected = 'All', multiple = TRUE),
                  br(),
                  checkboxGroupInput('instVer', 'Instrument Version:', choices = c('FA 1.5', 'FA 2.0', 'Torch'), selected = c('FA 1.5', 'FA 2.0', 'Torch')), 
                  br(),
                  radioButtons('panVassayBut', label=NULL, choices = c('Panel', 'Assay'), selected = 'Panel', inline = TRUE),
                  uiOutput('panVassay'),
                  br(),
                  textInput('pouchserial5', 'Exclude Pouch Serial Number(s):', value ='', placeholder = 'Separate with a comma'),
                  br(),
                  checkboxInput('includeabg3', 'Include alpha, beta, and gamma runs', value = FALSE),
                  br(),
                  br(),
                  downloadButton('downloadfppanel', 'Download Chart')
                ),
                box(
                  width = 8,
                  busyIndicator(text = 'Making chart...', wait=0),
                  plotOutput('fppanelchart', height = '600px')
                )
              )#end fluidrow
      ), #end tabItem
      tabItem(tabName = 'cfpattern',
              fluidRow(
                box(
                  title = 'Filters',
                  width = 2, 
                  dateRangeInput('dateRange1', 'Date Range:', start = '2012-01-01', min = '2012-01-01'),
                  br(),
                  checkboxGroupInput('panel4','Panel:', choices = as.character(unique(allruns.df$Panel)), selected = as.character(unique(allruns.df$Panel)), inline = FALSE),
                  br(),
                  selectizeInput('runOb', 'Run Observation:', choices = c('All', sort(as.character(runobs.df$RunObservation))), selected = 'All', multiple = TRUE),
                  br(),
                  textInput('pouchserial4', 'Exclude Pouch Serial Number(s):', value ='', placeholder = 'Separate with a comma'),
                  br(),
                  checkboxInput('includeabg5', 'Include alpha, beta, and gamma runs', value = FALSE),
                  br(),
                  br(),
                  downloadButton('downloadcfpattern', 'Download Chart')
                ),
                box(
                  width = 8,
                  busyIndicator(text = 'Making chart...', wait=0),
                  plotOutput('cfpatternchart', height = '600px')
                )
              )#end fluidrow
      )#end tabItem
    ) #end tabItems
  ) #end dashboardBody
) #end shinyUI
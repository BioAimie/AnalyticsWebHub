library(shiny)
library(shinydashboard)
library(shinysky)
library(DT)
library(stringr)
library(rhandsontable)

shinyUI(
dashboardPage( 
  dashboardHeader(title='Pouch SPC Anomaly Dashboard', titleWidth = 350),
  dashboardSidebar(width = 350,
    sidebarMenu(
      menuItem('Summary Data Table', tabName='datatable', icon = icon('table')),
      menuItem('Recent vs Previous Anomaly Rate', tabName = 'recentvprev', icon = icon('bar-chart')),
      menuItem('QC Anomaly Rate', tabName = 'qcanomrate', icon = icon('area-chart')),
      menuItem('QC Pouches Run To Date', tabName = 'qcpouches', icon = icon('bar-chart')),
      menuItem('Run Observation Rates', tabName = 'fppanel', icon = icon('bar-chart')),
      menuItem('Control Failure Pattern', tabName = 'cfpattern', icon = icon('area-chart')),
      menuItem('Permanently Exclude Pouch Serials', tabName = 'permex', icon = icon('table')),
      br(),
      br(),
      br(),
      tags$div(actionButton('refresh', 'Refresh Data'), style = "margin-left: 20px; color: black;"), 
      br(),
      tags$div(actionButton('curator', 'Pouch SPC Curator'), style = "margin-left: 20px; color: black;", onclick ="window.open('http://10.1.23.96:3032', '_blank')")
    )
  ),
  dashboardBody(
    list(tags$head(tags$style(HTML("
                                 .multicol { 
                                   height: 80px;
                                   -webkit-column-count: 7; /* Chrome, Safari, Opera */ 
                                   -moz-column-count: 7;    /* Firefox */ 
                                   column-count: 7; 
                                   -moz-column-fill: auto;
                                   -column-fill: auto;
                                   } 
                                   ")) 
    )),
    tabItems(
      tabItem(tabName = 'datatable', 
              fluidRow(
                box(
                  title = 'Filters',
                  width = 12, 
                  tags$div(class='multicol', checkboxGroupInput('columnsVisible','Columns to Show', choices = colnames(summary.df), selected = colnames(summary.df), inline=FALSE)),
                  actionLink('selectAll', label = 'Select All/Deselect All'),
                  br(),
                  checkboxGroupInput('excludeabg', 'Exclude Mix:', choices = c('Alpha', 'Beta', 'Gamma', 'Omega'), selected = NA, inline = TRUE), 
                  br(),
                  downloadButton('downloaddt', 'Download Data Table')
                )
              ),#end fluidRow
              fluidRow(
                box(
                  title = 'Anomaly Summary Table',
                  width = 12,
                  dataTableOutput('dataTable')
                ) #end box
              ) #end fluidRow
      ), # end tabItem
      tabItem(tabName = 'recentvprev',
        fluidRow(
          box(
            title = 'Filters',
            width = 2, 
            textInput('pouchserial1', 'Temporarily Exclude Pouch Serial Number(s):', value ='', placeholder = 'Separate with a comma'),
            br(),
            br(),
            downloadButton('downloadrecentvprev', 'Download Chart')
          ),
          box(
            width = 10,
            busyIndicator(text = 'Making chart...', wait=0),
            plotOutput('recentprevchart', height = '700px')
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
                  textInput('pouchserial2', 'Temporarily Exclude Pouch Serial Number(s):', value ='', placeholder = 'Separate with a comma'),
                  br(),
                  checkboxGroupInput('excludeabg2', 'Exclude Mix:', choices = c('Alpha', 'Beta', 'Gamma', 'Omega'), selected = c('Alpha', 'Beta', 'Gamma'), inline = FALSE), 
                  br(),
                  br(),
                  actionButton('goButton1', 'Generate Chart'), 
                  br(), 
                  br(), 
                  downloadButton('downloadqcanomrate', 'Download Chart')
                ),
                box(
                  width = 10,
                  busyIndicator(text = 'Making chart...', wait=0),
                  plotOutput('qcanomratechart', height = '700px')
                )
              )#end fluidrow
      ), #end tabItem
      tabItem(tabName = 'qcpouches',
              fluidRow(
                box(
                  title = 'Filters',
                  width = 2,
                  checkboxGroupInput('excludeabg3', 'Exclude Mix:', choices = c('Alpha', 'Beta', 'Gamma', 'Omega'), selected = NA, inline = FALSE), 
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
                  radioButtons('panVassayBut', label='Color by:', choices = c('Panel', 'Assay'), selected = 'Panel', inline = TRUE),
                  br(), 
                  selectizeInput('panel3', 'Panel:', choices = c('All', 'BCID', 'GI', 'ME', 'RP', 'RP2', 'RP2plus'), selected = 'All', multiple = TRUE),
                  br(), 
                  uiOutput('assayList'),
                  br(),
                  textInput('pouchserial5', 'Temporarily Exclude Pouch Serial Number(s):', value ='', placeholder = 'Separate with a comma'),
                  br(),
                  checkboxGroupInput('excludeabg4', 'Exclude Mix:', choices = c('Alpha', 'Beta', 'Gamma', 'Omega'), selected = c('Alpha', 'Beta', 'Gamma'), inline = FALSE), 
                  br(),
                  br(),
                  actionButton('goButton2', 'Generate Chart'), 
                  br(), 
                  br(), 
                  actionButton('rateButton', 'Generate Rate Only'), 
                  br(), 
                  br(), 
                  downloadButton('downloadfppanel', 'Download Chart')
                ),
                box(
                  width = 10,
                  busyIndicator(text = 'Processing data...', wait=0),
                  uiOutput('rateOnlyOut'), 
                  plotOutput('fppanelchart', height = '700px')
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
                  checkboxGroupInput('assay2', 'Assay:', choices = sort(unique(as.character(subset(allruns.df, CF==1)[,'Control_Failures']))), selected = sort(unique(as.character(subset(allruns.df, CF==1)[,'Control_Failures'])))),
                  br(), 
                  textInput('pouchserial4', 'Temporarily Exclude Pouch Serial Number(s):', value ='', placeholder = 'Separate with a comma'),
                  br(),
                  checkboxGroupInput('excludeabg5', 'Exclude Mix:', choices = c('Alpha', 'Beta', 'Gamma', 'Omega'), selected = c('Alpha', 'Beta', 'Gamma'), inline = FALSE), 
                  br(),
                  br(),
                  actionButton('goButton3', 'Generate Chart'), 
                  br(), 
                  br(), 
                  downloadButton('downloadcfpattern', 'Download Chart')
                ),
                box(
                  width = 10,
                  busyIndicator(text = 'Making chart...', wait=0),
                  plotOutput('cfpatternchart', height = '700px')
                )
              )#end fluidrow
      ), #end tabItem
      tabItem(tabName = 'permex',
              fluidRow(
                box(
                  width = 10,
                  rHandsontableOutput('hot'),
                  br(),
                  actionButton('savetable', 'Save')
                )
              )#end fluidrow
      )#end tabItem
    ) #end tabItems
  ) #end dashboardBody
) #end shinyUI
)
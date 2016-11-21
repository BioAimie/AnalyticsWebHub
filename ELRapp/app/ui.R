library(shinydashboard)
library(leaflet)

dashboardPage(skin = 'red',
              
              dashboardHeader(title = 'Executive Portfolio'),
              
              # Sidebar content
              dashboardSidebar(
                sidebarMenu(
                  menuItem('U.S. Complaints Map', tabName = 'usComplaints', icon = icon('cube')),
                  menuItem('U.S. Sales Map', tabName = 'usSales', icon = icon('cube')),
                  menuItem('U.S. Sales Trending', tabName = 'usSChart', icon = icon('cube')),
                  menuItem('Product Usage Trending', tabName = 'siteProd', icon = icon('cube')),
                  menuItem('Product Reliability Trending', tabName = 'prodReli', icon = icon('cube')),
                  menuItem('Instrument Reliability Trending', tabName = 'instReli', icon = icon('cube')),
                  menuItem('FilmArray RP Field Trending', tabName = 'FATrend', icon = icon('cube')),
                  menuItem('Instrument Shipment Trending', tabName = 'instShip', icon = icon('cube'))
                )
              ),
              
              dashboardBody(
                tabItems(
                  # Complaint map tab
                  tabItem(tabName = 'usComplaints',
                          fluidRow(
                            column(width = 9,
                                   box(width = NULL,
                                       tags$h6('Complaints from last 90 Days'),
                                       leafletOutput('ucMap', height = 800)
                                     ),
                                   box(width = NULL,
                                     tableOutput('ucDataTable')
                                     )
                                   ),
                            column(width = 3,
                                   box(width = NULL,
                                       selectInput('ucMapBy',
                                                 label = 'Map By:',
                                                 choices = c('Sales Territory','Customer Type'),
                                                 selected = 'Sales Territory'
                                                 )
                                       ),
                                   box(width = NULL,
                                       selectInput('ucProduct', 
                                                   label = 'Product:',
                                                   choices = c('All Products','Instruments','Pouches'),
                                                   selected = 'All Products'
                                                   ),
                                       uiOutput('ucProductCheckboxes')
                                    )))),
                  
                  #US Sales map tab
                  tabItem(tabName = 'usSales',
                          fluidRow(
                            column(width = 9,
                                   box(width = NULL,
                                       tags$h6('Sales from last 90 days'),
                                       leafletOutput('usSMap', height = 800)
                                   ),
                                   box(width = NULL,
                                       tableOutput('usSDataTable')
                                   )
                            ),
                            column(width = 3,
                                   box(width = NULL,
                                       selectInput('usSMapBy',
                                                   label = 'Map By:',
                                                   choices = c('Sales Territory','Customer Type'),
                                                   selected = 'Sales Territory'
                                       )
                                   ),
                                   box(width = NULL,
                                       selectInput('usSProduct', 
                                                   label = 'Product:',
                                                   choices = c('All Products','Instruments','Pouches'),
                                                   selected = 'All Products'
                                       ),
                                       uiOutput('usSProductCheckboxes')
                                   )))),
                  
                  #US Sales chart tab
                  tabItem(tabName = 'usSChart',
                          fluidRow(
                            column(width = 9,
                                   plotOutput('salesChart', height = 600)
                            ),
                            column(width = 3,
                                   box(width = NULL,
                                       radioButtons('type',
                                                   label = NULL,
                                                   choices = c('Revenue','Shipments'),
                                                   selected = 'Revenue'
                                       )
                                   ),
                                   box(width = NULL,
                                       selectInput('prodType', 
                                                   label = 'Product:',
                                                   choices = c('All Products','Instruments','Pouches'),
                                                   selected = 'All Products'
                                       ),
                                       uiOutput('prodBoxes')
                                   ),
                                   box(width = NULL,
                                       dateRangeInput('salesDates',
                                                   label = 'Date Range:',
                                                   start = Sys.Date()-365,
                                                   min = '2014-01-01',
                                                   max = Sys.Date()
                                                   ))))),
                  #Product usage tab
                  tabItem(tabName = 'siteProd',
                          fluidRow(
                            column(width = 9,
                                   box(width = NULL,
                                      plotOutput('prodChart', height=600)
                                   )
                                   #,
                                   # box(width = NULL,
                                   # 
                                   # )
                            ),
                            column(width = 3,
                                   box(width = NULL,
                                       checkboxGroupInput('ProdCombo',
                                                         label = 'Product Combination Used:',
                                                         choices = c('RP',
                                                                     'BCID',
                                                                     'GI',
                                                                     'ME',
                                                                     'BCID, RP',
                                                                     'BCID, GI',
                                                                     'BCID, ME',
                                                                     'GI, RP',
                                                                     'ME, RP',
                                                                     'GI, ME',
                                                                     'BCID, GI, RP',
                                                                     'BCID, ME, RP',
                                                                     'BCID, GI, ME',
                                                                     'GI, ME, RP',
                                                                     'BCID, GI, ME, RP'
                                                         ),
                                                         selected = c('RP',
                                                                      'BCID',
                                                                      'GI',
                                                                      'ME',
                                                                      'BCID, RP',
                                                                      'BCID, GI',
                                                                      'BCID, ME',
                                                                      'GI, RP',
                                                                      'ME, RP',
                                                                      'GI, ME',
                                                                      'BCID, GI, RP',
                                                                      'BCID, ME, RP',
                                                                      'BCID, GI, ME',
                                                                      'GI, ME, RP',
                                                                      'BCID, GI, ME, RP'
                                                         )
                                       ),
                                       actionLink('selectall',"Select All/Unselect All")
                                   )))),
                  #Product Reliability Trending chart tab
                  tabItem(tabName = 'prodReli',
                          fluidRow(
                            column(width = 9,
                                   plotOutput('productRel', height = 600)
                            ),
                            column(width = 3
                                   ))),
                  #Instrument Reliability Trending chart tab
                  tabItem(tabName = 'instReli',
                          fluidRow(
                            column(width = 9,
                                   plotOutput('instRel', height = 600)
                            ),
                            column(width = 3
                            ))),
                  #FilmArray RP Field Trending chart tab
                  tabItem(tabName = 'FATrend',
                          fluidRow(
                            column(width = 9,
                                   plotOutput('faTrend', height = 600)
                            ),
                            column(width = 3
                            ))),
                  #Instrument Shipment Trending chart tab
                  tabItem(tabName = 'instShip',
                          fluidRow(
                            column(width = 9,
                                   plotOutput('instShipment', height = 600)
                            ),
                            column(width = 3
                            )))
                  )))

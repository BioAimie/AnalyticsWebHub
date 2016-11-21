setwd('~/WebHub/AnalyticsWebHub/ELRapp')
#setwd('G:/Departments/PostMarket/DataScienceGroup/Data Science Products/InProcess/Amber/20160321_ExectuiveLevelReportingPlatform/ELRapp')

# load the libraries needed for the app
library(shinydashboard)
# library(RODBC)
# library(ggmap)
# library(maps)
# library(sp)
# library(leaflet)
# library(colorRamps)
# library(rgeos)
# library(ggplot2)
# library(rgdal)
# library(maptools)

# load the data and necessary functions
# source('Rfunctions/main.R')
source('Rfunctions/takeMapByAndInputsToMakeMap.R')
source('Rfunctions/takeMapByAndInputsToMakeTable.R')
source('Rfunctions/checkBoxes.R')
source('Rfunctions/makeProdChart.R')
source('Rfunctions/makeSalesChart.R')

shinyServer(function(input, output, session) {
  
  # reactive output checkboxGroupInput based on product type selected in the U.S. Complaint Dash
  output$ucProductCheckboxes <- renderUI ({
    switch(input$ucProduct,
           'Pouches' = checkboxGroupInput('ucProductTypes', 
                                          label = 'Display:',
                                          choices = c('RP','GI','BCID','ME'),
                                          selected = c('RP','GI','BCID','ME')
           ),
           'Instruments' = checkboxGroupInput('ucProductTypes', 
                                              label = 'Display:',
                                              choices = c('FA1.5','FA1.5R', 'FA2.0','FA2.0R'),
                                              selected = c('FA1.5','FA1.5R', 'FA2.0','FA2.0R')
           )
    )
  })
  

  
  # make the table that outputs a tabulated data summary based on inputs 
  output$ucDataTable <- renderUI({
      if (input$ucProduct == 'All Products') {
      takeMapByAndInputsToMakeTable('com', input$ucMapBy, input$ucProduct)
    } else {
      validate(
        checkBoxes(input$ucProductTypes)
      )
      takeMapByAndInputsToMakeTable('com', input$ucMapBy, input$ucProduct, input$ucProductTypes)
    }
  })
  
  # create the map
  output$ucMap <- renderLeaflet({
    # print(input$ucMapBy)
    # print(input$ucProduct)
    # print(input$ucProductTypes)
    
    if(input$ucProduct == 'All Products') {
      uc.df <- takeMapByAndInputsToMakeMap('com', input$ucMapBy, input$ucProduct)
    } else {
      uc.df <- takeMapByAndInputsToMakeMap('com', input$ucMapBy, input$ucProduct, input$ucProductTypes)
    }
     pal <- colorNumeric(c('darkorange','darkred'), domain = uc.df[,'Rate'])
     
    # mapStates <- map('state', regions = as.character(unique(uc.df[,'Region'])), fill = TRUE, plot = FALSE)
    
    stateID <- as.vector(unique(uc.df[,'NAME']))


    uc.df <- uc.df[order(uc.df$NAME), ]
    states.shp.a <- merge(states.shp, uc.df, by="NAME", all=TRUE)
    
    leaflet(states.shp.a) %>%
       addProviderTiles("Hydda.Base") %>%
       addProviderTiles("Stamen.TonerHybrid",
                        options = providerTileOptions(opacity = 0.35)
       ) %>%
       addPolygons(fillColor = ~pal(Rate),
                   fillOpacity=0.8,
                   color='#BDBDC3',
                   weight=1,
                   layerId=~NAME) %>%
       # circle size based on count, color based on qty affected
       #addCircleMarkers(radius=~Rad, color=~pal(Qty), stroke = FALSE, fillOpacity = 1, data = uc.df, layerId=stateID) %>%
       setView(lng = -93.85, lat = 37.45, zoom = 4)
  })
  
  # Show a popup at the given location
  showUCSummary <- function(state, lng, lat) {
    if(input$ucProduct == 'All Products') {
      uc.df <- takeMapByAndInputsToMakeMap('com', input$ucMapBy, input$ucProduct)
    } else {
      uc.df <- takeMapByAndInputsToMakeMap('com', input$ucMapBy, input$ucProduct, input$ucProductTypes)
    }
    selectedState <- uc.df[uc.df[,'NAME'] == state,]
    if(length(selectedState[,'Qty']) == 0) {
      return()
    }
    content <- as.character(tagList(
      tags$h4(selectedState[,'NAME']),
      # tags$h6(sprintf("Count of Complaints: %s", selectedState[,'Count'])),
      tags$h6(sprintf("Quantity of Product Affected: %s", selectedState[,'Qty']))))
    leafletProxy("ucMap") %>% addPopups(lng, lat, content)
  }


  observe({
    leafletProxy("ucMap") %>%
    clearPopups()
    event <- input$ucMap_shape_mouseover
    if (is.null(event))
      return()
    #print(event)
   showUCSummary(event$id, event$lng, event$lat)
  })
  

#-----------------------------Sales Map---------------------------------------------------------------------------------------
  # reactive output checkboxGroupInput based on product type selected in the U.S. Shipment Dash
  output$usSProductCheckboxes <- renderUI ({
    switch(input$usSProduct,
           'Pouches' = checkboxGroupInput('usSProductTypes', 
                                          label = 'Display:',
                                          choices = c('RP','GI','BCID','ME'),
                                          selected = c('RP','GI','BCID','ME')
           ),
           'Instruments' = checkboxGroupInput('usSProductTypes', 
                                              label = 'Display:',
                                              choices = c('FA1.5','FA1.5R', 'FA2.0','FA2.0R'),
                                              selected = c('FA1.5','FA1.5R', 'FA2.0','FA2.0R')
           )
    )
  })
  
  
  
  #make the table that outputs a tabulated data summary based on inputs
  output$usSDataTable <- renderUI({
    if (input$usSProduct == 'All Products') {
      takeMapByAndInputsToMakeTable('sale', input$usSMapBy, input$usSProduct)
    } else {
      validate(
        checkBoxes(input$usSProductTypes)
      )
      takeMapByAndInputsToMakeTable('sale', input$usSMapBy, input$usSProduct, input$usSProductTypes)
    }
  })

  # create the map
  output$usSMap <- renderLeaflet({
    # print(input$usSMapBy)
    # print(input$usSProduct)
    # print(input$usSProductTypes)

    if(input$usSProduct == 'All Products') {
      uss.df <- takeMapByAndInputsToMakeMap('sale', input$usSMapBy, input$usSProduct)
    } else {
      uss.df <- takeMapByAndInputsToMakeMap('sale', input$usSMapBy, input$usSProduct, input$usSProductTypes)
    }
    pal <- colorNumeric(c('#66c2a4','#00441b'), domain = uss.df[,'Qty'])

    stateID <- as.vector(unique(uss.df[,'NAME']))
    
    
    uss.df <- uss.df[order(uss.df$NAME), ]
    states.shp.a <- merge(states.shp, uss.df, by="NAME", all=TRUE)
    
    leaflet(states.shp.a) %>%
      addProviderTiles("Hydda.Base") %>%
      addProviderTiles("Stamen.TonerHybrid",
                       options = providerTileOptions(opacity = 0.35)
      ) %>%
      addPolygons(fillColor = ~pal(Qty),
                  fillOpacity=0.8,
                  color='#BDBDC3',
                  weight=1,
                  layerId=~NAME) %>%
      setView(lng = -93.85, lat = 37.45, zoom = 4)
  })
    
  # Show a popup at the given location
  showUSSalesSummary <- function(state, lng, lat) {
    if(input$usSProduct == 'All Products') {
      uss.df <- takeMapByAndInputsToMakeMap('sale', input$usSMapBy, input$usSProduct)
    } else {
      uss.df <- takeMapByAndInputsToMakeMap('sale', input$usSMapBy, input$usSProduct, input$usSProductTypes)
    }
    selectedState <- uss.df[uss.df[,'NAME'] == state,]
    if(length(selectedState[,'Qty']) == 0) {
      return()
    }
    content <- as.character(tagList(
      tags$h4(selectedState[,'NAME']),
      tags$h6(sprintf("Number of Units Sold: %s", selectedState[,'ItemsShipped'])),
      tags$h6(sprintf("Quantity of Product Sold: %s", selectedState[,'Count'])),
      tags$h6(paste('Revenue: $', format(selectedState[,'Qty'], big.mark=","), sep=""))))
    leafletProxy("usSMap") %>% addPopups(lng, lat, content)
  }
  
  observe({
    leafletProxy("usSMap") %>%
      clearPopups()
    event <- input$usSMap_shape_mouseover
    if (is.null(event))
      return()
    #print(event)
    showUSSalesSummary(event$id, event$lng, event$lat)
  })  
  #------------------------Product Usage by Site---------------------------------------------------------------
  output$prodChart <- renderPlot({
   # print(input$ProdCombo)
    makeProdChart(input$ProdCombo)
  })
  
  observe({
    combinations <- c('RP',
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
                      'BCID, GI, ME, RP')
    
   # print(input$selectall)
    if(input$selectall == 0) return(NULL) 
    else if (input$selectall%%2 == 0)
    {
      updateCheckboxGroupInput(session,'ProdCombo','Product Combination Used:',choices=combinations,selected=combinations)
    }
    else
    {
      updateCheckboxGroupInput(session,'ProdCombo','Product Combination Used:',choices=combinations)
    }
  })
  


#-----------------------------Revenue / shipments Chart-----------------------------------------------------------
# reactive output checkboxGroupInput based on product type selected in the U.S. Shipment Dash
  output$prodBoxes <- renderUI ({
    switch(input$prodType,
           'Pouches' = checkboxGroupInput('prods', 
                                          label = 'Display:',
                                          choices = c('RP','GI','BCID','ME'),
                                          selected = c('RP','GI','BCID','ME')
           ),
           'Instruments' = checkboxGroupInput('prods', 
                                              label = 'Display:',
                                              choices = c('FA1.5','FA1.5R','FA2.0','FA2.0R'),
                                              selected = c('FA1.5','FA1.5R','FA2.0','FA2.0R')
           )
    )
  })
  
  output$salesChart <- renderPlot ({
    #print(input$salesDates)

    makeSalesChart(input$prodType, input$prods, input$type, input$salesDates)

  })
  
#-----------------------------Product Reliability Trending------------------------------------------------------
  output$productRel <- renderPlot ({
    p.allCmplt.mavg
  })
  
  #-----------------------------Instrument Reliability Trending------------------------------------------------------
  output$instRel <- renderPlot ({
    p.mtbf
  })
  
  #-----------------------------FA Field Trending------------------------------------------------------
  output$faTrend <- renderPlot ({
    p.area.justvirus
  })
  
  #-----------------------------Instrument Shipment Trending------------------------------------------------------
  output$instShipment <- renderPlot ({
    ship.Source
  })
  
    
})

library(shiny)
library(shinyjs)
library(shinyBS)
library(shinythemes)
library(DT)


shinyUI(
	
	fluidPage(
	  
		## create the "Input Paremeters" Panel
		useShinyjs(),
		uiOutput("over.title"),
		sidebarPanel( id="sideb",
   		uiOutput("input.options"),
			uiOutput("space")
			#uiOutput("directionsText")
			),
		 
		## create the panel that holds the data table (or error message)
		mainPanel(id="mainPanel",
			uiOutput("plotLink"),
			uiOutput("cpError"),
		  uiOutput("errorMessage"),
			uiOutput("dataFrameTitle"),
			dataTableOutput("rate.table"),
			plotOutput("cpPlot")
		
			
			
		), # main panel 
	  
		
			# import the CSS file 
			tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "style.css"))
		
	)# fluidPage
	
) # shinyUI







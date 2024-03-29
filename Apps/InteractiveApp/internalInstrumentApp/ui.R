
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
			
			),
		 
		## create the panel that holds the data table (or error message)
		mainPanel(id="mainPanel",
			#uiOutput("modalTrigger"),
			actionButton("triggerId","Click Here to View Plots"), 
			uiOutput("cpError"),
		  uiOutput("errorMessage"),
			uiOutput("dataFrameTitle"),
			dataTableOutput("rate.table"),
			tags$hr(color="white"),
			uiOutput("downloadbutton"),
			plotOutput("cpPlot"),
			#bsModal(id="modalObject", textOutput("modalTitle"), trigger="triggerId", size="large", plotOutput("modalPlotCp"), plotOutput("modalPlotErrors"))
			uiOutput("modal")
		
			
		), # main panel 
	  
		
			# import the CSS file 
			tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "style.css"))
		
	)# fluidPage
	
) # shinyUI








library(shiny)
library(shinyjs)
library(shinyBS)
library(shinythemes)
library(DT)

#source("G:\\Departments\\PostMarket\\DataScienceGroup\\Data Science Products\\InProcess\\Anna\\20161229_InternalInstrumentPerformanceMonitoring\\Rfunctions\\loadInternalInstrumentApp.R")
setwd("G:\\Departments\\PostMarket\\DataScienceGroup\\Data Science Products\\InProcess\\Anna\\20161229_InternalInstrumentPerformanceMonitoring\\internalInstrumentApp")

error.message.list = list("pouchqc"="PouchQC", "validation"="Validation", "dungeon"= "the Dungeon", "7"="7", "30"="30", "90"="90", "360"="year")

shinyServer(function(input, output, session){
	
			########################################################################
	    ################# Create and Style Some UI Elements ####################
		  ########################################################################
			
			output$over.title <- renderUI( # main title of the page
				
				tags$div(id="overTitle", titlePanel("Internal Instrument Failure Rates"))
				
			)
			
			#output$main.title <- renderUI(
				
			#	tags$div(id="mainTitle", h1("Internal Instrument Failure Rates"))
					
			#	) 
			 
			
			output$input.options <- renderUI( # the side panel with all the input options 
				tags$div(id="inputOptions", 
			#	sidebarPanel( id="sideb", 
				
				h2("Select Input Parameters:"), 
				
	 			fluidRow(
	 				column(2, style="width:400px",
	 				radioButtons("location.choice", label=h3("Location Options"), 
	 					choices=list("Dungeon" = "dungeon" , "Validation" = "validation", "PouchQC"  = "pouchqc")))
	 					),
	 	
	 			fluidRow(
	 				column(2, style="width:400px", 	 
 					radioButtons( "date.range.choice", labe=h3("Date Range Options"), 
	 					choices=list("Last 7 Days" = "7", "Last 30 Days" = "30", "Last 90 Days" = "90", "One Year" = "360"))
	 					)
	 		
	 				),
			
				fluidRow(
						selectizeInput("protocol.choice", label=h3("Protocol Options"), selected=NULL,
							choices=list("NPS" ="NPS", "Stool"="Stool", "BC"="BC", "CSF"="CSF", "QC"="QC", "BT"="BT", "LRTI"="LRTI", "NGDS"="NGDS", "BJI"="BJI", "Custom"="Custom", "Other"="Other"), multiple=FALSE, options=list(placeholder="Click to See Protocol Options"))
					),
			
			 fluidRow(
	  	
	  			actionButton(class="loadingButton","load.data.table", "Load Data")	
	  		 )
				
					
			 
			#	) # sidebar panel 	
				) # tag 
			) # input options
			
			output$errorMessage <- renderUI( # the error message that's displayed if there is no instrument data for the given location/date range
				
				tags$div(id="errorMessage", textOutput("error.message"))
				
				
			) 
			
			output$dataFrameTitle <- renderUI( # the title that's displayed if there is instrument data for the given location/date range 
				
				tags$div(id="rateTableTitle", textOutput("data.Frame.Title"))
				
				
			) 
			
			output$directionsText <- renderUI(
				
				tags$div(id="directions", renderText("Directions: To get more information about an instrument, click on its row in the table and then click on the link that will appear above the plot title"))	
				
			)
			
			output$space <- renderUI(
				
				tags$hr()	
				
			)
			
			
			
			#################################################################################################
			###################### Load in the Requested Data Table (or error message) ######################
			#################################################################################################
		
			## wait for a user to click a row of the data table, then upload the plot(s)
			observeEvent(input$rate.table_rows_selected,{
				
				 rate.table.rowNum <- as.numeric(input$rate.table_rows_selected)
				 serial.num <- as.character(rate.tables[[isolate(input$location.choice)]][[isolate(input$protocol.choice)]][[isolate(input$date.range.choice)]][rate.table.rowNum, 1])
				 
				 # get the CP data associated with all the runs on that instrument in that location, protocol and timeframe 
				  cp.data <- cp.tables[[isolate(input$location.choice)]][[isolate(input$protocol.choice)]][[isolate(input$date.range.choice)]][[serial.num]]
					
				 if(!all(is.na(cp.data[1, ]))){ ## if there were no Cp runs to plot 
				 	  # create the plot and store it in the www/ folder
				 	  x.labels <- as.character(format(as.POSIXlt(cp.data[2, ], origin="1970-01-01"), format="%Y-%m-%d %H:%M:%S"))
				 	  plotTitle <- paste0(isolate(input$location.choice), isolate(input$date.range.choice), isolate(input$protocol.choice), serial.num,".jpg")
				 	  	
				 	  
				    #plot(cp.data[2, ], cp.data[1, ], main=main.title, col="#470898", cex.main=1.7, cex.lab=1.5,  cex=1.8, xaxt="n", xlab="", pch=15, ylab="Cp - yeastRNA", ylim=c(min(cp.data[1, ], na.rm=TRUE), max(cp.data[1, ], na.rm=TRUE)));
				    #lines(cp.data[2, ], cp.data[1, ],lwd=1.7 )
				 	  if(length(x.labels) <= 9){
				 	  	
				 	  		jpeg(paste0("www/", plotTitle), width=1000, height=600)
				 	 
				 	  		main.title <- paste0("yeastRNA Cp value for ", isolate(input$protocol.choice), " ", isolate(input$location.choice) , " runs on ", serial.num, " in the last ", isolate(input$date.range.choice), " days") 
				 	  		par(mar=c(14,5,4.1,2.1));
				 	  		barplot(cp.data[1, ], main=main.title, xlab="", xlim=c(0, 20), ylim=c(0,30), width=1.5, cex.main=1.6, cex.lab=1.4, cex.names=1.3, ylab="Cp - yeastRNA", names.arg=x.labels, col="#470898", axes=TRUE, axisnames=TRUE, las=2)
				 	  
				 	  }else if(length(x.labels) <= 35){
				 	  		jpeg(paste0("www/", plotTitle), width=1000, height=600)
				 	 
				 	  		main.title <- paste0("yeastRNA Cp value for ", isolate(input$protocol.choice), " ", isolate(input$location.choice) , " runs on ", serial.num, " in the last ", isolate(input$date.range.choice), " days") 
				 	  		par(mar=c(14,5,4.1,2.1));
				 	  	
				 	  		barplot(cp.data[1, ], main=main.title, xlab="", cex.main=1.6, cex.lab=1.4, cex.names=1.3, ylab="Cp - yeastRNA", ylim=c(0, 30), names.arg=x.labels, col="#470898", axes=TRUE, axisnames=TRUE, las=2)
				 	  }else{
				 	  		jpeg(paste0("www/", plotTitle), width=1800, height=600)
				 	 
				 	  		main.title <- paste0("yeastRNA Cp value for ", isolate(input$protocol.choice), " ", isolate(input$location.choice) , " runs on ", serial.num, " in the last ", isolate(input$date.range.choice), " days") 
				 	  		par(mar=c(14,5,4.1,2.1));
				 	  	
				 	  	  barplot(cp.data[1, ], main=main.title, xlab="", cex.main=1.6, cex.lab=1.4, cex.names=1.3, ylab="Cp - yeastRNA", names.arg=x.labels, ylim=c(0,30), col="#470898", axes=TRUE, axisnames=TRUE, las=2)
				 	  	
				 	  }
				 	
				    mtext("Run Date", side=1, line=13, cex=1.5)
				    dev.off()
				    hide("cpError")
				    showElement("plotLink")
				    # open the plot in another window 
				    output$plotLink <- renderUI(
				
							tags$a(id="plotlink", href=plotTitle, "Click Here to View Plot for Selected Row", rel="external", target="_blank")
				
						)
				    

				 }else{ ## if there are no cp values to plot, display an message that says that in lieu of the plot link 
				 	 hide("plotLink")
				 	 output$cpError <- renderUI(
				 	 		tags$div( id="cpErrorMessage", renderText(paste0("No Plot Available - there were no runs on ", serial.num, " with a yeastRNA control"))) 
				 	 )
				 	 
				 	 showElement("cpError")
				 }
			})
			
			### wait for a user to click the "Load Data" button the upload the data table
		  observeEvent(input$load.data.table, { 

		  hide("cpError")
		  hide("plotLink")
		  if(	length(rate.tables[[isolate(input$location.choice)]][[isolate(input$protocol.choice)]][[isolate(input$date.range.choice)]]) != 0){ # if there is data for the given location/date range 
		  	
				output$rate.table <- renderDataTable({rate.tables[[isolate(input$location.choice)]][[isolate(input$protocol.choice)]][[isolate(input$date.range.choice)]]}, selection="single")
				showElement("rate.table")
				output$error.message <- renderText("")
				output$data.Frame.Title <- renderText(paste0( isolate(input$protocol.choice), " Runs in ", error.message.list[[isolate(input$location.choice)]] , " Over the Last ", isolate(input$date.range.choice), " days"))
			  showElement("data.Frame.Title")
			  
			  
      }else{ # if the data table for that location/time period is empty 
		  
		  	output$error.message <- renderText(paste0("There were no ", isolate(input$protocol.choice),  " runs in ", error.message.list[[isolate(input$location.choice)]]," during the last ", error.message.list[[isolate(input$date.range.choice)]], " days"))
		  	hide("rate.table" )
		  	hide("data.Frame.Title")
		  }
		  	
		})
			
			
 				
 }) # shiny server 





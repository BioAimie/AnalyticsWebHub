
library(shiny)
library(shinyjs)
library(shinyBS)
library(DT)
library(ggplot2)
library(plotly)

setwd('~/WebHub/AnalyticsWebHub/Apps/InteractiveApp')
error.message.list = list("pouchqc"="PouchQC", "validation"="Validation", "dungeon"= "the Dungeon", "7"="7", "30"="30", "90"="90", "360"="year")


stringToPOSIXct <- function(string){
	## inputs: a date string in the form yyyy-mm-dd
	## outputs: a POSIXt date 
	return(as.POSIXct(strptime(string, "%Y-%m-%d")))
	
		
}


shinyServer(function(input, output, session){
	
			########################################################################
	    ################# Create and Style Some UI Elements ####################
		  ########################################################################
			hide("triggerId")
			hide("downloadbutton")
	     
			output$over.title <- renderUI( # main title of the page
				
				tags$div(id="overTitle", titlePanel("Internal Instrument Failure Rates"))
				
			)
		
			
			output$input.options <- renderUI( # the side panel with all the input options 
				tags$div(id="inputOptions", 
			#	sidebarPanel( id="sideb", 
				
				h2("Select Input Parameters:"), 
				
	 			fluidRow(
	 				column(2, style="width:400px",
	 				radioButtons("location.choice", label=h3("Location Options"), 
	 					choices=list("Dungeon" = "dungeon" , "PouchQC"  = "pouchqc")))
	 					),
	 	
	 			#fluidRow(
	 			#	column(2, style="width:400px", 	 
 				#	radioButtons( "date.range.choice", labe=h3("Date Range Options"), 
	 			#		choices=list("Last 7 Days" = "7", "Last 30 Days" = "30", "Last 90 Days" = "90", "One Year" = "360"))
	 			#		)
	 		
	 			#	),
				fluidRow(
					dateRangeInput("date.range.choice", label=h3("Date Range"), start= Sys.Date()-7, end=Sys.Date(), min=Sys.Date()- 360)
				),
			
				fluidRow(
						selectInput("protocol.choice", label=h3("Protocol Option(s)"),
							choices=list("All Except Custom"="All Except Custom", "All"="All", "NPS" ="NPS", "Stool"="Stool", "BC"="BC", "CSF"="CSF", "QC"="QC", "BT"="BT", "LRTI"="LRTI", "NGDS"="NGDS", "BJI"="BJI", "Custom"="Custom", "Other"="Other"), multiple=TRUE, selected="All Except Custom")
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
			
			output$space <- renderUI(
				
				tags$hr(id="sidepanelHR")	
				
			)
			
			output$downloadbutton <- renderUI(
				
				downloadLink( "downloadaction", "Download Data Table")	
			)
			
			output$downloadaction <- downloadHandler(
			
				filename=function(){
					paste0(isolate(input$location.choice), "_", paste(isolate(input$protocol.choice), collapse="_"), "_", paste(isolate(input$date.range.choice), collapse="-"), ".csv")    

				},
				content=function(file){
					if(length(isolate(input$protocol.choice)) == 1){
							write.csv(rate.table, file, row.names=FALSE)	
					}else{
						  write.csv(rate.table.combined, file, row.names=FALSE) 
								
					}
			
				}

			)
			
			
			#################################################################################################################
			######### wait for a user to click a row of the data table, then upload the cp/overall error plots ##############
			#################################################################################################################
			
			observeEvent(input$rate.table_rows_selected,{
				
				 ##### define some input varibles that will be used in the plots #####
				 rate.table.rowNum <- as.numeric(input$rate.table_rows_selected)
				 dates <- sapply(isolate(input$date.range.choice), stringToPOSIXct)
				 if(length(isolate(input$protocol.choice)) == 1){ # if one protocol is selected 
				 		serial.num <- as.character(rate.table[rate.table.rowNum, 1])
				 		dates.subset <- subset(sorted.tables[[isolate(input$location.choice)]][[isolate(input$protocol.choice)]], SerialNo == serial.num & dates[1] <= Date & dates[2] >= Date)
				 		cp.data <- data.frame(matrix(nrow=nrow(dates.subset)*2, ncol=3))
			  		colnames(cp.data) <- c("Date", "Values", "Key")
						cp.data[, 1] <- as.POSIXct(dates.subset[, "Date"], origin-"1970-01-01")
						cp.data[, 2] <- c(dates.subset[, "Cp"], dates.subset[, "Tm"]) 
						cp.data[, 3] <- c(rep( "Cp", nrow(dates.subset)), rep("Tm", nrow(dates.subset)))
						cp.data <- cp.data[order(cp.data$Date), ]
				 }else if(length(isolate(input$protocol.choice)) > 1){ # if multiple protocols are selected 
				 		serial.num <- as.character(rate.table.combined[rate.table.rowNum, 1])
				 		dates.subset <- subset(combined.rate.table, SerialNo == serial.num & dates[1] <= Date & dates[2] >= Date)
				 		cp.data <- data.frame(matrix(nrow=nrow(dates.subset)*2, ncol=3))
			  		colnames(cp.data) <- c("Date", "Values", "Key")
						cp.data[, 1] <- as.POSIXct(dates.subset[, "Date"], origin-"1970-01-01")
						cp.data[, 2] <- c(dates.subset[, "Cp"], dates.subset[, "Tm"]) 
						cp.data[, 3] <- c(rep( "Cp", nrow(dates.subset)), rep("Tm", nrow(dates.subset)))
				 		# re-order all the runs so they are in chronological order 
				 		cp.data <- cp.data[order(cp.data$Date), ]
				 }
				
					output$modalTitle <- renderText({serial.num})			
				  ########### create the overall error plot regardless of weather or not there is cp/tm data ############	
					
				 	output$stackedBarChart <- renderPlot({
				 		
				 		overall.plot.title <- paste0("failure percentage each week from ", paste(isolate(input$date.range.choice), collapse=" - ") ," for ", paste(isolate(input$protocol.choice), collapse=" , "), " runs on ", serial.num) 
  
				 		# call calcWeekErrorRate function 
				 		if(isolate(input$location.choice) != "dungeon"){
				 			week.error.rates <- calcWeekErrorRateQC(dates.subset)
				 		}else{
				 			week.error.rates <- calcWeekErrorRateDungeon(dates.subset)
				 		}
				 		# make the ggplots using the output of CalcWeekErrorRate 
				 		if(length(unique(week.error.rates$Date[!is.na(week.error.rates$Percentage)])) == 1){ # if only one bar will show up on the plot 
				 			ggplot(data=week.error.rates, aes(x=Date, y=Percentage, fill=FailureType)) +geom_bar(stat="identity", color="black",width =.08)+ labs(title=overall.plot.title, y="percent of runs with errors")	+ theme(axis.text.x = element_text(angle = 90, hjust = 1, size=14), axis.text.y=element_text(size=14), plot.title=element_text(face="bold", size=15), axis.title=element_text(size=14))

				 		}
				 		else if(max(week.error.rates$Percentage, na.rm=TRUE) <= 10){
		          ggplot(data=week.error.rates, aes(x=Date, y=Percentage, fill=FailureType)) +geom_bar(stat="identity", color="black")+ scale_y_continuous(limits=c(0, 15))+ labs(title=overall.plot.title, y="percent of runs with errors")	+ theme(axis.text.x = element_text(angle = 90, hjust = 1, size=14), axis.text.y=element_text(size=14),plot.title=element_text(face="bold", size=15), axis.title=element_text(size=14))
				 		}else{ 
				 			ggplot(data=week.error.rates, aes(x=Date, y=Percentage, fill=FailureType)) +geom_bar(stat="identity", color="black")+ labs(title=overall.plot.title, y="percent of runs with errors")	+ theme(axis.text.x = element_text(angle = 90, hjust = 1, size=14), axis.text.y=element_text(size=14), plot.title=element_text(face="bold", size=15), axis.title=element_text(size=14))
				 		}	

				 		})
				 
				 	
				 	
					############ create the yeast Cp/Tm plots if there is data #############	
				 	
				 	if(!is.null(cp.data) & !all(is.na(cp.data$Values))){ ## if there are Cp runs to plot 
				 		### define some variables for plotting
				 		cp.indices <-which(cp.data$Key == "Cp")
				    tm.indices <- which(cp.data$Key == "Tm")
				    main.title.cp <- paste0("average yeast Cp values for ", paste(isolate(input$protocol.choice), collapse=" , ") , " runs on ", serial.num, " from ", paste(isolate(input$date.range.choice), collapse=" - ")) 
				 		main.title.tm <- paste0("average yeast Tm values for ", paste(isolate(input$protocol.choice), collapse=" , ") , " runs on ", serial.num, " from ", paste(isolate(input$date.range.choice), collapse=" - ")) 

				    
				    # make y limits 
				    if(min(cp.data$Values[cp.indices], na.rm=TRUE) >= 5){
				    	cp.y.min <- floor(min(cp.data$Values[cp.indices], na.rm=TRUE) - 3)
				    	cp.y.max <- ceiling(max(cp.data$Values[cp.indices], na.rm=TRUE) + 3)
				    				
				    }else{
				    	cp.y.min<- 0 
				    	cp.y.max <- ceiling(max(cp.data$Values[cp.indices], na.rm=TRUE) + 3)
				    }
				    		
				    if(min(cp.data$Values[tm.indices], na.rm=TRUE) >= 5){
				    			
				    	tm.y.min <- floor(min(cp.data$Values[tm.indices], na.rm=TRUE) - 3)
				    	tm.y.max <- ceiling(max(cp.data$Values[tm.indices], na.rm=TRUE) + 3)
														    			
				    }else{
				    	tm.y.min<- 0 
				    	tm.y.max <- ceiling(max(cp.data$Values[tm.indices], na.rm=TRUE) + 3)

				    }
			
            
				 		if(length(cp.data$Date)/2 <= 45){
				    		date.labels <- as.character(format(cp.data$Date[tm.indices], format="%Y-%m-%d %H:%M:%S"))
				    		cp.data$Date <- as.factor(cp.data$Date)
				    		
				    
				    		x.min <- cp.data$Date[1]
				    		x.max <- cp.data$Date[length(cp.data$Date)]
				    		if(length(which(!(is.na(cp.data$Values)))) <= 2){
				    			output$cpValues <- renderPlot({
				    				ggplot(data=cp.data[cp.indices, ], aes(x=Date, y=Values)) +geom_bar(stat="identity", color="black", fill="black", width=.08) + labs(title=main.title.cp, y="average yeast Cp value") + theme(axis.text.x = element_text(angle = 90, hjust = 1, size=14, face="plain"), axis.text.y=element_text(size=14, face="plain"), plot.title=element_text(face="bold", size=15), axis.title=element_text(size=14, face="plain"), text=element_text(size=16, face="bold")) + coord_cartesian(ylim=c(cp.y.min, cp.y.max), expand=FALSE) + scale_x_discrete(breaks=cp.data$Date[cp.indices], labels=NULL, name=NULL) + theme(plot.margin = unit(c(1,1,.1,.5), "cm"))
				    			})
				    		
				    			output$tmValues <- renderPlot({
				    				ggplot(data=cp.data[tm.indices, ], aes(x=Date, y=Values)) +geom_bar(stat="identity", color="black", fill="black", width=.09) + labs(title=main.title.tm, y="average yeast Tm value") + theme(axis.text.x = element_text(angle = 90, hjust = 1, size=14, face="plain"), axis.text.y=element_text(size=14, face="plain"), plot.title=element_text(face="bold", size=15), axis.title=element_text(size=14, face="plain"), text=element_text(size=16, face="bold")) + coord_cartesian(ylim=c(tm.y.min, tm.y.max), expand=FALSE) + scale_x_discrete(name="Run Start Time", labels=date.labels, breaks=cp.data$Date[tm.indices]) + theme(plot.margin = unit(c(.5,1,1, .5), "cm"))
				    			})
				    			
				    		}else{
				    		
				    			output$cpValues <- renderPlot({
				    				ggplot(data=cp.data[cp.indices, ], aes(x=Date, y=Values)) +geom_bar(stat="identity", color="black", fill="black") + labs(title=main.title.cp, y="average yeast Cp value") + theme(axis.text.x = element_text(angle = 90, hjust = 1, size=14, face="plain"), axis.text.y=element_text(size=14, face="plain"), plot.title=element_text(face="bold", size=15), axis.title=element_text(size=14, face="plain"), text=element_text(size=16, face="bold")) + coord_cartesian(ylim=c(cp.y.min, cp.y.max), expand=FALSE) + scale_x_discrete(breaks=cp.data$Date[cp.indices], labels=NULL, name=NULL) + theme(plot.margin = unit(c(1,1,.1,.5), "cm"))
				    			})
				    		
				    			output$tmValues <- renderPlot({
				    				ggplot(data=cp.data[tm.indices, ], aes(x=Date, y=Values)) +geom_bar(stat="identity", color="black", fill="black") + labs(title=main.title.tm, y="average yeast Tm value") + theme(axis.text.x = element_text(angle = 90, hjust = 1, size=14, face="plain"), axis.text.y=element_text(size=14, face="plain"), plot.title=element_text(face="bold", size=15), axis.title=element_text(size=14, face="plain"), text=element_text(size=16, face="bold")) + coord_cartesian(ylim=c(tm.y.min, tm.y.max), expand=FALSE) + scale_x_discrete(name="Run Start Time", labels=date.labels, breaks=cp.data$Date[tm.indices]) + theme(plot.margin = unit(c(.5,1,1, .5), "cm"))
	
				    			
				    			})
				    		}
				     		## set plot dimensions
				    		height.cp <- "300px"
				    		width.cp <- "850px"
				    		
				    		height.tm <- "500px"
				    		width.tm <- "850px"
				    		
				    		
				    		

				    }else{ ## make the graph into two scatter plots if there are more than 45 runs 
				    		main.title <- paste0("average yeast Cp/Tm values for ", paste(isolate(input$protocol.choice), collapse=" , ") , " ", isolate(input$location.choice) , " runs on ", serial.num, " in the last ", isolate(input$date.range.choice), " days") 
				 
				    		## choose which runs to label so that the graph will look good
				    	  months.with.runs <- unique(format(cp.data$Date[order(cp.data$Date)], format="%Y-%m"))
				    	  
				    	  label.indices.cp <- unique(c(1, unlist(lapply(months.with.runs, function(x)which(grepl(x, cp.data$Date[cp.indices]))[1])), length(cp.data$Date[cp.indices]) )) 

				    	  
				    	  date.labels.scatter.cp <- as.character(format(cp.data$Date[cp.indices], format="%Y-%m-%d"))[label.indices.cp]
                scatter.breaks.cp <- as.vector(cp.data$Date[cp.indices])[label.indices.cp]
               
                label.indices.tm <- unique(c(1, unlist(lapply(months.with.runs, function(x)which(grepl(x, cp.data$Date[tm.indices]))[1])), length(cp.data$Date[tm.indices]) )) 

                date.labels.scatter.tm <- as.character(format(cp.data$Date[tm.indices], format="%Y-%m-%d"))[label.indices.tm]
                scatter.breaks.tm <- as.vector(cp.data$Date[tm.indices])[label.indices.tm]
                
                
                cp.data$Date <- as.factor(cp.data$Date)
                
				    		output$cpValues <- renderPlot({
				    			ggplot(data=cp.data[cp.indices, ], aes(x=Date, y=Values, group=1)) + geom_point( size=2) + geom_line(data=cp.data[cp.indices, ][!is.na(cp.data$Values[cp.indices]), ]) + labs(title=main.title.cp, y="average yeast Cp value") + theme(axis.text.x = element_text(angle = 90, hjust = 1, size=14), axis.text.y=element_text(size=14), plot.title=element_text(face="bold", size=15), axis.title=element_text(size=14)) + theme(plot.margin = unit(c(1, 1, 0.5, 0.5), "cm")) + scale_x_discrete(name=NULL, breaks=cp.data$Date[label.indices.cp], labels=NULL) + theme(plot.margin = unit(c(1,1,.1,.6), "cm"))
				    		})
				    		output$tmValues <- renderPlot({
				    			ggplot(data=cp.data[tm.indices, ], aes(x=Date, y=Values, group=1)) + geom_point( size=2) + geom_line(data=cp.data[tm.indices, ][!is.na(cp.data$Values[tm.indices]), ]) + labs(title=main.title.tm, y="average yeast Tm value") + theme(axis.text.x = element_text(angle = 90, hjust = 1, size=14), axis.text.y=element_text(size=14), plot.title=element_text(face="bold", size=15), axis.title=element_text(size=14)) + theme(plot.margin = unit(c(1, 1, 0.5, 0.5), "cm")) + scale_x_discrete(name="Run Start Time", breaks=cp.data$Date[label.indices.tm], labels=date.labels.scatter.tm) + theme(plot.margin = unit(c(.4,1,1,.6), "cm")) 

				    		})
				    		
				    		## set plot dimensions
				    		height.cp <- "300px"
				    		width.cp <- "800px"
				    			
				    		height.tm <- "400px"
				    		width.tm <- "800px"
				    		
				    }
				    
				 	 ####################################################################################################################################################################### 	
            
				   output$modalTrigger <- renderUI(
				
							actionButton("triggerId","Click Here to View Plots" ) 
					 )
				   output$modal <- renderUI(
				   	
				   		bsModal(id="modalObject", textOutput("modalTitle"), trigger="triggerId", size="large", plotOutput("cpValues", height=height.cp, width=width.cp), plotOutput("tmValues", height=height.tm, width=width.tm), tags$hr(color="white"), plotOutput("stackedBarChart"))
				   	
				   )
				    

				 	}else{ ## if there are no cp values to plot, display an message that says that in lieu of the plot link 
							output$modal <- renderUI(
										bsModal(id="modalObject", textOutput("modalTitle"), trigger="triggerId", size="large", plotOutput("stackedBarChart"))
							) 

				 }

				    show("triggerId")
         
		
		}) ## observe user clicking row of data table 
			
			
			##################################################################################################
			######### wait for a user to click the "Load Data" button, then upload the data table ############
			##################################################################################################
		  observeEvent(input$load.data.table, { 
		      
		  	## display error message if user does not select a protocol option 
		  	  
		  	if(length(isolate(input$protocol.choice)) > 1){ # if the user selected multiple protocol types 
		  	
		  		hide("cpError")
		  		hide("plotLink")
		  		dates <- sapply(isolate(input$date.range.choice), stringToPOSIXct)
		  		
		  		combined.rate.table <<- do.call("rbind", lapply(isolate(input$protocol.choice), function(x)return(sorted.tables[[isolate(input$location.choice)]][[x]])))
					if(nrow(subset(combined.rate.table, dates[1] <= Date & dates[2] >= Date)) != 0){ # if there is data for the given location/date range 
		  	  	# call calculate rates now
						
		  			rate.table.combined <<- createRateTable(combined.rate.table, dates[1], dates[2], isolate(input$location.choice))
		  			if(isolate(input$location.choice) == "pouchqc"){
		  				colnames(rate.table.combined) <<- c("Instrument Serial Number", "Version", "# of runs", "fraction of runs with at least one error", "Instrument Failure Rate", "Software Failure Rate", "PCR1 Negative Rate", "PCR2 Negative Rate", "Yeast Negative Rate", "Pouch Leak Rate", "Anomaly Rate")
		  			}else{
		  				colnames(rate.table.combined) <<- c("Instrument Serial Number", "Version", "# of runs", "fraction of runs with at least one error", "Instrument Failure Rate", "Software Failure Rate", "PCR1 Negative Rate", "PCR2 Negative Rate", "Yeast Negative Rate", "Pouch Leak Rate")
		  			}
		  			# load the table into the UI
		  			output$rate.table <- renderDataTable(datatable(rate.table.combined, selection="single", rownames=FALSE))
						show("rate.table")
						show("downloadbutton")
						output$error.message <- renderText("")
						output$data.Frame.Title <- renderText(paste0( paste(isolate(input$protocol.choice), collapse=","), " Runs in ", error.message.list[[isolate(input$location.choice)]] , " in between ", isolate(input$date.range.choice)[1], " and ", isolate(input$date.range.choice)[2]))
			  		show("data.Frame.Title")
			  
			  
      		}else{ # if the data table for that location/time period is empty 
		  
		  			output$error.message <- renderText(paste0("There were no ", paste(isolate(input$protocol.choice), collapse=","),  " runs in ", error.message.list[[isolate(input$location.choice)]], " in between ", isolate(input$date.range.choice)[1], " and ", isolate(input$date.range.choice)[2]))
		  			hide("rate.table" )
		  			hide("data.Frame.Title")
		  			hide("downloadbutton")
		  		}

		  	  
		  ####################################################	
		  }else{ ## if the user only selects one protocol type

		  	hide("cpError")
		  	hide("plotLink")
				
		  	# convert the date strings that were input from the user into POSIXct dates we can compare to the dates in the data frame
				dates <- sapply(isolate(input$date.range.choice), stringToPOSIXct)
		  	if(nrow(subset(sorted.tables[[isolate(input$location.choice)]][[isolate(input$protocol.choice)]], dates[1] <= Date & dates[2] >= Date)) != 0){ # if there is data for the given location/date range 
		  	  # call calculate rates now
		  		rate.table <<- createRateTable(sorted.tables[[isolate(input$location.choice)]][[isolate(input$protocol.choice)]], dates[1], dates[2], isolate(input$location.choice))
		  		if(isolate(input$location.choice) == "pouchqc"){
		  			colnames(rate.table) <<- c("Instrument Serial Number", "Version", "# of runs", "fraction of runs with at least one error", "Instrument Failure Rate", "Software Failure Rate", "PCR1 Negative Rate", "PCR2 Negative Rate", "Yeast Negative Rate", "Pouch Leak Rate", "Anomaly Rate")
		  		}else{
		  			colnames(rate.table) <<- c("Instrument Serial Number", "Version", "# of runs", "fraction of runs with at least one error", "Instrument Failure Rate", "Software Failure Rate", "PCR1 Negative Rate", "PCR2 Negative Rate", "Yeast Negative Rate", "Pouch Leak Rate")
		  		}
		  		# load the table into the UI
		  		output$rate.table <- renderDataTable(datatable(rate.table, selection="single", rownames=FALSE))
					show("rate.table")
					show("downloadbutton")
					output$error.message <- renderText("")
					output$data.Frame.Title <- renderText(paste0( isolate(input$protocol.choice), " Runs in ", error.message.list[[isolate(input$location.choice)]] , " in between ", isolate(input$date.range.choice)[1], " and ", isolate(input$date.range.choice)[2]))
			  	show("data.Frame.Title")
			  
			  
      	}else{ # if the data table for that location/time period is empty 
		  
		  		output$error.message <- renderText(paste0("There were no ", isolate(input$protocol.choice),  " runs in ", error.message.list[[isolate(input$location.choice)]], " in between ", isolate(input$date.range.choice)[1], " and ", isolate(input$date.range.choice)[2]))
		  		hide("rate.table" )
		  		hide("data.Frame.Title")
		  		hide("downloadbutton")
		  	}
		  
		  } # only one protocol
		  	
		})
			
			
 				
 }) # shiny server 





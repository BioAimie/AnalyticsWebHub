
library(shiny)
library(shinyjs)
library(shinyBS)
library(DT)
library(ggplot2)
library(plotly)

setwd('~/WebHub/AnalyticsWebHub/Apps/InteractiveApp')
error.message.list = list("pouchqc"="PouchQC", "validation"="Validation", "dungeon"= "the Dungeon", "7"="7", "30"="30", "90"="90", "360"="year")

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
	 	
	 			fluidRow(
	 				column(2, style="width:400px", 	 
 					radioButtons( "date.range.choice", labe=h3("Date Range Options"), 
	 					choices=list("Last 7 Days" = "7", "Last 30 Days" = "30", "Last 90 Days" = "90", "One Year" = "360"))
	 					)
	 		
	 				),
				#fluidRow(
				#	dateRangeInput("custom.date", label="")
				#),
			
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
					paste0(isolate(input$location.choice), "_", paste(isolate(input$protocol.choice), collapse="_"), "_", isolate(input$date.range.choice), "days.csv")    

				},
				content=function(file){
					if(length(isolate(input$protocol.choice)) == 1){
							write.csv(rate.tables[[isolate(input$location.choice)]][[isolate(input$protocol.choice)]][[isolate(input$date.range.choice)]], file, row.names=FALSE)	
					}else{
						  write.csv(combined.rate.table, file, row.names=FALSE) 
								
					}
			
				}

			)
			
			
			#################################################################################################################
			######### wait for a user to click a row of the data table, then upload the cp/overall error plots ##############
			#################################################################################################################
			
			observeEvent(input$rate.table_rows_selected,{
				
				 ##### define some input varibles that will be used in the plots #####
				 rate.table.rowNum <- as.numeric(input$rate.table_rows_selected)
				 if(length(isolate(input$protocol.choice)) == 1){ # if one protocol is selected 
				 			serial.num <- as.character(rate.tables[[isolate(input$location.choice)]][[isolate(input$protocol.choice)]][[isolate(input$date.range.choice)]][rate.table.rowNum, 1])
							# get the CP data associated with all the runs on that instrument in that location, protocol and timeframe 
				 			cp.data <- cp.tables[[isolate(input$location.choice)]][[isolate(input$protocol.choice)]][[isolate(input$date.range.choice)]][[serial.num]]
				 			output$modalTitle <- renderText({serial.num})
				 		

				 }else if(length(isolate(input$protocol.choice)) > 1){ # if multiple protocols are selected 
				 			serial.num <- as.character(combined.rate.table[rate.table.rowNum, 1])
							# combine all the cp data frames for the given protocols (for the given location and date range)
				 			cp.data <- cp.tables[[isolate(input$location.choice)]][[isolate(input$protocol.choice)[1]]][[isolate(input$date.range.choice)]][[serial.num]]
				 			for(p in isolate(input$protocol.choice)[-1]){
				 				cp.data <- rbind(cp.data, cp.tables[[isolate(input$location.choice)]][[p]][[isolate(input$date.range.choice)]][[serial.num]])
				 			}
				 			# re-order all the runs so they are in chronological order 
				 			correct.order <- order(cp.data$Date)
				 			cp.data <- cp.data[correct.order, ]
				 			
				 			output$modalTitle <- renderText({serial.num})
				 }
				
					
					 			
				  ########### create the overall error plot regardless of weather or not there is cp data ############			 	
				 	output$stackedBarChart <- renderPlot({
				 		  overall.plot.title <- paste0("failure percentage each week for the last ", isolate(input$date.range.choice) ," days for ", paste(isolate(input$protocol.choice), collapse=" , "), " runs on ", serial.num) 
				 		 
				 			if(length(isolate(input$protocol.choice)) == 1){ ## if the user only selected one protocol type 
				 				  
				 				  
				 				  if(max(overall.error.rate.tables[[isolate(input$location.choice)]][[isolate(input$protocol.choice)]][[isolate(input$date.range.choice)]][[serial.num]]$matrix$Percentage, na.rm=TRUE) <= 10){
				 				  		ggplot(data=overall.error.rate.tables[[isolate(input$location.choice)]][[isolate(input$protocol.choice)]][[isolate(input$date.range.choice)]][[serial.num]]$matrix, aes(x=Date, y=Percentage, fill=FailureType)) +geom_bar(stat="identity", color="black")+ scale_y_continuous(limits=c(0, 15))+ scale_x_continuous(name="Week Number (year-week)", labels=weeks.for.padding[[isolate(input$date.range.choice)]], breaks=seq(1, length(weeks.for.padding[[isolate(input$date.range.choice)]]), 1), limits=c(0, length(weeks.for.padding[[isolate(input$date.range.choice)]])+1 ))+ labs(title=overall.plot.title, y="percent of runs with errors")	+ theme(axis.text.x = element_text(angle = 90, hjust = 1, size=14), axis.text.y=element_text(size=14),plot.title=element_text(face="bold", size=15), axis.title=element_text(size=14))
		              
				 				  }else{ 
				 							ggplot(data=overall.error.rate.tables[[isolate(input$location.choice)]][[isolate(input$protocol.choice)]][[isolate(input$date.range.choice)]][[serial.num]]$matrix, aes(x=Date, y=Percentage, fill=FailureType)) +geom_bar(stat="identity", color="black")+  scale_x_continuous(name="Week Number (year-week)", labels=weeks.for.padding[[isolate(input$date.range.choice)]], breaks=seq(1, length(weeks.for.padding[[isolate(input$date.range.choice)]]), 1), limits=c(0, length(weeks.for.padding[[isolate(input$date.range.choice)]])+1))+ labs(title=overall.plot.title, y="percent of runs with errors")	+ theme(axis.text.x = element_text(angle = 90, hjust = 1, size=14), axis.text.y=element_text(size=14), plot.title=element_text(face="bold", size=15), axis.title=element_text(size=14))
				 				  }	
				 			}else if(length(isolate(input$protocol.choice)) > 1){ ## if the user selected multipe protocol types you have to combine the data frames 
				 				  ## initialize the combined.df with a non-empty data frame
				 					logical.vector <- unlist(lapply(c(isolate(input$protocol.choice)), function(x)return(!is.null(overall.error.rate.tables[[isolate(input$location.choice)]][[x]][[isolate(input$date.range.choice)]][[serial.num]]))))
				 					initial.protocol <- isolate(input$protocol.choice)[logical.vector][1]
				 					initial.index <- which(isolate(input$protocol.choice) == initial.protocol)
				 					combined.df <- overall.error.rate.tables[[isolate(input$location.choice)]][[isolate(input$protocol.choice)[initial.index]]][[isolate(input$date.range.choice)]][[serial.num]]$matrix
				 					
				 					combined.df$Percentage <- round((combined.df$Percentage/100)*combined.df$RunCounts)
				 					for( PROTOCOL in (isolate(input$protocol.choice)[-initial.index])){ ## add up the number of errors for each protcol 
				 							if(!is.null(overall.error.rate.tables[[isolate(input$location.choice)]][[PROTOCOL]][[isolate(input$date.range.choice)]][[serial.num]])){
				 								errors.for.this.protocol <- round((overall.error.rate.tables[[isolate(input$location.choice)]][[PROTOCOL]][[isolate(input$date.range.choice)]][[serial.num]]$matrix$Percentage/100)*overall.error.rate.tables[[isolate(input$location.choice)]][[PROTOCOL]][[isolate(input$date.range.choice)]][[serial.num]]$matrix$RunCounts)
				 								combined.df$Percentage <- apply(cbind(combined.df$Percentage, errors.for.this.protocol), 1, function(x)if(all(is.na(x))){return(NA)}else{return(sum(x, na.rm=TRUE))})
				 								combined.df$RunCounts <- apply(cbind(combined.df$RunCounts, overall.error.rate.tables[[isolate(input$location.choice)]][[PROTOCOL]][[isolate(input$date.range.choice)]][[serial.num]]$matrix$RunCounts), 1, function(x)if(all(is.na(x))){return(NA)}else{return(sum(x, na.rm=TRUE))})
				 								
				 							}
				 					}
				 					## convert the sums into percentages
				 					combined.df$Percentage <- round((combined.df$Percentage/combined.df$RunCounts)*100, 2)
				 				  
				 					## plot the combined data frame 
				 					ggplot(data=combined.df, aes(x=Date, y=Percentage, fill=FailureType)) +geom_bar(stat="identity", color="black")+ scale_x_continuous(name="Week Number (year-week)", labels=weeks.for.padding[[isolate(input$date.range.choice)]], breaks=seq(1, length(weeks.for.padding[[isolate(input$date.range.choice)]]), 1), limits=c(0, length(weeks.for.padding[[isolate(input$date.range.choice)]])+1))+ labs(title=overall.plot.title, y="percent of runs with errors")	+ theme(axis.text.x = element_text(angle = 90, hjust = 1, size=14), axis.text.y=element_text(size=14), plot.title=element_text(face="bold", size=15), axis.title=element_text(size=14))

				 				  
				 			}
				 	})
				 	
				 	
					############ create the yeast Cp/Tm plots if there is data #############	
				 	
				 	if(!is.null(cp.data) & !all(is.na(cp.data$Values))){ ## if there are Cp runs to plot 
            
				 		### define some variables for plotting
				 		cp.indices <-which(cp.data$Key == "Cp")
				    tm.indices <- which(cp.data$Key == "Tm")
				    main.title.cp <- paste0("average yeast Cp values for ", paste(isolate(input$protocol.choice), collapse=" , "), " ", isolate(input$location.choice) , " runs on ", serial.num, " in the last ", isolate(input$date.range.choice), " days") 
				 		main.title.tm <- paste0("average yeast Tm values for ", paste(isolate(input$protocol.choice), collapse=" , "), " ", isolate(input$location.choice) , " runs on ", serial.num, " in the last ", isolate(input$date.range.choice), " days") 

				    
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
				    		
				    		output$cpValues <- renderPlot({
				    			ggplot(data=cp.data[cp.indices, ], aes(x=Date, y=Values)) +geom_bar(stat="identity", color="black", fill="black") + labs(title=main.title.cp, y="average yeast Cp value") + theme(axis.text.x = element_text(angle = 90, hjust = 1, size=14, face="plain"), axis.text.y=element_text(size=14, face="plain"), plot.title=element_text(face="bold", size=15), axis.title=element_text(size=14, face="plain"), text=element_text(size=16, face="bold")) + coord_cartesian(ylim=c(cp.y.min, cp.y.max), expand=FALSE) + scale_x_discrete(breaks=cp.data$Date[cp.indices], labels=NULL, name=NULL) + theme(plot.margin = unit(c(1,1,.1,.5), "cm"))
				    		})
				    		
				    		output$tmValues <- renderPlot({
				    			ggplot(data=cp.data[tm.indices, ], aes(x=Date, y=Values)) +geom_bar(stat="identity", color="black", fill="black") + labs(title=main.title.tm, y="average yeast Tm value") + theme(axis.text.x = element_text(angle = 90, hjust = 1, size=14, face="plain"), axis.text.y=element_text(size=14, face="plain"), plot.title=element_text(face="bold", size=15), axis.title=element_text(size=14, face="plain"), text=element_text(size=16, face="bold")) + coord_cartesian(ylim=c(tm.y.min, tm.y.max), expand=FALSE) + scale_x_discrete(name="Run Start Time", labels=date.labels, breaks=cp.data$Date[tm.indices]) + theme(plot.margin = unit(c(.5,1,1, .5), "cm"))

				    			
				    		})
				    		
				     		## set plot dimensions
				    		height.cp <- "300px"
				    		width.cp <- "850px"
				    		
				    		height.tm <- "500px"
				    		width.tm <- "850px"
				    		
				    		
				    		

				    }else{ ## make the graph into two scatter plots if there are more than 45 runs 
				    		main.title <- paste0("average yeast Cp/Tm values for ", paste(isolate(input$protocol.choice), collapse=" , ") , " ", isolate(input$location.choice) , " runs on ", serial.num, " in the last ", isolate(input$date.range.choice), " days") 
				 
				    		## choose which runs to label so that the graph will look good
				    	  months.with.runs <- unique(format(cp.data$Date[order(cp.data$Date)], format="%Y-%m"))
				    	  
				    	  #last.month <- months.with.runs[length(months.with.runs)]
				    	 
				    	  label.indices.cp <- unique(c(1, unlist(lapply(months.with.runs, function(x)which(grepl(x, cp.data$Date[cp.indices]))[1])), length(cp.data$Date[cp.indices]) )) 
				    	  #last.label.vector.cp <- which(grepl(last.month, cp.data$Date[cp.indices]))
				    		#last.label.cp <- last.label.vector.cp[length(last.label.vector.cp)] 
				    	  #label.indices.cp <- unique(c(label.indices.cp, last.label.cp))
				    	  
				    	  date.labels.scatter.cp <- as.character(format(cp.data$Date[cp.indices], format="%Y-%m-%d"))[label.indices.cp]
                scatter.breaks.cp <- as.vector(cp.data$Date[cp.indices])[label.indices.cp]
               
                label.indices.tm <- unique(c(1, unlist(lapply(months.with.runs, function(x)which(grepl(x, cp.data$Date[tm.indices]))[1])), length(cp.data$Date[tm.indices]) )) 
                #last.label.vector.tm <- which(grepl(last.month, cp.data$Date[tm.indices]))
				    		#last.label.tm <- last.label.vector.tm[length(last.label.vector.tm)] 
				    	  #label.indices.tm <- unique(c(label.indices.tm, last.label.tm))
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
		  	  
          
		  	  combined.rate.table <<- rate.tables[[isolate(input$location.choice)]][[isolate(input$protocol.choice)[1]]][[isolate(input$date.range.choice)]]
		  	  
		  	  # combine the different protocol data frames together 
		  	  
		  		for(p in isolate(input$protocol.choice)[-1]){ 
		  				combined.rate.table <<- rbind(combined.rate.table, rate.tables[[isolate(input$location.choice)]][[p]][[isolate(input$date.range.choice)]])
		  		}
		  	  
		  	  combineRowsDungeon <- function(x){
		  	  	if(length(which(combined.rate.table[ , "Instrument Serial Number"] == x)) > 1){ ## if there are actually multiple different protocol runs on the same instrument in this location/date range 
		  	  	     
		  	  			 indices <- which(combined.rate.table[ , "Instrument Serial Number"] == x)
		  	  			 
		  	  	     number.runs <- sum(combined.rate.table[indices, "# of runs"], na.rm=TRUE)
		  	  	     individual.runs <- combined.rate.table[indices, "# of runs"]
		  	  	     version <- combined.rate.table[indices, "Version"][1]
		  	  	     instrument.errors <- round(sum(combined.rate.table[indices, "Instrument Failure Rate"]*individual.runs)/number.runs, 3)
		  	  	     
		  	  	     software.errors <- round(sum(combined.rate.table[indices, "Software Failure Rate"]*individual.runs)/number.runs, 3)
		  	  	     pcr1.errors <- round(sum(combined.rate.table[indices, "PCR1 Negative Rate"]*individual.runs)/number.runs, 3)
		  	  	     pcr2.errors <- round(sum(combined.rate.table[indices, "PCR2 Negative Rate"]*individual.runs)/number.runs, 3)
		  	  	     yeast.errors <- round(sum(combined.rate.table[indices, "yeast Negative Rate"]*individual.runs)/number.runs, 3)
		  	  	     pouchleak.errors <- round(sum(combined.rate.table[indices, "Pouch Leak Rate"]*individual.runs)/number.runs, 3)
		  	  	     
		  	  	     total.errors <- round(sum(combined.rate.table[indices, "fraction of runs with at least one error"]*individual.runs)/number.runs, 3)
		  	  	
		  	  	     combined.rate.table <<- rbind(combined.rate.table, list(combined.rate.table[indices[1], "Instrument Serial Number"], version, number.runs , total.errors, instrument.errors, software.errors, pcr1.errors, pcr2.errors, yeast.errors, pouchleak.errors))  
		  	  			 combined.rate.table <<- combined.rate.table[-indices,  ]
		  	  	}
		  	  	
		  	  }
		  	  
		  	  
		  	  	combineRowsPouchqc <- function(x){
		  	  	if(length(which(combined.rate.table[ , "Instrument Serial Number"] == x)) > 1){ ## if there are actually multiple different protocol runs on the same instrument in this location/date range 
		  	  	     
		  	  			 indices <- which(combined.rate.table[ , "Instrument Serial Number"] == x)
		  	  			 
		  	  	     number.runs <- sum(combined.rate.table[indices, "# of runs"], na.rm=TRUE)
		  	  	     individual.runs <- combined.rate.table[indices, "# of runs"]
		  	  	     version <- combined.rate.table[indices, "Version"][1]
		  	  	     instrument.errors <- round(sum(combined.rate.table[indices, "Instrument Failure Rate"]*individual.runs)/number.runs, 3)
		  	  	     
		  	  	     software.errors <- round(sum(combined.rate.table[indices, "Software Failure Rate"]*individual.runs)/number.runs, 3)
		  	  	     pcr1.errors <- round(sum(combined.rate.table[indices, "PCR1 Negative Rate"]*individual.runs)/number.runs, 3)
		  	  	     pcr2.errors <- round(sum(combined.rate.table[indices, "PCR2 Negative Rate"]*individual.runs)/number.runs, 3)
		  	  	     yeast.errors <- round(sum(combined.rate.table[indices, "yeast Negative Rate"]*individual.runs)/number.runs, 3)
		  	  	     pouchleak.errors <- round(sum(combined.rate.table[indices, "Pouch Leak Rate"]*individual.runs)/number.runs, 3)
		  	  	     anomaly.errors <- round(sum(combined.rate.table[indices, "Anomaly Rate"]*individual.runs)/number.runs, 3)
		  	  	     total.errors <- round(sum(combined.rate.table[indices, "fraction of runs with at least one error"]*individual.runs)/number.runs, 3)
		  	  	     combined.rate.table <<- rbind(combined.rate.table, list(combined.rate.table[indices[1], "Instrument Serial Number"], version, number.runs , total.errors, instrument.errors, software.errors, pcr1.errors, pcr2.errors, yeast.errors, pouchleak.errors, anomaly.errors))  
		  	  			 combined.rate.table <<- combined.rate.table[-indices,  ]
		  	  	}
		  	  	
		  	  }

		  	  
		  	  serial.nums <- unique(combined.rate.table[, "Instrument Serial Number"])
		  	  
		  	  if(isolate(input$location.choice) == "dungeon"){
		  	  	lapply(serial.nums, combineRowsDungeon)
		  	  }else{
		  	  	lapply(serial.nums, combineRowsPouchqc)
		  	  }
		  	  
		  	  
					

		  	  title.string <- paste(isolate(input$protocol.choice), collapse=" , ")
		  	  # now re-order the new combined data frame 
		  	  
		  		if(length(combined.rate.table[ ,"fraction of runs with at least one error"]) > 1){ # if there are rows to sort 
		  	  		row.order <-  order(combined.rate.table[ ,"fraction of runs with at least one error"], decreasing=TRUE)
		  	  		combined.rate.table <<- combined.rate.table[row.order, ]
		  		}
		  	  
		  	  # now load the data table 
		  	  hide("cpError")
		  		hide("plotLink")
		  		if(	length(combined.rate.table) != 0){ # if there is data for the given location/date range 
		  	
						output$rate.table <- renderDataTable(datatable(combined.rate.table, rownames=FALSE, selection="single" ))
						show("rate.table")
						show("downloadbutton")
						show("triggerId")
						output$error.message <- renderText("")
						output$data.Frame.Title <- renderText(paste0( title.string, " Runs in ", error.message.list[[isolate(input$location.choice)]] , " Over the Last ", isolate(input$date.range.choice), " days"))
			  		show("data.Frame.Title")
			  
			  
      		}else{ # if the data table for that location/time period is empty 
		  
		  			output$error.message <- renderText(paste0("There were no ", title.string,  " runs in ", error.message.list[[isolate(input$location.choice)]]," during the last ", error.message.list[[isolate(input$date.range.choice)]], " days"))
		  			hide("rate.table" )
		  			hide("data.Frame.Title")
		  			hide("downloadbutton")
		  			hide("triggerId")
		  		}
		  	  
		  	  
		  ####################################################	
		  }else{ ## if the user only selects one protocol type

		  	hide("cpError")
		  	hide("plotLink")
		  	if(	length(rate.tables[[isolate(input$location.choice)]][[isolate(input$protocol.choice)]][[isolate(input$date.range.choice)]]) != 0){ # if there is data for the given location/date range 
		  	
					output$rate.table <- renderDataTable(datatable(rate.tables[[isolate(input$location.choice)]][[isolate(input$protocol.choice)]][[isolate(input$date.range.choice)]], selection="single", rownames=FALSE))
					show("rate.table")
					show("downloadbutton")
					output$error.message <- renderText("")
					output$data.Frame.Title <- renderText(paste0( isolate(input$protocol.choice), " Runs in ", error.message.list[[isolate(input$location.choice)]] , " Over the Last ", isolate(input$date.range.choice), " days"))
			  	show("data.Frame.Title")
			  
			  
      	}else{ # if the data table for that location/time period is empty 
		  
		  		output$error.message <- renderText(paste0("There were no ", isolate(input$protocol.choice),  " runs in ", error.message.list[[isolate(input$location.choice)]]," during the last ", error.message.list[[isolate(input$date.range.choice)]], " days"))
		  		hide("rate.table" )
		  		hide("data.Frame.Title")
		  		hide("downloadbutton")
		  	}
		  
		  } # only one protocol
		  	
		})
			
			
 				
 }) # shiny server 





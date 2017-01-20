
setwd("G:\\Departments\\PostMarket\\DataScienceGroup\\Data Science Products\\InProcess\\Anna\\20161229_InternalInstrumentPerformanceMonitoring")

library(rJava)
library(xlsx)
library(RODBC)

#######################################################
################## Load In Data  ######################
#######################################################


### get the dungeon instrument serial numbers 
FA.Instruments <- read.xlsx("G:\\Departments\\BioChem\\BioChem1_Shared\\Lab Management\\Instruments\\FA Instruments.xlsx", 1)
dungeon.instrument.serial.numbers <- as.vector(FA.Instruments$Instrument[which(FA.Instruments$Owner == "IDATEC")])
dungeon.instrument.serial.numbers <- paste(dungeon.instrument.serial.numbers, collapse="', '")
dungeon.instrument.serial.numbers <- paste0("( '", dungeon.instrument.serial.numbers, "') ")

### scan in the SQL queries 
dungeon.query <- gsub('serialnumbervector', dungeon.instrument.serial.numbers, paste(scan("SQL\\dungeon_instruments.txt",what=character(),quote=""), collapse=' '))   
pouch.qc.query <- paste(scan("SQL\\pouch_qc_instruments.txt",what=character(),quote=""), collapse=" ")
#validation.query <- paste(scan("SQL\\validation_instruments.txt",what=character(),quote=""), collapse=" ")

# initialize the list that will hold the query results 
location.frames <<- vector(mode="list")

# execute the queries to retrieve the instrument data 
print("running sql queries...")

PMScxn <- odbcConnect("PMS_PROD")

location.frames[["dungeon"]] <- sqlQuery(PMScxn, dungeon.query)
location.frames[["pouchqc"]] <- sqlQuery(PMScxn, pouch.qc.query)
#location.frames[["validation"]] <- sqlQuery(PMScxn, validation.query)


odbcClose(PMScxn)

print("sql queries completed")

############################################################################################################################
################ Create the rate tables that will be loaded into the UI (cut down on website load time) ####################
############################################################################################################################

print("creating rate tables...")

## figure out what protocols should be listed in the drop down 

protocol.types <- c("NPS", "Stool", "BC", "CSF", "QC", "BT", "LRTI", "NGDS", "BJI", "Custom")


## initialize the output data structue that holds the information to go in the data tables 
rate.tables <<- list()

for( l in c("dungeon" , "pouchqc")){ # first layer, locations 
	
	rate.tables[[l]] <- list()
	for( p in c(protocol.types, "Other")){ # second layer, protocol types
		
		rate.tables[[l]][[p]] <- list("7"=list(), "30"=list(), "90"=list(), "360"=list() ) # third layer, date rages 
	}
}

## initialize the output data structure that holds the information that will go in the plots 

cp.tables <<- list()

for( l in c("dungeon", "pouchqc")){ # first layer, locations 
	
	cp.tables[[l]] <- list()
	for( p in c(protocol.types, "Other")){ # second layer, protocol types
		
		cp.tables[[l]][[p]] <- list("7"=list(), "30"=list(), "90"=list(), "360"=list() ) # third layer, date rages 
	}
}



## calculate the date ranges for "today"
today <- as.POSIXct(Sys.Date(), origin="1970-01-01")
date.ranges <- list()
date.ranges[["7"]] <- c(seq(today, length=2, by="-1 week")[2], today)
date.ranges[["30"]] <- c(seq(today, length=2, by="-1 month")[2], today)
date.ranges[["90"]] <- c(seq(today, length=2, by="-3 months")[2], today)
date.ranges[["360"]] <- c(seq(today, length=2, by="-1 year")[2], today)


calculateRates <- function(x, all.row.Numbers, l, p, d){
	## input: a serial number and a list of row numbers and the location, protocol, date range
	## output: add a row to the rate.tables data structure, and return CP values for cp.tables 

	# calculate the different types of failure rates 
	x.row.numbers <- all.row.Numbers[which(location.frames[[l]]$SerialNo[all.row.Numbers] == x)]

	instrument.rate <- round((sum(location.frames[[l]][ x.row.numbers, "InstrumentError"])/length(location.frames[[l]][ x.row.numbers, "InstrumentError"]))*100, 2)
	software.rate <- round((sum(location.frames[[l]][ x.row.numbers, "SoftwareError"])/length(location.frames[[l]][ x.row.numbers, "SoftwareError"]))*100, 2)
	control.rate <- round((sum(location.frames[[l]][ x.row.numbers, "ControlFail"])/length(location.frames[[l]][ x.row.numbers, "ControlFail"]))*100, 2)
	pouchleak.rate <-round((sum(location.frames[[l]][ x.row.numbers, "PouchLeak"])/length(location.frames[[l]][ x.row.numbers, "PouchLeak"]))*100, 2) 
	
	#total.rate <-  round(sum(instrument.rate, software.rate, control.rate, pouchleak.rate, na.rm=TRUE), 2)
	total.rate.numerator <- sum(unlist(lapply(x.row.numbers, function(k)if(sum(location.frames[[l]][k, c("InstrumentError", "SoftwareError", "PouchLeak", "ControlFail")]) > 0){return(1)}else{return(0)})))
	total.rate <- round((total.rate.numerator/length(x.row.numbers))*100, 2)
	# convert them into strings 
	instrument.rate <- paste0(as.character(instrument.rate), "%")
  software.rate <- paste0(as.character(software.rate), "%")
	control.rate <- paste0(as.character(control.rate), "%")
	pouchleak.rate <- paste0(as.character(pouchleak.rate), "%")
	
	# add the rates to rate.tables 
	rate.tables[[l]][[p]][[d]] <<- rbind(rate.tables[[l]][[p]][[d]], list("Instrument Serial Number" = x , "# of runs"= length(x.row.numbers), "% of runs with at least one error" =  total.rate, "Instrument Failure Rate" = instrument.rate, 
		"Software Failure Rate"=software.rate, "Control Failure Rate"=control.rate, "Pouch Leak Rate"=pouchleak.rate))
	
	# add the rates to the "All" protocol category in rate.tables
	if(p != "Custom"){
		rate.tables[[l]][["All Except Custom"]][[d]] <<- rbind(rate.tables[[l]][["All Except Custom"]][[d]], list("Instrument Serial Number" = x , "# of runs"= length(x.row.numbers), "% of runs with at least one error" =  total.rate, "Instrument Failure Rate" = instrument.rate, 
			"Software Failure Rate"=software.rate, "Control Failure Rate"=control.rate, "Pouch Leak Rate"=pouchleak.rate))
	}
		
	rate.tables[[l]][["All"]][[d]] <<- rbind(rate.tables[[l]][["All"]][[d]], list("Instrument Serial Number" = x , "# of runs"= length(x.row.numbers), "% of runs with at least one error" =  total.rate, "Instrument Failure Rate" = instrument.rate, 
		"Software Failure Rate"=software.rate, "Control Failure Rate"=control.rate, "Pouch Leak Rate"=pouchleak.rate))
			

	## now return the CP data
	output <- matrix(ncol=length(x.row.numbers), nrow=2)
	output[1, ] <- location.frames[[l]][x.row.numbers, "Cp"] 
	output[2, ] <- as.POSIXct(location.frames[[l]][x.row.numbers, "Date"], origin-"1970-01-01")
		
	output[which(output == 40)] <- NA
		
	return(output)
  
			
}

#getCPvalues <- function(x, all.row.Numbers, l, p, d){
		## input: a serial number, a list of the corresponding row numbers in location.frames, the location, protocol and date
	  ## output: a 2 X length(all.row.Number) matrix that holds the Cp values in the top row and the date in the bottom row 
		
#		x.row.numbers <- all.row.Numbers[which(location.frames[[l]]$SerialNo[all.row.Numbers] == x)]
#		output <- matrix(ncol=length(x.row.numbers), nrow=2)
#		output[1, ] <- location.frames[[l]][x.row.numbers, "Cp"] 
#		output[2, ] <- as.POSIXct(location.frames[[l]][x.row.numbers, "Date"], origin-"1970-01-01")
		
#		output[which(output == 40)] <- NA
		
#		return(output)
#}


## fill up the output data structure 
for( location in c("dungeon", "pouchqc")){
	  print(location)
		for( d in c("7", "30", "90", "360")){
			
			rows.in.protocol.categories <- vector()
      
			for( protocol in protocol.types){
			
						row.numbers <-	which(location.frames[[location]]$Date > date.ranges[[d]][1] & location.frames[[location]]$Date <= date.ranges[[d]][2] & grepl(protocol, location.frames[[location]]$Protocol))
					  
						if(length(row.numbers) >  0){ # if there are runs for that location, protocol and date range combo 
						
							## add row.numbers to a list of row numbers that will be used to make the "Other" protocol category 
							rows.in.protocol.categories <- c(rows.in.protocol.categories,  row.numbers)
						
							serial.numbers <- as.character(unique(location.frames[[location]]$SerialNo[row.numbers]))
							
							## get the data that will go into the plots AND add a row to rate.tables 
							cp.tables[[location]][[protocol]][[d]] <- lapply(serial.numbers, calculateRates, row.numbers, location, protocol, d)
							
							names(cp.tables[[location]][[protocol]][[d]]) <- serial.numbers
							
							## order the rows in the output data structure by highest overall failure rate -> lowest overall failure rate
							
							if(dim(rate.tables[[location]][[protocol]][[d]])[1] > 1 ){## if there is only one entry "Order" will throw an error 
									rate.tables[[location]][[protocol]][[d]] <- rate.tables[[location]][[protocol]][[d]][order(unlist(rate.tables[[location]][[protocol]][[d]][, 3]), decreasing=TRUE), ]
									
							}
							## convert the overall failure rates into strings 
							rate.tables[[location]][[protocol]][[d]][, 3] <- paste0(as.character(rate.tables[[location]][[protocol]][[d]][, 3]), "%")
					
								
							
						}
						
				} # protocols
			
			     ## now make the "Other" protocol category 
						
					  other.row.numbers <-	which(location.frames[[location]]$Date > date.ranges[[d]][1] & location.frames[[location]]$Date <= date.ranges[[d]][2])
					  other.row.numbers <- other.row.numbers[-which(other.row.numbers %in% as.vector(rows.in.protocol.categories))]
					  
		
						if(length(other.row.numbers) > 0){
								serial.numbers <- as.character(unique(location.frames[[location]]$SerialNo[other.row.numbers]))
								
								## get the data that will go into the plots AND add a row to rate.tables 
								cp.tables[[location]][["Other"]][[d]] <- lapply(serial.numbers, calculateRates, other.row.numbers, location, "Other", d)
								names(cp.tables[[location]][["Other"]][[d]]) <- serial.numbers
								
								
								## order the rows of the df by decending overall failure rate 
								if( dim(rate.tables[[location]][["Other"]][[d]])[1] > 1 ){ ## if there is only one entry "Order" will throw an error 
										rate.tables[[location]][["Other"]][[d]] <- rate.tables[[location]][["Other"]][[d]][order(unlist(rate.tables[[location]][["Other"]][[d]][, 3]), decreasing=TRUE), ]
								}
								## convert the overall failure rates into strings 
								
								rate.tables[[location]][["Other"]][[d]][, 3] <- paste0(as.character(rate.tables[[location]][["Other"]][[d]][, 3]), "%")
						
						}
					  
					  # now that everything is added to the all protocol types order them by hightest overall failure rate 
					  rate.tables[[location]][["All Except Custom"]][[d]] <- rate.tables[[location]][["All Except Custom"]][[d]][order(unlist(rate.tables[[location]][["All Except Custom"]][[d]][, 3]), decreasing=TRUE), ]
						rate.tables[[location]][["All"]][[d]] <- rate.tables[[location]][["All"]][[d]][order(unlist(rate.tables[[location]][["All"]][[d]][, 3]), decreasing=TRUE), ]
						
						# now that everything is added to the all protocol types convert the overall failure rate to strings 
						rate.tables[[location]][["All"]][[d]][, 3] <- paste0(as.character(rate.tables[[location]][["All"]][[d]][, 3]), "%")
						rate.tables[[location]][["All Except Custom"]][[d]][, 3] <- paste0(as.character(rate.tables[[location]][["All Except Custom"]][[d]][, 3]), "%")
					  
					  
		} # date ranges  
} # locations 




print("rate tables created")


			
			
			
			
			   
			





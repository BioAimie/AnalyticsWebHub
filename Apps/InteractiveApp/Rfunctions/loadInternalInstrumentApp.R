

library(rJava)
library(xlsx)
library(RODBC)
library(lubridate)

#***************************************************
#******************* functions**********************
#***************************************************



makeVersionNames <- function(v){
	## inputs: an entry of the Version column of location.frames
	## outputs: a modified version of that string, just to make it more readable 
	## without this funcion the versions would just be "1", "2" or "3"
	for( k in names(version.names)){
		if(grepl(k, v)){
			return(gsub(k, version.names[[k]], v))	
		}
	}
	return(v)
	
}

fixWeekZero <- function(x){
	## inputs: a "year-week" date group from the overall.error.lablels vector
	## outputs: a new "year-week" date group that it is either the same or modified 
  ## This function is necessary because r makes a "2017-00" week group instead of "2016-52"
	
	if(grepl("-00", x)){
		
		 year <- as.character(as.numeric(substr(x, 4, 4)) - 1)
		 ret <- paste0(substr(x, 1,3), year, "-52")
		 return(ret)
	}else{
		
			return(x)	
	}
}

orderAllExceptCustomCpValues <- function( instrument, location, d){
	
	## inputs: serial number, locat, date
  ## outputs: none, re-order the columns in the cp table matrices so they are in chronological order 

	  if( dim(cp.tables[[location]][["All Except Custom"]][[d]][[instrument]])[2] > 1){ # if there is more than one column to order
				except.custom.order <- order(cp.tables[[location]][["All Except Custom"]][[d]][[instrument]][ 2,])
				cp.tables[[location]][["All Except Custom"]][[d]][[instrument]] <<- cp.tables[[location]][["All Except Custom"]][[d]][[instrument]][ , except.custom.order]
	  }
	  
}

orderAllCpValues <- function(instrument, location, d){
	
	## inputs: serial number, locat, date
  ## outputs: none, re-order the columns in the cp table matrices so they are in chronological order 

		if(dim(cp.tables[[location]][["All"]][[d]][[instrument]])[2] > 1){ # if there is more than one column to order 
				all.order <- order(cp.tables[[location]][["All"]][[d]][[instrument]][ 2,])
				cp.tables[[location]][["All"]][[d]][[instrument]] <<- cp.tables[[location]][["All"]][[d]][[instrument]][ , all.order]
		}
}


allProtocolsOverallErrorRate <- function(instrument, location, protocol.type, date.range){
	
		## inputs: matrix from the overall.error.rate.tables data structure
		## output: nothing, this function calculates rates for each instrument in each location after all the runs on that machine for location have been counted
	  ## after that, it pads the matrix with NA's so it will be the length of the # of weeks in the last year
		
		################## calculate the rates for the All and All Except Custom protocols ##################
		if(protocol.type == "All" || protocol.type == "All Except Custom"){ # convert the sums to rates for the All and All Except Protocol data tables 
				overall.error.rate.tables[[location]][[protocol.type]][[date.range]][[instrument]]$matrix[ , c(2,3,4,5)] <<- round((overall.error.rate.tables[[location]][[protocol.type]][[date.range]][[instrument]]$matrix[ , c(2,3,4,5)]/overall.error.rate.tables[[location]][[protocol.type]][[date.range]][[instrument]]$matrix[ ,6])*100, 2)  
		}
	
		######## now pad the data frames with NA's so they will all be the length of the # of weeks in the given date range #########
		temp.matrix <- matrix(ncol=5, nrow=length(weeks.for.padding[[date.range]]))
	  for(k in 2:6){


	  	temp.matrix[overall.error.rate.tables[[location]][[protocol.type]][[date.range]][[instrument]]$matrix[ , 1], k-1] <- overall.error.rate.tables[[location]][[protocol.type]][[date.range]][[instrument]]$matrix[, k]  
	  }
	  overall.error.rate.tables[[location]][[protocol.type]][[date.range]][[instrument]]$matrix <<- temp.matrix

	  ############## now re-shape it into a data frame ggplot can use #####################
	  temp.dataframe <- data.frame(matrix(ncol=4, nrow=nrow(overall.error.rate.tables[[location]][[protocol.type]][[date.range]][[instrument]]$matrix)*4))
	  colnames(temp.dataframe) <- c("Date", "Percentage", "FailureType", "RunCounts")
	  number.weeks <- nrow(overall.error.rate.tables[[location]][[protocol.type]][[date.range]][[instrument]]$matrix)
	  temp.dataframe$Date <- rep(seq(1, number.weeks, 1), 4)
	  temp.dataframe$Percentage <- c(overall.error.rate.tables[[location]][[protocol.type]][[date.range]][[instrument]]$matrix[ ,1], overall.error.rate.tables[[location]][[protocol.type]][[date.range]][[instrument]]$matrix[ , 2], overall.error.rate.tables[[location]][[protocol.type]][[date.range]][[instrument]]$matrix[ , 3], overall.error.rate.tables[[location]][[protocol.type]][[date.range]][[instrument]]$matrix[ , 4])
	  temp.dataframe$FailureType <- c(rep("Instrument Error", number.weeks), rep("Software Error", number.weeks), rep("PouchLeak", number.weeks), rep("Control Fails", number.weeks))  
		temp.dataframe$RunCounts <- rep(overall.error.rate.tables[[location]][[protocol.type]][[date.range]][[instrument]]$matrix[ ,5], 4)
	  
		### turn the zero percentages into NA's so the old version of R won't plot zeros
		temp.dataframe$Percentage[which(temp.dataframe$Percentage == 0)] <- NA
		overall.error.rate.tables[[location]][[protocol.type]][[date.range]][[instrument]]$matrix <<- temp.dataframe
	  
	   
	  
}


storeOverallErrorRate <- function(row.numbers, location, protocol, serial.num, date.range){
	
	  ## inputs: a list of relevant row numbers, the current location, protocol and serial number that was given to the apply function
	  ## outputs: none, this function either adds a row to overall.error.rate.tables or adds data into an existing row of overall.error.rate.tables 
	
		temp.location.frames <- location.frames[[location]][row.numbers, ]
		temp.location.frames$Date <- format(temp.location.frames$Date, format="%Y-%W")
		
		## if this is an All or All Except Custom protocol it should be handeled differently 
		if(protocol == "All"  || protocol == "All Except Custom"){
			  
				if(nrow(temp.location.frames) != 0){
					dates <- unique(temp.location.frames$Date)
				
					for(w in dates ){
							## group all the runs by week and then calculate the error rate for that week 
							
				 			week.sums <- as.vector(unlist(apply(temp.location.frames[which(temp.location.frames$Date == w), c("InstrumentError", "SoftwareError", "PouchLeak", "PCR2", "PCR1" ,"yeast")], 2, function(x)sum(x, na.rm=TRUE))))
							
				 			# squish all the controls together (pcr1, pcr2, yeast)
				 			control.sum <- sum(unlist(apply(temp.location.frames[which(temp.location.frames$Date == w), c("PouchLeak", "PCR2", "PCR1", "yeast")], 1, function(x)if(sum(x[2:4]) >= 1 & x[1] != 1){return(1)}else{return(0)})), na.rm=TRUE)
				 			
				 			week.sums <- c(week.sums[1], week.sums[2], week.sums[3], control.sum)
				 			if(w %in% overall.error.rate.tables[[location]][[protocol]][[date.range]][[serial.num]][["xlabels"]]){  #if another protocol already had data for this week, don't add a new row, just combine the rates
					     
				 					row.index <- which(overall.error.rate.tables[[location]][[protocol]][[date.range]][[serial.num]][["matrix"]][ ,1] == which( weeks.for.padding[[date.range]] == w ))
				 					overall.error.rate.tables[[location]][[protocol]][[date.range]][[serial.num]][["matrix"]][row.index, c(2,3,4,5,6)] <<- overall.error.rate.tables[[location]][[protocol]][[date.range]][[serial.num]][["matrix"]][row.index, c(2,3,4,5,6)] + c(week.sums, length(which(temp.location.frames$Date == w)))
										
				 			}else{ # if this is the first time we're seeing this week, add a new row for it 
				 					
				 					overall.error.rate.tables[[location]][[protocol]][[date.range]][[serial.num]]$xlabels <<- c(overall.error.rate.tables[[location]][[protocol]][[date.range]][[serial.num]]$xlabels, w)
				 					date.row <- which(weeks.for.padding[[date.range]] == w)
				 					overall.error.rate.tables[[location]][[protocol]][[date.range]][[serial.num]][["matrix"]] <<- rbind(overall.error.rate.tables[[location]][[protocol]][[date.range]][[serial.num]][["matrix"]], c(date.row, week.sums, length(which(temp.location.frames$Date == w))))
				 					
				 			}
					}
						## now that the table is created, re order the rows/xlabels to be the chronological order 
					if(length(overall.error.rate.tables[[location]][[protocol]][[serial.num]][["xlabels"]]) > 1){
			 				correct.order <- order(unlist(lapply(overall.error.rate.tables[[location]][[protocol]][[serial.num]][["xlabels"]], function(x)as.Date(paste("1", substr(x,6,7), substr(x,1,4) , sep = "-"), format = "%w-%W-%Y"))))
			 				overall.error.rate.tables[[location]][[protocol]][[date.range]][[serial.num]][["xlabels"]]	<<- overall.error.rate.tables[[location]][[protocol]][[date.range]][[serial.num]][["xlabels"]][correct.order]
				 			overall.error.rate.tables[[location]][[protocol]][[date.range]][[serial.num]][["matrix"]] <<- overall.error.rate.tables[[location]][[protocol]][[date.range]][[serial.num]][["matrix"]][correct.order, ]
					}
				
			}	## if everything isn't empty
			
			
			
		## if this is not  all or all except custom protocol 	
		}else{
		
			if(nrow(temp.location.frames) != 0){
				dates <- unique(temp.location.frames$Date)
				
				for(w in dates ){
						week.rates <- as.vector(unlist(apply(temp.location.frames[which(temp.location.frames$Date == w), c("InstrumentError", "SoftwareError", "PouchLeak")], 2, function(x)round((sum(x, na.rm=TRUE)/length(x))*100,2))))
						control.sum <- sum(unlist(apply(temp.location.frames[which(temp.location.frames$Date == w), c("PouchLeak", "PCR2", "PCR1", "yeast")], 1, function(x)if(sum(x[2:4]) >= 1 &  x[1] != 1){return(1)}else{return(0)})), na.rm=TRUE)
						
						control.sum <- round((control.sum/length(which(temp.location.frames$Date == w)))*100, 2) 
				 		
				 		week.rates <- c(week.rates, control.sum)

				 		date.row <- which( weeks.for.padding[[date.range]] == w)
						overall.error.rate.tables[[location]][[protocol]][[date.range]][[serial.num]][["matrix"]] <<- rbind(overall.error.rate.tables[[location]][[protocol]][[date.range]][[serial.num]][["matrix"]], c( date.row, week.rates,length(which(temp.location.frames$Date == w))))
				}
			
				overall.error.rate.tables[[location]][[protocol]][[date.range]][[serial.num]][["xlabels"]] <<- dates
			
				}	
		
   } ## else this wasn't an all or all except custom protocol 
		
}   
   

   
calculateRates <- function(x, all.row.Numbers, l, p, d){
		## input: a serial number and a list of row numbers and the location, protocol, date range
		## output: add a row to the rate.tables data structure, return CP values for cp.tables, and add a table to the overall.error.rate.tables  
		
		x.row.numbers <- all.row.Numbers[which(location.frames[[l]]$SerialNo[all.row.Numbers] == x)] ## all the row number for the relevent runs on instrument x 
		
		version <- location.frames[[l]][x.row.numbers[1], "Version"]
		################# overall error rate tables #######################
	
			
		storeOverallErrorRate(x.row.numbers, l, p, x, d)	
				
		if(p != "Custom"){
			storeOverallErrorRate(x.row.numbers, l, "All Except Custom", x, d)
		}
		storeOverallErrorRate(x.row.numbers, l, "All", x, d)
				
		#}
	  ####################################################################
		
		# calculate the different types of failure rates 
		instrument.rate <- round((sum(location.frames[[l]][ x.row.numbers, "InstrumentError"])/length(location.frames[[l]][ x.row.numbers, "InstrumentError"])), 3)
		software.rate <- round((sum(location.frames[[l]][ x.row.numbers, "SoftwareError"])/length(location.frames[[l]][ x.row.numbers, "SoftwareError"])), 3)
		pcr2.rate <- round((sum(location.frames[[l]][ x.row.numbers, "PCR2"])/length(location.frames[[l]][ x.row.numbers, "PCR2"])), 3)
		pcr1.rate <-round((sum(location.frames[[l]][ x.row.numbers, "PCR1"])/length(location.frames[[l]][ x.row.numbers, "PCR1"])), 3)
		yeast.rate <- round((sum(location.frames[[l]][ x.row.numbers, "yeast"])/length(location.frames[[l]][ x.row.numbers, "yeast"])), 3)
		pouchleak.rate <- round((sum(location.frames[[l]][ x.row.numbers, "PouchLeak"])/length(location.frames[[l]][ x.row.numbers, "PouchLeak"])), 3) 
	
		total.rate.numerator <- sum(unlist(lapply(x.row.numbers, function(k)if(sum(location.frames[[l]][k, c("InstrumentError", "SoftwareError", "PouchLeak", "PCR1", "PCR2", "yeast")]) > 0){return(1)}else{return(0)})))
		total.rate <- round((total.rate.numerator/length(x.row.numbers)), 3)
		
		##################### put data into rate.tables ################################
		# add the rates to the "All" protocol category in rate.tables
		if(p != "Custom"){
			if(x %in% unlist(rate.tables[[l]][["All Except Custom"]][[d]][ , 1])){ #if this machine was alredady added in a previously processed protocol 
					row.num <- which(unlist(rate.tables[[l]][["All Except Custom"]][[d]][ , 1]) == x)
					number.runs <- unlist(unname(rate.tables[[l]][["All Except Custom"]][[d]][ row.num, 3]))
					error.run.counts <- round((unlist(unname(rate.tables[[l]][["All Except Custom"]][[d]][row.num, c(4 ,5 ,6,7, 8, 9, 10) ])))*number.runs)
					new.number.runs <- length(x.row.numbers)+ number.runs
					new.total.rate <- round(((error.run.counts[1] + total.rate.numerator)/new.number.runs), 3)  
					new.instrument.error <- round(((error.run.counts[2]+ sum(location.frames[[l]][ x.row.numbers, "InstrumentError"]))/new.number.runs), 3)
					new.software.error <-  round(((error.run.counts[3]+ sum(location.frames[[l]][ x.row.numbers, "SoftwareError"]))/new.number.runs), 3)
					new.pcr1.error <- round(((error.run.counts[4]+ sum(location.frames[[l]][ x.row.numbers, "PCR1"]))/new.number.runs), 3)
					new.pcr2.error <- round(((error.run.counts[5]+ sum(location.frames[[l]][ x.row.numbers, "PCR2"]))/new.number.runs), 3)
					new.yeast.error <- round(((error.run.counts[6]+ sum(location.frames[[l]][ x.row.numbers, "yeast"]))/new.number.runs), 3)
					new.pouchleak <- round(((error.run.counts[7]+ sum(location.frames[[l]][ x.row.numbers, "PouchLeak"]))/new.number.runs), 3)
					rate.tables[[l]][["All Except Custom"]][[d]][row.num, c(3 ,4 ,5 ,6,7, 8, 9, 10) ] <<-  c(new.number.runs, new.total.rate, new.instrument.error, new.software.error, new.pcr1.error, new.pcr2.error, new.yeast.error, new.pouchleak)  # num of runs
					
			}else{ # if this machine was not previously added, then make a new row for it 
					rate.tables[[l]][["All Except Custom"]][[d]] <<- rbind(rate.tables[[l]][["All Except Custom"]][[d]], list("Instrument Serial Number" = x , "Version"=version, "# of runs"= length(x.row.numbers), "fraction of runs with at least one error" =  total.rate, "Instrument Failure Rate" = instrument.rate, 
						"Software Failure Rate"=software.rate, "PCR1 Negative Rate"=pcr1.rate, "PCR2 Negative Rate"=pcr2.rate, "yeast Negative Rate" =yeast.rate, "Pouch Leak Rate"=pouchleak.rate))

			}	
		}
		
		
		if(x %in% unlist(rate.tables[[l]][["All"]][[d]][ , 1])){
					
					row.num <- which(unlist(rate.tables[[l]][["All"]][[d]][ , 1]) == x)
					number.runs <- unlist(unname(rate.tables[[l]][["All"]][[d]][ row.num, 3]))
					error.run.counts <- round((unlist(unname(rate.tables[[l]][["All"]][[d]][row.num, c(4 ,5 ,6, 7, 8, 9, 10) ])))*number.runs)
					new.number.runs <- length(x.row.numbers)+ number.runs
					new.total.rate <- round(((error.run.counts[1] + total.rate.numerator)/new.number.runs), 3)  
					new.instrument.error <- round(((error.run.counts[2]+ sum(location.frames[[l]][ x.row.numbers, "InstrumentError"]))/new.number.runs), 3)
					new.software.error <-  round(((error.run.counts[3]+ sum(location.frames[[l]][ x.row.numbers, "SoftwareError"]))/new.number.runs), 3)
					new.pcr1.error <- round(((error.run.counts[4]+ sum(location.frames[[l]][ x.row.numbers, "PCR1"]))/new.number.runs), 3)
					new.pcr2.error <- round(((error.run.counts[5]+ sum(location.frames[[l]][ x.row.numbers, "PCR2"]))/new.number.runs), 3)
					new.yeast.error <- round(((error.run.counts[6]+ sum(location.frames[[l]][ x.row.numbers, "yeast"]))/new.number.runs),3 )
					new.pouchleak <- round(((error.run.counts[7]+ sum(location.frames[[l]][ x.row.numbers, "PouchLeak"]))/new.number.runs), 3)
					rate.tables[[l]][["All"]][[d]][row.num, c(3 ,4 ,5 ,6, 7, 8, 9, 10) ] <<-  c(new.number.runs, new.total.rate, new.instrument.error, new.software.error, new.pcr1.error, new.pcr2.error, new.yeast.error, new.pouchleak)  # num of runs
		
		}else{
				rate.tables[[l]][["All"]][[d]] <<- rbind(rate.tables[[l]][["All"]][[d]], list("Instrument Serial Number" = x ,"Version"=version, "# of runs"= length(x.row.numbers), "fraction of runs with at least one error" =  total.rate, "Instrument Failure Rate" = instrument.rate, 
						"Software Failure Rate"=software.rate, "PCR1 Negative Rate"=pcr1.rate, "PCR2 Negative Rate"=pcr2.rate, "yeast Negative Rate" =yeast.rate, "Pouch Leak Rate"=pouchleak.rate))

		}


		# add the rates to rate.tables for the protocol that is being processed right now  
		rate.tables[[l]][[p]][[d]] <<- rbind(rate.tables[[l]][[p]][[d]], list("Instrument Serial Number" = x , "Version"=version, "# of runs"= length(x.row.numbers), "fraction of runs with at least one error" =  total.rate, "Instrument Failure Rate" = instrument.rate, 
			"Software Failure Rate"=software.rate,"PCR1 Negative Rate"=pcr1.rate, "PCR2 Negative Rate"=pcr2.rate, "yeast Negative Rate" =yeast.rate , "Pouch Leak Rate"=pouchleak.rate))

			
    ################################## put data into cp tables ###############################
		
		if( p != "Custom" & !is.null(cp.tables[[l]][["All Except Custom"]][[d]][[x]])){ # if this matrix has already been initialized in another protocol 
			
			  new.rows <- data.frame(matrix(nrow=length(x.row.numbers)*2, ncol=3))
			  colnames(new.rows) <- c("Date", "Values", "Key")
				new.rows[, 1] <- as.POSIXct(location.frames[[l]][x.row.numbers, "Date"], origin-"1970-01-01")
				new.rows[, 2] <- c(location.frames[[l]][x.row.numbers, "Cp"], location.frames[[l]][x.row.numbers, "Tm"]) 
				new.rows[, 3] <- c(rep( "Cp", length(x.row.numbers)), rep("Tm", length(x.row.numbers)))
			
				cp.tables[[l]][["All Except Custom"]][[d]][[x]] <<- rbind(cp.tables[[l]][["All Except Custom"]][[d]][[x]], new.rows)
			
		}else if(p != "Custom"){
			
			  first.rows <- data.frame(matrix(nrow=length(x.row.numbers)*2, ncol=3))
			  colnames(first.rows) <- c("Date", "Values", "Key")
				first.rows[, 1] <- as.POSIXct(location.frames[[l]][x.row.numbers, "Date"], origin-"1970-01-01")
				first.rows[, 2] <- c(location.frames[[l]][x.row.numbers, "Cp"], location.frames[[l]][x.row.numbers, "Tm"]) 
				first.rows[, 3] <- c(rep( "Cp", length(x.row.numbers)), rep("Tm", length(x.row.numbers)))
				
			  cp.tables[[l]][["All Except Custom"]][[d]][[x]] <<- first.rows
		}
		
		
		if(!is.null(cp.tables[[l]][["All"]][[d]][[x]])){ ## if this matrix has already been initialized in another protocol 
				
				new.rows <- data.frame(matrix(nrow=length(x.row.numbers)*2, ncol=3))
			  colnames(new.rows) <- c("Date", "Values", "Key")
				new.rows[, 1] <- as.POSIXct(location.frames[[l]][x.row.numbers, "Date"], origin-"1970-01-01")
				new.rows[, 2] <- c(location.frames[[l]][x.row.numbers, "Cp"], location.frames[[l]][x.row.numbers, "Tm"]) 
				new.rows[, 3] <- c(rep( "Cp", length(x.row.numbers)), rep("Tm", length(x.row.numbers)))
				
				cp.tables[[l]][["All"]][[d]][[x]] <<- rbind(cp.tables[[l]][["All"]][[d]][[x]], new.rows)


		}else{
			
				first.rows <- data.frame(matrix(nrow=length(x.row.numbers)*2, ncol=3))
			  colnames(first.rows) <- c("Date", "Values", "Key")
				first.rows[, 1] <- as.POSIXct(location.frames[[l]][x.row.numbers, "Date"], origin-"1970-01-01")
				first.rows[, 2] <- c(location.frames[[l]][x.row.numbers, "Cp"], location.frames[[l]][x.row.numbers, "Tm"]) 
				first.rows[, 3] <- c(rep( "Cp", length(x.row.numbers)), rep("Tm", length(x.row.numbers)))
				#first.rows$Values[which(first.rows$Values[1:length(x.row.numbers)] == 40)] <- NA
			  cp.tables[[l]][["All"]][[d]][[x]] <<- first.rows
					
			
		}
		
		## now return the cp data for the non-all/all except custom protocols 
		output <- data.frame(matrix(nrow=length(x.row.numbers)*2, ncol=3))
		colnames(output) <- c("Date", "Values", "Key")
		output[, 1] <- as.POSIXct(location.frames[[l]][x.row.numbers, "Date"], origin-"1970-01-01")
		output[, 2] <- c(location.frames[[l]][x.row.numbers, "Cp"], location.frames[[l]][x.row.numbers, "Tm"]) 
		output[, 3] <- c(rep( "Cp", length(x.row.numbers)), rep("Tm", length(x.row.numbers)))
		#output$Values[which(output$Values[1:length(x.row.numbers)] == 40)] <- NA
		
		return(output)
  
			
}

 
#**********************************************************************************************
#********************** initialize variables/data structures **********************************
#**********************************************************************************************

### get the dungeon instrument serial numbers 

FA.Instruments <- read.xlsx("\\\\Filer01/Data/Departments\\BioChem\\BioChem1_Shared\\Lab Management\\Instruments\\FA Instruments.xlsx", 1)
dungeon.instrument.serial.numbers <- as.vector(FA.Instruments$Instrument[which(FA.Instruments$Owner == "IDATEC")])
dungeon.instrument.serial.numbers <- paste(dungeon.instrument.serial.numbers, collapse="', '")
dungeon.instrument.serial.numbers <- paste0("( '", dungeon.instrument.serial.numbers, "') ")

### scan in the SQL queries 
dungeon.query <- gsub('serialnumbervector', dungeon.instrument.serial.numbers, paste(scan("SQL\\dungeon_instruments.txt",what=character(),quote=""), collapse=' '))   
pouch.qc.query <- paste(scan("SQL\\pouch_qc_instruments.txt",what=character(),quote=""), collapse=" ")

location.frames <<- list()

print("running sql queries..")

PMScxn <- odbcConnect("PMS_PROD")


location.frames[["dungeon"]] <- sqlQuery(PMScxn, dungeon.query)
location.frames[["pouchqc"]] <- sqlQuery(PMScxn, pouch.qc.query)


odbcClose(PMScxn)


print("sql queries completed")

print("creating rate tables...")

## figure out what protocols should be listed in the drop down 

protocol.types <- c("NPS", "Stool", "BC", "CSF", "QC", "BT", "LRTI", "NGDS", "BJI", "Custom")


## make the LastServiceDate column an actual date
location.frames[["pouchqc"]]$LastServiceDate <- as.POSIXct(location.frames[["pouchqc"]]$LastServiceDate)
location.frames[["dungeon"]]$LastServiceDate <- as.POSIXct(location.frames[["dungeon"]]$LastServiceDate)
## make the "Version" column  of location.frames more understandable 
version.names <<- list("1"="1.5", "2"="2.0", "3"="Torch")
location.frames[["pouchqc"]]$Version <- unlist(lapply(location.frames[["pouchqc"]]$Version, makeVersionNames))
location.frames[["dungeon"]]$Version <- unlist(lapply(location.frames[["dungeon"]]$Version, makeVersionNames))



## initialize the output data structue that holds the information to go in the data tables 
rate.tables <<- list()

for( l in c("dungeon" , "pouchqc")){ # first layer, locations 
	
	rate.tables[[l]] <- list()
	for( p in c(protocol.types, "Other")){ # second layer, protocol types
		
		rate.tables[[l]][[p]] <- list("7"=list(), "30"=list(), "90"=list(), "360"=list()) # third layer, date rages
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

overall.error.rate.tables <<- list()

for( l in c("dungeon", "pouchqc")){ # first layer, locations 
	
	overall.error.rate.tables[[l]] <- list()
	for( p in c(protocol.types, "Other")){ # second layer, protocol types
		
		overall.error.rate.tables[[l]][[p]] <- list("7"=list(), "30"=list(), "90"=list(), "360"=list()) ## this list will be for serial numbers 
	}
}


## calculate the date ranges for "today"
today <- as.POSIXct(Sys.Date(), origin="1970-01-01") + 30*60*60
date.ranges <- list()
date.ranges[["7"]] <- c(seq(today, length=2, by="-1 week")[2], today)
date.ranges[["7"]][1] <- date.ranges[["7"]][1] - 22*60*60
date.ranges[["30"]] <- c(seq(today, length=2, by="-1 month")[2], today)
date.ranges[["30"]][1] <- date.ranges[["30"]][1] - 22*60*60
date.ranges[["90"]] <- c(seq(today, length=2, by="-3 months")[2], today)
date.ranges[["90"]][1] <- date.ranges[["90"]][1] - 22*60*60
date.ranges[["360"]] <- c(seq(today, length=2, by="-1 year")[2], today)
date.ranges[["360"]][1] <- date.ranges[["360"]][1] - 22*60*60

## make the lables that will go on the overall error rate plots 

overall.error.labels <<- unlist(lapply(unique(c(format(seq(date.ranges[["360"]][1], today, by="1 week"), format="%Y-%W"), format(today, format="%Y-%W"))), fixWeekZero))
weeks.for.padding <<- list()


for( d in c("7", "30", "90", "360")){
	
	weeks.for.padding[[d]] <- unique(unlist(lapply(format(seq(date.ranges[[d]][1], date.ranges[[d]][2], by="1 day"), format="%Y-%W"), fixWeekZero)))
	
}



#****************************************************************************************
#****************************** fill up the output data structures **********************
#****************************************************************************************



for( location in c("dungeon", "pouchqc")){
	
	  print(location)
		for( d in c("7", "30", "90", "360")){
		
			rows.in.protocol.categories <- vector()
      
			for( protocol in protocol.types){
            
				    if(protocol != "Custom"){ # handel the cases where a protocol has "Custom" and another protocol type in the title (if it has both classify it as "Custom")
				    	
				    		row.numbers <-	which(location.frames[[location]]$Date > date.ranges[[d]][1] & location.frames[[location]]$Date <= date.ranges[[d]][2] & grepl(protocol, location.frames[[location]]$Protocol) & !grepl("Custom", location.frames[[location]]$Protocol) )
				    }else{
				    		row.numbers <-	which(location.frames[[location]]$Date > date.ranges[[d]][1] & location.frames[[location]]$Date <= date.ranges[[d]][2] & grepl(protocol, location.frames[[location]]$Protocol))
				    }
						
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

						}
				
			
				######### re-format the rate.tables so that the shiny row sort function will work ###########
				rate.tables[[location]][[protocol]][[d]] <- as.data.frame(rate.tables[[location]][[protocol]][[d]])
			  for(c in colnames(rate.tables[[location]][[protocol]][[d]])){
			  			rate.tables[[location]][[protocol]][[d]][[c]] <- unlist(rate.tables[[location]][[protocol]][[d]][[c]])
			  	}
				} # protocols
			
			     ## now make the "Other" protocol category 
						
					  other.row.numbers <-	which(location.frames[[location]]$Date > date.ranges[[d]][1] & location.frames[[location]]$Date <= date.ranges[[d]][2])
					  other.row.numbers <- other.row.numbers[-which(other.row.numbers %in% as.vector(rows.in.protocol.categories))]
					  
		
						if(length(other.row.numbers) > 0){
								serial.numbers <- as.character(unique(location.frames[[location]]$SerialNo[other.row.numbers]))
								
								## call calculateRates
								cp.tables[[location]][["Other"]][[d]] <- lapply(serial.numbers, calculateRates, other.row.numbers, location, "Other", d)
								names(cp.tables[[location]][["Other"]][[d]]) <- serial.numbers
								
								
								## order the rows of the df by decending overall failure rate 
								if( dim(rate.tables[[location]][["Other"]][[d]])[1] > 1 ){ ## if there is only one entry "Order" will throw an error 
										rate.tables[[location]][["Other"]][[d]] <- rate.tables[[location]][["Other"]][[d]][order(unlist(rate.tables[[location]][["Other"]][[d]][, 3]), decreasing=TRUE), ]
								}
								## convert the overall failure rates into strings 
								

						}
					  
					  # now that everything is added to the all protocol types in rate.tables order them by hightest overall failure rate 
					  if(!is.null(rate.tables[[location]][["All Except Custom"]][[d]][, 3])){
					  		rate.tables[[location]][["All Except Custom"]][[d]] <- rate.tables[[location]][["All Except Custom"]][[d]][order(unlist(rate.tables[[location]][["All Except Custom"]][[d]][, 3]), decreasing=TRUE), ]
					  }
					  if(!is.null(rate.tables[[location]][["All"]][[d]][, 3])){
					  		rate.tables[[location]][["All"]][[d]] <- rate.tables[[location]][["All"]][[d]][order(unlist(rate.tables[[location]][["All"]][[d]][, 3]), decreasing=TRUE), ]

					  }

						
					
						##################### re-order the cp values for the All and All Except Custom Protocols ###########################
						
						cp.instruments.except.custom <- names(cp.tables[[location]][["All Except Custom"]][[d]])
						cp.instruments.except.custom <- cp.instruments.except.custom[which(!is.na(cp.instruments.except.custom))]
						cp.instruments.all <- names(cp.tables[[location]][["All"]][[d]])
					  cp.instruments.all <- cp.instruments.all[which(!is.na(cp.instruments.all))]
						lapply(cp.instruments.except.custom, orderAllExceptCustomCpValues, location, d)
						lapply(cp.instruments.all, orderAllCpValues, location, d)
						
						
					  
		} # date ranges  
	  
	  ####### now do post processing on the overall.error.rate.tables so the ggplot will work ################
	 
	  
	  	for(dateRange in c("7", "30", "90", "360")){
	  		
	  		for( PROTOCOL in c("NPS", "Stool", "BC", "CSF", "QC", "BT", "LRTI", "NGDS", "BJI", "Custom","Other", "All", "All Except Custom")){
	  			instruments <- names(overall.error.rate.tables[[location]][[PROTOCOL]][[dateRange]])
	  			lapply(instruments, allProtocolsOverallErrorRate, location, PROTOCOL, dateRange)
	  	}
	  }
	  
		
	  ######### re-format the all/other protocol types in rate.tables so that the shiny row sort function will work ###########
		for( p in c("All", "All Except Custom", "Other")){
			for(date in c("7", "30", "90", "360")){
				rate.tables[[location]][[p]][[date]] <- as.data.frame(rate.tables[[location]][[p]][[date]])
			  for(c in colnames(rate.tables[[location]][[p]][[date]])){
			  			rate.tables[[location]][[p]][[date]][[c]] <- unlist(rate.tables[[location]][[p]][[date]][[c]])
			  }
					
			}
			
		}
	  
	  
} # locations 




print("data structures created")


			
			
			   
			





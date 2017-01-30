

library(rJava)
library(xlsx)
library(RODBC)
library(lubridate)

#source("Rfunctions/internal_instrument_overall_helper.R")




storeOverallErrorRate <- function(row.numbers, location, protocol, serial.num){
		print("here")
		temp.location.frames <- location.frames[[location]][row.numbers, ]
		temp.location.frames$Date <- format(temp.location.frames$Date, format="%Y-%W")
		
		## if this is an All or All Except Custom protocol it should be handeled differently 
		if(protocol == "All" || protocol == "All Except Custom"){
			  
				if(nrow(temp.location.frames) != 0){
					dates <- unique(temp.location.frames$Date)
				
					for(w in dates ){
				 			week.rates <- as.vector(unlist(apply(temp.location.frames[which(temp.location.frames$Date == w), c("InstrumentError", "SoftwareError", "PouchLeak", "PCR2", "PCR1" ,"yeastRNA")], 2, function(x)round((sum(x, na.rm=TRUE)/length(x))*100,2))))
						
				 			if(w %in% overall.error.rate.tables[[location]][[protocol]][[serial.num]][["xlabels"]]){  #if another protocol already had data for this week, don't add a new row, just add the rates
									row.index <- which(overall.error.rate.tables[[location]][[protocol]][[serial.num]][["matrix"]][ ,1] == which(overall.error.labels ==w ))
				 					overall.error.rate.tables[[location]][[protocol]][[serial.num]][["matrix"]][row.index, c(2,3,4,5,6,7)] <<- overall.error.rate.tables[[location]][[protocol]][[serial.num]][["matrix"]][row.index, c(2,3,4,5,6,7)] + week.rates
								
				 			}else{ # if this is the first time we're seeing this week 
				 					overall.error.rate.tables[[location]][[protocol]][[serial.num]][["matrix"]] <<- rbind(overall.error.rate.tables[[location]][[protocol]][[serial.num]][["matrix"]], c(which(overall.error.labels == w), week.rates))
				 						overall.error.rate.tables[[location]][[protocol]][[serial.num]]$xlabels <<- c(overall.error.rate.tables[[location]][[protocol]][[serial.num]]$xlabels, w)
							}
					}
						## now that the table is created, re order the rows/xlabels to be the chronological order 
					if(length(overall.error.rate.tables[[location]][[protocol]][[serial.num]][["xlabels"]]) > 1){
			 				correct.order <- order(unlist(lapply(overall.error.rate.tables[[location]][[protocol]][[serial.num]][["xlabels"]], function(x)as.Date(paste("1", substr(x,6,7), substr(x,1,4) , sep = "-"), format = "%w-%W-%Y"))))
			 				overall.error.rate.tables[[location]][[protocol]][[serial.num]][["xlabels"]]	<<- overall.error.rate.tables[[location]][[protocol]][[serial.num]][["xlabels"]][correct.order]
				 			overall.error.rate.tables[[location]][[protocol]][[serial.num]][["matrix"]] <<- overall.error.rate.tables[[location]][[protocol]][[serial.num]][["matrix"]][correct.order, ]
					}
				
			}	## if everything isn't empty
			
			
			
		 ## if this is not  all or all except custom protocol 	
		}else{
		
			if(nrow(temp.location.frames) != 0){
				dates <- unique(temp.location.frames$Date)
				for(w in dates ){
				 		week.rates <- as.vector(unlist(apply(temp.location.frames[which(temp.location.frames$Date == w), c("InstrumentError", "SoftwareError", "PouchLeak", "PCR2", "PCR1" ,"yeastRNA")], 2, function(x)round((sum(x, na.rm=TRUE)/length(x))*100,2))))
						
				 		overall.error.rate.tables[[location]][[protocol]][[serial.num]][["matrix"]] <<- rbind(overall.error.rate.tables[[location]][[protocol]][[serial.num]][["matrix"]], c(which(overall.error.labels == w), week.rates))
				}
			
				overall.error.rate.tables[[location]][[protocol]][[serial.num]][["xlabels"]] <<- dates
			
				}	
		
   } ## else this wasn't an all or all except custom protocol 
		
}   
    


#######################################################
################## Load In Data  ######################
#######################################################


### get the dungeon instrument serial numbers 

FA.Instruments <- read.xlsx("\\\\Filer01/Data/Departments\\BioChem\\BioChem1_Shared\\Lab Management\\Instruments\\FA Instruments.xlsx", 1)
dungeon.instrument.serial.numbers <- as.vector(FA.Instruments$Instrument[which(FA.Instruments$Owner == "IDATEC")])
dungeon.instrument.serial.numbers <- paste(dungeon.instrument.serial.numbers, collapse="', '")
dungeon.instrument.serial.numbers <- paste0("( '", dungeon.instrument.serial.numbers, "') ")

### scan in the SQL queries 
dungeon.query <- gsub('serialnumbervector', dungeon.instrument.serial.numbers, paste(scan("SQL\\dungeon_instruments.txt",what=character(),quote=""), collapse=' '))   
pouch.qc.query <- paste(scan("SQL\\pouch_qc_instruments.txt",what=character(),quote=""), collapse=" ")


# initialize the list that will hold the query results 
location.frames <<- vector(mode="list")

# execute the queries to retrieve the instrument data 
print("running sql queries...")

PMScxn <- odbcConnect("PMS_PROD")

location.frames[["dungeon"]] <- sqlQuery(PMScxn, dungeon.query)
location.frames[["pouchqc"]] <- sqlQuery(PMScxn, pouch.qc.query)


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

overall.error.rate.tables <<- list()

for( l in c("dungeon", "pouchqc")){ # first layer, locations 
	
	overall.error.rate.tables[[l]] <- list()
	for( p in c(protocol.types, "Other")){ # second layer, protocol types
		
		overall.error.rate.tables[[l]][[p]] <- list() ## this list will be for serial numbers 
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

overall.error.labels <<- rev(format(seq(today, length=53, by="-1 week"), format="%Y-%W"))


    
calculateRates <- function(x, all.row.Numbers, l, p, d){
		## input: a serial number and a list of row numbers and the location, protocol, date range
		## output: add a row to the rate.tables data structure, return CP values for cp.tables, and add a table to the overall.error.rate.tables  
		
		x.row.numbers <- all.row.Numbers[which(location.frames[[l]]$SerialNo[all.row.Numbers] == x)]
  	
		if(d == "360"){
				
				#storeOverallErrorRate(x.row.numbers, l, p, x)	
				#storeOverallErrorRate(x.row.numbers, l, "All", x)
				#if(p != "Custom"){
				#	storeOverallErrorRate(x.row.numbers, l, "All Except Custom", x)
				#}
		}
		
		# calculate the different types of failure rates 
		instrument.rate <- round((sum(location.frames[[l]][ x.row.numbers, "InstrumentError"])/length(location.frames[[l]][ x.row.numbers, "InstrumentError"]))*100, 2)
		software.rate <- round((sum(location.frames[[l]][ x.row.numbers, "SoftwareError"])/length(location.frames[[l]][ x.row.numbers, "SoftwareError"]))*100, 2)
		pcr2.rate <- round((sum(location.frames[[l]][ x.row.numbers, "PCR2"])/length(location.frames[[l]][ x.row.numbers, "PCR2"]))*100, 2)
		pcr1.rate <- round((sum(location.frames[[l]][ x.row.numbers, "PCR1"])/length(location.frames[[l]][ x.row.numbers, "PCR1"]))*100, 2)
		yeast.rate <- round((sum(location.frames[[l]][ x.row.numbers, "yeastRNA"])/length(location.frames[[l]][ x.row.numbers, "yeastRNA"]))*100, 2)
		pouchleak.rate <-round((sum(location.frames[[l]][ x.row.numbers, "PouchLeak"])/length(location.frames[[l]][ x.row.numbers, "PouchLeak"]))*100, 2) 
	
		#total.rate <-  round(sum(instrument.rate, software.rate, control.rate, pouchleak.rate, na.rm=TRUE), 2)
		total.rate.numerator <- sum(unlist(lapply(x.row.numbers, function(k)if(sum(location.frames[[l]][k, c("InstrumentError", "SoftwareError", "PouchLeak", "PCR1", "PCR2", "yeastRNA")]) > 0){return(1)}else{return(0)})))
		total.rate <- round((total.rate.numerator/length(x.row.numbers))*100, 2)
		
		# add the rates to the "All" protocol category in rate.tables
		if(p != "Custom"){
			if(x %in% unlist(rate.tables[[l]][["All Except Custom"]][[d]][ , 1])){ #if this machine was alredady added in a previously processed protocol 
					row.num <- which(unlist(rate.tables[[l]][["All Except Custom"]][[d]][ , 1]) == x)
					number.runs <- unlist(unname(rate.tables[[l]][["All Except Custom"]][[d]][ row.num, 2]))
					error.run.counts <- round((unlist(unname(rate.tables[[l]][["All Except Custom"]][[d]][row.num, c(3 ,4 ,5,6, 7, 8, 9) ]))/100)*number.runs)
					new.number.runs <- length(x.row.numbers)+ number.runs
					new.total.rate <- round(((error.run.counts[1] + total.rate.numerator)/new.number.runs)*100, 2)  
					new.instrument.error <- round(((error.run.counts[2]+ sum(location.frames[[l]][ x.row.numbers, "InstrumentError"]))/new.number.runs)*100, 2)
					new.software.error <-  round(((error.run.counts[3]+ sum(location.frames[[l]][ x.row.numbers, "SoftwareError"]))/new.number.runs)*100, 2)
					new.pcr1.error <- round(((error.run.counts[4]+ sum(location.frames[[l]][ x.row.numbers, "PCR1Error"]))/new.number.runs)*100, 2)
					new.pcr2.error <- round(((error.run.counts[5]+ sum(location.frames[[l]][ x.row.numbers, "PCR2Error"]))/new.number.runs)*100, 2)
					new.yeast.error <- round(((error.run.counts[6]+ sum(location.frames[[l]][ x.row.numbers, "yeastRNA"]))/new.number.runs)*100, 2)
					new.pouchleak <- round(((error.run.counts[7]+ sum(location.frames[[l]][ x.row.numbers, "PouchLeak"]))/new.number.runs)*100, 2)
					rate.tables[[l]][["All Except Custom"]][[d]][row.num, c(2 ,3 ,4 ,5,6, 7, 8, 9) ] <<-  c(new.number.runs, new.total.rate, new.instrument.error, new.software.error, new.pcr1.error, new.pcr2.error, new.yeast.error, new.pouchleak)  # num of runs
					
			}else{ # if this machine was not previously added, then make a new row for it 
					rate.tables[[l]][["All Except Custom"]][[d]] <<- rbind(rate.tables[[l]][["All Except Custom"]][[d]], list("Instrument Serial Number" = x , "# of runs"= length(x.row.numbers), "% of runs with at least one error" =  total.rate, "Instrument Failure Rate" = instrument.rate, 
						"Software Failure Rate"=software.rate, "PCR1 Negative Rate"=pcr1.rate, "PCR2 Negative Rate"=pcr2.rate, "yeastRNA Negative Rate" =yeast.rate, "Pouch Leak Rate"=pouchleak.rate))
			}	
		}
		
		
		if(x %in% unlist(rate.tables[[l]][["All"]][[d]][ , 1])){
					row.num <- which(unlist(rate.tables[[l]][["All"]][[d]][ , 1]) == x)
					number.runs <- unlist(unname(rate.tables[[l]][["All"]][[d]][ row.num, 2]))
					error.run.counts <- round((unlist(unname(rate.tables[[l]][["All"]][[d]][row.num, c(3 ,4 ,5,6, 7, 8, 9) ]))/100)*number.runs)
					new.number.runs <- length(x.row.numbers)+ number.runs
					new.total.rate <- round(((error.run.counts[1] + total.rate.numerator)/new.number.runs)*100, 2)  
					new.instrument.error <- round(((error.run.counts[2]+ sum(location.frames[[l]][ x.row.numbers, "InstrumentError"]))/new.number.runs)*100, 2)
					new.software.error <-  round(((error.run.counts[3]+ sum(location.frames[[l]][ x.row.numbers, "SoftwareError"]))/new.number.runs)*100, 2)
					new.pcr1.error <- round(((error.run.counts[4]+ sum(location.frames[[l]][ x.row.numbers, "PCR1Error"]))/new.number.runs)*100, 2)
					new.pcr2.error <- round(((error.run.counts[5]+ sum(location.frames[[l]][ x.row.numbers, "PCR2Error"]))/new.number.runs)*100, 2)
					new.yeast.error <- round(((error.run.counts[6]+ sum(location.frames[[l]][ x.row.numbers, "yeastRNA"]))/new.number.runs)*100, 2)
					new.pouchleak <- round(((error.run.counts[7]+ sum(location.frames[[l]][ x.row.numbers, "PouchLeak"]))/new.number.runs)*100, 2)
					rate.tables[[l]][["All"]][[d]][row.num, c(2 ,3 ,4 ,5,6, 7, 8, 9) ] <<-  c(new.number.runs, new.total.rate, new.instrument.error, new.software.error, new.pcr1.error, new.pcr2.error, new.yeast.error, new.pouchleak)  # num of runs

		}else{
				rate.tables[[l]][["All"]][[d]] <<- rbind(rate.tables[[l]][["All"]][[d]], list("Instrument Serial Number" = x , "# of runs"= length(x.row.numbers), "% of runs with at least one error" =  total.rate, "Instrument Failure Rate" = instrument.rate, 
						"Software Failure Rate"=software.rate, "PCR1 Negative Rate"=pcr1.rate, "PCR2 Negative Rate"=pcr2.rate, "yeastRNA Negative Rate" =yeast.rate, "Pouch Leak Rate"=pouchleak.rate))
		}

		# convert them into strings 
		instrument.rate <- paste0(as.character(instrument.rate), "%")
  	software.rate <- paste0(as.character(software.rate), "%")
		pcr1.rate <- paste0(as.character(pcr1.rate), "%")
		pcr2.rate <- paste0(as.character(pcr2.rate), "%")
		yeast.rate <- paste0(as.character(yeast.rate), "%")
		pouchleak.rate <- paste0(as.character(pouchleak.rate), "%")
	
		# add the rates to rate.tables 
		rate.tables[[l]][[p]][[d]] <<- rbind(rate.tables[[l]][[p]][[d]], list("Instrument Serial Number" = x , "# of runs"= length(x.row.numbers), "% of runs with at least one error" =  total.rate, "Instrument Failure Rate" = instrument.rate, 
			"Software Failure Rate"=software.rate,"PCR1 Negative Rate"=pcr1.rate, "PCR2 Negative Rate"=pcr2.rate, "yeastRNA Negative Rate" =yeast.rate , "Pouch Leak Rate"=pouchleak.rate))
	
			

		## now return the CP data
		output <- matrix(ncol=length(x.row.numbers), nrow=2)
		output[1, ] <- location.frames[[l]][x.row.numbers, "Cp"] 
		output[2, ] <- as.POSIXct(location.frames[[l]][x.row.numbers, "Date"], origin-"1970-01-01")
		
		output[which(output == 40)] <- NA
		
		return(output)
  
			
}



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
						rate.tables[[location]][["All"]][[d]][, c(3, 4, 5, 6, 7, 8, 9)] <- paste0(as.character(rate.tables[[location]][["All"]][[d]][, c(3, 4, 5, 6, 7, 8, 9)]), "%")
						rate.tables[[location]][["All Except Custom"]][[d]][, c(3, 4, 5, 6, 7 ,8 ,9)] <- paste0(as.character(rate.tables[[location]][["All Except Custom"]][[d]][, c(3, 4, 5, 6 ,7, 8, 9)]), "%")
					  
					  
		} # date ranges  
} # locations 



print("rate tables created")


			
			
			
			
			   
			





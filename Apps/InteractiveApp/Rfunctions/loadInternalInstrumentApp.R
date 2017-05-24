

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


calcWeekErrorRateQC <- function(datesSubset){
	# inputs: a subset of sorted.tables
	# output: a data frame with the date, failure percentage and failure type to go into the overall error plots in the modal 
	output.df <- data.frame(Date=character(),
													Percentage=numeric(),
													FailureType=character())
	datesSubset$Date <- format(datesSubset$Date, format="%Y-%W")
	week.groups <- unique(datesSubset$Date)
	error.types <- c("InstrumentError", "SoftwareError", "PouchLeak", "Anomaly", "ControlFail")
	for(w in week.groups ){
		
		# group all the runs by week and then calculate the error rate for that week 
		number.runs <- length(which(datesSubset$Date == w))
		week.rates <- as.vector(unlist(apply(datesSubset[which(datesSubset$Date == w), c("InstrumentError", "SoftwareError", "PouchLeak", "Anomaly")], 2, function(x)sum(x, na.rm=TRUE))))
						
		# squish all the controls together 
		control.rate <- sum(unlist(apply(datesSubset[which(datesSubset$Date == w), c("PouchLeak", "PCR2", "PCR1", "yeast")], 1, function(x)if(sum(x[2:4]) >= 1 & x[1] != 1){return(1)}else{return(0)})), na.rm=TRUE)
		week.rates <- round((c(week.rates, control.rate)/number.runs)*100, 2)
		thisWeek.df <- do.call("rbind", lapply(seq(1, length(week.rates), 1), function(x)return(c(w, week.rates[x], error.types[x]))))
		output.df <- rbind(output.df, thisWeek.df)
	}
	
	colnames(output.df) <- c("Date", "Percentage", "FailureType")
	output.df$Percentage <- as.numeric(as.character(output.df$Percentage))
	output.df$Percentage[which(output.df$Percentage == 0)] <- NA
	print(output.df)
	return(output.df)
}


calcWeekErrorRateDungeon <- function(datesSubset){
	# inputs: a subset of sorted.tables
	# output: a data frame with the date, failure percentage and failure type to go into the overall error plots in the modal
	output.df <- data.frame(Date=character(),
													Percentage=numeric(),
													FailureType=character())

	datesSubset$Date <- format(datesSubset$Date, format="%Y-%W")
	week.groups <- unique(datesSubset$Date)
	error.types <- c("InstrumentError", "SoftwareError", "PouchLeak", "ControlFail")
	for(w in week.groups ){
		
		# count the the runs that were in week w
		number.runs <- length(which(datesSubset$Date == w))
		week.rates <- as.vector(unlist(apply(datesSubset[which(datesSubset$Date == w), c("InstrumentError", "SoftwareError", "PouchLeak")], 2, function(x)return(sum(x, na.rm=TRUE)))))
		
		# squish all the controls together 
		control.rate <- sum(unlist(apply(datesSubset[which(datesSubset$Date == w), c("PouchLeak", "PCR2", "PCR1", "yeast")], 1, function(x)if(sum(x[2:4]) >= 1 & x[1] != 1){return(1)}else{return(0)})), na.rm=TRUE)
		week.rates <- round((c(week.rates, control.rate)/number.runs)*100, 2)
		thisWeek.df <- do.call("rbind", lapply(seq(1, length(week.rates), 1), function(x)return(c(w, week.rates[x], error.types[x]))))
		output.df <- rbind(output.df, thisWeek.df)
	}

	colnames(output.df) <- c("Date", "Percentage", "FailureType")
	output.df$Percentage <- as.numeric(as.character(output.df$Percentage))
	output.df$Percentage[which(output.df$Percentage == 0)] <- NA
	print(output.df)
	return(output.df)
}



calculateRatesQC <- function(serial.num, dataFrameSN, version){
	# input: a serial number, the data frame given to createRateTable, and the instrument version 
	# output: a row off the data frame of rates 
	
	dataFrameSN <- subset(dataFrameSN, SerialNo == serial.num)
	version <- dataFrameSN$Version[1]
	nrows <- nrow(dataFrameSN)
	instrument.rate <- round((sum(dataFrameSN[, "InstrumentError"], na.rm=TRUE)/nrows), 3)
	software.rate <- round((sum(dataFrameSN[, "SoftwareError"], na.rm=TRUE)/nrows), 3)
	pcr2.rate <- round((sum(dataFrameSN[, "PCR2"], na.rm=TRUE)/nrows), 3)
	pcr1.rate <-round((sum(dataFrameSN[, "PCR1"], na.rm=TRUE)/nrows), 3)
	yeast.rate <- round((sum(dataFrameSN[, "yeast"], na.rm=TRUE)/nrows), 3)
	pouchleak.rate <- round((sum(dataFrameSN[, "PouchLeak"], na.rm=TRUE)/nrows), 3)
	anomaly.rate <- round((sum(dataFrameSN[, "Anomaly"], na.rm=TRUE)/nrows), 3)
	total.rate.numerator <- sum(apply(dataFrameSN, 1, function(k)if(sum(as.numeric(k[5]), as.numeric(k[6]), as.numeric(k[7]), as.numeric(k[8]), as.numeric(k[9]), as.numeric(k[10]), as.numeric(k[14]), na.rm=TRUE) > 0){return(1)}else{return(0)}))
	total.rate <- round((total.rate.numerator/nrows), 3)
	return(data.frame("1" = serial.num , "2"=version, "3"= nrow(dataFrameSN), "4" =  total.rate, "5" = instrument.rate, 
		"6"=software.rate,"7"=pcr1.rate, "8"=pcr2.rate, "9" =yeast.rate , "10"=pouchleak.rate, "11"=anomaly.rate))
}


calculateRatesDungeon <- function(serial.num, dataFrameSN, version){
	# input: a serial number, the data frame given to createRateTable, and the instrument version 
	# output: a row off the data frame of rates 
	
	dataFrameSN <- subset(dataFrameSN, SerialNo == serial.num)
	version <- dataFrameSN$Version[1]
	nrows <- nrow(dataFrameSN)
	instrument.rate <- round((sum(dataFrameSN[, "InstrumentError"], na.rm=TRUE)/nrows), 3)
	software.rate <- round((sum(dataFrameSN[, "SoftwareError"], na.rm=TRUE)/nrows), 3)
	pcr2.rate <- round((sum(dataFrameSN[, "PCR2"], na.rm=TRUE)/nrows), 3)
	pcr1.rate <-round((sum(dataFrameSN[, "PCR1"], na.rm=TRUE)/nrows), 3)
	yeast.rate <- round((sum(dataFrameSN[, "yeast"], na.rm=TRUE)/nrows), 3)
	pouchleak.rate <- round((sum(dataFrameSN[, "PouchLeak"], na.rm=TRUE)/nrows), 3)
	total.rate.numerator <- sum(apply(dataFrameSN, 1, function(k)if(sum(as.numeric(k[5]), as.numeric(k[6]), as.numeric(k[7]), as.numeric(k[8]), as.numeric(k[9]), as.numeric(k[10]), na.rm=TRUE) > 0){return(1)}else{return(0)}))
	total.rate <- round((total.rate.numerator/nrows), 3)
	return(data.frame("1" = serial.num , "2"=version, "3"= nrow(dataFrameSN), "4" =  total.rate, "5" = instrument.rate, 
		"6"=software.rate,"7"=pcr1.rate, "8"=pcr2.rate, "9" =yeast.rate , "10"=pouchleak.rate))
}


  
createRateTable <- function(dataFrame, date.start, date.stop, location){
	# input: a data frame from sorted.tables, a minimum date, a maximum date, the user selected location 
	# output: a a table of rates for all the relevant serial numbers 
	
	dataFrame <- subset(dataFrame, date.start <= Date & date.stop >= Date)
	serial.numbers <- as.character(unique(dataFrame$SerialNo))
	if(location == "dungeon"){
		rate.table <- do.call("rbind", lapply(serial.numbers, calculateRatesDungeon, dataFrame, version))
		rate.table <- rate.table[order(rate.table$X4, decreasing=TRUE), ]
	}else{
		rate.table <- do.call("rbind", lapply(serial.numbers, calculateRatesQC, dataFrame, version))
		rate.table <- rate.table[order(rate.table$X4, decreasing=TRUE), ]
	}

	return(rate.table)
}

 
#**********************************************************************************************
#********************** initialize variables/data structures **********************************
#**********************************************************************************************

### get the dungeon instrument serial numbers 

FA.Instruments <- read.xlsx("\\\\Filer01/Data/Departments\\BioChem\\BioChem1_Shared\\Lab Management\\Instruments\\FA Instruments.xlsx", 1)
dungeon.instrument.serial.numbers <- as.vector(FA.Instruments$Instrument[which(FA.Instruments$Owner == "IDATEC")])
dungeon.instrument.serial.numbers <- paste(dungeon.instrument.serial.numbers, collapse="', '")
dungeon.instrument.serial.numbers <- paste0("( '", dungeon.instrument.serial.numbers, "') ")

### read in the SQL queries 
dungeon.query <- gsub('serialnumbervector', dungeon.instrument.serial.numbers, paste(readLines('SQL\\dungeon_instruments.sql'), collapse=' '))   
pouch.qc.query <- readLines('SQL\\pouch_qc_instruments.sql')
pouch.qc.query <- paste(pouch.qc.query, collapse='\n')
anomaly.query <- paste(readLines("SQL\\anomaly_tables.sql"), collapse= " ")
pouch.leaks.query <- paste(readLines('SQL\\pouch_leaks.sql'), collapse=" ")
location.frames <<- list()

print("running sql queries..")

PMScxn <- odbcConnect("PMS_PROD")
location.frames[["dungeon"]] <- sqlQuery(PMScxn, dungeon.query)
location.frames[["pouchqc"]] <- sqlQuery(PMScxn, pouch.qc.query)
odbcClose(PMScxn)

postmarketscxn <- odbcConnect("postmarkets")
anomalies <- sqlQuery(postmarketscxn, anomaly.query)
odbcClose(postmarketscxn)

pouchTrackercxn <- odbcConnect('pouch_tracker')
pouchLeaks <- sqlQuery(pouchTrackercxn, pouch.leaks.query)
odbcClose(pouchTrackercxn)

pouchLeaks$PouchSerialNumber <- gsub('\t', '', as.character(pouchLeaks$PouchSerialNumber))

# add the pouch leak data to location.frames
for( l in c("dungeon", "pouchqc")){
	location.frames[[l]] <- merge(location.frames[[l]], pouchLeaks, by ="PouchSerialNumber", all.x=TRUE)
	location.frames[[l]]$PouchLeak[which(is.na(location.frames[[l]]$PouchLeak))] <- 0 
}
rm(l)
location.frames[["pouchqc"]] <- merge(location.frames[["pouchqc"]], anomalies, by ="PouchSerialNumber", all.x=TRUE)

# get rid of PouchSerialNumber Column
location.frames[["pouchqc"]] <- location.frames[["pouchqc"]][, subset(names(location.frames[["pouchqc"]]), names(location.frames[["pouchqc"]]) != "PouchSerialNumber")]

print("sql queries completed")

print("creating rate tables...")

## figure out what protocols should be listed in the drop down 

protocol.types <- c("NPS", "Stool", "BC", "CSF", "QC", "BT", "LRTI", "NGDS", "BJI", "Custom", "Other", "All", "All Except Custom")

## make the LastServiceDate column an actual date
location.frames[["pouchqc"]]$LastServiceDate <- as.POSIXct(location.frames[["pouchqc"]]$LastServiceDate)
location.frames[["dungeon"]]$LastServiceDate <- as.POSIXct(location.frames[["dungeon"]]$LastServiceDate)
## make the "Version" column  of location.frames more understandable 
version.names <<- list("1"="1.5", "2"="2.0", "3"="Torch")
location.frames[["pouchqc"]]$Version <- unlist(lapply(location.frames[["pouchqc"]]$Version, makeVersionNames))
location.frames[["dungeon"]]$Version <- unlist(lapply(location.frames[["dungeon"]]$Version, makeVersionNames))



## initialize the output data structue that holds the information to go in the data tables 
sorted.tables <<- list()

for( l in c("dungeon" , "pouchqc")){ # first layer, locations 
	
	sorted.tables[[l]] <- list()
	for( p in c(protocol.types, "Other")){ # second layer, protocol types
		
		if(l == "pouchqc"){
			sorted.tables[[l]][[p]] <- data.frame(Date=as.POSIXct(character()), 
																					SerialNo=character(), 
																					Protocol=character(),
																					Version=character(),
																					InstrumentError=numeric(),
																					SoftwareError=numeric(),
																					PouchLeak=numeric(), 
																					PCR2=numeric(),
																					PCR1=numeric(), 
																					yeast=numeric(),
																					Cp=numeric(), 
																					Tm=numeric(),
																					LastSerivceDate=as.POSIXct(character()),
																					Anomaly=numeric())
		}else{
			sorted.tables[[l]][[p]] <- data.frame(Date=as.POSIXct(character()), 
																					SerialNo=character(), 
																					Protocol=character(),
																					Version=character(),
																					InstrumentError=numeric(),
																					SoftwareError=numeric(),
																					PouchLeak=numeric(), 
																					PCR2=numeric(),
																					PCR1=numeric(), 
																					yeast=numeric(),
																					Cp=numeric(), 
																					Tm=numeric(),
																					LastSerivceDate=as.POSIXct(character()))
																					
		}
	}
}


#***************************************************************************************************************
#****************************** sort the data in location.frames by location and protocol **********************
#***************************************************************************************************************


non.other.row.numbers <- vector()
for(location in c("dungeon", "pouchqc")){
	sorted.tables[[location]][["All"]] <- rbind(sorted.tables[[location]][["All"]], location.frames[[location]])
	sorted.tables[[location]][["All Except Custom"]] <- rbind(sorted.tables[[location]][["All Except Custom"]], subset(location.frames[[location]],!grepl("Custom", location.frames[[location]]$Protocol)))
	for(protocol in protocol.types){
		if(protocol != "Custom"){
			row.numbers <- which(grepl(protocol, location.frames[[location]]$Protocol) & !grepl("Custom", location.frames[[location]]$Protocol))
			non.other.row.numbers <- c(non.other.row.numbers, row.numbers)
		}else{
			row.numbers <- which(grepl(protocol, location.frames[[location]]$Protocol))
			non.other.row.numbers <- c(non.other.row.numbers, row.numbers)
		}
		sorted.tables[[location]][[protocol]] <- rbind(sorted.tables[[location]][[protocol]], location.frames[[location]][row.numbers, ])
	}
	sorted.tables[[location]][["Other"]] <- location.frames[[location]][seq(1, nrow(location.frames[[location]]), 1)[-non.other.row.numbers], ]
	non.other.row.numbers <- vector()
}



print("data structures created")


			
			
			   
			





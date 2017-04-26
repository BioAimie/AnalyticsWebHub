


library(shiny)
library(sendmailR)
library(lubridate)

# set the working directory 
setwd('~/WebHub/AnalyticsWebHub/Apps/InteractiveApp')


# load in the data to be displayed
source("Rfunctions\\loadInternalInstrumentApp.R")



calculateAlerts <- function(serial.num, alert.frame, location){
	
		 
	if(length(which(alert.frame$SerialNo == serial.num)) >= 3 ){ ## greater thant 3 because the minimum requirement for an alert is three consecutive runs with errors 
		
		## make alert.frame have only the runs on serial.num
		
		alert.frame <- alert.frame[which(alert.frame$SerialNo == serial.num), ]
		
		## order by run start time
		alert.frame <- alert.frame[order(alert.frame$Date), ]
		alert.frame$error <- apply(alert.frame[ , c("InstrumentError", "SoftwareError", "PouchLeak", "PCR2", "PCR1", "yeast")], 1, function(x)if(sum(x, na.rm=TRUE) >= 1){return(1)}else{return(0)})
		number.runs <- dim(alert.frame)[1] 
  
		## alert case 1: machine had five or more runs in a week AND at least 20% of them had errors 
		if( number.runs >= 5){
			failure.rate <- sum(alert.frame$error, na.rm=TRUE)/number.runs
			
			if(failure.rate >= .2){
				## THIS MACHINE NEEDS AN ALERT
				alerts.output[[location]][["20percent"]] <<- c(alerts.output[[location]][["20percent"]], as.character(serial.num))
			}
		## alert case 2: three consecutive runs with errors (there doesn't need to be five runs in the past week) 	
		}else if(sum(alert.frame$error, na.rm=TRUE) == 3){ # if there were at least three runs with errors 
			  
				if(all(alert.frame$error[2:3] == 1)){ # if the three runs with errors were consecutive
					## THIS MACHINE NEEDS AN ALERT 
					alerts.output[[location]][["3consecutive"]] <<- c(alerts.output[[location]][["3consecutive"]], as.character(serial.num))
				}
			
			}
			
	} ## if this machine has 3 or more runs 
	
} # end calculateAlerts 


#if(wday(Sys.Date()) == 4){
if(wday(Sys.Date()) == 4){
	
	
	## initialize the output data structure and email varialbes for the instrument alerts 
	alerts.output <<- list()
  alerts.output[["dungeon"]] <- list("20percent"=vector(), "3consecutive"=vector())
  alerts.output[["pouchqc"]] <- list("20percent"=vector(), "3consecutive"=vector())
	
	alert.location.frames <- list()
	#alert.location.frames[["dungeon"]] <- location.frames[["dungeon"]][which(location.frames[["dungeon"]]$Date >= date.ranges[["7"]][1] & location.frames[["dungeon"]]$Protocol != "Custom") , ]
	alert.location.frames[["dungeon"]] <- subset(location.frames[["dungeon"]], Date >= date.ranges[["7"]][1] & Protocol != "Custom" & (LastServiceDate < date.ranges[["7"]][1] | is.na(LastServiceDate)))
	#alert.location.frames[["pouchqc"]] <- location.frames[["pouchqc"]][which(location.frames[["pouchqc"]]$Date >= date.ranges[["7"]][1] & location.frames[["pouchqc"]]$LastServiceDate > ), ]
	alert.location.frames[["pouchqc"]] <- subset(location.frames[["pouchqc"]], Date >= date.ranges[["7"]][1] & (LastServiceDate < date.ranges[["7"]][1] | is.na(LastServiceDate)))
	
	from <-"Anna.Hoffee@biofiredx.com"
	#dungeon.people <- c("Anna.Hoffee@biofiredx.com", "Aimie.Faucett@biofiredx.com", "Lisa.Ogden@biofiredx.com", "Bartek.Ksok@biofiredx.com", "Shane.Woodhouse@biofiredx.com" )
	#qc.people <- c("Anna.Hoffee@biofiredx.com", "Aimie.Faucett@biofiredx.com", "Emily.Fernandez@biofiredx.com", "Kristel.Borsos@biofiredx.com", "Dana.Saif@biofiredx.com", "Kimon.Clarke@biofiredx.com")

	dungeon.people <- c("Anna.Hoffee@biofiredx.com")
	qc.people <- c("Anna.Hoffee@biofiredx.com")
	
	mailControl <- list(smtpServer="webmail.biofiredx.com")
	subject.names <- list("pouchqc" = "Pouch QC", "dungeon"="Dungeon")
	
	for( l in c("dungeon", "pouchqc")){
			serial.numbers <- unique(alert.location.frames[[l]]$SerialNo)
			lapply(serial.numbers, calculateAlerts, alert.location.frames[[l]], l)
			print(l)
			##### now write the results in an email ######
			if(length(alerts.output[[l]][["20percent"]]) > 0 & length(alerts.output[[l]][["3consecutive"]]) > 0){ #both kinds of alerts
				subject <- paste0("Weekly ", subject.names[[l]], " Suspect Instrument Alert")
				body <- capture.output(cat("The following instrument(s) had at least 5 runs and a 20% failure rate in the last seven days: \n\n ", paste0(alerts.output[[l]][["20percent"]], collapse=", "), "\n\nThe following instrument(s) had 3 consecutive failed runs in less than 5 runs in the last seven days: \n\n ", paste0(alerts.output[[l]][["3consecutive"]], collapse=", ")))      
				if( l == "dungeon"){
					for(person in dungeon.people){
							sendmail(from=from, to=person, subject=subject, msg=body, control=mailControl)
					}
				}else if( l == "pouchqc"){
					for(qcperson in qc.people){
							sendmail(from=from, to=qcperson, subject=subject, msg=body, control=mailControl)
					}
				}
			}else if(length(alerts.output[[l]][["20percent"]]) > 0 & length(alerts.output[[l]][["3consecutive"]]) == 0 ){ # just 20% alerts
				subject <- paste0("Weekly ", subject.names[[l]], " Suspect Instrument Alert")
				body <- capture.output(cat("The following instrument(s) had at least 5 runs and a 20% failure rate in the last seven days: \n\n ", paste0(alerts.output[[l]][["20percent"]], collapse=", ")))
				if( l == "dungeon"){
					for(person in dungeon.people){
							sendmail(from=from, to=person, subject=subject, msg=body, control=mailControl)
					}
				}else if( l == "pouchqc"){
					for(qcperson in qc.people){
							sendmail(from=from, to=qcperson, subject=subject, msg=body, control=mailControl)
					}
				}
			}else if(length(alerts.output[[l]][["20percent"]]) == 0 & length(alerts.output[[l]][["3consecutive"]]) > 0){ # just 3 consecutive failure alerts 
				subject <- paste0("Weekly ", subject.names[[l]], " Suspect Instrument Alert")
				body <- capture.output(cat("The following instrument(s) had 3 consecutive failed runs in less than 5 runs in the last seven days: \n\n ", paste0(alerts.output[[l]][["3consecutive"]], collapse=", ")))      
				if( l == "dungeon"){
					for(person in dungeon.people){
							sendmail(from=from, to=person, subject=subject, msg=body, control=mailControl)
					}
				}else if( l == "pouchqc"){
					for(qcperson in qc.people){
							sendmail(from=from, to=qcperson, subject=subject, msg=body, control=mailControl)
					}
				}

			}
	}

}


runApp('internalInstrumentApp', port = 4038,
       launch.browser = getOption('shiny.launch.browser', interactive()), host = getOption('shiny.host', '10.1.23.96'))




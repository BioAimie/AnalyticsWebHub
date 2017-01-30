


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
    

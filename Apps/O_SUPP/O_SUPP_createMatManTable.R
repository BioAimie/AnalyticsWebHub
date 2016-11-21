createMatManTable <- function(paretoType, paretoFilterType, paretoFilterValue, dateStart, dateEnd, supplierFault = FALSE) {
  
  # first, the NCR data should be trimmed down to only include tickets in the date range
  ncr.df <- affParts.date[affParts.date$Date >= dateStart & affParts.date$Date <= dateEnd, ]
  
  # if the user only wants to see data where the supplier is at fault, filter down the data
  if(supplierFault) {
    
    ncr.df <- merge(filters.df[filters.df$SupplierAtFault == 1, c('TicketId','Type','SCAR','Vendor')], ncr.df, by='TicketId')
  } else {
    
    ncr.df <- merge(filters.df[, c('TicketId','Type','SCAR','Vendor')], ncr.df, by='TicketId')
  }
  
  # now apply the paretoFilterType and paretoFilterValue to trim the data set
  ncr.trim <- switch(paretoFilterType,
                     
                     'NCR Type' = ncr.df[ncr.df$Type == paretoFilterValue, ],
                     'Item Class' = merge(ncr.df, smi.df[smi.df$ItemClass == paretoFilterValue, c('ItemID','ItemClass')], by.x='PartNumber', by.y='ItemID'),
                     'SCAR' = ncr.df[ncr.df$SCAR == paretoFilterValue, ],
                     'SMI' = merge(ncr.df, smi.df[smi.df$SMI == paretoFilterValue, c('ItemID','SMI')], by.x='PartNumber', by.y='ItemID'),
                     'Vendor Name' = ncr.df[as.character(ncr.df$Vendor) == paretoFilterValue, ]
  )
  
  num.ncr <- with(ncr.trim, aggregate(Record~Vendor, FUN=sum))
  num.receipt <- receipts.df[receipts.df$Date >= dateStart & receipts.df$Date <= dateEnd, c('VendName','PartNumber','RcvQty')]
  num.receipt <- with(num.receipt, aggregate(RcvQty~VendName, FUN=sum))
  denom.receipt <- with(receipts.df, aggregate(RcvQty~VendName, FUN=sum))
  rate.df <- merge(num.receipt, num.ncr, by.x='VendName', by.y='Vendor', all.x=TRUE)
  rate.df[is.na(rate.df$Record),'Record'] <- 0
  rate.df <- merge(rate.df, denom.receipt, by='VendName')
  colnames(rate.df) <- c('Vendor','QtyRcv','QtyNCR','QtyRcvTotal')
  rate.df$Rate <- with(rate.df, (QtyRcv - QtyNCR)/QtyRcv)
  rate.df <- rate.df[with(rate.df, order(Rate, decreasing = TRUE)), ]
  rate.df$Rate <- paste(round(rate.df$Rate*100,2), '%', sep='')
  colnames(rate.df) <- c('Vendor','Qty Received in Period','Qty in NCRs','Qty Received (all time)','Rate of Acceptance in Period')
  
  if(length(rate.df[,1])==0) {
    
    return(NULL)
  } else {
    
    return(as.table(as.matrix(rate.df))) 
  }
}
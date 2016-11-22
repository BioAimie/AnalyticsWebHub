validateDF <- function(ncrType, vendName, supplierAtFault=FALSE, partNumber=NULL) {
  
  #######################################
  # ncrType <- 'Raw Material'
  # vendName <- 'Dan Flachsbart'
  # partNumber <- NULL
  ##########################################
  # all <- c('Raw Material','Instrument Production WIP','BioReagents', 'HTFA Instrument WIP', 'FA2.0 Instrument WIP','FA1.5 Instrument WIP')
  # 
  # iNcrType <- c('Instrument Production WIP','HTFA Instrument WIP', 'FA2.0 Instrument WIP','FA1.5 Instrument WIP')
  
  if(is.null(vendName)) {
    return(0)
  }

  if(supplierAtFault) {
    
    ncrParts.sum <- subset(ncrParts.df, SupplierAtFault=='Yes')
  } else {
    
    ncrParts.sum <- ncrParts.df
  }
  
  if(!is.null(partNumber)) {
    if(ncrType=='All NCRs') {
      filteredData <- subset(ncrParts.sum, Type %in% all & VendName == vendName & PartNumber == partNumber)
    } else if(ncrType == 'Instrument') {
      filteredData <- subset(ncrParts.sum, Type %in% iNcrType & VendName == vendName & PartNumber == partNumber)
    } else {
      filteredData <- subset(ncrParts.sum, Type == ncrType & VendName == vendName & PartNumber == partNumber)
    }
    
    suppReceipts <- subset(receipts.df, VendName == vendName & PartNumber == partNumber)
  } else {
    if(ncrType=='All NCRs') {
      filteredData <- subset(ncrParts.sum, Type %in% all & VendName == vendName)
    } else if (ncrType == 'Instrument') {
      filteredData <- subset(ncrParts.sum, Type %in% iNcrType & VendName == vendName)
    } else {
      filteredData <- subset(ncrParts.sum, Type == ncrType & VendName == vendName)
    }
    
    suppReceipts <- subset(receipts.df, VendName == vendName)
  }
  
  if(nrow(suppReceipts)==0){
    return(0)
  } else if (nrow(filteredData)==0) {
    return(1)
  }
  return(2)
}
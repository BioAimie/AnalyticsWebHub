# takes in the ncrType or vendor and filters data to provide dynamic list
filterPerInput <- function(type, ncrType, supplierAtFault=FALSE, selection=NULL) {
  
  #####################################################
  # type <- 'parts'
  # selection <- 'Thermo Fisher Scientific Biosciences Inc'
  # ncrType <- 'BioReagents'
  
  ########################################################

  #all <- c('Raw Material','Instrument Production WIP','BioReagents', 'HTFA Instrument WIP', 'FA2.0 Instrument WIP','FA1.5 Instrument WIP')
  #iNcrType <- c('Instrument Production WIP','HTFA Instrument WIP', 'FA2.0 Instrument WIP','FA1.5 Instrument WIP')
  
  if(supplierAtFault) {
    
    ncrParts.sum <- subset(ncrParts.df, SupplierAtFault=='Yes')
  } else {
    
    ncrParts.sum <- ncrParts.df
  }
  
  if(type=='ncr') {
    if(ncrType == "All NCRs") {
      output <- as.character(unique(ncrParts.sum[ncrParts.sum[,'Type'] %in% all, 'VendName']))
      output <- output[!(output %in% c('N/A','NA','na','n/a','CM')) & !(is.na(output))]
      output <- output[order(output)]
    } else if(ncrType == 'Instrument') {
      output <- as.character(unique(ncrParts.sum[ncrParts.sum[,'Type'] %in% iNcrType, 'VendName']))
      output <- output[!(output %in% c('N/A','NA','na','n/a','CM')) & !(is.na(output))]
      output <- output[order(output)]
    } else {
      output <- as.character(unique(ncrParts.sum[ncrParts.sum[,'Type']==ncrType, 'VendName']))
      output <- output[!(output %in% c('N/A','NA','na','n/a','CM')) & !(is.na(output))]
      output <- output[order(output)]
    }  
  } else {
    if(is.null(selection)) {
      return(0)
      }
    
    if (ncrType == "All NCRs") {
      filter <- ncrParts.sum[ncrParts.sum[,'Type'] %in% all, ]
    } else if(ncrType == 'Instrument') {
      filter <- ncrParts.sum[ncrParts.sum[,'Type'] %in% iNcrType, ]
    } else {
      filter <- ncrParts.sum[ncrParts.sum[,'Type']==ncrType, ]
    }
    output <- as.character(unique(filter[filter[,'VendName']== selection, 'PartNumber']))
    output <- sort(output)
  }
  
  return(output)
}
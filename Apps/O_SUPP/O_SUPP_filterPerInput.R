# takes in the ncrType or vendor and filters data to provide dynamic list
filterPerInput <- function(type, ncrType, selection=NULL) {
  
  #####################################################
  # type <- 'parts'
  # selection <- 'Thermo Fisher Scientific Biosciences Inc'
  # ncrType <- 'BioReagents'
  
  ########################################################

  #all <- c('Raw Material','Instrument Production WIP','BioReagents', 'HTFA Instrument WIP', 'FA2.0 Instrument WIP','FA1.5 Instrument WIP')
  #iNcrType <- c('Instrument Production WIP','HTFA Instrument WIP', 'FA2.0 Instrument WIP','FA1.5 Instrument WIP')
  
  if(type=='ncr') {
    if(ncrType == "All NCRs") {
      output <- as.character(unique(ncrParts.df[ncrParts.df[,'Type'] %in% all, 'VendName']))
      output <- output[!(output %in% c('N/A','NA','na','n/a','CM')) & !(is.na(output))]
      output <- output[order(output)]
    } else if(ncrType == 'Instrument') {
      output <- as.character(unique(ncrParts.df[ncrParts.df[,'Type'] %in% iNcrType, 'VendName']))
      output <- output[!(output %in% c('N/A','NA','na','n/a','CM')) & !(is.na(output))]
      output <- output[order(output)]
    } else {
      output <- as.character(unique(ncrParts.df[ncrParts.df[,'Type']==ncrType, 'VendName']))
      output <- output[!(output %in% c('N/A','NA','na','n/a','CM')) & !(is.na(output))]
      output <- output[order(output)]
    }  
  } else {
    if(is.null(selection)) {
      return(0)
    }
    
    if (ncrType == "All NCRs") {
      filter <- ncrParts.df[ncrParts.df[,'Type'] %in% all, ]
    } else if(ncrType == 'Instrument') {
      filter <- ncrParts.df[ncrParts.df[,'Type'] %in% iNcrType, ]
    } else {
      filter <- ncrParts.df[ncrParts.df[,'Type']==ncrType, ]
    }
    output <- as.character(unique(filter[filter[,'VendName']== selection, 'PartNumber']))
    output <- sort(output)
  }
  
  return(output)
}
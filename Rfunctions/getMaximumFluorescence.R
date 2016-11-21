getMaximumFluorescence <- function(index) {
  
  if(fluor.df[index,'PouchVersion'] == '1.1') {
    yeast <- c(5,16,17,20,44,59,77,97,99)
  } else {
    yeast <- c(14,18,34,48,51,62,74,80,100)
  }
  
  wells <- strsplit(as.character(fluor.df[index,'MaximumFluorArray']),',')[[1]]
  avgFluor <- mean(as.numeric(wells[yeast]))
  
  return(avgFluor)
}

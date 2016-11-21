getBaselineFluorescence <- function(index) {
  
  if(fluor.df[index,'PouchVersion'] == '1.1') {
    empties <- c(3,23,37,42,61,65,79,93,95)
  } else {
    empties <- c(3,12,36,39,64,67,90,93,94)
  }
  
  wells <- strsplit(as.character(fluor.df[index,'BaselineFluorArray']),',')[[1]]
  avgFluor <- mean(as.numeric(wells[empties]))
  
  return(avgFluor)
}
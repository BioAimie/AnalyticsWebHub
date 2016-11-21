subsetBasedOnTimeFrame <- function(timeFrame) {
  
  thisYear <- as.numeric(strsplit(as.character(Sys.Date()),'-')[[1]][1])
  thisMonth <- as.numeric(strsplit(as.character(Sys.Date()),'-')[[1]][2])
  thisQuarter <- ifelse(as.numeric(strsplit(as.character(Sys.Date()),'-')[[1]][2]) < 4, 1, 
                        ifelse(as.numeric(strsplit(as.character(Sys.Date()),'-')[[1]][2]) < 7, 2,
                               ifelse(as.numeric(strsplit(as.character(Sys.Date()),'-')[[1]][2]) < 10, 3, 4)))
  subFrame <- switch(timeFrame,
                     'This Year' = rootCause.df[rootCause.df[,'Year']==thisYear, ],
                     'This Quarter' = rootCause.df[rootCause.df[,'Year']==thisYear & rootCause.df[,'Quarter']==thisQuarter, ],
                     'This Month' = rootCause.df[rootCause.df[,'Year']==thisYear & rootCause.df[,'Month']==thisMonth, ],
                     'Last 90 Days' = rootCause.df[rootCause.df[,'last90days']==1, ],
                     'Last 30 Days' = rootCause.df[rootCause.df[,'last30days']==1, ],
                     '52 Weeks' = rootCause.df[rootCause.df[,'lastYear']==1, ]
  )
  
  return(subFrame)
}

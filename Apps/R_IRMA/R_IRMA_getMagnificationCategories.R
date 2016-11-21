getMagnificationCategories <- function(topLevelCategory, dateInput, topPercent = 0.8) {
  
  dataFrame <- subsetBasedOnTimeFrame(dateInput)
  
  if(topLevelCategory == 'Where Found') {
    return(as.character(unique(dataFrame[,'WhereFound'])))
  }
  else if(topLevelCategory == 'Problem Area') {
    return(itemsInPareto(dataFrame,'ProblemArea',topPercent))
  }
  else if(topLevelCategory == 'Failed Part') {
    return(itemsInPareto(dataFrame,'FailCat',topPercent))
  }
  else {
    return(itemsInPareto(dataFrame,'SubFailCat',topPercent))
  }
}

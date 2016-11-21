dataForHighLevelCharts <- function(denomFrame, numKey, complaintType, bigGroup, smallGroup, startDate, periods, lag, sdFac, thumbNail=FALSE, thumbParams=NULL, byLocation=FALSE) {
  
  if(thumbNail == FALSE) {
    
    if(is.null(numKey)) {
      
      num.all <- failures.df[,c(bigGroup, smallGroup, 'Record')]
      num.all$Key <- 'Complaint'
      num.all <- makeDateGroupAndFillGaps(calendar.df, num.all, bigGroup, smallGroup, 'Key', startDate)
      num.all.ma <- computeRollingRateAndAddStats(denomFrame, num.all, c('DateGroup','Key'), c('DateGroup','Key'), 'DateGroup', periods, lag, startDate)
      num.all.ma <- markForReview(num.all.ma, sdFac, 'Key')
    }
    
    else {
      
      num.all <- failures.df[failures.df[,numKey]==complaintType, ]
      num.all <- makeDateGroupAndFillGaps(calendar.df, num.all[,c(bigGroup, smallGroup, numKey, 'Record')], bigGroup, smallGroup, numKey, startDate)
      num.all.ma <- computeRollingRateAndAddStats(denomFrame, num.all, c('DateGroup',numKey), c('DateGroup',numKey), 'DateGroup', periods, lag, startDate)
      num.all.ma <- markForReview(num.all.ma, sdFac, numKey, TRUE, 0.001)
    }
    
    return(num.all.ma)
  }
  
  else {
    
    denom.agg.cols <- colnames(denomFrame)[!(colnames(denomFrame) %in% c('Record'))]
    join.cols <- c('DateGroup', thumbParams[thumbParams %in% denom.agg.cols])
    
    if(byLocation) {
      num.all <- complaints.df[complaints.df[,numKey]==complaintType, c(bigGroup, smallGroup, thumbParams, 'Record')]
    }
    else {
      num.all <- failures.df[failures.df[,numKey]==complaintType, c(bigGroup, smallGroup, thumbParams, 'Record')]
    }
    num.all <- makeDateGroupAndFillGaps(calendar.df, num.all, bigGroup, smallGroup, thumbParams, startDate)
    num.all.ma <- computeRollingRateAndAddStats(denomFrame, num.all, denom.agg.cols, c('DateGroup', thumbParams), join.cols, periods, lag, startDate)
    num.all.ma <- num.all.ma[!(is.nan(num.all.ma[,'average'])),]
    num.all.ma <- num.all.ma[!(is.nan(num.all.ma[,'RollingRate'])),]
    failKey <- thumbParams[!(thumbParams %in% denom.agg.cols)]
    num.all.ma   <- markForReview(num.all.ma, sdFac, failKey, TRUE, 0.001)
    
    return(num.all.ma)
  }
  
}

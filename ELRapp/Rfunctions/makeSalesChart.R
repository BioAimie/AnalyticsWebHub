makeSalesChart <- function(prodType, prods, type, salesDates) {
  ###############################################
  # prodType <- 'Instrument'
  # prods <- c()
  #  prods <- c('FA1.5','FA1.5R','FA2.0','FA2.0R')
  #  type <- 'Revenue'
  # salesDates <- c('2016-01-01', '2016-05-02')
  #################################################
  library(scales)
  library(RColorBrewer)
  
  source('Rfunctions/makeDateGroupAndFillGaps.R')
  sc <- sales.chart
  if(type == 'Revenue') {
    colnames(sc)[grep('Revenue', colnames(sc))] <- 'Record'
    ylabel <- ylab('Revenue ($)')
    ctitle <- ggtitle('Revenue per Month')
  } else {
    colnames(sc)[grep('QtyShipped', colnames(sc))] <- 'Record'
    ylabel <- ylab('Shipments')
    ctitle <- ggtitle('Shipments per Month')
  }
  
  sc <- makeDateGroupAndFillGaps(calendar.df,sc, 'Year','Month',c('Product'),'2014-01')
  
  start <- ifelse(month(salesDates[1]) < 10,
            paste(year(salesDates[1]),paste0('0',month(salesDates[1])),sep='-'),
            paste(year(salesDates[1]),month(salesDates[1]),sep='-'))
  
  end <- ifelse(month(salesDates[2]) < 10,
                paste(year(salesDates[2]),paste0('0',month(salesDates[2])),sep='-'),
                paste(year(salesDates[2]),month(salesDates[2]),sep='-'))
  
  sc <- subset(sc, as.character(DateGroup) >= start & as.character(DateGroup) <= end)
  
  if(prodType == 'All Products') {
    prods <- c('FA1.5','FA1.5R','FA2.0','FA2.0R','RP','BCID','GI','ME')  
  }
  
  sc <- sc[sc[,'Product'] %in% prods, ]
  
  if(nrow(sc) == 0) {
    return(0)
  }
  
  sc.agg <- with(sc, aggregate(Record~DateGroup+Product, FUN=sum))
  sc.agg <- droplevels(sc.agg)
  
  pal <- brewer.pal(8, 'Paired')
  
  schart <- ggplot(sc.agg, aes(x=as.numeric(DateGroup), y=Record, fill=Product)) + geom_area(stat='identity',position='stack') + xlab('Date\n(Year-Month)') + ylabel + 
    theme(text=element_text(size=18), axis.text.x=element_text(angle=90,vjust=0.5,color='black',size=14), axis.text.y=element_text(hjust=1, color='black', size=14)) + 
    ctitle + scale_y_continuous(labels=comma) + scale_fill_manual(values=pal, name='Products') + 
    scale_x_continuous(breaks=c(1:length(unique(sc.agg$DateGroup))),labels=levels(sc.agg$DateGroup))
  
  return(schart)
}
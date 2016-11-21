makeProdChart <- function(prodCombo) {
  #########################################
 # prodCombo <- c('RP','BCID, RP')
 # prodCombo <- c('GI','BCID, GI, ME, RP')
  
  ###########################################
  
  prod.df <- out.agg[out.agg[,'Code'] %in% prodCombo, ]

  myColors <- c('#9ecae1','#6baed6','#3182bd','#08519c','#dadaeb','#bcbddc','#9e9ac8','#807dba','#6a51a3','#4a1486','#a1d99b','#74c476','#31a354','#006d2c','#de2d26')
  names(myColors) <- levels(out.agg$Code)
  
  pchart <- ggplot(prod.df, aes(x=DateGroup, y=Record, group=Code, fill=Code)) + geom_bar(stat='identity') +
    xlab("Date\n(Year-Quarter)") + ylab("Number of Sites") + ggtitle("Product Combination Usage per Site") + theme(text=element_text(size=18),
    axis.text.x=element_text(angle=45, vjust=0.5,color='black',size=14), axis.text.y=element_text(hjust=1, color='black', size=14)) +
    scale_fill_manual(values=myColors, name="Product Combination") 
  
  return(pchart)
}
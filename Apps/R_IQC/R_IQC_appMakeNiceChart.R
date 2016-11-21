appMakeNiceChart <- function(controlName, paramName, dateRange) {
  
  dateFlag <- ifelse(dateRange == '52 weeks', 'thisYear', 'Year')
  
  underScore <- switch(controlName,
                       '60 Melt Probe' = '60',
                       'RNA' = 'RNA',
                       'PCR1' ='PCR1',
                       'PCR2' = 'PCR2',
                       'Noise' = 'med'
                       )
  
  first <- switch(paramName,
                  'Cp' = 'Cp',
                  'Tm' = 'Tm',
                  'Tm Range' = 'TmRange',
                  'Median DF' = 'medianDeltaRFU',
                  'DF Range over Median' = 'normalizedRangeRFU',
                  'Baseline' = 'Noise'
                  )
  
  toAverage <- paste(first,underScore,sep='_')

  a <- averageOfParameters(data, c(toAverage))
  
  b <- cbind(data[ ,dateFlag], a)
  colnames(b)[1] <- c('flag')
  b$flag <- ifelse(b$flag == 1, '52 weeks', b$flag)
  
  scatter <- toAverage
  line <- paste(toAverage,'avg',sep='_')
  avgAll <- paste(toAverage,'mean',sep='_')
  sdAll <- paste(toAverage,'sdev',sep='_')
  
  c <- b[ ,c('flag','DateGroup','Key','Version','Record', scatter, line, avgAll, sdAll)]
  
  d <- c[c$flag==dateRange, c('DateGroup','Key','Version', scatter, line, avgAll, sdAll)]
  colnames(d) <- c('DateGroup','Key','Version','Scatter','Line','avgAll','sdAll')

  BFDXcolors <- c('#000000','#0000FF')
  gTitle <- paste('Weekly Average of ', paramName,' in ',controlName, 'Control')
  yLab <- paramName
  
  specs <- switch(toAverage,
                  'Cp_RNA' = c(12,25),
                  'Tm_RNA' = c(77.3,82.3),
                  'Cp_PCR1' = c(12.5,21.5),
                  'Tm_PCR1' = c(78.1,83.1),
                  'Cp_PCR2' = c(13,19),
                  'Tm_PCR2' = c(76,79),
                  'TmRange_60' = c(-1,1),
                  'medianDeltaRFU_60' = c(7,27.5),
                  'normalizedRangeRFU_60' = c(0,60),
                  'Noise_med' = c(0,0.1)
                  )
  
#   p <- ggplot(d, aes(x=DateGroup, y=Scatter, group=Key, color=Key)) + geom_point(color='grey') + scale_color_manual(values=BFDXcolors) + geom_line(aes(x=DateGroup, y=Line)) + geom_line(aes(x=DateGroup, y=avgAll+sdAll, group=Key, color=Key)) + geom_line(aes(x=DateGroup, y=avgAll-sdAll, group=Key, color=Key)) + facet_wrap(~Version, nrow=2) + ylim(specs) + theme(axis.text.x = element_text(angle=90, hjust=1)) + labs(title=gTitle, y=yLab, x='Date')
  p <- ggplot(d, aes(x=DateGroup, y=Scatter, group=Key, color=Key)) + geom_point(color='grey') + scale_color_manual(values=BFDXcolors) + geom_line(aes(x=DateGroup, y=Line)) + facet_wrap(~Version, nrow=2) + ylim(specs) + theme(axis.text.x = element_text(angle=90, hjust=1)) + labs(title=gTitle, y=yLab, x='Date') # + geom_line(aes(x=DateGroup, y=avgAll+sdAll, group=Key, color=Key)) + geom_line(aes(x=DateGroup, y=avgAll-sdAll, group=Key, color=Key))

  return(p)
  
}

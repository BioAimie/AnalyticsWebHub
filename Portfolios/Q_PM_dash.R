
workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_PouchManufacturingQuality/'
pdfDir <- '~/WebHub/pdfs/'

setwd(workDir)

# Load needed libraries
library(lubridate)
library(zoo)
library(ggplot2)
library(devtools)
library(dateManip)

# Load data and functions
source('Portfolios/Q_PM_load.R')
source('Rfunctions/analyzeOrderIMR.R')
source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/makeTimeStamp.R')
source('Rfunctions/xbarRangeCalculator.R')

# set theme for line charts ------------------------------------------------------------------------------------------------------------------
seqBreak <- 12
fontSize <- 20
fontFace <- 'bold'
theme_set(theme_gray() + theme(plot.title = element_text(hjust = 0.5)))
# set theme for line charts ------------------------------------------------------------------------------------------------------------------

# # IMR CHARTS ---------------------------------------------------------------------------------------------------------------------------------
# ------- LAST 30 DAYS (does not differentiate by equipment)
burst.df[,'Date'] <- as.Date(burst.df[,'DateOpened'], tz='MST')
hydration.df[,'Date'] <- as.Date(hydration.df[,'DateOpened'], tz='MST')
faivLine.df[,'Date'] <- as.Date(faivLine.df[,'DateOpened'], tz='MST')
faivLineWater.df[,'Date'] <- as.Date(faivLineWater.df[,'DateOpened'], tz='MST')

ltd.burst <- unique(burst.df[,'Date'])[order(unique(burst.df[,'Date']), decreasing = TRUE)][1:30]
points.ltd.burst <- nrow(burst.df[burst.df$Date %in% ltd.burst, ])
burst.imr.ltd <- analyzeOrderIMR(burst.df, 'Result', 'DateOpened', points.ltd.burst, 3, 'GroupName', byEquipment = FALSE)
burst.imr.good <- burst.df[burst.df$Result < 200 & burst.df$Result >= 0, ]
burst.ltd.i.sd <- sd(burst.imr.good$Result)
burst.ltd.mr.sd <- sd(sapply(2:nrow(burst.imr.good), function(x) abs(burst.imr.good[(x), 'Result'] - burst.imr.good[(x-1), 'Result'])))
burst.imr.ltd[burst.imr.ltd$Key=='Individual Value', 'LCL'] <- burst.imr.ltd[burst.imr.ltd$Key=='Individual Value', 'Average'] - 5*burst.ltd.i.sd
burst.imr.ltd[burst.imr.ltd$Key=='Individual Value', 'UCL'] <- burst.imr.ltd[burst.imr.ltd$Key=='Individual Value', 'Average'] + 5*burst.ltd.i.sd
burst.imr.ltd[burst.imr.ltd$Key=='Moving Range', 'LCL'] <- burst.imr.ltd[burst.imr.ltd$Key=='Moving Range', 'Average'] - 5*burst.ltd.mr.sd
burst.imr.ltd[burst.imr.ltd$Key=='Moving Range' & burst.imr.ltd$LCL < 0, 'LCL'] <- 0
burst.imr.ltd[burst.imr.ltd$Key=='Moving Range', 'UCL'] <- burst.imr.ltd[burst.imr.ltd$Key=='Moving Range', 'Average'] + 5*burst.ltd.mr.sd

# burst.imr.ltd <- subset(burst.df, Date %in% ltd.burst)
# burst.imr.ltd <- analyzeOrderIMR(burst.imr.ltd, 'Result', 'DateOpened', length(burst.imr.ltd[,'Date']), 3, 'GroupName', byEquipment = FALSE)

ltd.hydra <- unique(hydration.df[,'Date'])[order(unique(hydration.df[,'Date']), decreasing = TRUE)][1:30]
points.ltd.hydra <- nrow(hydration.df[hydration.df$Date %in% ltd.hydra, ])
hydra.imr.wsw.ltd <- analyzeOrderIMR(hydration.df, 'WaterSideWeight', 'DateOpened', points.ltd.hydra, 3, 'GroupName', byEquipment = FALSE)
hydra.imr.ssw.ltd <- analyzeOrderIMR(hydration.df, 'SampleSideWeight', 'DateOpened', points.ltd.hydra, 3, 'GroupName', byEquipment = FALSE)

ltd.faivLine <- unique(faivLine.df[,'Date'])[order(unique(faivLine.df[,'Date']), decreasing = TRUE)][1:30]
points.ltd.faiv <- nrow(faivLine.df[faivLine.df$Date %in% ltd.faivLine, ])
faivLine.imr.ltd <- analyzeOrderIMR(faivLine.df, 'Result', 'DateOpened', points.ltd.faiv, 3, 'GroupName', byEquipment = FALSE)
# for cannula pull strength, the group wants IMR charts to show +5sd rather than 3, so do that instead
# cannula.mean.ltd <- mean(faivLine.df.ltd[faivLine.df.ltd$Result <= 100 & faivLine.df.ltd$Result >= 0, 'Result'])
cannula.mean.ltd <- mean(faivLine.df[faivLine.df$Result <= 100 & faivLine.df$Result >= 0 , 'Result'])
# cannula.sd.ltd <- sd(faivLine.df.ltd[faivLine.df.ltd$Result <= 100 & faivLine.df.ltd$Result >= 0, 'Result'])
cannula.sd.ltd <- sd(faivLine.df[faivLine.df$Result <= 100 & faivLine.df$Result >= 0, 'Result'])
faivLine.imr.ltd$LCL <- cannula.mean.ltd - 5*cannula.sd.ltd
faivLine.imr.ltd$UCL <- cannula.mean.ltd + 5*cannula.sd.ltd

ltd.faivLineWater <- unique(faivLineWater.df[,'Date'])[order(unique(faivLineWater.df[,'Date']), decreasing = TRUE)][1:30]
points.ltd.faivWater <- nrow(faivLineWater.df[faivLineWater.df$Date %in% ltd.faivLineWater, ])
# faivLineWater.imr.ltd <- subset(faivLineWater.df, Date %in% ltd.faivLineWater)
faivLineWater.imr.ltd <- analyzeOrderIMR(faivLineWater.df, 'Result', 'DateOpened', points.ltd.faivWater, 3, 'GroupName', byEquipment = FALSE)

burst.ltd.seq <- floor(length(burst.imr.ltd[burst.imr.ltd$Key=='Individual Value', 'DateOpened'])/20)
burst.ltd.labels <- burst.imr.ltd[burst.imr.ltd$Key=='Individual Value', 'DateOpened'][order(burst.imr.ltd[burst.imr.ltd$Key=='Individual Value', 'DateOpened'])][seq(1, nrow(burst.imr.ltd)/2, burst.ltd.seq)]
#burst.ltd.breaks <- burst.imr.ltd[burst.imr.ltd$Key=='Individual Value', 'Observation'][seq(1, length(burst.imr.ltd[burst.imr.ltd$Key=='Individual Value', 'Observation']), burst.ltd.seq)]
burst.ltd.breaks <- seq(1, nrow(burst.imr.ltd)/2, burst.ltd.seq)
p.burst.ltd <- ggplot(burst.imr.ltd, aes(x=Observation, y=Result, group='1')) + geom_line() + geom_point() + facet_wrap(~Key, ncol=1) + geom_hline(aes(yintercept=LCL), color='darkgreen') + geom_hline(aes(yintercept=UCL), color='darkgreen') + geom_hline(aes(yintercept=Average), color='blue') + theme(plot.title=element_text(size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1, size=14)) + scale_x_continuous(labels = burst.ltd.labels, breaks = burst.ltd.breaks) + labs(title='Burst Testing\n (Last 30 Days of Manufacturing)', y='Result (FYI limits include all historical data)', x='Observation Time')

hydra.ltd.wsw.seq <- floor(length(hydra.imr.wsw.ltd[hydra.imr.wsw.ltd$Key=='Individual Value', 'DateOpened'])/20)
hydra.ltd.wsw.labels <- hydra.imr.wsw.ltd[hydra.imr.wsw.ltd$Key=='Individual Value', 'DateOpened'][order(hydra.imr.wsw.ltd[hydra.imr.wsw.ltd$Key=='Individual Value', 'DateOpened'])][seq(1, nrow(hydra.imr.wsw.ltd)/2, hydra.ltd.wsw.seq )]
hydra.ltd.wsw.breaks <- seq(1, nrow(hydra.imr.wsw.ltd)/2, hydra.ltd.wsw.seq )
#hydra.ltd.wsw.breaks <- hydra.imr.wsw.ltd[hydra.imr.wsw.ltd$Key=='Individual Value', 'Observation'][seq(1, length(hydra.imr.wsw.ltd[hydra.imr.wsw.ltd$Key=='Individual Value', 'Observation']), hydra.ltd.wsw.seq)]
p.hydra.wsw.ltd <- ggplot(hydra.imr.wsw.ltd, aes(x=Observation, y=Result, group='1')) + geom_line() + geom_point() + facet_wrap(~Key, ncol=1) + geom_hline(aes(yintercept=LCL), color='darkgreen') + geom_hline(aes(yintercept=UCL), color='darkgreen') + geom_hline(aes(yintercept=Average), color='blue') + theme(plot.title=element_text(size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1, size=14)) + scale_x_continuous(labels = hydra.ltd.wsw.labels, breaks = hydra.ltd.wsw.breaks) + labs(title='Pouch Hydration Water Side Weight Testing\n (Last 30 Days of Manufacturing)', y='Result (FYI limits include all historical data)')

hydra.ltd.ssw.seq <- floor(length(hydra.imr.ssw.ltd[hydra.imr.ssw.ltd$Key=='Individual Value', 'DateOpened'])/20)
hydra.ltd.ssw.labels <- hydra.imr.ssw.ltd[hydra.imr.ssw.ltd$Key=='Individual Value', 'DateOpened'][order(hydra.imr.ssw.ltd[hydra.imr.ssw.ltd$Key=='Individual Value', 'DateOpened'])][seq(1, nrow(hydra.imr.ssw.ltd)/2, hydra.ltd.ssw.seq )]
hydra.ltd.ssw.breaks <- seq(1, nrow(hydra.imr.ssw.ltd)/2, hydra.ltd.ssw.seq )
#hydra.ltd.ssw.breaks <- hydra.imr.ssw.ltd[hydra.imr.ssw.ltd$Key=='Individual Value', 'Observation'][seq(1, length(hydra.imr.ssw.ltd[hydra.imr.ssw.ltd$Key=='Individual Value', 'Observation']), hydra.ltd.ssw.seq)]
p.hydra.ssw.ltd <- ggplot(hydra.imr.ssw.ltd, aes(x=Observation, y=Result, group='1')) + geom_line() + geom_point() + facet_wrap(~Key, ncol=1) + geom_hline(aes(yintercept=LCL), color='darkgreen') + geom_hline(aes(yintercept=UCL), color='darkgreen') + geom_hline(aes(yintercept=Average), color='blue') + theme(plot.title=element_text(size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1, size=14)) + scale_x_continuous(labels = hydra.ltd.ssw.labels, breaks = hydra.ltd.ssw.breaks) + labs(title='Pouch Hydration Sample Side Weight Testing\n (Last 30 Days of Manufacturing)', y='Result (FYI limits include all historical data)')

faivLine.ltd.seq <- floor(length(faivLine.imr.ltd[faivLine.imr.ltd$Key=='Individual Value', 'DateOpened'])/20)
faivLine.ltd.labels <- faivLine.imr.ltd[faivLine.imr.ltd$Key=='Individual Value', 'DateOpened'][order(faivLine.imr.ltd[faivLine.imr.ltd$Key=='Individual Value', 'DateOpened'])][seq(1, nrow(faivLine.imr.ltd)/2, faivLine.ltd.seq)]
faivLine.ltd.breaks <- seq(1, nrow(faivLine.imr.ltd)/2, faivLine.ltd.seq)
#faivLine.ltd.breaks <- faivLine.imr.ltd[faivLine.imr.ltd$Key=='Individual Value', 'Observation'][seq(1, length(faivLine.imr.ltd[faivLine.imr.ltd$Key=='Individual Value', 'Observation']), faivLine.ltd.seq)]
p.faivLine.ltd <- ggplot(faivLine.imr.ltd, aes(x=Observation, y=Result, group='1')) + geom_line() + geom_point() + facet_wrap(~Key, ncol=1) + geom_hline(aes(yintercept=LCL), color='darkgreen') + geom_hline(aes(yintercept=UCL), color='darkgreen') + geom_hline(aes(yintercept=Average), color='blue') + theme(plot.title=element_text(size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1, size=14)) + scale_x_continuous(labels = faivLine.ltd.labels, breaks = faivLine.ltd.breaks) + labs(title='FAIV Line Cannula Pull Strength Testing\n (Last 30 Days of Manufacturing)', y='Result', x='Observation Time')

faivLineWater.ltd.seq <- floor(length(faivLineWater.imr.ltd[faivLineWater.imr.ltd$Key=='Individual Value', 'DateOpened'])/20)
faivLineWater.ltd.labels <- faivLineWater.imr.ltd[faivLineWater.imr.ltd$Key=='Individual Value', 'DateOpened'][order(faivLineWater.imr.ltd[faivLineWater.imr.ltd$Key=='Individual Value', 'DateOpened'])][seq(1, nrow(faivLineWater.imr.ltd)/2, faivLineWater.ltd.seq)]
faivLineWater.ltd.breaks  <- seq(1, nrow(faivLineWater.imr.ltd)/2, faivLineWater.ltd.seq)
#faivLineWater.ltd.breaks <- faivLineWater.imr.ltd[faivLineWater.imr.ltd$Key=='Individual Value', 'Observation'][seq(1, length(faivLineWater.imr.ltd[faivLineWater.imr.ltd$Key=='Individual Value', 'Observation']), faivLineWater.ltd.seq)]
p.faivLineWater.ltd <- ggplot(faivLineWater.imr.ltd, aes(x=Observation, y=Result, group='1')) + geom_line() + geom_point() + facet_wrap(~Key, ncol=1, scales='free_y') + geom_hline(aes(yintercept=LCL), color='darkgreen') + geom_hline(aes(yintercept=UCL), color='darkgreen') + geom_hline(aes(yintercept=Average), color='blue') + theme(plot.title=element_text(size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1, size=14)) + scale_x_continuous(labels = faivLineWater.ltd.labels, breaks = faivLineWater.ltd.breaks) + labs(title='FAIV Line Water Weight Testing\n (Last 30 Days of Manufacturing)', y='Result', x='Observation Time')

# ------- LAST 7 DAYS (is differentiated by line) ADD FAIV LINE
lsd.burst <- unique(burst.df[,'Date'])[order(unique(burst.df[,'Date']), decreasing = TRUE)][1:7]
points.lsd.burst <- nrow(burst.df[burst.df$Date %in% lsd.burst, ])
burst.imr.lsd <- analyzeOrderIMR(burst.df, 'Result', 'DateOpened', points.lsd.burst, 3, 'GroupName', byEquipment = TRUE)
#burst.imr.lsd[,'LineKey'] <- as.numeric(substring(as.character(burst.imr.lsd[,'Equipment']), 12, 12))
burst.imr.lsd[burst.imr.lsd$Key=='Individual Value', 'LCL'] <- burst.imr.lsd[burst.imr.lsd$Key=='Individual Value', 'Average'] - 5*burst.ltd.i.sd
burst.imr.lsd[burst.imr.lsd$Key=='Individual Value', 'UCL'] <- burst.imr.lsd[burst.imr.lsd$Key=='Individual Value', 'Average'] + 5*burst.ltd.i.sd
burst.imr.lsd[burst.imr.lsd$Key=='Moving Range', 'LCL'] <- burst.imr.lsd[burst.imr.lsd$Key=='Moving Range', 'Average'] - 5*burst.ltd.mr.sd
burst.imr.lsd[burst.imr.lsd$Key=='Moving Range' & burst.imr.lsd$LCL < 0, 'LCL'] <- 0
burst.imr.lsd[burst.imr.lsd$Key=='Moving Range', 'UCL'] <- burst.imr.lsd[burst.imr.lsd$Key=='Moving Range', 'Average'] + 5*burst.ltd.mr.sd
burst.imr.lsd[,'LineKey'] <- as.numeric(substring(as.character(burst.imr.lsd[,'Equipment']), 12, 13))

lsd.hydra <- unique(hydration.df[,'Date'])[order(unique(hydration.df[,'Date']), decreasing = TRUE)][1:7]
points.lsd.hydra <- nrow(hydration.df[hydration.df$Date %in% lsd.hydra, ])
hydration.imr.lsd.wsw <- analyzeOrderIMR(hydration.df, 'WaterSideWeight', 'DateOpened', points.lsd.hydra, 3, 'GroupName', byEquipment = TRUE)
hydration.imr.lsd.ssw <- analyzeOrderIMR(hydration.df, 'SampleSideWeight', 'DateOpened', points.lsd.hydra, 3, 'GroupName', byEquipment = TRUE)

lsd.faivLine <- unique(faivLine.df[,'Date'])[order(unique(faivLine.df[,'Date']), decreasing = TRUE)][1:7]
points.lsd.faivLine <- nrow(faivLine.df[faivLine.df$Date %in% lsd.faivLine, ])
faivLine.imr.lsd <- analyzeOrderIMR(faivLine.df, 'Result', 'DateOpened', points.lsd.faivLine, 3, 'GroupName', byEquipment = TRUE)
# for cannula pull strength, the group wants IMR charts to show +5sd rather than 3, so do that instead
cannula.mean.lsd <- with(faivLine.df[faivLine.df$Result <= 100 & faivLine.df$Result >= 0, ], aggregate(Result~GroupName, FUN=mean))
cannula.sd.lsd <- with(faivLine.df[faivLine.df$Result <= 100 & faivLine.df$Result >= 0, ], aggregate(Result~GroupName, FUN=sd))
faivLine.imr.lsd <- merge(merge(faivLine.imr.lsd, cannula.mean.lsd, by.x='Equipment', by.y='GroupName'), cannula.sd.lsd, by.x='Equipment', by.y='GroupName')
colnames(faivLine.imr.lsd) <- c('Equipment','LotNumber','TestNumber','DateOpened','Observation','Result','Key','Average','LCL','UCL','HistMean','HistSD')
faivLine.imr.lsd$LCL <- with(faivLine.imr.lsd, HistMean - 5*HistSD)
faivLine.imr.lsd$UCL <- with(faivLine.imr.lsd, HistMean + 5*HistSD)

lsd.faivLineWater <- unique(faivLineWater.df[,'Date'])[order(unique(faivLineWater.df[,'Date']), decreasing = TRUE)][1:7]
points.lsd.faivWater <- nrow(faivLineWater.df[faivLineWater.df$Date %in% lsd.faivLineWater, ])
faivLineWater.imr.lsd <- analyzeOrderIMR(faivLineWater.df, 'Result', 'DateOpened', points.lsd.faivWater, 3, 'GroupName', byEquipment = TRUE)

# BURST TESTING
burst.lines <- as.character(unique(burst.imr.lsd$Equipment))[order(as.character(unique(burst.imr.lsd$Equipment)))]
burst.lines <- data.frame(Seq = seq(1, length(burst.lines), 1), Line = burst.lines)

plot.names <- c()

for(line.name in burst.lines$Line) {
  
  plot.name <- paste('p.burst.lsd', gsub(' ', '' ,gsub('-', '', line.name)), sep='.')
  plot.names <- c(plot.names, plot.name)
  
  plot.data <- subset(burst.imr.lsd, Equipment == line.name)
  # make the lables 
  increment.value <- floor((nrow(plot.data)/2)/5)
  # labels <-  plot.data[plot.data$Key=='Individual Value', 'DateOpened'][seq(1, nrow(plot.data)/2, increment.value)]
  breaks <- seq(1, nrow(plot.data)/2, increment.value)
  labels <- plot.data[plot.data$Key=='Individual Value', 'DateOpened'][order(plot.data[plot.data$Key=='Individual Value', 'DateOpened'])][breaks]
  p <- ggplot(plot.data, aes(x=Observation, y=Result, group='1')) + 
  	geom_line() + 
  	geom_point() + 
  	facet_wrap(~Key, ncol=1, scales='free_y') + 
  	geom_hline(aes(yintercept=LCL), color='darkgreen') + 
  	geom_hline(aes(yintercept=UCL), color='darkgreen') + 
  	geom_hline(aes(yintercept=Average), color='blue') + 
  	theme(plot.title=element_text(size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, size=14, hjust=1)) + 
  	scale_x_continuous(labels = labels, breaks = breaks) + 
  	labs(title=paste('Burst Testing on ', line.name, '\n (Last 7 Days of Manufacturing)', sep=''), y='Result (FYI limits include all historical data)', x='Observation Time')
  
  imgName <- paste(substring(plot.name,3),'.png',sep='')
  png(file=paste(imgDir, imgName, sep=''), width=1200, height=800, units='px')
  print(p)
  makeTimeStamp(author='Data Science')
  dev.off()
}

# HYDRATION TESTING - WSW
wsw.lines <- as.character(unique(hydration.imr.lsd.wsw$Equipment))[order(as.character(unique(hydration.imr.lsd.wsw$Equipment)))]
wsw.lines <- data.frame(Seq = seq(1, length(wsw.lines), 1), Line = wsw.lines)
#wsw.panels <- ceiling(length(wsw.lines$Seq)/4)
for( line.name in wsw.lines$Line) {

	plot.data <- subset(hydration.imr.lsd.wsw, Equipment == line.name)
  plot.name <- paste('p.hydra.wsw.lsd', gsub(' ', '' ,gsub('-', '', line.name)), sep='.')
  plot.names <- c(plot.names, plot.name)
  # make the lables 
  increment.value <- floor((nrow(plot.data)/2)/5)
  # labels <-  plot.data[plot.data$Key=='Individual Value', 'DateOpened'][seq(1, nrow(plot.data)/2, increment.value)]
  breaks <- seq(1, nrow(plot.data)/2, increment.value)
  labels <- plot.data[plot.data$Key=='Individual Value', 'DateOpened'][order(plot.data[plot.data$Key=='Individual Value', 'DateOpened'])][breaks]
  p <- ggplot(plot.data, aes(x=Observation, y=Result, group='1')) +
  	geom_line() + 
  	geom_point() +
  	facet_wrap(~Key, ncol=1, scales='free_y') + 
  	geom_hline(aes(yintercept=LCL), color='darkgreen') + 
  	geom_hline(aes(yintercept=UCL), color='darkgreen') + 
  	geom_hline(aes(yintercept=Average), color='blue') + 
  	theme(plot.title=element_text(size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, size=14, hjust=1)) + 
  	scale_x_continuous(labels = labels, breaks=breaks) + 
  	labs(title=paste('Pouch Hydration Testing on ', line.name, ' - Water Side Weight\n (Last 7 Days of Manufacturing)', sep=''), y='Result (FYI limits include all historical data)', x='Observation Time')
  
  imgName <- paste(substring(plot.name,3),'.png',sep='')
  png(file=paste(imgDir, imgName, sep=''), width=1200, height=800, units='px')
  print(p)
  makeTimeStamp(author='Data Science')
  dev.off()
}

# HYDRATION TESTING - SSW
ssw.lines <- as.character(unique(hydration.imr.lsd.ssw$Equipment))[order(as.character(unique(hydration.imr.lsd.ssw$Equipment)))]
ssw.lines <- data.frame(Seq = seq(1, length(ssw.lines), 1), Line = ssw.lines)
#ssw.panels <- ceiling(length(ssw.lines$Seq)/4)
for(line.name in ssw.lines$Line) {
  
  plot.data <- subset(hydration.imr.lsd.ssw, Equipment == line.name)
  plot.name <- paste('p.hydra.ssw.lsd', gsub(' ', '' ,gsub('-', '', line.name)), sep='.')
  plot.names <- c(plot.names, plot.name)
   # make the lables 
  increment.value <- floor((nrow(plot.data)/2)/5)
  # labels <-  plot.data[plot.data$Key=='Individual Value', 'DateOpened'][seq(1, nrow(plot.data)/2, increment.value)]
  breaks <- seq(1, nrow(plot.data)/2, increment.value)
  labels <- plot.data[plot.data$Key=='Individual Value', 'DateOpened'][order(plot.data[plot.data$Key=='Individual Value', 'DateOpened'])][breaks]

  p <- ggplot(plot.data, aes(x=Observation, y=Result, group='1')) + 
  	geom_line() + 
  	geom_point() + 
  	facet_wrap(~Key, ncol=1, scales='free_y') + 
  	geom_hline(aes(yintercept=LCL), color='darkgreen') + 
  	geom_hline(aes(yintercept=UCL), color='darkgreen') + 
  	geom_hline(aes(yintercept=Average), color='blue') + 
  	theme(plot.title=element_text(size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, size=14, hjust=1)) + 
  	scale_x_continuous(labels =labels, breaks=breaks) + 
  	labs(title=paste('Pouch Hydration Testing on', line.name, ' - Sample Side Weight\n (Last 7 Days of Manufacturing)', sep=''), y='Result (FYI limits include all historical data)', x='Observation Time')
  
  imgName <- paste(substring(plot.name,3),'.png',sep='')
  png(file=paste(imgDir, imgName, sep=''), width=1200, height=800, units='px')
  print(p)
  makeTimeStamp(author='Data Science')
  dev.off()
}

## split up the graphs by pouch line 
for( pouchLine in unique(faivLine.imr.lsd$Equipment)){
	pouchline.subset <- subset(faivLine.imr.lsd, Equipment == pouchLine)
	increment.value <- floor((nrow(pouchline.subset)/2)/5) 
	# print(seq(1, length(pouchline.subset[pouchline.subset$Key=='Individual Value', 'DateOpened'])))
	# labels <-  pouchline.subset[pouchline.subset$Key=='Individual Value', 'DateOpened'][seq(1, nrow(pouchline.subset)/2, increment.value)]
	breaks <- seq(1, nrow(pouchline.subset)/2, increment.value)
	labels <- pouchline.subset[pouchline.subset$Key=='Individual Value', 'DateOpened'][order(pouchline.subset[pouchline.subset$Key=='Individual Value', 'DateOpened'])][breaks]
	plot <- ggplot(pouchline.subset,aes(x=Observation, y=Result, group='1')) + geom_line() + 
		geom_point() + 
		facet_wrap(~Key, ncol=1, scales="free_y") + 
		geom_hline(aes(yintercept=LCL), color='darkgreen') + 
		geom_hline(aes(yintercept=UCL), color='darkgreen') +
		geom_hline(aes(yintercept=Average), color='blue') + 
		theme(plot.title=element_text(size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1, size=14)) + 
		scale_x_continuous(labels = labels, breaks=breaks) + 
		labs(title=paste('FAIV Cannula Pull Strength Testing on ', gsub(' ', '', pouchLine), '\n' ,'(Last 7 Days of Manufacturing)', sep=''), y='Result', x='Observation Time')
	assign(paste('p.faivline.lsd.', gsub('-', '', gsub(' ', '', pouchLine)), sep=''), plot)
		
}

## split up the graphs by pouch line 
for( pouchLine in unique(faivLineWater.imr.lsd$Equipment)){
	pouchline.subset <- subset(faivLineWater.imr.lsd, Equipment == pouchLine)
	increment.value <- floor((nrow(pouchline.subset)/2)/5) 
	labels <-  pouchline.subset[pouchline.subset$Key=='Individual Value', 'DateOpened'][seq(1, nrow(pouchline.subset)/2, increment.value)]
	#breaks <- pouchline.subset[pouchline.subset$Key=='Individual Value', 'Observation'][seq(1, length(pouchline.subset[pouchline.subset$Key=='Individual Value', 'Observation']), increment.value)]
	breaks <- seq(1, nrow(pouchline.subset)/2, increment.value)
	plot <- ggplot(pouchline.subset,aes(x=Observation, y=Result, group='1')) + geom_line() + 
		geom_point() + 
		facet_wrap(~Key, ncol=1, scales="free_y") + 
		geom_hline(aes(yintercept=LCL), color='darkgreen') + 
		geom_hline(aes(yintercept=UCL), color='darkgreen') +
		geom_hline(aes(yintercept=Average), color='blue') + 
		theme(plot.title=element_text(size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1, size=14)) + 
		scale_x_continuous(labels = labels, breaks=breaks) + 
		labs(title=paste('FAIV Water Weight Testing on ', pouchLine,  '\n', '(Last 7 Days of Manufacturing)', sep=''), y='Result', x='Observation Time')
	assign(paste('p.faivlineWater.lsd.', gsub('-', '', gsub(' ', '', pouchLine)), sep=''), plot)
		
}

# ------- RATE OF POLARIZED LIGHT TEST FAILURES IN BURST TESTING FOR THE LAST 7 DAYS
polarized.df[,'Date'] <- as.Date(polarized.df[,'DateOpened'], tz='MST')
polarized.lsd <- subset(polarized.df, Date %in% lsd.burst)
polarized.lsd[,'Record'] <- 1
polarized.lsd.agg <- with(polarized.lsd, aggregate(cbind(Record, PassedPolarized)~Date+GroupName, FUN=sum))
p.polarized.fail <- ggplot(polarized.lsd.agg, aes(x=Date, y=(Record-PassedPolarized), fill=GroupName)) + 
	geom_bar(stat='identity') + 
	labs(title='Count of Failures in Polarized Light Test by Pouch Line\nLast 7 Days of Manufacturing', y='Count of Failures', x='Day')+ 
	theme(plot.title=element_text(size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1))

# ------- COUNT OF FAILURES IN LAST 30 DAYS (BURST, WATER SIDE WEIGHT, AND SAMPLE SIDE WEIGHT)
burst.ltd <- subset(burst.imr.ltd, Key == 'Individual Value')
hydra.wsw.ltd <- subset(hydra.imr.wsw.ltd, Key == 'Individual Value')
hydra.ssw.ltd <- subset(hydra.imr.ssw.ltd, Key == 'Individual Value')
faivLine.ltd <- subset(faivLine.imr.ltd, Key == 'Individual Value')
faivLineWater.ltd <- subset(faivLineWater.imr.ltd, Key == 'Individual Value')

burst.ltd[,'Date'] <- as.Date(burst.ltd[,'DateOpened'], 'MST')
hydra.wsw.ltd[,'Date'] <- as.Date(hydra.wsw.ltd[,'DateOpened'], 'MST')
hydra.ssw.ltd[,'Date'] <- as.Date(hydra.ssw.ltd[,'DateOpened'], 'MST')
faivLine.ltd[,'Date'] <- as.Date(faivLine.ltd[,'DateOpened'], 'MST')
faivLineWater.ltd[,'Date'] <- as.Date(faivLineWater.ltd[,'DateOpened'], 'MST')

burst.ltd[,'FailCount'] <- with(burst.ltd, ifelse(Result < 50, 1, 0))
hydra.wsw.ltd[,'FailCount'] <- with(hydra.wsw.ltd, ifelse(Result < 0.8, 1, 0))
hydra.ssw.ltd[,'FailCount'] <- with(hydra.ssw.ltd, ifelse(Result < 0.2, 1, 0))
faivLine.ltd[,'FailCount'] <- with(faivLine.ltd, ifelse(Result < 9, 1, 0))
faivLineWater.ltd[,'FailCount'] <- with(faivLineWater.ltd, ifelse(Result < 1.4, 1, 0))

burst.agg <- aggregate(FailCount~Date+Equipment, burst.ltd, FUN=sum) 
p.burst.fail.ltd <- ggplot(burst.agg, aes(x=as.factor(Date), y=FailCount, fill=Equipment)) + 
	geom_bar( stat='identity') + 
	scale_x_discrete(breaks = as.factor(unique(burst.ltd[,'Date'])[order(unique(burst.ltd[,'Date']))]), drop=FALSE) + 
	theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + 
	labs(title='Failing Burst Tests in Last 30 Days\n(Result < 50.0PSI)', x='Date', y='Count of Failed Tests')

hydra.wsw.ltd.agg <- aggregate(FailCount~Date+Equipment, hydra.wsw.ltd, FUN=sum)
hydra.ssw.ltd.agg <- aggregate(FailCount~Date+Equipment, hydra.ssw.ltd, FUN=sum)
faivLine.ltd.agg <- aggregate(FailCount~Date+Equipment, faivLine.ltd, FUN=sum)
faivLineWater.ltd.agg <- aggregate(FailCount~Date+Equipment, faivLineWater.ltd, FUN=sum)
faivLineWater.ltd.agg$LineType <- rep('Auto', nrow(faivLineWater.ltd.agg))
faivLineWater.ltd.agg$LineType[which(!grepl('Auto', faivLineWater.ltd.agg$Equipment))] <- 'Manual'
p.hydra.wsw.fail.ltd <- ggplot(hydra.wsw.ltd.agg, aes(x=as.factor(Date), y=FailCount, fill=Equipment)) + geom_bar(stat='identity') + scale_x_discrete(breaks = as.factor(unique(hydra.wsw.ltd[,'Date'])[order(unique(hydra.wsw.ltd[,'Date']))])) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Failing Hydration Tests in Last 30 Days\n(Water Side Weight < 0.8g)', x='Date', y='Count of Failed Tests')
p.hydra.ssw.fail.ltd <- ggplot(hydra.ssw.ltd.agg, aes(x=as.factor(Date), y=FailCount, fill=Equipment)) + geom_bar(stat='identity') + scale_x_discrete(breaks = as.factor(unique(hydra.ssw.ltd[,'Date'])[order(unique(hydra.ssw.ltd[,'Date']))])) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Failing Hydration Tests in Last 30 Days\n(Sample Side Weight < 0.2g)', x='Date', y='Count of Failed Tests')

annotate.text <- grobTree(textGrob('NCR-21878', x=0.25,  y=0.90,gp=gpar(col='black', fontsize=13, fontface='bold')))

p.faivLine.fail.ltd <- ggplot(faivLine.ltd.agg, aes(x=as.factor(Date), y=FailCount, fill=Equipment)) + 
  geom_bar(stat='identity') + 
  scale_x_discrete(breaks = as.factor(unique(faivLine.ltd[,'Date'])[order(unique(faivLine.ltd[,'Date']))])) + 
  annotation_custom(annotate.text) +
  theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + 
  labs(title='Failing FAIV Cannula Pull Strength Tests in Last 30 Days\n(Result < 9lbs)', x='Date', y='Count of Failed Tests')  + 
  ylim(c(0, ifelse(max(with(faivLine.ltd, aggregate(FailCount~Date, FUN=sum))$FailCount) > 5, max(with(faivLine.ltd, aggregate(FailCount~Date, FUN=sum))$FailCount), 5)))

p.faivLineWater.fail.ltd <- ggplot(faivLineWater.ltd.agg, aes(x=as.factor(Date), y=FailCount, fill=Equipment)) + 
  facet_wrap(~LineType) + 
  geom_bar(stat='identity') + 
  scale_x_discrete(breaks = as.factor(unique(faivLineWater.ltd[,'Date'])[order(unique(faivLineWater.ltd[,'Date']))])) + 
  theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + 
  labs(title='Failing FAIV Water Weight Tests in Last 30 Days\n(Result < 1.4)', x='Date', y='Count of Failed Tests') + 
  ylim(c(0, ifelse(max(with(faivLineWater.ltd, aggregate(FailCount~Date, FUN=sum))$FailCount) > 5, max(with(faivLineWater.ltd, aggregate(FailCount~Date, FUN=sum))$FailCount), 5)))

# TREND CHARTS -- not a moving average... the team perfers a box and whisker plot by week ---------------------------------------------------------------------------
burst.df[,'DateGroup'] <- with(burst.df, ifelse(Week < 10, paste(Year, Week, sep='-0'), paste(Year, Week, sep='-')))
hydration.df[,'DateGroup'] <- with(hydration.df, ifelse(Week < 10, paste(Year, Week, sep='-0'), paste(Year, Week, sep='-')))
faivLine.df[,'DateGroup'] <- with(faivLine.df, ifelse(Week < 10, paste(Year, Week, sep='-0'), paste(Year, Week, sep='-')))
faivLineWater.df[,'DateGroup'] <- with(faivLineWater.df, ifelse(Week < 10, paste(Year, Week, sep='-0'), paste(Year, Week, sep='-')))

calendar.df <- createCalendarLikeMicrosoft(year(Sys.Date())-2, 'Week')
calendar.df[,'Date'] <- as.character(calendar.df[,'Date'])
startDate <- findStartDate(calendar.df, 'Week', 53, keepPeriods=53)
burst.trend <- analyzeOrderIMR(burst.df, 'Result', 'DateOpened', points.burst, 3, 'GroupName', byEquipment = FALSE, returnClean = TRUE)
hydra.wsw.trend <- analyzeOrderIMR(hydration.df, 'WaterSideWeight', 'DateOpened', points.hydra, 3, 'GroupName', byEquipment = FALSE, returnClean = TRUE)
hydra.ssw.trend <- analyzeOrderIMR(hydration.df, 'SampleSideWeight', 'DateOpened', points.hydra, 3, 'GroupName', byEquipment = FALSE, returnClean = TRUE)
faivLine.trend <- analyzeOrderIMR(faivLine.df, 'Result', 'DateOpened', points.faivLine, 3, 'GroupName', byEquipment = FALSE, returnClean = TRUE)
faivLineWater.trend <- analyzeOrderIMR(faivLineWater.df, 'Result', 'DateOpened', points.faivLineWater, 3, 'GroupName', byEquipment = FALSE, returnClean = TRUE)

burst.trend <- merge(calendar.df[calendar.df$DateGroup >= startDate, ], burst.trend, by='Date')
hydra.wsw.trend <- merge(calendar.df[calendar.df$DateGroup >= startDate, ], hydra.wsw.trend, by='Date')
hydra.ssw.trend <- merge(calendar.df[calendar.df$DateGroup >= startDate, ], hydra.ssw.trend, by='Date')
faivLine.trend <- merge(calendar.df[calendar.df$DateGroup >= startDate, ], faivLine.trend, by='Date')
faivLineWater.trend <- merge(calendar.df[calendar.df$DateGroup >= startDate, ], faivLineWater.trend, by='Date')

# make the charts
dateBreaks <- unique(calendar.df[calendar.df$DateGroup >= startDate, 'DateGroup'])[seq(1, length(calendar.df[calendar.df$DateGroup >= startDate, ]), seqBreak)]
p.burst.trend <- ggplot(burst.trend, aes(x=DateGroup, y=Result)) + geom_boxplot(outlier.colour = 'orange', color='dodgerblue') + scale_x_discrete(breaks = dateBreaks) + theme(plot.title=element_text(size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Burst Testing Result Distribution by Week', x='Test Date\n(Year-Week)', y='Result')
p.hydra.wsw.trend <- ggplot(hydra.wsw.trend, aes(x=DateGroup, y=Result)) + geom_boxplot(outlier.colour = 'orange', color='dodgerblue') + scale_x_discrete(breaks = dateBreaks) + theme(plot.title=element_text(size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Hydration Testing Water Side Weight Distribution by Week', x='Test Date\n(Year-Week)', y='Result') + ylim(c(0,1.25))
p.hydra.ssw.trend <- ggplot(hydra.ssw.trend, aes(x=DateGroup, y=Result)) + geom_boxplot(outlier.colour = 'orange', color='dodgerblue') + scale_x_discrete(breaks = dateBreaks) + theme(plot.title=element_text(size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='Hydration Testing Sample Side Weight Distribution by Week', x='Test Date\n(Year-Week)', y='Result') + ylim(c(0,0.6))
p.faivLine.trend <- ggplot(faivLine.trend, aes(x=DateGroup, y=Result)) + geom_boxplot(outlier.colour = 'orange', color='dodgerblue') + scale_x_discrete(breaks = dateBreaks) + theme(plot.title=element_text(size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='FAIV Cannula Pull Strength Testing Result Distribution by Week', x='Test Date\n(Year-Week)', y='Result')
p.faivLineWater.trend <- ggplot(faivLineWater.trend, aes(x=DateGroup, y=Result)) + geom_boxplot(outlier.colour = 'orange', color='dodgerblue') + scale_x_discrete(breaks = dateBreaks) + theme(plot.title=element_text(size=fontSize, face=fontFace), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90)) + labs(title='FAIV Water Weight Testing Result Distribution by Week', x='Test Date\n(Year-Week)', y='Result')

# Make images for the web hub
setwd(imgDir)
plots <- ls()[grep('^p\\.', ls())]
for(i in 1:length(plots)) {
  
  imgName <- paste(substring(plots[i],3),'.png',sep='')
  png(file=imgName, width=1200, height=800, units='px')
  print(eval(parse(text = plots[i])))
  makeTimeStamp(author='Data Science')
  dev.off()
}

# Make pdf report for the web hub
setwd(pdfDir)
pdf("PouchManufacturingInlineQC.pdf", width=11, height=8)
for(i in 1:length(plots)) {
  
  print(eval(parse(text = plots[i])))
}
dev.off()

rm(list = ls())

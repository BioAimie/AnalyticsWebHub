workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_PouchQC/'
pdfDir <- '~/WebHub/pdfs/'
bioDir <- '\\\\Filer01/Data/Departments/PostMarket/~Dashboards/WebHub/images/Dashboard_PouchQC'

# set the working directory
setwd(workDir)

# Load needed libraries
library(RODBC)
library(zoo)
library(ggplot2)
library(scales)
library(gridExtra)
library(grid)
library(png)
library(lubridate)
library(devtools)
install_github('BioAimie/dateManip')
library(dateManip)

# Load data
source('Portfolios/Q_PQC_load.R')
source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/makeTimestamp.R')

# establish some properties used throughout the code- these are kept up top to facilitate changes
periods <- 4
weeks <- 53
lagPeriods <- 4
validateDate <- '2015-40'

# make a calendar that matches the weeks from SQL DATEPART function and find a start date such that charts show one year
startYear <- year(Sys.Date()) - 2
calendar.df <- createCalendarLikeMicrosoft(startYear, 'Week')
startDate <- findStartDate(calendar.df, 'Week', weeks, periods)
# set theme for line charts ------------------------------------------------------------------------------------------------------------------
seqBreak <- 12
dateBreaks <- as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup']))[order(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup'])))][seq(4,length(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup']))), seqBreak)]
fontSize <- 20
fontFace <- 'bold'
# set theme for line charts ------------------------------------------------------------------------------------------------------------------

# Rate of Hydration Failures in Pouch QC per all pouches run in pouch final QC
runs.all <- data.frame(Year = rehydration.df[,'Year'], Week = rehydration.df[,'Week'], Key = 'qcRun', Record = 1)
runs.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', runs.all, c('Key'), startDate, 'Record', 'sum', NA)
hydra.fail <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', pqcRuns.df, c('Key'), startDate, 'Record', 'sum', 0)
hydra.rate <- mergeCalSparseFrames(hydra.fail, runs.fill, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
hydra.lims <- addStatsToSparseHandledData(hydra.rate, c('Key'), lagPeriods, TRUE, 3, 'upper', 0)
x_positions <- c('2016-18', '2016-24')
annotations <- c('NCR-18150,\nNCR-18165', 'CAPA-13276')
y_positions <- hydra.lims[(hydra.lims[,'DateGroup']) %in% c('2016-21','2016-24'), 'Rate'] + 0.001
p.hydra.fail <- ggplot(hydra.lims, aes(x=DateGroup, y=Rate, group=Key, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('blue','red'), guide=FALSE) + geom_hline(aes(yintercept=UL), color='red', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Hydration Failures per Pouch Run in Final QC', x='Date\n(Year-Week)', y='Rolling 4-week Average Rate') + annotate("text", x=x_positions, y=y_positions, label=annotations, size=4)

# Leak Failures in Pouch QC per all pouches run in pouch final QC
pqcRuns.df[,'SerialNumber'] <- paste(0, pqcRuns.df[,'SerialNumber'],sep='')
ptRuns.df[,'SerialNumber'] <- as.character(ptRuns.df[,'SerialNumber'])
leak.fail <- merge(pqcRuns.df[,c('SerialNumber','Year','Week')], ptRuns.df, by='SerialNumber')[,c('Year','Week','Key','Record')]
leak.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', leak.fail, c('Key'), startDate, 'Record', 'sum', 0)
leak.rate <- mergeCalSparseFrames(leak.fill, runs.fill, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
leak.lims <- addStatsToSparseHandledData(leak.rate, c('Key'), lagPeriods, TRUE, 3, 'upper', 0)
x_pos.leak <- c('2016-32')
annot.leak <- c('DX-DCT-031999')
y_pos.leak <- leak.lims[(leak.lims[,'DateGroup']) %in% x_pos.leak, 'Rate'] + 0.0001
p.leak.fail <- ggplot(leak.lims, aes(x=DateGroup, y=Rate, group=Key, color=Color)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('black','black'), guide=FALSE) + geom_hline(aes(yintercept=UL), color='blue', lty=2) + scale_y_continuous(labels=percent) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Leak Failures per Pouch Run in Final QC', x='Date\n(Year-Week)', y='Rolling 4-week Average Rate') + annotate("text", x=x_pos.leak, y=y_pos.leak, label=annot.leak, size=4)

# Rehydration trends
rehydration.df <- rehydration.df[rehydration.df[,'Record'] >= 0 & rehydration.df[,'Record'] <= 1.6, ]
rehydration.box <- rehydration.df
rehydration.box[,'DateGroup'] <- with(rehydration.box, ifelse(Week < 10, paste(Year, Week, sep='-0'), paste(Year, Week, sep='-')))
p.rehydration.box <- ggplot(rehydration.box[rehydration.box[,'DateGroup'] >= startDate, ], aes(x=DateGroup, y=Record)) + geom_boxplot(outlier.colour = 'orange', fill='dodgerblue') + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, hjust=1), axis.text=element_text(size=fontSize, color='black',face=fontFace)) + labs(x='Date\n(Year-Week)', y='Rehydration Weight', title='Rehydration Weight Distributions by Week')
rehydration.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', rehydration.df, c('Key'), startDate, 'Record', 'sum', 0)
rehydration.avg <- mergeCalSparseFrames(rehydration.fill, runs.fill, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
rehydration.lims <- addStatsToSparseHandledData(rehydration.avg, c('Key'), lagPeriods, TRUE, 3, 'two.sided', 0, 100)
p.rehydration.trend <- ggplot(rehydration.box[rehydration.box[,'DateGroup'] >= startDate, ], aes(x=DateGroup, y=Record)) + geom_point(color='lightskyblue') + geom_line(aes(x=DateGroup, y=Rate, group=Key), data=rehydration.lims, color='black') + geom_point(aes(x=DateGroup, y=Rate, color=Color), data=rehydration.lims) + scale_color_manual(values=c('blue','orange'), guide=FALSE) + geom_hline(aes(yintercept=UL), data=rehydration.lims, color='black', lty=2) + geom_hline(aes(yintercept=LL), data=rehydration.lims, color='black', lty=2) + scale_x_discrete(breaks=dateBreaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, hjust=1), axis.text=element_text(size=fontSize, color='black',face=fontFace)) + labs(x='Date\n(Year-Week)', y='Rehydration Weight, 4-week Rolling Average', title='Rehydration Weight Trends')
p.rehydration.trend.hist <- ggplot(rehydration.box[rehydration.box[,'DateGroup'] >= startDate, ], aes(x=Record)) + geom_histogram() + coord_flip() + theme(text=element_text(size=fontSize, face=fontFace), axis.text.y=element_blank(), axis.text.x=element_text(size=fontSize, color='black', angle=90, face=fontFace), axis.ticks.y=element_blank()) + labs(x='',y='',title='Weight\nDistribution')

# Compare the rate of control failures in the field to those in Pouch QC
  # # first, check to see if the failure rate per pouches shipped matches BioMath's... it doesn't, why???
  # cf.df <- rbind(fa2.cf.df, fa1.cf.df[!(fa1.cf.df$SerialNo %in% fa2.cf.df$SerialNo), ])
  # cf.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(cf.df, Key=='ControlFailure'), c('Key'), startDate, 'Record', 'sum', 0)
  # pouches.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', pouches.df, c('Key'), startDate, 'Record','sum', 0)
  # cf.rate <- mergeCalSparseFrames(cf.fill, pouches.fill, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, 4)
  # ggplot(cf.rate, aes(x=DateGroup, y=Rate, group=Key)) + geom_line() + geom_point() + scale_x_discrete(breaks=dateBreaks) + scale_y_continuous(labels = percent)
#   # -------------------------------------------
# once the data match, this part will find the control failure rate by lot in Pouch QC and in the Field
control.fail.qc.df <- rbind(fa2.cf.df[,c('SerialNo','LotNo','Key','Record')] , fa1.cf.df[!(fa1.cf.df[,'SerialNo'] %in% fa2.cf.df[,'SerialNo']), c('SerialNo','LotNo','Key','Record')])
control.runs.qc <- with(unique(control.fail.qc.df[,c('SerialNo','Record','LotNo')]), aggregate(Record~LotNo, FUN=sum))
control.fail.qc <- with(subset(control.fail.qc.df, Key=='ControlFailure'), aggregate(Record~LotNo, FUN=sum))
control.fail.qc <- merge(control.runs.qc, control.fail.qc, by='LotNo', all.x=TRUE)
colnames(control.fail.qc) <- c('LotNo','qcRuns','controlFailures')
control.fail.qc[is.na(control.fail.qc[,'controlFailures']),'controlFailures'] <- 0
control.fail.qc[,'Rate'] <- with(control.fail.qc, controlFailures/qcRuns)
control.fail.qc[,'Key'] <- 'qcFailures'
control.fail.field.complaints <- with(subset(field.df, Complaint=='Control Failure'), aggregate(ComplaintQty~LotNo, FUN=sum))
control.fail.field.size <- with(subset(field.df, Complaint=='Control Failure'), aggregate(QtyShipped~LotNo, FUN=sum))
control.fail.field <- merge(control.fail.field.complaints, control.fail.field.size, by='LotNo')
control.fail.field[,'Rate'] <- with(control.fail.field, ComplaintQty/QtyShipped)
control.fail.field[,'Key'] <- 'fieldComplaints'
control.fail.combo <- rbind(control.fail.field[,c('LotNo','Key','Rate')], control.fail.qc[control.fail.qc[,'LotNo'] %in% control.fail.field[,'LotNo'],c('LotNo','Key','Rate')])
control.breaks <- sort(as.character(unique(subset(control.fail.combo, substr(control.fail.combo[,'LotNo'], 5, 6)  == '16')[, 'LotNo'])))[seq(1,length(as.character(unique(subset(control.fail.combo, substr(control.fail.combo[,'LotNo'], 5, 6)  == '16')[, 'LotNo']))), 5)]
p.control.QCvField <- ggplot(subset(control.fail.combo, substr(control.fail.combo[,'LotNo'], 5, 6)  == '16'), aes(x=as.factor(LotNo), y=Rate)) + geom_bar(stat='identity') + facet_wrap(~Key, scales='free_y', ncol=1) + scale_x_discrete(breaks=control.breaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, hjust=1), axis.text=element_text(size=fontSize, color='black',face=fontFace)) + labs(y='Failures/QC Runs, Complaints/Qty Shipped', x='Lot Number', title='WIP:\nControl Failure Rate in Field vs. Lot Performance in QC')

# Compare the rate of Hydration Failures in Pouch QC to those in the field by lot
hydration.fail.field.complaints <- with(subset(field.df, Complaint == 'Failure To Hydrate'), aggregate(ComplaintQty~LotNo, FUN=sum))
hydration.fail.field.size <- with(subset(field.df, Complaint == 'Failure To Hydrate'), aggregate(QtyShipped~LotNo, FUN=sum))
hydration.fail.field <- merge(hydration.fail.field.complaints, hydration.fail.field.size, by='LotNo')
hydration.fail.field[,'Rate'] <- with(hydration.fail.field, ComplaintQty/QtyShipped)
hydration.fail.field[,'Key'] <- 'fieldComplaints'
hydration.fail.qc <- with(pqcRuns.df[pqcRuns.df[,'LotNumber'] %in% hydration.fail.field[,'LotNo'], ], aggregate(Record~LotNumber, FUN=sum))
hydration.runs.qc <- with(data.frame(LotNo = pqcRuns.df[pqcRuns.df[,'LotNumber'] %in% hydration.fail.field[,'LotNo'],'LotNumber'], Key = 'qcFailures', Runs = 1), aggregate(Runs~LotNo+Key, FUN=sum))
hydration.fail.qc <- merge(hydration.runs.qc, hydration.fail.qc, by.x='LotNo', by.y='LotNumber', all.x=TRUE)
hydration.fail.qc[,'Rate'] <- with(hydration.fail.qc, Record/Runs)
hydration.fail.combo <- rbind(hydration.fail.field[,c('LotNo','Key','Rate')], hydration.fail.qc[,c('LotNo','Key','Rate')])
hydration.breaks <- sort(as.character(unique(subset(hydration.fail.combo, substr(hydration.fail.combo[,'LotNo'], 5, 6)  == '16')[, 'LotNo'])))[seq(1,length(as.character(unique(subset(hydration.fail.combo, substr(hydration.fail.combo[,'LotNo'], 5, 6)  == '16')[, 'LotNo']))), 5)]
p.hydration.QCvField <- ggplot(subset(hydration.fail.combo, substr(hydration.fail.combo[,'LotNo'], 5, 6)  == '16'), aes(x=as.factor(LotNo), y=Rate)) + geom_bar(stat='identity') + facet_wrap(~Key, scales='free_y', ncol=1) + scale_x_discrete(breaks=hydration.breaks) + theme(text=element_text(size=fontSize, face=fontFace), axis.text.x=element_text(angle=90, hjust=1), axis.text=element_text(size=fontSize, color='black',face=fontFace)) + labs(y='Failures/QC Runs, Complaints/Qty Shipped', x='Lot Number', title='Hydration Failure Rate in Field vs. Lot Performance in QC')

# Create images for the Web Hub
setwd(imgDir)
plots <- ls()[grep('^p\\.', ls())]
plots.combo <- plots[grep('\\.trend$', plots)]
plots.hist <- plots[grep('\\.hist', plots)]
plots.alt <- plots[!(plots %in% plots.hist)]
for(i in 1:length(plots.alt)) {
  
  imgName <- paste(substring(plots.alt[i],3),'.png',sep='')
  
  if(plots.alt[i] %in% plots.combo) {
    
    plot1 <- plots.alt[i]
    plot2 <- paste(plot1, 'hist', sep='.') 
    png(file=imgName, width=1200, height=800, units='px')
    eval(parse(text = paste('grid.arrange(',plot1,',',plot2,', ncol=2, nrow=1, widths=c(4,1.4), heights=c(4))', sep='')))
    makeTimeStamp(author='Post Market Surveillance')
    dev.off()
  } else {
    
    png(file=imgName, width=1200, height=800, units='px')
    print(eval(parse(text = plots.alt[i])))
    makeTimeStamp(author='Post Market Surveillance')
    dev.off()
  }
}
#timestamp biomath plots
# first, read in the images created by BioMath
bioFiles <- list.files(path=bioDir)[grep('Smoothed',list.files(path=bioDir))]
for(i in 1:length(bioFiles)) {
  timeCreated <- file.mtime(paste(bioDir,'/',bioFiles[i],sep=''))
  imgName <- substring(bioFiles[i],3)
  png(file=imgName, width=1200, height=800, units='px') 
  img <- as.raster(readPNG(paste(bioDir, bioFiles[i], sep='/'))) 
  grid.newpage()
  grid.raster(img, interpolate = FALSE)
  makeTimeStamp(timeStamp = timeCreated, author='BioMath')
  dev.off()
}

# Create the pdf
setwd(pdfDir)
pdf("PouchQC.pdf", width=11, height=8)
for(i in 1:length(bioFiles)) {
  
  img <- as.raster(readPNG(paste(bioDir, bioFiles[i], sep='/'))) 
  grid.newpage()
  grid.raster(img, interpolate = FALSE)
}
# then print the plots created by PostMarket to the same pdf
for(i in 1:length(plots.alt)) {
  
  if(plots.alt[i] %in% plots.combo) {
    
    plot1 <- plots.alt[i]
    plot2 <- paste(plot1, 'hist', sep='.') 
    eval(parse(text = paste('grid.arrange(',plot1,',',plot2,', ncol=2, nrow=1, widths=c(4,1.4), heights=c(4))', sep='')))
  } else {
    
    print(eval(parse(text = plots.alt[i])))
  }
}
dev.off()

rm(list = ls())
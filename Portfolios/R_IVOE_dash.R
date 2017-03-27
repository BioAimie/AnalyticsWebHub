# Set the environment
workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_InstrumentVOE/'
pdfDir <- '~/WebHub/pdfs/'

setwd(workDir)

# Load needed libraries
library(ggplot2)
library(zoo)
library(scales)
library(devtools)
install_github('BioAimie/dateManip')
library(dateManip)

# load the data from SQL that's needed
source('Portfolios/R_IVOE_load.R')
source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/makeTimeStamp.R')

# establish some properties used throughout the code- these are kept up top to facilitate changes
periods <- 4
lagPeriods <- 4

# use '2014-51' as the start date so that the 4-week rolling trend starts in week 1 of 2015
startYear <- 2014
startDate <- '2014-51'

# create a calendar and set some other variables 
calendar.df <- createCalendarLikeMicrosoft(startYear, 'Week')

# set theme for line charts ------------------------------------------------------------------------------------------------------------------
seqBreak <- 12
dateBreaks <- as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup']))[order(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup'])))][seq(4,length(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup']))), seqBreak)]
fontSize <- 20
fontFace <- 'bold'
# set theme for line charts ------------------------------------------------------------------------------------------------------------------

# Plunger manifold gaskets creeping per pouches shipped
pouches.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', pouches.df, c('Key'), startDate, 'Record', 'sum', 0)
gaskets.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', gasketCreep.df, c('Key'), startDate, 'Record', 'sum', 0)
gaskets.rate <- mergeCalSparseFrames(gaskets.fill, pouches.fill, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
# for the gasket voe, the engineers would like to see a zero line for the new gasket, so if that key doesn't exist add it
if(length(unique(gaskets.rate[,'Key']))==1) {
  
  g <- data.frame(DateGroup=gaskets.rate[,'DateGroup'], Key='FLM1-GAS-0018', Rate=0)
  gaskets.rate <- rbind(gaskets.rate, g)
}
x_positions <- c('2015-50')
y_positions <- max(gaskets.rate[, 'Rate'])
annotations.gasket <- c('Gasket\nChange')
indices <- which(unique(as.character(gaskets.rate[,'DateGroup']))==x_positions)
pal.gasket <- createPaletteOfVariableLength(gaskets.rate, 'Key')
p.gasket.voe <- ggplot(gaskets.rate, aes(x=DateGroup, y=Rate, group=Key, color=Key)) + geom_line() + geom_point() + scale_color_manual(values = pal.gasket, name='Part') + scale_x_discrete(breaks=dateBreaks) + scale_y_continuous(labels=percent) + theme(plot.title=element_text(hjust=0.5),text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Plunger Manifold Gaskets Creeping per Pouches Shipped', x='Date\n(Year-Week)', y='Rolling 4-Week Average') + annotate('text',x=x_positions,y=y_positions,label=annotations.gasket,size=4) + geom_vline(xintercept=indices)

# Window bladder lots that have failed with < 100 hours run on them by lot manufacturing date
bladder.num.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(bladderLots.df, Key=='EarlyFailuresInLot'), c('Key','RecordedValue'), '2015-01', 'Record', 'sum', 0)
bladder.denom.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(bladderLots.df, Key=='LotSizeInLot'), c('Key'), '2015-01', 'Record', 'sum', 0)
bladder.rate <- mergeCalSparseFrames(bladder.num.fill, bladder.denom.fill, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0)
bladder.rate[,'Key'] <- 'Failures/Lot Size in Field'
bladder.count <- data.frame(DateGroup = bladder.num.fill[,'DateGroup'], Key = 'Count of Failures', RecordedValue = bladder.num.fill[,'RecordedValue'], Rate = bladder.num.fill[,'Record'])
bladder.voe <- rbind(bladder.rate, bladder.count)
x_dates <- c('2015-40', '2017-02')
y_record <- c(0,0)
annotations.bladder <- c('                    Heat Press Fix', '100% Qualification Screen')
annot.bladder <- data.frame(DateGroup = x_dates, Record = y_record, Label = annotations.bladder)
pal.bladder <- createPaletteOfVariableLength(bladder.voe, 'RecordedValue')
p.bladder.voe <- ggplot(subset(bladder.voe, RecordedValue != 'NoFailure'), aes(x=DateGroup, y=Rate, fill=RecordedValue)) + geom_bar(stat='identity') + scale_fill_manual(values=pal.bladder, name='') + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5),text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Effect of Enhanced Window Bladder QC:\nFailures at < 100 Run Hours/Lot Size in Field', y='Failures/Lot, Failure Count', x='Date of Lot Manufacture\n(Year-Week)') + facet_wrap(~Key, ncol=1, scale='free_y') + geom_text(data = annot.bladder, inherit.aes = FALSE, aes(label=Label, x=DateGroup, y=Record), angle=90, hjust=0, size=6, fontface='bold')
# Window bladder lots with all failures, not just early failures... but maybe fill them differently
bladder.all.fail <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', subset(bladderLots.df, Key=='EarlyFailuresInLot'), c('Key','RecordedValue','HoursBetweenBin'), '2015-01', 'AdjRecord', 'sum', 0)
bladder.all.rate <- mergeCalSparseFrames(bladder.all.fail, bladder.denom.fill, c('DateGroup'), c('DateGroup'), 'AdjRecord', 'Record', 0)
bladder.all.rate$Key <- 'Failures/Lot Size in Field'
bladder.all.count <- data.frame(DateGroup = bladder.all.fail[,'DateGroup'], Key = 'Count of Failures', RecordedValue = bladder.all.fail[,'RecordedValue'], HoursBetweenBin = bladder.all.fail[,'HoursBetweenBin'], Rate = bladder.all.fail[,'AdjRecord'])
bladder.all.voe <- rbind(bladder.all.rate, bladder.all.count)
bladder.all.voe$HoursBetweenBin <- factor(bladder.all.voe$HoursBetweenBin, levels = c('0-100','100-500','500-1000','1000+','Unknown'))
p.bladder.all.voe <- ggplot(subset(bladder.all.voe, RecordedValue != 'NoFailure')[with(subset(bladder.all.voe, RecordedValue != 'NoFailure'), order(HoursBetweenBin)), ], aes(x=DateGroup, y=Rate, fill=HoursBetweenBin)) + geom_bar(stat='identity') + scale_fill_manual(values = createPaletteOfVariableLength(bladder.all.voe, 'HoursBetweenBin'), name='') + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5),text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Effect of Enhanced Window Bladder QC:\nAll Failures/Lot Size in Field', y='Failures/Lot, Failure Count', x='Date of Lot Manufacture\n(Year-Week)') + facet_wrap(~Key, ncol=1, scale='free_y') + geom_text(data = annot.bladder, inherit.aes = FALSE, aes(label=Label, x=DateGroup, y=Record), angle=90, hjust=0, size=6, fontface='bold')

# BOARD VoEs:
# thermoboard
board.thermo.start <- '2015-01'
board.thermo.field.fail <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', data.frame(board.thermo.df, Key='FeildFailures'), c('Key'), board.thermo.start, 'QtyFailedInField', 'sum', 0)
board.thermo.house.fail <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', data.frame(board.thermo.df, Key='InHouseFailures'), c('Key'), board.thermo.start, 'QtyFailedInHouse', 'sum', 0)
board.thermo.field.size <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', data.frame(board.thermo.df, Key='thermoboard'), c('Key'), board.thermo.start, 'LotSizeUsed', 'sum', 0)
board.thermo.total.size <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', data.frame(board.thermo.df, Key='thermoboard'), c('Key'), board.thermo.start, 'ActualLotSize', 'sum', 0)
board.thermo.field.rate <- mergeCalSparseFrames(board.thermo.field.fail, board.thermo.field.size, c('DateGroup'), c('DateGroup'), 'QtyFailedInField', 'LotSizeUsed', 0, 0)
board.thermo.total.fail <- rbind(data.frame(board.thermo.house.fail[,c('DateGroup','Key')], Record = board.thermo.house.fail$QtyFailedInHouse), data.frame(board.thermo.field.fail[,c('DateGroup','Key')], Record = board.thermo.field.fail$QtyFailedInField))
board.thermo.total.rate <- mergeCalSparseFrames(board.thermo.total.fail, board.thermo.total.size, c('DateGroup'), c('DateGroup'), 'Record', 'ActualLotSize', 0, 0)
board.thermo.total <- rbind(data.frame(DateGroup = board.thermo.total.rate$DateGroup, Type='(NCR Qty + RMA Failures)/Actual Lot Size in Production Web', Key = board.thermo.total.rate$Key, Rate = board.thermo.total.rate$Rate),
                           data.frame(DateGroup = board.thermo.total.fail$DateGroup, Type='NCR Qty + RMA Failures', Key = board.thermo.total.fail$Key, Rate = board.thermo.total.fail$Record))
p.board.thermo.field <- ggplot(board.thermo.field.rate, aes(x=DateGroup, y=Rate, fill='filler')) + geom_bar(stat='identity') + scale_fill_manual(values=createPaletteOfVariableLength(data.frame(Key='filler'),'Key'), guide=FALSE) + scale_x_discrete(breaks=dateBreaks) + scale_y_continuous(labels=percent) + theme(plot.title=element_text(hjust=0.5),text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(hjust=1, angle=90)) + labs(title='Thermoboard Field Failures Per Lot Size', y='Failures/Lot', x='Date of Board Lot Manufacturing\n(Year-Week)')
p.board.thermo.total <- ggplot(board.thermo.total, aes(x=DateGroup, y=Rate, fill=Key)) + geom_bar(stat='identity') + facet_wrap(~Type, ncol=1, scale='free_y') + scale_fill_manual(values=createPaletteOfVariableLength(board.thermo.total,'Key'), name='', labels=c('NCR','RMA')) + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5),text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(hjust=1, angle=90)) + labs(title='Thermoboard Failures', x='Date of Manufacturing\n(Year-Week)', y='Failure Count, Failure Rate')
# image master board
board.image.start <- '2015-01'
board.image.field.fail <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', data.frame(board.image.df, Key='FeildFailures'), c('Key'), board.image.start, 'QtyFailedInField', 'sum', 0)
board.image.house.fail <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', data.frame(board.image.df, Key='InHouseFailures'), c('Key'), board.image.start, 'QtyFailedInHouse', 'sum', 0)
board.image.field.size <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', data.frame(board.image.df, Key='imageboard'), c('Key'), board.image.start, 'LotSizeUsed', 'sum', 0)
board.image.total.size <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', data.frame(board.image.df, Key='imageboard'), c('Key'), board.image.start, 'ActualLotSize', 'sum', 0)
board.image.field.rate <- mergeCalSparseFrames(board.image.field.fail, board.image.field.size, c('DateGroup'), c('DateGroup'), 'QtyFailedInField', 'LotSizeUsed', 0, 0)
board.image.total.fail <- rbind(data.frame(board.image.house.fail[,c('DateGroup','Key')], Record = board.image.house.fail$QtyFailedInHouse), data.frame(board.image.field.fail[,c('DateGroup','Key')], Record = board.image.field.fail$QtyFailedInField))
board.image.total.rate <- mergeCalSparseFrames(board.image.total.fail, board.image.total.size, c('DateGroup'), c('DateGroup'), 'Record', 'ActualLotSize', 0, 0)
board.image.total <- rbind(data.frame(DateGroup = board.image.total.rate$DateGroup, Type='(NCR Qty + RMA Failures)/Actual Lot Size in Production Web', Key = board.image.total.rate$Key, Rate = board.image.total.rate$Rate),
                           data.frame(DateGroup = board.image.total.fail$DateGroup, Type='NCR Qty + RMA Failures', Key = board.image.total.fail$Key, Rate = board.image.total.fail$Record))
p.board.image.field <- ggplot(board.image.field.rate, aes(x=DateGroup, y=Rate, fill='filler')) + geom_bar(stat='identity') + scale_fill_manual(values=createPaletteOfVariableLength(data.frame(Key='filler'),'Key'), guide=FALSE) + scale_x_discrete(breaks=dateBreaks) + scale_y_continuous(labels=percent) + theme(plot.title=element_text(hjust=0.5),text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(hjust=1, angle=90)) + labs(title='Image Board Field Failures Per Lot Size', y='Failures/Lot', x='Date of Board Lot Manufacturing\n(Year-Week)')
p.board.image.total <- ggplot(board.image.total, aes(x=DateGroup, y=Rate, fill=Key)) + geom_bar(stat='identity') + facet_wrap(~Type, ncol=1, scale='free_y') + scale_fill_manual(values=createPaletteOfVariableLength(board.image.total,'Key'), name='', labels=c('NCR','RMA')) + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5),text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(hjust=1, angle=90)) + labs(title='Image Board Failures', x='Date of Manufacturing\n(Year-Week)', y='Failure Count, Failure Rate')
# camera board
board.camera.start <- '2015-01'
board.camera.field.fail <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', data.frame(board.camera.df, Key='FeildFailures'), c('Key'), board.camera.start, 'QtyFailedInField', 'sum', 0)
board.camera.house.fail <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', data.frame(board.camera.df, Key='InHouseFailures'), c('Key'), board.camera.start, 'QtyFailedInHouse', 'sum', 0)
board.camera.field.size <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', data.frame(board.camera.df, Key='cameraboard'), c('Key'), board.camera.start, 'LotSizeUsed', 'sum', 0)
board.camera.total.size <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', data.frame(board.camera.df, Key='cameraboard'), c('Key'), board.camera.start, 'ActualLotSize', 'sum', 0)
board.camera.field.rate <- mergeCalSparseFrames(board.camera.field.fail, board.camera.field.size, c('DateGroup'), c('DateGroup'), 'QtyFailedInField', 'LotSizeUsed', 0, 0)
board.camera.total.fail <- rbind(data.frame(board.camera.house.fail[,c('DateGroup','Key')], Record = board.camera.house.fail$QtyFailedInHouse), data.frame(board.camera.field.fail[,c('DateGroup','Key')], Record = board.camera.field.fail$QtyFailedInField))
board.camera.total.rate <- mergeCalSparseFrames(board.camera.total.fail, board.camera.total.size, c('DateGroup'), c('DateGroup'), 'Record', 'ActualLotSize', 0, 0)
board.camera.total <- rbind(data.frame(DateGroup = board.camera.total.rate$DateGroup, Type='(NCR Qty + RMA Failures)/Actual Lot Size in Production Web', Key = board.camera.total.rate$Key, Rate = board.camera.total.rate$Rate),
                           data.frame(DateGroup = board.camera.total.fail$DateGroup, Type='NCR Qty + RMA Failures', Key = board.camera.total.fail$Key, Rate = board.camera.total.fail$Record))
p.board.camera.field <- ggplot(board.camera.field.rate, aes(x=DateGroup, y=Rate, fill='filler')) + geom_bar(stat='identity') + scale_fill_manual(values=createPaletteOfVariableLength(data.frame(Key='filler'),'Key'), guide=FALSE) + scale_x_discrete(breaks=dateBreaks) + scale_y_continuous(labels=percent) + theme(plot.title=element_text(hjust=0.5),text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(hjust=1, angle=90)) + labs(title='Camera Board Field Failures Per Lot Size', y='Failures/Lot', x='Date of Board Lot Manufacturing\n(Year-Week)')
p.board.camera.total <- ggplot(board.camera.total, aes(x=DateGroup, y=Rate, fill=Key)) + geom_bar(stat='identity') + facet_wrap(~Type, ncol=1, scale='free_y') + scale_fill_manual(values=createPaletteOfVariableLength(board.camera.total,'Key'), name='', labels=c('NCR','RMA')) + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5),text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(hjust=1, angle=90)) + labs(title='Camera Board Failures', x='Date of Manufacturing\n(Year-Week)', y='Failure Count, Failure Rate')
# valve board
board.valve.start <- '2015-01'
board.valve.field.fail <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', data.frame(board.valve.df, Key='FeildFailures'), c('Key'), board.valve.start, 'QtyFailedInField', 'sum', 0)
board.valve.house.fail <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', data.frame(board.valve.df, Key='InHouseFailures'), c('Key'), board.valve.start, 'QtyFailedInHouse', 'sum', 0)
board.valve.field.size <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', data.frame(board.valve.df, Key='valveboard'), c('Key'), board.valve.start, 'LotSizeUsed', 'sum', 0)
board.valve.total.size <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', data.frame(board.valve.df, Key='valveboard'), c('Key'), board.valve.start, 'ActualLotSize', 'sum', 0)
board.valve.field.rate <- mergeCalSparseFrames(board.valve.field.fail, board.valve.field.size, c('DateGroup'), c('DateGroup'), 'QtyFailedInField', 'LotSizeUsed', 0, 0)
board.valve.total.fail <- rbind(data.frame(board.valve.house.fail[,c('DateGroup','Key')], Record = board.valve.house.fail$QtyFailedInHouse), data.frame(board.valve.field.fail[,c('DateGroup','Key')], Record = board.valve.field.fail$QtyFailedInField))
board.valve.total.rate <- mergeCalSparseFrames(board.valve.total.fail, board.valve.total.size, c('DateGroup'), c('DateGroup'), 'Record', 'ActualLotSize', 0, 0)
board.valve.total <- rbind(data.frame(DateGroup = board.valve.total.rate$DateGroup, Type='(NCR Qty + RMA Failures)/Actual Lot Size in Production Web', Key = board.valve.total.rate$Key, Rate = board.valve.total.rate$Rate),
                            data.frame(DateGroup = board.valve.total.fail$DateGroup, Type='NCR Qty + RMA Failures', Key = board.valve.total.fail$Key, Rate = board.valve.total.fail$Record))
p.board.valve.field <- ggplot(board.valve.field.rate, aes(x=DateGroup, y=Rate, fill='filler')) + geom_bar(stat='identity') + scale_fill_manual(values=createPaletteOfVariableLength(data.frame(Key='filler'),'Key'), guide=FALSE) + scale_x_discrete(breaks=dateBreaks) + scale_y_continuous(labels=percent) + theme(plot.title=element_text(hjust=0.5),text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(hjust=1, angle=90)) + labs(title='Valve Board Field Failures Per Lot Size', y='Failures/Lot', x='Date of Board Lot Manufacturing\n(Year-Week)')
p.board.valve.total <- ggplot(board.valve.total, aes(x=DateGroup, y=Rate, fill=Key)) + geom_bar(stat='identity') + facet_wrap(~Type, ncol=1, scale='free_y') + scale_fill_manual(values=createPaletteOfVariableLength(board.valve.total,'Key'), name='', labels=c('NCR','RMA')) + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5),text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(hjust=1, angle=90)) + labs(title='Valve Board Failures', x='Date of Manufacturing\n(Year-Week)', y='Failure Count, Failure Rate')

# Lid latch failures per RMAs shipped
rmas.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', rmaShipped.df, c('Key'), "2015-10", 'Record', 'sum', 0)
lids.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', lids.df, c('Key'), "2015-10", 'Record', 'sum', 0)
if(length(unique(lids.fill[,'Key']))==1) {
  
  lids.more <- data.frame(DateGroup=lids.fill[,'DateGroup'], Key='new', Record=0)
  lids.fill <- rbind(lids.fill, lids.more)
}
lids.rate <- mergeCalSparseFrames(lids.fill, rmas.fill, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, periods)
pal.lids <- createPaletteOfVariableLength(lids.rate, 'Key')
p.lids.voe <- ggplot(lids.rate, aes(x=DateGroup, y=Rate, group=Key, color=Key)) + scale_color_manual(values=pal.lids, name='') + geom_line() + geom_point() + scale_x_discrete(breaks=dateBreaks) + scale_y_continuous(labels=percent) + theme(plot.title=element_text(hjust=0.5),text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Lid Latch Failures per RMAs Shipped', x='Date\n(Year-Week)', y='Rolling 4-Week Average')

# LED Excitation Error VoE
order.lots <- c('071709', 'Bad-NoScreeningOrRework','Bad-WithScreening','Bad-Reworked','New-PriorToFirmwareUpdate','New-UpdatedFirmware')
order.lots.new <- as.character(excitation.df[!(as.character(excitation.df$Lot) %in% order.lots), 'Lot'])
excitation.unique <- unique(excitation.df[,c('Lot','LotSizeInField')])
excitation.unique$Lot <- factor(excitation.unique$Lot, levels = order.lots)
excitation.ordered <- merge(excitation.unique, excitation.df, by=c('Lot','LotSizeInField'))
excitation.ordered$Key <- as.character(excitation.ordered$Key)
excitation.ordered[excitation.ordered$Key=='1000+','Key'] <- 'a1000+'
excitation.ordered[excitation.ordered$Key=='NoFailur','Key'] <- 'zNoFailure'
pal.excitation <- createPaletteOfVariableLength(excitation.ordered, 'Key')
pal.excitation[names(pal.excitation)=='zNoFailure'] <- '#FFFFFF'
p.excitation.voe <- ggplot(excitation.ordered[with(excitation.ordered, order(Key)), ], aes(x=Lot, y=Record/LotSizeInField, fill=Key)) + geom_bar(stat='identity') + scale_fill_manual(values = pal.excitation, name='Hours Run', labels=c('0-100','100-500','500-1000','1000+','Unknown','')) + scale_y_continuous(labels=percent) + theme(plot.title=element_text(hjust=0.5),text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=40, hjust=1)) + labs(title='LED Excitation Errors Reported by Bead Beater Lot Size in Field', x='Lot', y='7003 Complaints/Lot Size')

# Seal bar alignment NCRs and RMAs
sealBarNCR.num.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', sealBarNCR.df, 'Version', '2015-01', 'Record', 'sum', 0)
sealBarRMA.num.fill <- aggregateAndFillDateGroupGaps(calendar.df, 'Week', sealBarRMA.df, 'Version', '2015-01', 'Record', 'sum', 0)
sealBar.voe = rbind(cbind(sealBarNCR.num.fill, Key='NCR'),cbind(sealBarRMA.num.fill, Key='RMA'));
#sealBar.voe$Key = as.character(sealBar.voe$Key);
sealBar.x_position <- c('2016-49')
annotations.sealBar <- c('Process Change')
afterChangeNCR = subset(sealBarNCR.df, DateOfManufacturing>'2016-11-30');
afterChangeNCR$Date = as.Date(afterChangeNCR$DateOfManufacturing);
afterChangeNCR = merge(afterChangeNCR,calendar.df,by="Date")
afterChangeNCRAgg = aggregate(list(TicketStrings=as.character(afterChangeNCR$TicketString)), by=list(DateGroup=afterChangeNCR$DateGroup), FUN=function(tickets){ paste(tickets,collapse=", ") })
#sealBar.x_position = c(sealBar.x_position, afterChangeNCR$DateGroup);
#annotations.sealBar = c(annotations.sealBar, as.character(afterChangeNCR$TicketString));
sealBarNCRAnnotation.df = data.frame(x=c('2016-49','2016-49',as.character(afterChangeNCRAgg$DateGroup)), label=c('Process Change','Process Change',afterChangeNCRAgg$TicketStrings), Key=c("RMA",rep("NCR",nrow(afterChangeNCRAgg)+1)), stringsAsFactors = FALSE);
pal.sealBar <- createPaletteOfVariableLength(sealBar.voe, 'Version')
p.sealBar.voe <- ggplot(sealBar.voe, aes(x=DateGroup, y=Record, fill=Version)) + geom_bar(stat='identity') + scale_fill_manual(values=pal.sealBar, name='') + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(hjust=0.5),text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Seal bar alignment failures for new FA2.0 instruments', y='Failure Count', x='Manifold Date of Manufacture\n(Year-Week)') + facet_wrap(~Key, ncol=1) #+ geom_text(aes(label=annotations.sealBar, x=sealBar.x_position, y=0), angle=90, hjust=-0.5, size=4)
p.sealBar.voe <- p.sealBar.voe + geom_text(data=sealBarNCRAnnotation.df, inherit.aes=FALSE, aes(x=x, y=2, label=label), hjust=0, angle=90, size=4)


# #Thermoboard date settings
# bigGroup <- 'Year'
# smallGroup <- 'Month'
# periods <- 3
# weeks <- 53
# months <- 13
# lagPeriods <- 0
# validateDate <- '2015-30'
# startYear <- 2015
# calendar.df <- createCalendarLikeMicrosoft(startYear, smallGroup)
# startDate <- findStartDate(calendar.df, 'Month', 13, 0)
# #Thermoboard functions
# thermoBoard.bad <- aggregateAndFillDateGroupGaps(calendar.df, 'Month', subset(thermoBoard.df,Key!='StockSize'), c('Key','RecordedValue'), startDate, 'Record','sum',0)
# thermoBoard.bad <- thermoBoard.bad[thermoBoard.bad[,'RecordedValue'] != 'NoFailure', ]
# thermoBoard.size <- aggregateAndFillDateGroupGaps(calendar.df,'Month', subset(thermoBoard.df,Key=='StockSize'), c('Key'), startDate,'Record','sum',1)
# thermoBoard.rate <- mergeCalSparseFrames(thermoBoard.bad,thermoBoard.size,'DateGroup','DateGroup','Record','Record',0,0)
# #Thermoboard charts
# myPal.tb <- createPaletteOfVariableLength(thermoBoard.rate, 'Key')
# dateBreaks.tb <- as.character(unique(thermoBoard.rate[,'DateGroup']))[order(as.character(unique(thermoBoard.rate[,'DateGroup'])))][seq(1,length(as.character(unique(thermoBoard.rate[,'DateGroup']))), seqBreak)]
# x_position.tb<- c('2016-02')
# indices.tb <- which(unique(as.character(thermoBoard.rate[,'DateGroup']))==x_position.tb)
# annotations.tb <- c('Thermoboard\nSCAR')
# p.thermoBoard.voe <- ggplot(thermoBoard.rate, aes(x=DateGroup, y=Rate, fill=Key)) + geom_bar(stat='identity') + scale_fill_manual(values=myPal.tb, name='Type') + scale_x_discrete(breaks=dateBreaks.tb) + theme(plot.title=element_text(hjust=0.5),text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1))+ labs(title='Effect of Thermoboard Rework:\nThermoards Serviced/Instruments Released', y='Failures/Instruments Released', x='Date of Transaction\n(Year-Month)') + facet_wrap(~RecordedValue, ncol=1, scale='free_y') + geom_text(aes(label=annotations.tb, x=x_position.tb, y=0), angle=90, hjust=-0.5, size=4) + geom_vline(xintercept=indices.tb, color = "black")

# export images for web hub
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
pdf("InstrumentVOE.pdf", width = 11, height = 8)
for(i in 1:length(plots)) {
  
  print(eval(parse(text = plots[i])))
}
dev.off()

rm(list=ls())

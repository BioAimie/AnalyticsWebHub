# Set the environment
workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '../images/Dashboard_InstrumentVOE/'
pdfDir <- '../pdfs/'
setwd(workDir)

# Load needed libraries
library(dplyr)
library(lubridate)
library(tidyr)
library(forcats)
library(ggplot2)
library(zoo)
library(scales)
library(devtools)
library(colorspace)
#install_github('BioAimie/dateManip')
library(dateManip)
source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/makeTimeStamp.R')
source('Rfunctions/loadSQL.R')

# load the data from SQL that's needed
#*note: to set DB paths go to Control Panel/Systems & Security/Administrative Tools/Data Sources (ODBC)
PMScxn = odbcConnect('PMS_PROD')
loadSQL(PMScxn, 'SQL/R_IVOE_PlungerGasketCreepByPart.sql', 'gasketCreep.df')
loadSQL(PMScxn, 'SQL/R_IVOE_WindowBladderFailureByLot.sql', 'bladderLots.df')
loadSQL(PMScxn, 'SQL/R_IVOE_LidFailuresByPart.sql', 'lids.df')
loadSQL(PMScxn, 'SQL/R_IRMA_RMAsShippedByInstrumentVersion.sql', 'rmaShipped.df')
loadSQL(PMScxn, 'SQL/R_CC_CustPouchesShippedDetailed.sql', 'pouches.df')
loadSQL(PMScxn, 'SQL/R_IVOE_Board.sql', 
        c('boardsInField.df', 'boardFailureRMA.df', 'boardNCR.df', 'boardLots.df'))
loadSQL(PMScxn, 'SQL/R_IVOE_LEDExcitationError.sql', 'excitation.df')
loadSQL(PMScxn, 'SQL/R_IVOE_SealBarAlignmentNCR.sql', 'sealBarNCR.df')
loadSQL(PMScxn, 'SQL/R_IVOE_SealBarAlignmentRMA.sql', 'sealBarRMA.df')
loadSQL(PMScxn, 'SQL/R_IVOE_WireHarnessNCR.sql', 'wireharnessNCR.df')
loadSQL(PMScxn, 'SQL/R_IVOE_WireHarnessRMA.sql', 'wireharnessRMA.df')
loadSQL(PMScxn, 'SQL/R_IRMA_NewCompShip.sql', 'compShip.df')
loadSQL(PMScxn, 'SQL/R_IRMA_ComputerEarlyFailure.sql', 'computerEF.df')
loadSQL(PMScxn, 'SQL/R_INCR_InstrumentsProduced_denom.sql', 'newInst.df')
loadSQL(PMScxn, 'SQL/R_IVOE_LooseScrewRMA.sql', 'looseScrew.df')
loadSQL(PMScxn, 'SQL/R_IVOE_EdgeLoadComplaints.sql', 'edgeLoad.df')
loadSQL(PMScxn, 'SQL/R_IVOE_SealBarThermistor.sql', 'sealBarTherm.df')
loadSQL(PMScxn, 'SQL/R_IVOE_InstShippedByManfDate.sql', 'shippedManf.df')
close(PMScxn)

# establish some properties used throughout the code- these are kept up top to facilitate changes
periods <- 4
lagPeriods <- 4
wireharness.numCharts = 5
wireharness.nrow = 5
wireharness.ncol = 5
minimumDenom = 5

# use '2014-51' as the start date so that the 4-week rolling trend starts in week 1 of 2015
startYear <- 2014
startDate <- '2014-51'

# create a calendar and set some other variables 
calendar.df <- createCalendarLikeMicrosoft(startYear, 'Week')

# set theme for line charts
seqBreak <- 12
dateBreaks <- as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup']))[order(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup'])))][seq(4,length(as.character(unique(calendar.df[calendar.df[,'DateGroup'] >= startDate,'DateGroup']))), seqBreak)]
#dateBreaks.month <- unique(calendar.month$DateGroup)[seq(13, length(unique(calendar.month$DateGroup)), by=3)];
fontSize <- 20
fontFace <- 'bold'
theme_set(theme_grey()+theme(plot.title=element_text(hjust=0.5),
                             text=element_text(size=fontSize, face=fontFace), 
                             axis.text=element_text(color='black',size=fontSize,face=fontFace)));

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

# Aggregate boards in field and failure RMAs (used in several charts)
boardsInField.parts = unique(boardsInField.df$PartDesc);
boardsInField.count = boardsInField.df %>%
  inner_join(calendar.df, by = c("BoardReceiptDate" = "Date")) %>%
  group_by(DateGroup, PartDesc) %>% summarize(FieldCount = sum(QuantityInField)) %>% ungroup() %>%
  complete(DateGroup = calendar.df$DateGroup, PartDesc = boardsInField.parts, fill = list(FieldCount = 0));
boardFailureRMA.count = boardFailureRMA.df %>% 
  inner_join(calendar.df, by = c("BoardReceiptDate" = "Date")) %>%
  group_by(DateGroup, PartDesc) %>% 
  summarize(FailureRMACount = n(), 
            EarlyFailureRMACount = sum(HoursRun<100 | EarlyFailureType != 'N/A', na.rm = TRUE)) %>% 
  ungroup() %>%
  complete(DateGroup = calendar.df$DateGroup, PartDesc = boardsInField.parts, 
           fill = list(FailureRMACount = 0, EarlyFailureRMACount = 0));
boardFailureRMA.rate = boardsInField.count %>%
  inner_join(boardFailureRMA.count, by = c("DateGroup", "PartDesc")) %>%
  mutate(FailureRMARate = FailureRMACount / FieldCount,
         EarlyFailureRMARate = EarlyFailureRMACount / FieldCount
#         FailureRMARate0 = ifelse(FieldCount > minimumDenom, FailureRMACount / FieldCount, NA),
#         EarlyFailureRMARate0 = ifelse(FieldCount > minimumDenom, EarlyFailureRMACount / FieldCount, NA)
  ) %>%
  filter(DateGroup >= '2015-01') %>%
  mutate(PartDesc = fct_reorder(PartDesc, FailureRMACount, sum, na.rm=TRUE));
boardFailureRMA.total = boardFailureRMA.rate %>% 
  group_by(DateGroup) %>% 
  summarize(FailureRMACount = sum(FailureRMACount),
            EarlyFailureRMACount = sum(EarlyFailureRMACount))
makePalette = function(n){
  hex(HLS(rev(seq(0, length.out = n, by = 360/n)), 
          .6 - .3 * ((1:n %/% 2) %%2 ),
          .8 - .4 * (((0:(n - 1) %/% 2) %% 2))));
} 
board.pal = makePalette(length(boardsInField.parts));

# Chart: Board failure RMAs
boardFailureRMA.gather = 
  boardFailureRMA.rate %>%
  gather(Key, Value, c(FailureRMARate, FailureRMACount), factor_key=TRUE) %>%
  mutate(Key = fct_recode(Key, 'Failure RMA Count'='FailureRMACount', 
                          'Failure RMA Count/Quantity Shipped'='FailureRMARate')) %>%
  arrange(PartDesc)
nudge1 = max(boardFailureRMA.total$FailureRMACount)*.035;
K1 = boardFailureRMA.gather$Key[boardFailureRMA.gather$Key == 'Failure RMA Count'][1];
p.boardFailureRMA = boardFailureRMA.gather %>%
  ggplot(aes(x=DateGroup, y=Value, fill=PartDesc)) + 
  facet_wrap(~Key, ncol=1, scale='free_y') +
  geom_col(color='black') +
  geom_text(data = boardFailureRMA.total %>% mutate(Key = K1),
            aes(x = DateGroup, y = FailureRMACount + nudge1, label = FailureRMACount),
            inherit.aes = FALSE) +
  theme(axis.text.x=element_text(angle=90, hjust=1),
        legend.position='bottom') +
  guides(fill = guide_legend(ncol = 3, title = '')) +
  scale_x_discrete(breaks=dateBreaks) +
  scale_fill_manual(values = board.pal, drop = FALSE) +
  labs(x='Board receipt date (Year-Week)',
       y=element_blank(),
       fill=element_blank(),
       title='Board Failure RMAs')

# Chart: Board failure RMAs <100 hours
boardEarlyFailureRMA.gather = boardFailureRMA.rate %>% 
  gather(Key, Value, c(EarlyFailureRMARate, EarlyFailureRMACount), factor_key=TRUE) %>% 
  mutate(Key = fct_recode(Key, 'Failure RMAs <100 Hours'='EarlyFailureRMACount', 'Failure RMAs <100 Hours/Quantity Shipped'='EarlyFailureRMARate')) %>%
  arrange(PartDesc)
nudge2 = max(boardFailureRMA.total$EarlyFailureRMACount)*.035;
K2 = boardEarlyFailureRMA.gather$Key[boardEarlyFailureRMA.gather$Key == 'Failure RMAs <100 Hours'][1];
p.boardEarlyFailureRMA = boardEarlyFailureRMA.gather %>%
  ggplot(aes(x=DateGroup, y=Value, fill=PartDesc)) + 
  facet_wrap(~Key, ncol=1, scale='free_y') +
  geom_col(color='black') +
  geom_text(data = boardFailureRMA.total %>% mutate(Key = K2),
            aes(x = DateGroup, y = EarlyFailureRMACount + nudge2, label = EarlyFailureRMACount),
            inherit.aes = FALSE) +
  theme(axis.text.x=element_text(angle=90, hjust=1),
        legend.position='bottom') +
  guides(fill = guide_legend(ncol = 3, title = '')) +
  scale_x_discrete(breaks=dateBreaks) +
  scale_fill_manual(values = board.pal, drop = FALSE) +
  labs(x='Board Receipt Date (Year-Week)',
       y=element_blank(),
       fill=element_blank(),
       title='Board Failure RMAs <100 Hours Run')

# Function to create board part-specific charts: 
#   [Thermoboard/Valve board/Camera board/Image master board] NCRs and RMA failures <100 hours run
makeBoardCharts = function(partDesc, partTitle, outputPrefix){
  # partDesc='PCB, FA Thermocycler 4CH'
  # partTitle='Thermoboard'
  # outputPrefix='thermo';
  specificBoardFailureRMA.count = boardFailureRMA.df %>% 
    filter(PartDesc == partDesc) %>%
    mutate(HoursRunBin = cut(HoursRun, c(-Inf, 100, 500, 1000, Inf), labels = FALSE)) %>%
    mutate(HoursRunBin = factor(HoursRunBin, levels=c(1:4,NA,0), exclude = NULL,
                                labels = c('0-100', '100-500', '500-1000', '1000+', 'Unknown', 'NCR'))) %>%
    inner_join(calendar.df, by = c("BoardReceiptDate" = "Date")) %>%
    group_by(DateGroup, HoursRunBin, PartDesc) %>% summarize(FailureRMACount = n()) %>% ungroup() %>%
    complete(DateGroup = calendar.df$DateGroup, HoursRunBin, PartDesc = partDesc, 
             fill = list(FailureRMACount = 0)) %>%
    filter(HoursRunBin != 'NCR', DateGroup >= '2015-01')
  
  specificBoardFailureRMA.rate = specificBoardFailureRMA.count %>%
    inner_join(boardsInField.count, by = c("DateGroup", "PartDesc")) %>%
    mutate(FailureRMARate = FailureRMACount / FieldCount)
  
  specificBoardFailureRMA.total = specificBoardFailureRMA.rate %>% 
    group_by(DateGroup) %>% 
    summarize(FailureRMACount = sum(FailureRMACount),
              FieldCount = mean(FieldCount))

  specificBoardFailureRMA.gather = specificBoardFailureRMA.rate %>% 
    gather(Key, Value, c(FailureRMARate, FailureRMACount), factor_key = TRUE) %>% 
    mutate(Key = fct_recode(Key, 'Failure RMAs'='FailureRMACount', 'Failure RMAs per Quantity Shipped'='FailureRMARate')) %>%
    arrange(Key, HoursRunBin)
  
  nudge1 = max(specificBoardFailureRMA.total$FailureRMACount)*.03;
  K1 = specificBoardFailureRMA.gather$Key[specificBoardFailureRMA.gather$Key == 'Failure RMAs'][1];
  dummy1 = tibble(Key = K1, DateGroup = specificBoardFailureRMA.gather$DateGroup[1], 
                  Value = -nudge1*2);
  specificBoardFailureRMA.plot = specificBoardFailureRMA.gather %>%
    ggplot(aes(x=DateGroup, y=Value, fill=HoursRunBin)) +
    geom_col(color='black') +
    facet_wrap(~Key, ncol=1, scale='free_y') +
    geom_text(data = specificBoardFailureRMA.total %>% mutate(Key = K1),
              aes(x = DateGroup, y = FailureRMACount + nudge1, label = FailureRMACount),
              inherit.aes = FALSE) +
    geom_text(data = specificBoardFailureRMA.total%>% mutate(Key = K1),
              aes(x = DateGroup, y = -0.5*nudge1, label = FieldCount),
              inherit.aes = FALSE, angle = 90, hjust=1) +
    # dummy data used to enlarge plot area to avoid clipping annotations
    geom_blank(data = dummy1, aes(x = DateGroup, y = Value), inherit.aes = FALSE) + 
    theme(axis.text.x=element_text(angle=90, hjust=1)) +
    scale_fill_manual(values = createPaletteOfVariableLength(
      as.data.frame(specificBoardFailureRMA.gather), 'HoursRunBin')) +
    scale_x_discrete(breaks = dateBreaks) +
    labs(x='Board Receipt Date (Year-Week)',
         y=element_blank(),
         fill=element_blank(),
         title=paste0(partTitle,' Failure RMAs'))
  
  assign(paste0('p.board.',outputPrefix,'.field'), specificBoardFailureRMA.plot, globalenv());
  
  specificBoardNCR.quantity = 
    boardNCR.df %>%
    inner_join(calendar.df, by = c("BoardReceiptDate" = "Date")) %>%
    filter(PartDesc == partDesc) %>%
    group_by(DateGroup, PartDesc) %>% summarize(NCRQuantity = sum(QuantityAffected)) %>% ungroup() %>%
    complete(DateGroup = calendar.df$DateGroup, PartDesc = partDesc, fill = list(NCRQuantity = 0)) %>%
    filter(DateGroup >= '2015-01')
  
  specificBoardLots.size = 
    boardLots.df %>%
    inner_join(calendar.df, by = c("BoardReceiptDate" = "Date")) %>%
    group_by(DateGroup, PartDesc) %>% summarize(DesiredLotSize = sum(DesiredLotSize)) %>% ungroup() %>%
    complete(DateGroup = calendar.df$DateGroup, PartDesc = boardsInField.parts, fill = list(DesiredLotSize = 0));
  
  specificBoardFailure.rate = 
    rbind(specificBoardFailureRMA.count %>% 
            transmute(DateGroup, PartDesc, HoursRunBin, Quantity = FailureRMACount),
          specificBoardNCR.quantity %>%
            transmute(DateGroup, PartDesc, HoursRunBin = 'NCR', Quantity = NCRQuantity)
    ) %>%
    left_join(specificBoardLots.size, by = c("DateGroup", "PartDesc")) %>%
    mutate(Rate = Quantity / DesiredLotSize)
  
  specificBoardFailure.total = specificBoardFailure.rate %>% 
    group_by(DateGroup) %>% 
    summarize(Quantity = sum(Quantity),
              DesiredLotSize = mean(DesiredLotSize))
  
  specificBoardFailure.gather = specificBoardFailure.rate %>%
    gather(Key, Value, c(Rate, Quantity), factor_key=TRUE) %>%
    mutate(Key = fct_recode(Key, 
        setNames('Quantity', 'NCR Qty Affected + RMA Failures'),
        setNames('Rate', '(NCR Qty Affected + RMA Failures)/Sum of Desired Lot Size'))) %>%
    arrange(Key, DateGroup);
  
  nudge2 = max(specificBoardFailure.total$Quantity)*.03;
  K2 = specificBoardFailure.gather$Key[specificBoardFailure.gather$Key == 'NCR Qty Affected + RMA Failures'][1];
  dummy2 = tibble(Key = K2, DateGroup=specificBoardFailure.gather$DateGroup[1], Value = -nudge2*2);
  specificBoardFailure.plot = specificBoardFailure.gather %>% 
    ggplot(aes(x = DateGroup, y = Value, fill = HoursRunBin)) + 
    facet_wrap(~Key, ncol = 1, scale = 'free_y') +
    geom_col(color='black') +
    geom_text(data = specificBoardFailure.total %>% mutate(Key = K2),
              aes(x = DateGroup, y = Quantity + nudge2, label = Quantity),
              inherit.aes = FALSE) + 
    geom_text(data = specificBoardFailure.total %>% mutate(Key = K2),
              aes(x = DateGroup, y = -0.5*nudge2, label = DesiredLotSize), 
              angle = 90, hjust = 1, inherit.aes = FALSE) +
    geom_blank(data = dummy2, aes(x = DateGroup, y = Value), inherit.aes = FALSE) + 
    theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
    scale_x_discrete(breaks = dateBreaks) +
    scale_fill_manual(values = createPaletteOfVariableLength(
      as.data.frame(specificBoardFailure.gather), 'HoursRunBin')) +
    labs(x='Board receipt date (Year-Week)',
         y=element_blank(),
         fill=element_blank(),
         title=paste0(partTitle,' NCRs and Failure RMAs'))
  assign(paste0('p.board.',outputPrefix,'.total'), specificBoardFailure.plot, globalenv());
}

# BOARD VoEs: apply the function defined above to each of four cases
makeBoardCharts('PCB, FA Thermocycler 4CH', 'Thermoboard', 'thermo');
makeBoardCharts('FA Valve Controller Enhanced Valve Drive', 'Valve Board', 'valve');
makeBoardCharts('FA CAMERA VERTICAL FOV ASSY FILES', 'Camera Board', 'camera');
makeBoardCharts('FA IMAGE MASTER', 'Image Master Board', 'image');

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

# Calendar for wire harness:
months = 24
wireharness.calendar.df <- createCalendarLikeMicrosoft(startYear, 'Month')
wireharness.startDate <- findStartDate(wireharness.calendar.df, 'Month', months, periods, keepPeriods=0)
wireharness.seqBreak <- 3
wireharness.dates = as.character(unique(wireharness.calendar.df[wireharness.calendar.df[,'DateGroup'] >= wireharness.startDate,'DateGroup']))
wireharness.dateBreaks <- sort(wireharness.dates)[seq(1,length(wireharness.dates), wireharness.seqBreak)]

# Wire harness NCR count - Top 25 parts
wireharnessNCR.fill <- aggregateAndFillDateGroupGaps(wireharness.calendar.df, 'Month', wireharnessNCR.df, c('PartAffected'), startDate, 'Record', 'sum', 0)
wireharnessRMA.fill <- aggregateAndFillDateGroupGaps(wireharness.calendar.df, 'Month', wireharnessRMA.df, c('PartNumber'), startDate, 'FailCount', 'sum', 0)
wireharness.all <- rbind(
  data.frame(DateGroup=wireharnessNCR.fill$DateGroup, 
             PartNumber=wireharnessNCR.fill$PartAffected,
             Record=wireharnessNCR.fill$Record,
             Type='NCR'),
  data.frame(DateGroup=wireharnessRMA.fill$DateGroup, 
             PartNumber=wireharnessRMA.fill$PartNumber,
             Record=wireharnessRMA.fill$FailCount,
             Type='RMA')
);
wireharness.all$PartNumber = as.character(wireharness.all$PartNumber);
wireharness.maxrecord.bypart = aggregate(x = wireharness.all$Record, 
                                         by = list(part = wireharness.all$PartNumber), FUN = max);
wireharness.maxrecord.bypart = wireharness.maxrecord.bypart[order(wireharness.maxrecord.bypart$x,
                                                                  decreasing=TRUE),];
wireharness.parts = wireharness.maxrecord.bypart$part;
wireharness.maxrecord <- max(wireharness.all$Record);
parts=wireharness.maxrecord.bypart$part[1:(wireharness.nrow * wireharness.ncol)];
wireharness.fill = do.call(rbind,lapply(parts,function(part){
  subset(wireharness.all, PartNumber == part);
}));
wireharness.fill$PartNumber = factor(wireharness.fill$PartNumber, levels=wireharness.parts);
p.wireharness.count = ggplot(wireharness.fill, aes(x=DateGroup, y=Record, group=Type, fill=Type)) + geom_bar(stat='identity', position='identity', alpha=.5, color='black') + scale_x_discrete(breaks=wireharness.dateBreaks) + scale_y_continuous(limits=c(0,wireharness.maxrecord)) + scale_fill_manual(values=c('blue','red'), name='') + facet_wrap(~PartNumber) + theme(axis.text.x=element_text(angle=90)) + labs(title='Count of Wire Harness NCRs and RMAs - Top 25 parts', x='Wire Harness Manufacture Date (Year-Month)', y='Count of NCRs/RMAs')

# Wire harness NCR quantity affected - Top 25 parts
wireharnessNCR.qty.fill <- aggregateAndFillDateGroupGaps(wireharness.calendar.df, 'Month', wireharnessNCR.df, c('PartAffected'), startDate, 'QuantityAffected', 'sum', 0)
wireharnessNCR.qty.max = max(wireharnessNCR.qty.fill$QuantityAffected);
wireharnessRMA.infield <- aggregateAndFillDateGroupGaps(wireharness.calendar.df, 'Month', wireharnessRMA.df, c('PartNumber'), startDate, 'LotSizeInField', 'sum', 0)
wireharnessRMA.rate <- mergeCalSparseFrames(wireharnessRMA.fill, wireharnessRMA.infield, c('DateGroup','PartNumber'), c('DateGroup','PartNumber'), 'FailCount', 'LotSizeInField', 0, 0)
wireharnessRMA.rate.max = max(wireharnessRMA.rate$Rate);
wireharness.all <- rbind(
  data.frame(DateGroup=wireharnessNCR.qty.fill$DateGroup, 
             PartNumber=wireharnessNCR.qty.fill$PartAffected,
             Record=wireharnessNCR.qty.fill$QuantityAffected,
             Type='NCR'),
  data.frame(DateGroup=wireharnessRMA.rate$DateGroup, 
             PartNumber=wireharnessRMA.rate$PartNumber,
             Record=wireharnessRMA.rate$Rate * wireharnessNCR.qty.max / wireharnessRMA.rate.max,
             Type='RMA')
);
wireharness.maxrecord.bypart = aggregate(x = wireharness.all$Record, 
                                         by = list(part = wireharness.all$PartNumber), FUN = max);
wireharness.maxrecord.bypart = wireharness.maxrecord.bypart[order(wireharness.maxrecord.bypart$x,
                                                                  decreasing=TRUE),];
wireharness.parts = wireharness.maxrecord.bypart$part;
parts=wireharness.parts[1:(wireharness.nrow * wireharness.ncol)];
wireharness.fill = do.call(rbind,lapply(parts,function(part){
  subset(wireharness.all, PartNumber == part);
}));
wireharness.fill$PartNumber = factor(wireharness.fill$PartNumber, levels=parts);
p.wireharness.quantity = ggplot(wireharness.fill, aes(x=DateGroup, y=Record, group=Type, fill=Type)) + geom_bar(color='black', stat='identity', position='identity', alpha=.5) + scale_x_discrete(breaks=wireharness.dateBreaks) + scale_y_continuous(limits=c(0,wireharnessNCR.qty.max+1), sec.axis = sec_axis(~. * wireharnessRMA.rate.max / wireharnessNCR.qty.max, labels = scales::percent, name = "RMA Count / Lot Size In Field")) + facet_wrap(~PartNumber) + scale_fill_manual(values=c('blue','red'), name='')+ theme(axis.text.x=element_text(angle=90)) + labs(title='Wire harness NCR Quantity Affected and RMA Count/Lot Size In Field - Top 25 parts', x='Wire Harness Manufacture Date (Year-Month)', y='NCR Quantity affected')


# Wire harness NCR count
wireharnessNCR.fill <- aggregateAndFillDateGroupGaps(wireharness.calendar.df, 'Month', wireharnessNCR.df, c('PartAffected'), startDate, 'Record', 'sum', 0)
wireharnessRMA.fill <- aggregateAndFillDateGroupGaps(wireharness.calendar.df, 'Month', wireharnessRMA.df, c('PartNumber'), startDate, 'FailCount', 'sum', 0)
wireharness.all <- rbind(
  data.frame(DateGroup=wireharnessNCR.fill$DateGroup, 
             PartNumber=wireharnessNCR.fill$PartAffected,
             Record=wireharnessNCR.fill$Record,
             Type='NCR'),
  data.frame(DateGroup=wireharnessRMA.fill$DateGroup, 
             PartNumber=wireharnessRMA.fill$PartNumber,
             Record=wireharnessRMA.fill$FailCount,
             Type='RMA')
);
wireharness.all$PartNumber = as.character(wireharness.all$PartNumber);
wireharness.parts = sort(unique(wireharness.all$PartNumber));
wireharness.maxrecord <- max(wireharness.all$Record)
for(i in 1:wireharness.numCharts){
  partmin = floor(length(wireharness.parts) * ((i-1) / wireharness.numCharts))+1;
  partmax = floor(length(wireharness.parts) * (i / wireharness.numCharts));
  parts=wireharness.parts[partmin:partmax];
  wireharness.fill = subset(wireharness.all, PartNumber %in% parts);
  wireharness.fill = wireharness.fill[order(as.character(wireharness.fill$PartNumber)),]
  assign(paste("p.wireharness.count",i,sep=""),
         ggplot(wireharness.fill, aes(x=DateGroup, y=Record, group=Type, fill=Type)) + geom_bar(stat='identity', position='identity', alpha=.5, color='black') + scale_x_discrete(breaks=wireharness.dateBreaks) + scale_y_continuous(limits=c(0,wireharness.maxrecord)) + scale_fill_manual(values=c('blue','red'), name='') + facet_wrap(~PartNumber) + theme(axis.text.x=element_text(angle=90)) + labs(title='Count of Wire Harness NCRs and RMAs', x='Wire Harness Manufacture Date (Year-Month)', y='Count of NCRs/RMAs')
  );
}

# Wire harness NCR quantity affected
wireharnessNCR.qty.fill <- aggregateAndFillDateGroupGaps(wireharness.calendar.df, 'Month', wireharnessNCR.df, c('PartAffected'), startDate, 'QuantityAffected', 'sum', 0)
wireharnessNCR.qty.max = max(wireharnessNCR.qty.fill$QuantityAffected);
wireharnessRMA.infield <- aggregateAndFillDateGroupGaps(wireharness.calendar.df, 'Month', wireharnessRMA.df, c('PartNumber'), startDate, 'LotSizeInField', 'sum', 0)
wireharnessRMA.rate <- mergeCalSparseFrames(wireharnessRMA.fill, wireharnessRMA.infield, c('DateGroup','PartNumber'), c('DateGroup','PartNumber'), 'FailCount', 'LotSizeInField', 0, 0)
wireharnessRMA.rate.max = max(wireharnessRMA.rate$Rate);
wireharness.qty.all <- rbind(
  data.frame(DateGroup=wireharnessNCR.qty.fill$DateGroup, 
             PartNumber=wireharnessNCR.qty.fill$PartAffected,
             Record=wireharnessNCR.qty.fill$QuantityAffected,
             Type='NCR'),
  data.frame(DateGroup=wireharnessRMA.rate$DateGroup, 
             PartNumber=wireharnessRMA.rate$PartNumber,
             Record=wireharnessRMA.rate$Rate * wireharnessNCR.qty.max / wireharnessRMA.rate.max,
             Type='RMA')
);
wireharness.qty.all$PartNumber = as.character(wireharness.qty.all$PartNumber);
wireharness.qty.parts = sort(unique(wireharness.qty.all$PartNumber));
for(i in 1:wireharness.numCharts){
  partmin = floor(length(wireharness.parts) * ((i-1) / wireharness.numCharts))+1;
  partmax = floor(length(wireharness.parts) * (i / wireharness.numCharts));
  parts=wireharness.qty.parts[partmin:partmax];
  wireharness.fill = subset(wireharness.qty.all, PartNumber %in% parts);
  wireharness.fill = wireharness.fill[order(as.character(wireharness.fill$PartNumber)),]
  assign(paste("p.wireharness.quantity",i,sep=""),
         ggplot(wireharness.fill, aes(x=DateGroup, y=Record, group=Type, fill=Type)) + geom_bar(color='black', stat='identity', position='identity', alpha=.5) + scale_x_discrete(breaks=wireharness.dateBreaks) + scale_y_continuous(limits=c(0,wireharnessNCR.qty.max+1), sec.axis = sec_axis(~. * wireharnessRMA.rate.max / wireharnessNCR.qty.max, labels = scales::percent, name = "RMA Count / Lot Size In Field")) + facet_wrap(~PartNumber) + scale_fill_manual(values=c('blue','red'), name='')+ theme(axis.text.x=element_text(angle=90)) + labs(title='Wire harness NCR Quantity Affected and RMA Count/Lot Size In Field', x='Wire Harness Manufacture Date (Year-Month)', y='NCR Quantity affected')
  );
}

# create the charts for early failures of computers per 2.0 instruments shipped in a month (non-rolling), by version of computer
calendar.month <- createCalendarLikeMicrosoft(startYear, 'Month')
startMonth <- findStartDate(calendar.month, 'Month', 24, 0, keepPeriods=0)
computerEF2.df <- subset(computerEF.df, Version=='FA2.0')
compShip2.df <- subset(compShip.df, Version=='FA2.0')
computerEF.month <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', computerEF2.df, c('Version','CompVersion','Key'), startMonth, 'Record', 'sum', 0)
newShip.month <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', compShip2.df, c('Version'), startMonth, 'Record', 'sum', 0)
computerEF.fail.month <- mergeCalSparseFrames(computerEF.month, newShip.month, c('DateGroup','Version'), c('DateGroup','Version'), 'Record', 'Record', 0, 0)
computerEF.textShift = max(computerEF.fail.month$Rate)*.05;
computerEF.agg = aggregateAndFillDateGroupGaps(calendar.month, 'Month', computerEF.df, c('Version'), startMonth, 'Record', 'sum', 0)
computerEF.agg.rate = mergeCalSparseFrames(computerEF.agg, newShip.month, c('DateGroup','Version'), c('DateGroup','Version'), 'Record', 'Record', 0, 0)
computerEF.agg.merge = merge(computerEF.agg.rate, computerEF.agg, by=c('DateGroup','Version'))
p.computerEF.voe.month <- ggplot(computerEF.fail.month, aes(x=DateGroup, y=Rate, fill=CompVersion)) + geom_bar(stat='identity') + scale_fill_manual(values=createPaletteOfVariableLength(computerEF.fail.month, 'CompVersion'), name='') + facet_wrap(~Version, ncol=1, scale='free_y') + scale_y_continuous(label=percent) + theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Computer Early Failure Rates by Month', x='Date\n(Year-Month)', y='Failures/New Computers Shipped (Count shown above)') + geom_text(data=subset(computerEF.agg.merge,Record>0), aes(x=DateGroup, y=Rate+computerEF.textShift, label=Record), inherit.aes=FALSE, size=6) 

# Loose screw/fastener failures
looseScrew.fail <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', looseScrew.df, c('HoursRunBin'), '2015-01', 'Record', 'sum', 0)
newInst.fill <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', newInst.df, c('Key'), '2015-01', 'Record', 'sum', 0)
looseScrew.rate <- mergeCalSparseFrames(looseScrew.fail, newInst.fill, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0)
looseScrew.rate$Key <- 'Failures/Instruments Manufactured'
looseScrew.count <- looseScrew.fail;
looseScrew.count$Key <- 'Count of Failures';
colnames(looseScrew.count)[colnames(looseScrew.count)=='Record'] = 'Rate'
looseScrew.all <- rbind(looseScrew.rate, looseScrew.count)
looseScrew.all$HoursRunBin <- factor(looseScrew.all$HoursRunBin, levels = c('0-100','100-500','500-1000','1000+','Unknown'))
looseScrew.annot = rbind(
  data.frame(Label="Loose component check", DateGroup='2016-07', Key='Failures/Instruments Manufactured', Rate=.01),
  data.frame(Label="Loose component check", DateGroup='2016-07', Key='Count of Failures', Rate=2.5)
);
p.looseScrew.all.voe <- ggplot(looseScrew.all, aes(x=DateGroup, y=Rate, fill=HoursRunBin)) + geom_bar(stat='identity') + scale_fill_manual(values = createPaletteOfVariableLength(looseScrew.all, 'HoursRunBin'), name='') + theme(plot.title=element_text(hjust=0.5),text=element_text(size=fontSize, face=fontFace), axis.text=element_text(size=fontSize, face=fontFace, color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Loose Screw/Fastener Failures on New Instruments', y='Failures/Instrument Manufactured, Failure Count', x='Date of Instrument Manufacture\n(Year-Month)') +  geom_text(data = looseScrew.annot, inherit.aes = FALSE, aes(label=Label, x=DateGroup, y=Rate), angle=90, hjust=0, size=6, fontface='bold') + facet_wrap(~Key, ncol=1, scale='free_y');

# Edge loader complaints
edgeLoad.fail <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', edgeLoad.df, c('Version'), '2015-01', 'Record', 'sum', 0)
newInst.fill <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', subset(newInst.df, Version=='Torch'), c('Key'), '2015-01', 'Record', 'sum', 0)
idx = which(newInst.fill$Record > 10);
edgeLoad.rate <- mergeCalSparseFrames(edgeLoad.fail[idx,], newInst.fill[idx,], c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0)
edgeLoad.rate$Key <- 'Complaints/Torch Modules Manufactured (for months with >10 modules manufactured)'
edgeLoad.count <- edgeLoad.fail;
edgeLoad.count$Key <- 'Count of Complaints';
colnames(edgeLoad.count)[colnames(edgeLoad.count)=='Record'] = 'Rate'
edgeLoad.all <- rbind(edgeLoad.rate, edgeLoad.count)
edgeLoad.annot = rbind(
 data.frame(Label="Motor pulley setscrew update", DateGroup='2016-10', Key=edgeLoad.rate$Key[1], Rate=edgeLoad.rate$Rate[edgeLoad.rate$DateGroup=='2016-10']+.01),
 #data.frame(Label="Motor pulley setscrew update", DateGroup='2016-10', Key=edgeLoad.count$Key[1], Rate=edgeLoad.count$Rate[edgeLoad.count$DateGroup=='2016-10']+1),
 data.frame(Label="Clear sheet tightening", DateGroup='2017-04', Key=edgeLoad.rate$Key[1], Rate=edgeLoad.rate$Rate[edgeLoad.rate$DateGroup=='2017-04']+.01),
 data.frame(Label="Clear sheet tightening", DateGroup='2017-04', Key=edgeLoad.count$Key[1], Rate=edgeLoad.count$Rate[edgeLoad.count$DateGroup=='2017-04']+1)
);
p.edgeLoad.voe <- ggplot(subset(edgeLoad.all, DateGroup>='2016-06'), aes(x=DateGroup, y=Rate)) + geom_bar(stat='identity', color='black') + theme(axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Torch - Failure to Eject Pouch Complaints', y='Complaints/Torch Module Manufactured, Complaint Count', x='Date of Torch Module Manufacture\n(Year-Month)') + facet_wrap(~Key, ncol=1, scale='free_y') + geom_text(data = edgeLoad.annot, inherit.aes = FALSE, aes(label=Label, x=DateGroup, y=Rate), angle=90, hjust=0, size=5) 

# Seal Bar Thermistor Failures (Service Code 254)
shippedManf.fill = shippedManf.df %>%
  inner_join(calendar.df, by = c(DateOfManufacturing = 'Date')) %>%
  group_by(DateGroup, Version) %>% summarize(Shipped = n()) %>% ungroup() %>%
  filter(Version %in% c('FA2.0', 'Torch')) %>%
  complete(DateGroup = unique(calendar.df$DateGroup), Version, fill = list(Shipped = 0))
sealBarTherm.rate = sealBarTherm.df %>%
  inner_join(calendar.df, by = c(DateOfManufacturing = 'Date')) %>%
  mutate(HoursRunBin = cut(HoursRun, c(-Inf, 100, 500, 1000, Inf), labels = FALSE)) %>%
  mutate(HoursRunBin = factor(HoursRunBin, levels=c(1:4,NA), exclude = NULL,
                              labels = c('0-100', '100-500', '500-1000', '1000+', 'Unknown'))) %>%
  group_by(DateGroup, Version, HoursRunBin) %>% summarize(Failures = n()) %>% ungroup() %>%
  filter(Version %in% c('FA2.0', 'Torch')) %>%
  complete(DateGroup = unique(calendar.df$DateGroup), Version, HoursRunBin, fill = list(Failures = 0)) %>%
  inner_join(shippedManf.fill, by = c('DateGroup', 'Version')) %>%
  mutate(Rate = Failures/Shipped) %>%
  filter(DateGroup >= dateBreaks[1])
sealBarTherm.count =sealBarTherm.rate %>% 
  group_by(DateGroup, Version) %>% 
  summarize(Failures = sum(Failures), 
            Rate = sum(Rate), 
            Shipped = mean(Shipped))
p.sealBarThermistor = sealBarTherm.rate %>%
  ggplot(aes(x = DateGroup, y = Rate, fill = HoursRunBin)) +
  facet_wrap(~Version, ncol=1) +
  geom_col(color = 'black') +
  geom_text(data = sealBarTherm.count, aes(x = DateGroup, y = ifelse(is.na(Rate), 0, Rate), label = Failures), 
            inherit.aes = FALSE, nudge_y = .01) +
  geom_text(data = sealBarTherm.count, aes(x = DateGroup, y = 0, label = Shipped), 
            inherit.aes = FALSE, nudge_y = -.01, angle = 90) +
  annotate('text', x = '2017-19', y = .1, label = 'DX-CO-036177', angle = 90) +
  labs(title = 'Seal Bar Thermistor Failures (Service Code 254)',
       x = 'Instrument Date of Manufacturing (Year-Week)',
       y = 'Failures/New Instrument Shipped',
       fill = '') + 
  scale_x_discrete(breaks = dateBreaks) +
  scale_fill_manual(values = createPaletteOfVariableLength(as.data.frame(sealBarTherm.rate), 'HoursRunBin')) +
  theme(axis.text.x = element_text(angle=90, hjust=1),
        legend.position = 'bottom') 

# export images for web hub
plots <- ls()[grep('^p\\.', ls())]
for(i in 1:length(plots)) {
  imgName <- paste(substring(plots[i],3),'.png',sep='')
  png(file=paste0(imgDir,'/',imgName), width=1200, height=800, units='px')
  print(eval(parse(text = plots[i])))
  makeTimeStamp(author='Data Science')
  dev.off()
}

# Make pdf report for the web hub
pdf(paste0(pdfDir,'InstrumentVOE.pdf'), width = 11, height = 8)
for(i in 1:length(plots)) {
  print(eval(parse(text = plots[i])))
}
dev.off()

rm(list=ls())

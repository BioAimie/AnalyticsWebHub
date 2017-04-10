library(shiny)
library(shinydashboard)
library(shinysky)
library(DT)
library(stringr)

shinyServer(function(input, output, session) {
  # Load data on page load---------------------------------------------------------------------------------------------------
  withProgress(message = 'Loading Data...', value = 1, {source('reload.R', local=TRUE)})
  
  # Refresh Data------------------------------------------------------------------------------------------------------------
  observeEvent(input$refresh, {session$reload()})
  
  # Data Table tab----------------------------------------------------------------------------------------------------------
  
  summaryDT <- reactive({
    temp <- summary.df
    temp[,'Start Time'] <- as.character(temp[,'Start Time'])
    if(is.null(input$includeabg) | input$includeabg == FALSE) {
      temp <- temp[!grepl('alpha', temp[,'Sample ID'], ignore.case=TRUE) & !grepl('beta', temp[,'Sample ID'], ignore.case=TRUE) & !grepl('gamma', temp[,'Sample ID'], ignore.case=TRUE), ]
    }
    temp[, input$columnsVisible]
  })

  observe({
    if(is.null(input$selectAll))
      return()
    isolate({
      if (input$selectAll%%2 == 0) {
        updateCheckboxGroupInput(session,'columnsVisible',label = NULL,choices = colnames(summary.df), selected = colnames(summary.df))
      } else {
        updateCheckboxGroupInput(session,'columnsVisible',label = NULL,choices = colnames(summary.df))
      }
    })
  })

  output$dataTable <- renderDataTable({
    datatable(summaryDT(), filter = 'top', options = list(pageLength = 25, scrollX = TRUE, autoWidth=TRUE, columnDefs = list(list(width='200px', targets='_all'))), rownames=FALSE, escape = FALSE)
  })
  
  #QC Pouches Run to Date-----------------------------------------------------------------------------------------------------------------------
  makeQCPouches <- reactive({
    if(is.null(input$includeabg4) | input$includeabg4 == FALSE) {
      temp <- subset(allruns.df, !grepl('alpha', allruns.df$SampleId, ignore.case = TRUE) & !grepl('beta', allruns.df$SampleId, ignore.case = TRUE) & !grepl('gamma', allruns.df$SampleId, ignore.case = TRUE))
    } else {
      temp <- allruns.df
    }
    qcruns <- with(temp, aggregate(Record~Panel, FUN=sum))
    qcruns$Panel <- factor(qcruns$Panel, levels = as.character(qcruns[with(qcruns, order(Record)),'Panel']))
    ggplot(qcruns, aes(x=Panel, y=Record)) + geom_bar(stat='identity', fill = 'firebrick3') + coord_flip() + geom_text(aes(label=Record), hjust = 1.5, size = 5, fontface = 'bold', color='black') + theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5)) + labs(title='QC Pouches Run to Date', subtitle = 'Starting 1-1-2012', y='', x='')
  })

  output$qcpoucheschart <- renderPlot({
    makeQCPouches()
  })

  #Recent vs Previous Anomaly-----------------------------------------------------------------------------------------------------------------------
  makeRecentvPrev <- reactive({
    temp <- subset(allruns.df, !grepl('alpha', allruns.df$SampleId, ignore.case = TRUE) & !grepl('beta', allruns.df$SampleId, ignore.case = TRUE) & !grepl('gamma', allruns.df$SampleId, ignore.case = TRUE))

    if(!is.null(input$pouchserial1)) {
      exserials <- str_trim(unlist(strsplit(input$pouchserial1,',')), side = 'both')
      allqcruns.30 <- sum(subset(temp, ThirtyDayRun == 1 & !(PouchSerialNumber %in% exserials))[,'Record'])
      allqcruns.90 <- sum(subset(temp, NinetyDayRunNet == 1 & !(PouchSerialNumber %in% exserials))[,'Record'])
      anomaly.30 <- with(subset(temp, (CF > 0 | FP > 0 | FN > 0) & !is.na(RunObservation) & ThirtyDayRun == 1 & !(PouchSerialNumber %in% exserials)), aggregate(Record~RunObservation, FUN=sum))
      anomaly.90 <- with(subset(temp, (CF > 0 | FP > 0 | FN > 0) & !is.na(RunObservation) & NinetyDayRunNet == 1 & !(PouchSerialNumber %in% exserials)), aggregate(Record~RunObservation, FUN=sum))
    } else {
      allqcruns.30 <- sum(subset(temp, ThirtyDayRun == 1)[,'Record'])
      allqcruns.90 <- sum(subset(temp, NinetyDayRunNet == 1)[,'Record'])
      anomaly.30 <- with(subset(temp, (CF > 0 | FP > 0 | FN > 0) & !is.na(RunObservation) & ThirtyDayRun == 1), aggregate(Record~RunObservation, FUN=sum))
      anomaly.90 <- with(subset(temp, (CF > 0 | FP > 0 | FN > 0) & !is.na(RunObservation) & NinetyDayRunNet == 1), aggregate(Record~RunObservation, FUN=sum))
    }

    anomaly.30 <- merge(anomaly.30, runobs.df, all = TRUE)
    anomaly.30$Key <- '< 30 Day Anomaly'
    anomaly.30$Record <- with(anomaly.30,ifelse(is.na(Record), 0, Record))
    anomaly.30$Rate <- anomaly.30$Record / allqcruns.30
    anomaly.90 <- merge(anomaly.90, runobs.df, all = TRUE)
    anomaly.90$Key <- '31 - 90 Day Anomaly'
    anomaly.90$Record <- with(anomaly.90,ifelse(is.na(Record), 0, Record))
    anomaly.90$Rate <- anomaly.90$Record / allqcruns.90
    anomaly.pareto <- rbind(anomaly.30, anomaly.90)
    anomaly.pareto$RunObservation <- factor(anomaly.pareto$RunObservation, levels = as.character(anomaly.30[with(anomaly.30, order(Rate, decreasing = TRUE)),'RunObservation']))
    ggplot(anomaly.pareto, aes(x=RunObservation, y=Rate, fill=Key)) + geom_bar(stat='identity', position='dodge') + scale_fill_manual(name='', values = c('#a30000','#ff8585')) + scale_y_continuous(labels = percent)+ theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(size = 15, angle=45, hjust=1), plot.title = element_text(hjust=0.5)) + labs(title='Previous vs Recent Anomaly Rate', y='Observations per QC Runs', x='Anomaly Observations')
  })

  output$recentprevchart <- renderPlot({
    makeRecentvPrev()
  })

  #QC Anomlay Rate-----------------------------------------------------------------------------------------------------------------------
  makeQCAnomRate <- reactive({
    if(is.null(input$includeabg2) | input$includeabg2 == FALSE) {
      temp <- subset(allruns.df, !grepl('alpha', allruns.df$SampleId, ignore.case = TRUE) & !grepl('beta', allruns.df$SampleId, ignore.case = TRUE) & !grepl('gamma', allruns.df$SampleId, ignore.case = TRUE))
    } else {
      temp <- allruns.df
    }

    if(!is.null(input$pouchserial2)) {
      exserials <- str_trim(unlist(strsplit(input$pouchserial2,',')), side = 'both')
      anomaly.overall <- subset(temp, StartTime >= '2015-01-01' & !(PouchSerialNumber %in% exserials))
      allqcruns.denom <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', subset(temp, !(PouchSerialNumber %in% exserials)), 'Key', '2014-04', 'Record', 'sum', 1)
    } else {
      anomaly.overall <- subset(temp, StartTime >= '2015-01-01')
      allqcruns.denom <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', temp, 'Key', '2014-04', 'Record', 'sum', 1)
    }
    
    if(!is.null(input$panel2)) {
      anomaly.overall <- subset(anomaly.overall, Panel %in% input$panel2)  
    }

    anomaly.overall$DateGroup <- with(anomaly.overall, ifelse(Month < 10, paste0(Year, '-0', Month), paste0(Year, '-', Month)))
    anomaly.overallCF <- with(anomaly.overall, aggregate(CF~DateGroup, FUN=sum))
    colnames(anomaly.overallCF)[colnames(anomaly.overallCF) == 'CF'] <- 'Anomaly'
    anomaly.overallCF$Key <- 'Control Failure'
    anomaly.overallFP <- with(anomaly.overall, aggregate(FP~DateGroup, FUN=sum))
    colnames(anomaly.overallFP)[colnames(anomaly.overallFP) == 'FP'] <- 'Anomaly'
    anomaly.overallFP$Key <- 'False Positive'
    anomaly.overallFN <- with(anomaly.overall, aggregate(FN~DateGroup, FUN=sum))
    colnames(anomaly.overallFN)[colnames(anomaly.overallFN) == 'FN'] <- 'Anomaly'
    anomaly.overallFN$Key <- 'False Negative'
    anomaly.overall <- rbind(anomaly.overallCF, anomaly.overallFN, anomaly.overallFP)
    anomaly.rate <- merge(anomaly.overall, allqcruns.denom, by='DateGroup')
    anomaly.rate$Rate <- anomaly.rate$Anomaly / anomaly.rate$Record
    anomaly.rate$Key.x <- factor(anomaly.rate$Key.x, levels = c('False Positive','False Negative','Control Failure'))
    dateLabels <- as.character(unique(anomaly.rate[,'DateGroup']))[order(as.character(unique(anomaly.rate[,'DateGroup'])))]
    dateBreaks <- 1:length(as.character(unique(anomaly.rate[,'DateGroup'])))
    
    if(!is.null(input$anomalyfilter)) {
      ggplot(subset(anomaly.rate, Key.x %in% input$anomalyfilter), aes(x=as.numeric(as.factor(DateGroup)), y=Rate, fill=Key.x)) + geom_area(stat='identity', position = 'stack') + scale_fill_manual(name='', values = c('#7a0000','#cc0000','#ff8585')) + scale_x_continuous(breaks=dateBreaks, labels=dateLabels) + scale_y_continuous(labels = percent)+ theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(size = 15, angle=90, vjust=0.5), plot.title = element_text(hjust=0.5)) + labs(title='QC Anomaly Rate', y='Anomaly per QC Runs', x='Date\n(Year-Month)')
    } else {
      ggplot(anomaly.rate, aes(x=as.numeric(as.factor(DateGroup)), y=Rate, fill=Key.x)) + geom_area(stat='identity', position = 'stack') + scale_fill_manual(name='', values = c('#7a0000','#cc0000','#ff8585')) + scale_x_continuous(breaks=dateBreaks, labels=dateLabels) + scale_y_continuous(labels = percent)+ theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(size = 15, angle=90, vjust=0.5), plot.title = element_text(hjust=0.5)) + labs(title='QC Anomaly Rate', y='Anomaly per QC Runs', x='Date\n(Year-Month)')
    }
  })

  output$qcanomratechart <- renderPlot({
    makeQCAnomRate()
  })

  # Real False Positives By Panel--------------------------------------------------------------------------------------------------
  output$calendar <- renderUI({
    if(is.null(input$dateBut))
      return()
    
    if(input$dateBut == 'Custom') {
      dateRangeInput('dateRange2', label=NULL, start = '2015-01-01', min='2012-01-01')
    }
  })
  
  output$panVassay <- renderUI({
    if(is.null(input$panVassayBut))
      return()
    
    if(input$panVassayBut == 'Panel') {
      selectizeInput('panel3', 'Panel:', choices = c('All', 'BCID', 'GI', 'ME', 'RP'), selected = 'All', multiple = TRUE)
    } else {
      selectizeInput('assay', 'Assay:', choices = c('All', sort(unique(c(unique(str_trim(unlist(strsplit(as.character(unique(allruns.df$Control_Failures)), ',')))), unique(str_trim(unlist(strsplit(as.character(unique(allruns.df$False_Positives)), ',')))), unique(str_trim(unlist(strsplit(as.character(unique(allruns.df$False_Negatives)), ',')))))))), selected = 'All', multiple = TRUE)
    }
  })
  
  makeRealFPPanel <- reactive({
    if(is.null(input$includeabg3) | input$includeabg3 == FALSE) {
      temp <- subset(allruns.df, !grepl('alpha', allruns.df$SampleId, ignore.case = TRUE) & !grepl('beta', allruns.df$SampleId, ignore.case = TRUE) & !grepl('gamma', allruns.df$SampleId, ignore.case = TRUE))
    } else {
      temp <- allruns.df
    }
    #date input
    if(is.null(input$dateBut)) {
      return()
    } else if (input$dateBut == '1 Year') {
      temp <- subset(temp, StartTime >= Sys.Date() - 365)
      startD <- substr(as.character(Sys.Date()-365), 1, 7)
    } else if (input$dateBut == 'Historic') {
      startD <- substr(as.character(min(temp$StartTime)), 1, 7)
    } else {
      if(!is.null(input$dateRange2)) {
        temp <- subset(temp, StartTime >= input$dateRange2[1] & StartTime <= as.Date(input$dateRange2[2])+1)
        startD <- substr(input$dateRange2[1], 1, 7)
      } else {
        startD <- '2015-01'
      }
    }
    #Version
    if(!is.null(input$instVer))
      temp <- subset(temp, Version %in% input$instVer)
    #Pouch exclude
    if(!is.null(input$pouchserial5)) {
      exserials <- str_trim(unlist(strsplit(input$pouchserial5,',')), side = 'both')
      temp <- subset(temp, !(PouchSerialNumber %in% exserials))
    }
    #denominator
    allqcruns.denom <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', temp, 'Key', startD, 'Record', 'sum', 1)
    #run ob input
    if(!is.null(input$runOb2) & !('All' %in% input$runOb2)) {
      temp <- subset(temp, RunObservation %in% input$runOb2)
      runObSelected <- paste(input$runOb2, sep='', collapse = ', ')
    } else {
      temp <- subset(temp, !is.na(RunObservation))
      runObSelected <- 'All Run Observations'
    }
    #Panel or Assay
    if(is.null(input$panVassayBut) | input$panVassayBut == 'Panel') {
      if(!is.null(input$panel3) & !('All' %in% input$panel3)) {
        temp <- subset(temp, Panel %in% input$panel3)  
      }
      anomaly <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', temp, 'Panel', startD, 'Record', 'sum', 0)
      anomaly.rate <- mergeCalSparseFrames(anomaly, allqcruns.denom, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, 0)
      ggplot(anomaly.rate, aes(x=DateGroup, y=Rate, fill=Panel)) + geom_bar(stat='identity', position='stack') + scale_fill_manual(name='', values = createPaletteOfVariableLength(anomaly.rate, 'Panel')) + scale_y_continuous(labels = percent)+ theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(size = 15, angle=90, vjust=0.5), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5)) + labs(title='Anomalies By Panel', subtitle = runObSelected, y='Anomaly Rate', x='Date\n(Year-Month)')
    } else {
      pouchAssays <- subset(temp, select = c('PouchSerialNumber', 'Control_Failures', 'False_Negatives', 'False_Positives'))  
      serials <- as.character(unique(pouchAssays$PouchSerialNumber))
      assaySerials <- c()
      for(i in 1:length(serials)) {
        fn <- as.character(pouchAssays[pouchAssays$PouchSerialNumber == serials[i], 'False_Negatives'])[!is.na(as.character(pouchAssays[pouchAssays$PouchSerialNumber == serials[i], 'False_Negatives']))]
        fp <- as.character(pouchAssays[pouchAssays$PouchSerialNumber == serials[i], 'False_Positives'])[!is.na(as.character(pouchAssays[pouchAssays$PouchSerialNumber == serials[i], 'False_Positives']))]
        cf <- as.character(pouchAssays[pouchAssays$PouchSerialNumber == serials[i], 'Control_Failures'])[!is.na(as.character(pouchAssays[pouchAssays$PouchSerialNumber == serials[i], 'Control_Failures']))]
        assays <- str_trim(unlist(strsplit(paste(fn, fp, cf, sep=','),',')), side = 'both')
        temp1 <- c()
        if(length(assays) > 0) {
          for(j in 1:length(assays)){
            temp1 <- rbind(temp1, data.frame(PouchSerialNumber = serials[i], Assay = assays[j]))
            temp1 <- subset(temp1, Assay != '')
          }
          if(nrow(temp1) > 0){
            assaySerials <- rbind(assaySerials, temp1)
          }
        }
      }
      if(!is.null(input$assay) & !('All' %in% input$assay)) {
        temp <- merge(subset(assaySerials, Assay %in% input$assay), temp)  
      } else {
        temp <- merge(assaySerials, temp)
      }
      anomaly <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', temp, 'Assay', startD, 'Record', 'sum', 0)
      anomaly.rate <- mergeCalSparseFrames(anomaly, allqcruns.denom, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, 0)
      ggplot(anomaly.rate, aes(x=DateGroup, y=Rate, fill=Assay)) + geom_bar(stat='identity', position='stack') + scale_fill_manual(name='', values = colVector[1:length(unique(anomaly.rate$Assay))]) + scale_y_continuous(labels = percent)+ theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(size = 15, angle=90, vjust=0.5), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5)) + labs(title='Anomalies By Assay', subtitle = runObSelected, y='Anomaly Rate', x='Date\n(Year-Month)')
    }
  })

  output$fppanelchart <- renderPlot({
    makeRealFPPanel()
  })

  #Control Failure Pattern-----------------------------------------------------------------------------------------------------------------------
  makeControlFailurePattern <- reactive({
    if(is.null(input$includeabg5) | input$includeabg5 == FALSE) {
      temp <- subset(allruns.df, !grepl('alpha', allruns.df$SampleId, ignore.case = TRUE) & !grepl('beta', allruns.df$SampleId, ignore.case = TRUE) & !grepl('gamma', allruns.df$SampleId, ignore.case = TRUE))
    } else {
      temp <- allruns.df
    }
    #date input
    if(!is.null(input$dateRange1)) {
      temp <- subset(allruns.df, StartTime >= input$dateRange1[1] & StartTime <= as.Date(input$dateRange1[2])+1)
      startD <- substr(input$dateRange1[1], 1, 7)
    } else {
      startD <- '2012-01'
    }
    allqcruns.denom <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', temp, 'Key', startD, 'Record', 'sum', 1)
    
    #Panel input
    if(!is.null(input$panel4)) {
      temp <- subset(temp, Panel %in% input$panel4)
    }
    #runob input
    if(!is.null(input$runOb) & !('All' %in% input$runOb)) {
      temp <- subset(temp, RunObservation %in% input$runOb)
    } 
    #exclude pouch
    if(!is.null(input$pouchserial4)) {
      exserials <- str_trim(unlist(strsplit(input$pouchserial4,',')), side = 'both')
      temp <- subset(temp, !(PouchSerialNumber %in% exserials))
    }
    
    controlFails <- subset(temp, CF == 1)
    controlFails$Control_Failures <- gsub(',','-',controlFails$Control_Failures)
    controlFails <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', controlFails, 'Control_Failures', startD,'Record', 'sum', 0)
    controlFails$Control_Failures <- gsub('-',',',controlFails$Control_Failures)
    controlFails.rate <- mergeCalSparseFrames(controlFails, allqcruns.denom, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, 0)
    dateLabels <- as.character(unique(controlFails.rate[,'DateGroup']))[order(as.character(unique(controlFails.rate[,'DateGroup'])))]
    dateBreaks <- 1:length(as.character(unique(controlFails.rate[,'DateGroup'])))
    
    if(!is.null(input$runOb) & !('All' %in% input$runOb)){
      ggplot(controlFails.rate, aes(x=as.numeric(as.factor(DateGroup)), y=Rate, fill=Control_Failures)) + geom_area(stat='identity', position = 'stack') + scale_fill_manual(name='', values = createPaletteOfVariableLength(controlFails.rate, 'Control_Failures')) + scale_x_continuous(breaks=dateBreaks, labels=dateLabels) + scale_y_continuous(labels = percent)+ theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(size = 15, angle=90, vjust=0.5), plot.title = element_text(hjust=0.5), plot.caption = element_text(size=13, face = 'plain')) + labs(title='Control Failure Pattern', caption = paste0('Including: ', paste(input$runOb, sep='', collapse = ', ')), y='Anomaly Rate', x='Date\n(Year-Month)')  
    } else {
      ggplot(controlFails.rate, aes(x=as.numeric(as.factor(DateGroup)), y=Rate, fill=Control_Failures)) + geom_area(stat='identity', position = 'stack') + scale_fill_manual(name='', values = createPaletteOfVariableLength(controlFails.rate, 'Control_Failures')) + scale_x_continuous(breaks=dateBreaks, labels=dateLabels) + scale_y_continuous(labels = percent)+ theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(size = 15, angle=90, vjust=0.5), plot.title = element_text(hjust=0.5), plot.caption = element_text(size=13, face = 'plain')) + labs(title='Control Failure Pattern', y='Anomaly Rate', x='Date\n(Year-Month)')  
    }
  })
  
  output$cfpatternchart <- renderPlot({
    makeControlFailurePattern()
  })
  
  # downloads-----------------------------------------------------------------------------------------------------------------------
  output$downloadrecentvprev <- downloadHandler(
    filename = function() {
      paste0('RecentvPrev_',Sys.Date(),'.png')
    },
    content = function(file) {
      png(file, height=600, width=800)
      print(makeRecentvPrev())
      dev.off()
    }
  )

  output$downloadqcanomrate <- downloadHandler(
    filename = function() {
      paste0('QCAnomalyRate_',Sys.Date(),'.png')
    },
    content = function(file) {
      png(file, height=600, width=800)
      print(makeQCAnomRate())
      dev.off()
    }
  )

  output$downloadqcpouches <- downloadHandler(
    filename = function() {
      paste0('QCPouchesRun_',Sys.Date(),'.png')
    },
    content = function(file) {
      png(file, height=600, width=800)
      qcruns <- with(allruns.df, aggregate(Record~Panel, FUN=sum))
      qcruns$Panel <- factor(qcruns$Panel, levels = as.character(qcruns[with(qcruns, order(Record)),'Panel']))
      print(ggplot(qcruns, aes(x=Panel, y=Record)) + geom_bar(stat='identity', fill = 'firebrick3') + coord_flip() + geom_text(aes(label=Record), hjust = 1.5, size = 5, fontface = 'bold', color='white') + theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5)) + labs(title='QC Pouches Run to Date', subtitle = 'Starting 4-1-2014', y='', x=''))
      dev.off()
    }
  )

  output$downloaddt <- downloadHandler(
    filename = function() {
      paste0('SummaryAnomalyTable_',Sys.Date(),'.csv')
    },
    content = function(file) {
      write.csv(summaryDT(), file)
    }
  )

    output$downloadfppanel <- downloadHandler(
      filename = function() {
        paste0('RealFalsePositiveByPanel_',Sys.Date(),'.png')
      },
      content = function(file) {
        png(file, height=600, width=800)
        print(makeRealFPPanel())
        dev.off()
      }
    )
    
    output$downloadcfpattern <- downloadHandler(
      filename = function() {
        paste0('ControlFailurePattern_',Sys.Date(),'.png')
      },
      content = function(file) {
        png(file, height=600, width=800)
        print(makeControlFailurePattern())
        dev.off()
      }
    )
  
}) #end shinyServer
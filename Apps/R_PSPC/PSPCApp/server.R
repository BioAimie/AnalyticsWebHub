library(shiny)
library(shinydashboard)
library(shinysky)
library(DT)
library(stringr)
library(rhandsontable)

shinyServer(function(input, output, session) {
  # Load data on page load---------------------------------------------------------------------------------------------------
  withProgress(message = 'Loading Data...', value = 1, {source('reload.R', local=TRUE)})
  
  # Refresh Data------------------------------------------------------------------------------------------------------------
  observeEvent(input$refresh, {session$reload()})
  
  # Data Table tab----------------------------------------------------------------------------------------------------------
  
  summaryDT <- reactive({
    temp <- summary.df
    temp[,'Start Time'] <- as.character(temp[,'Start Time'])
    
    if(!is.null(input$excludeabg)){
      if('Alpha' %in% input$excludeabg) {
        temp <- temp[!grepl('alpha', temp[,'Sample ID'], ignore.case=TRUE), ]
      }
      
      if('Beta' %in% input$excludeabg) {
        temp <- temp[!grepl('beta', temp[,'Sample ID'], ignore.case=TRUE), ]
      }
      
      if('Gamma' %in% input$excludeabg) {
        temp <- temp[!grepl('gamma', temp[,'Sample ID'], ignore.case=TRUE), ]
      }
      
      if('Omega' %in% input$excludeabg) {
        temp <- temp[!grepl('omega', temp[,'Sample ID'], ignore.case=TRUE), ]
      }
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
    datatable(summaryDT(), filter = 'top', options = list(pageLength = 50, scrollX = TRUE, autoWidth=TRUE, columnDefs = list(list(width='100px', targets='_all'))), rownames=FALSE, escape = FALSE)
  })
  
  #QC Pouches Run to Date-----------------------------------------------------------------------------------------------------------------------
  makeQCPouches <- reactive({
    temp <- allruns.df
    
    if(!is.null(input$excludeabg3)){
      if('Alpha' %in% input$excludeabg3) {
        temp <- temp[!grepl('alpha', temp[,'SampleId'], ignore.case=TRUE), ]
      }
      
      if('Beta' %in% input$excludeabg3) {
        temp <- temp[!grepl('beta', temp[,'SampleId'], ignore.case=TRUE), ]
      }
      
      if('Gamma' %in% input$excludeabg3) {
        temp <- temp[!grepl('gamma', temp[,'SampleId'], ignore.case=TRUE), ]
      }
      
      if('Omega' %in% input$excludeabg3) {
        temp <- temp[!grepl('omega', temp[,'SampleId'], ignore.case=TRUE), ]
      }
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

    if(nrow(expouchserials) > 0) {
      exserials <- as.character(expouchserials[,'PouchSerialNumber'])
      if(!is.null(input$pouchserial1)) {
        exserials <- c(exserials, str_trim(unlist(strsplit(input$pouchserial1,',')), side = 'both'))
      }
    } else if (!is.null(input$pouchserial1)) {
      exserials <- str_trim(unlist(strsplit(input$pouchserial1,',')), side = 'both')
    } else {
      exserials <- c()
    }
    if(length(exserials > 0)) {
      exserials <- sprintf('%08d', as.numeric(exserials))
      temp <- subset(temp, !(PouchSerialNumber %in% exserials))
    }
    
    allqcruns.30 <- sum(subset(temp, ThirtyDayRun == 1)[,'Record'])
    allqcruns.90 <- sum(subset(temp, NinetyDayRunNet == 1)[,'Record'])
    anomaly.30 <- with(subset(temp, (CF > 0 | FP > 0 | FN > 0) & !is.na(RunObservation) & ThirtyDayRun == 1), aggregate(Record~RunObservation, FUN=sum))
    anomaly.90 <- with(subset(temp, (CF > 0 | FP > 0 | FN > 0) & !is.na(RunObservation) & NinetyDayRunNet == 1), aggregate(Record~RunObservation, FUN=sum))

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
    ggplot(anomaly.pareto, aes(x=RunObservation, y=Rate, fill=Key)) + geom_bar(stat='identity', position='dodge') + scale_fill_manual(name='', values = c('#a30000','#ff8585')) + scale_y_continuous(labels = percent)+ theme(text=element_text(size=20, face='bold'), axis.title = element_text(size=16), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(size = 15, angle=60, hjust=1), plot.title = element_text(hjust=0.5)) + labs(title='Previous vs Recent Anomaly Rate', y='Observations per QC Runs', x='Anomaly Observations')
  })

  output$recentprevchart <- renderPlot({
    makeRecentvPrev()
  })

  #QC Anomlay Rate-----------------------------------------------------------------------------------------------------------------------
  makeQCAnomRate <- reactive({
    temp <- allruns.df
    
    if(!is.null(input$excludeabg2)){
      if('Alpha' %in% input$excludeabg2) {
        temp <- temp[!grepl('alpha', temp[,'SampleId'], ignore.case=TRUE), ]
      }
      
      if('Beta' %in% input$excludeabg2) {
        temp <- temp[!grepl('beta', temp[,'SampleId'], ignore.case=TRUE), ]
      }
      
      if('Gamma' %in% input$excludeabg2) {
        temp <- temp[!grepl('gamma', temp[,'SampleId'], ignore.case=TRUE), ]
      }
      
      if('Omega' %in% input$excludeabg2) {
        temp <- temp[!grepl('omega', temp[,'SampleId'], ignore.case=TRUE), ]
      }
    }

    if(!is.null(input$panel2)) {
      temp <- subset(temp, Panel %in% input$panel2)
    }
    
    if(nrow(expouchserials) > 0) {
      exserials <- as.character(expouchserials[,'PouchSerialNumber'])
      if(!is.null(input$pouchserial2)) {
        exserials <- c(exserials, str_trim(unlist(strsplit(input$pouchserial2,',')), side = 'both'))
      }
    } else if (!is.null(input$pouchserial2)) {
      exserials <- str_trim(unlist(strsplit(input$pouchserial2,',')), side = 'both')
    } else {
      exserials <- c()
    }
    if(length(exserials > 0)) {
      exserials <- sprintf('%08d', as.numeric(exserials))
      temp <- subset(temp, !(PouchSerialNumber %in% exserials))   
    }
    
    anomaly.overall <- subset(temp, StartTime >= '2015-01-01')
    allqcruns.denom <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', temp, 'Key', '2014-04', 'Record', 'sum', 1)

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
    panelsFiltered <- paste0('Panels Included: ', paste(input$panel2, collapse = ', '))
    
    if(!is.null(input$anomalyfilter)) {
      ggplot(subset(anomaly.rate, Key.x %in% input$anomalyfilter), aes(x=as.numeric(as.factor(DateGroup)), y=Rate, fill=Key.x)) + geom_area(stat='identity', position = 'stack') + scale_fill_manual(name='', values = c('#7a0000','#cc0000','#ff8585')) + scale_x_continuous(breaks=dateBreaks, labels=dateLabels) + scale_y_continuous(labels = percent)+ theme(text=element_text(size=20, face='bold'), axis.title = element_text(size=16), axis.text=element_text(size=16, face='bold', color='black'), axis.text.x=element_text(size = 15, angle=90, vjust=0.5), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5)) + labs(title='QC Anomaly Rate', subtitle = panelsFiltered, y='Anomaly per QC Runs', x='Date\n(Year-Month)')
    } else {
      ggplot(anomaly.rate, aes(x=as.numeric(as.factor(DateGroup)), y=Rate, fill=Key.x)) + geom_area(stat='identity', position = 'stack') + scale_fill_manual(name='', values = c('#7a0000','#cc0000','#ff8585')) + scale_x_continuous(breaks=dateBreaks, labels=dateLabels) + scale_y_continuous(labels = percent)+ theme(text=element_text(size=20, face='bold'), axis.title = element_text(size=16), axis.text=element_text(size=16, face='bold', color='black'), axis.text.x=element_text(size = 15, angle=90, vjust=0.5), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5)) + labs(title='QC Anomaly Rate', subtitle = panelsFiltered, y='Anomaly per QC Runs', x='Date\n(Year-Month)')
    }
  })
  
  generateChart1 <- eventReactive(input$goButton1, {
    makeQCAnomRate()
  })

  output$qcanomratechart <- renderPlot({
    generateChart1()
  })

  # Run Observation Rates--------------------------------------------------------------------------------------------------
  output$calendar <- renderUI({
    if(is.null(input$dateBut))
      return()
    
    if(input$dateBut == 'Custom') {
      dateRangeInput('dateRange2', label=NULL, start = '2015-01-01', min='2012-01-01')
    }
  })
  
  createAssayList <- reactive({
    if(is.null(input$panel3) | 'All' %in% input$panel3) {
      temp <- subset(allruns.df, !is.na(RunObservation), select = c('Panel', 'Control_Failures', 'False_Negatives', 'False_Positives'))
      cf <- unique(as.character(temp$Control_Failures)[!is.na(temp$Control_Failures)])
      fn <- unique(as.character(temp$False_Negatives)[!is.na(temp$False_Negatives)])
      fp <- unique(as.character(temp$False_Positives)[!is.na(temp$False_Positives)])
      assays <- str_trim(unlist(strsplit(paste(fn, fp, cf, sep=','),',')), side = 'both')
      c('All', sort(unique(assays)))
    } else {
      temp <- subset(allruns.df, !is.na(RunObservation), select = c('Panel', 'Control_Failures', 'False_Negatives', 'False_Positives'))
      temp <- subset(temp, Panel %in% input$panel3)
      cf <- unique(as.character(temp$Control_Failures)[!is.na(temp$Control_Failures)])
      fn <- unique(as.character(temp$False_Negatives)[!is.na(temp$False_Negatives)])
      fp <- unique(as.character(temp$False_Positives)[!is.na(temp$False_Positives)])
      assays <- str_trim(unlist(strsplit(paste(fn, fp, cf, sep=','),',')), side = 'both')
      c('All', sort(unique(assays)))
    }
  })
  
  output$assayList <- renderUI({
    selectizeInput('assay', 'Assay:', choices = createAssayList(), selected = 'All', multiple = TRUE)
  })
  
  makeRealFPPanel <- reactive({
    temp <- allruns.df
    
    if(!is.null(input$excludeabg4)){
      if('Alpha' %in% input$excludeabg4) {
        temp <- temp[!grepl('alpha', temp[,'SampleId'], ignore.case=TRUE), ]
      }
      
      if('Beta' %in% input$excludeabg4) {
        temp <- temp[!grepl('beta', temp[,'SampleId'], ignore.case=TRUE), ]
      }
      
      if('Gamma' %in% input$excludeabg4) {
        temp <- temp[!grepl('gamma', temp[,'SampleId'], ignore.case=TRUE), ]
      }
      
      if('Omega' %in% input$excludeabg4) {
        temp <- temp[!grepl('omega', temp[,'SampleId'], ignore.case=TRUE), ]
      }
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
    if(nrow(expouchserials) > 0) {
      exserials <- as.character(expouchserials[,'PouchSerialNumber'])
      if(!is.null(input$pouchserial5)) {
        exserials <- c(exserials, str_trim(unlist(strsplit(input$pouchserial5,',')), side = 'both'))
      }
    } else if (!is.null(input$pouchserial5)) {
      exserials <- str_trim(unlist(strsplit(input$pouchserial5,',')), side = 'both')
    } else {
      exserials <- c()
    }
    if(length(exserials > 0)) {
      exserials <- sprintf('%08d', as.numeric(exserials))
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
    if(!is.null(input$panel3) & !('All' %in% input$panel3)) {
      temp <- subset(temp, Panel %in% input$panel3)  
    }
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
    temp[,'RunObservation'] <- gsub(', ','-',as.character(temp[,'RunObservation']))
    overallRate <- sum(temp$Record)/sum(allqcruns.denom$Record)
    if(is.null(input$panVassayBut) | input$panVassayBut == 'Panel') {
      anomaly <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', temp, c('Panel','RunObservation'), startD, 'Record', 'sum', 0)
      anomaly.rate <- mergeCalSparseFrames(anomaly, allqcruns.denom, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, 0)
      anomaly.rate$RunObservation <- factor(anomaly.rate$RunObservation, levels = as.character(with(anomaly.rate, aggregate(Rate~RunObservation, FUN=sum))[with(with(anomaly.rate, aggregate(Rate~RunObservation, FUN=sum)), order(Rate)), 'RunObservation']))
      ggplot(anomaly.rate, aes(x=DateGroup, y=Rate, fill=Panel, alpha=RunObservation)) + geom_bar(stat='identity', position='stack') + scale_fill_manual(name='', values = createPaletteOfVariableLength(anomaly.rate, 'Panel')) + scale_y_continuous(labels = percent)+ theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(size = 15, angle=90, vjust=0.5), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5), plot.caption = element_text(size = 13)) + labs(title='Anomalies By Panel', subtitle = paste0(runObSelected, ';   Overall Rate: ', format(overallRate, digits = 3)), y='Anomaly Rate', x='Date\n(Year-Month)', caption = paste0('Panel(s): ', paste0(input$panel3, collapse=', '), '     Assay(s): ', paste0(input$assay, collapse = ', '))) + scale_alpha_discrete(name='Run Observation', range = c(0.3,1))
    } else {
      anomaly <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', temp, c('Assay','RunObservation'), startD, 'Record', 'sum', 0)
      anomaly.rate <- mergeCalSparseFrames(anomaly, allqcruns.denom, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, 0)
      anomaly.rate$RunObservation <- factor(anomaly.rate$RunObservation, levels = as.character(with(anomaly.rate, aggregate(Rate~RunObservation, FUN=sum))[with(with(anomaly.rate, aggregate(Rate~RunObservation, FUN=sum)), order(Rate)), 'RunObservation']))
      ggplot(anomaly.rate, aes(x=DateGroup, y=Rate, fill=Assay, alpha=RunObservation)) + geom_bar(stat='identity', position='stack') + scale_fill_manual(name='', values = colVector[1:length(unique(anomaly.rate$Assay))]) + scale_y_continuous(labels = percent)+ theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(size = 15, angle=90, vjust=0.5), plot.title = element_text(hjust=0.5), plot.subtitle = element_text(hjust=0.5), plot.caption = element_text(size = 13)) + labs(title='Anomalies By Assay', subtitle = paste0(runObSelected, ';   Overall Rate: ', format(overallRate, digits = 3)), y='Anomaly Rate', x='Date\n(Year-Month)', caption = paste0('Panel(s): ', paste0(input$panel3, collapse=', '), '     Assay(s): ', paste0(input$assay, collapse = ', '))) + scale_alpha_discrete(name='Run Observation', range = c(0.3,1))
    }
  })
  
  generateRunObRateOnly <- reactive({
    temp <- allruns.df
    
    if(!is.null(input$excludeabg4)){
      if('Alpha' %in% input$excludeabg4) {
        temp <- temp[!grepl('alpha', temp[,'SampleId'], ignore.case=TRUE), ]
      }
      
      if('Beta' %in% input$excludeabg4) {
        temp <- temp[!grepl('beta', temp[,'SampleId'], ignore.case=TRUE), ]
      }
      
      if('Gamma' %in% input$excludeabg4) {
        temp <- temp[!grepl('gamma', temp[,'SampleId'], ignore.case=TRUE), ]
      }
      
      if('Omega' %in% input$excludeabg4) {
        temp <- temp[!grepl('omega', temp[,'SampleId'], ignore.case=TRUE), ]
      }
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
    if(nrow(expouchserials) > 0) {
      exserials <- as.character(expouchserials[,'PouchSerialNumber'])
      if(!is.null(input$pouchserial5)) {
        exserials <- c(exserials, str_trim(unlist(strsplit(input$pouchserial5,',')), side = 'both'))
      }
    } else if (!is.null(input$pouchserial5)) {
      exserials <- str_trim(unlist(strsplit(input$pouchserial5,',')), side = 'both')
    } else {
      exserials <- c()
    }
    if(length(exserials > 0)) {
      exserials <- sprintf('%08d', as.numeric(exserials))
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
    if(!is.null(input$panel3) & !('All' %in% input$panel3)) {
      temp <- subset(temp, Panel %in% input$panel3)  
    }
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
    temp[,'RunObservation'] <- gsub(', ','-',as.character(temp[,'RunObservation']))
    format(sum(temp$Record)/sum(allqcruns.denom$Record), digits = 3)   
  })
  
  generateRateOnly <- eventReactive(input$rateButton, {
    generateRunObRateOnly()  
  })
  
  output$rateOnlyOut <- renderUI({
    paste0('Overall Rate: ', generateRateOnly())
  })
  
  generateChart2 <- eventReactive(input$goButton2, {
    makeRealFPPanel()
  })
  
  output$fppanelchart <- renderPlot({
    generateChart2()
  })

  #Control Failure Pattern-----------------------------------------------------------------------------------------------------------------------
  makeControlFailurePattern <- reactive({
    temp <- allruns.df
    
    if(!is.null(input$excludeabg5)){
      if('Alpha' %in% input$excludeabg5) {
        temp <- temp[!grepl('alpha', temp[,'SampleId'], ignore.case=TRUE), ]
      }
      
      if('Beta' %in% input$excludeabg5) {
        temp <- temp[!grepl('beta', temp[,'SampleId'], ignore.case=TRUE), ]
      }
      
      if('Gamma' %in% input$excludeabg5) {
        temp <- temp[!grepl('gamma', temp[,'SampleId'], ignore.case=TRUE), ]
      }
      
      if('Omega' %in% input$excludeabg5) {
        temp <- temp[!grepl('omega', temp[,'SampleId'], ignore.case=TRUE), ]
      }
    }

    #date input
    if(!is.null(input$dateRange1)) {
      temp <- subset(allruns.df, StartTime >= input$dateRange1[1] & StartTime <= as.Date(input$dateRange1[2])+1)
      startD <- substr(input$dateRange1[1], 1, 7)
    } else {
      startD <- '2012-01'
    }
    
    #Panel input
    if(!is.null(input$panel4)) {
      temp <- subset(temp, Panel %in% input$panel4)
    }
    #exclude pouch
    if(nrow(expouchserials) > 0) {
      exserials <- as.character(expouchserials[,'PouchSerialNumber'])
      if(!is.null(input$pouchserial4)) {
        exserials <- c(exserials, str_trim(unlist(strsplit(input$pouchserial4,',')), side = 'both'))
      }
    } else if (!is.null(input$pouchserial4)) {
      exserials <- str_trim(unlist(strsplit(input$pouchserial4,',')), side = 'both')
    } else {
      exserials <- c()
    }
    if(length(exserials > 0)) {
      exserials <- sprintf('%08d', as.numeric(exserials))
      temp <- subset(temp, !(PouchSerialNumber %in% exserials))   
    }
    #denominator
    allqcruns.denom <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', temp, 'Key', startD, 'Record', 'sum', 1)
    
    #runob input
    if(!is.null(input$runOb) & !('All' %in% input$runOb)) {
      temp <- subset(temp, RunObservation %in% input$runOb)
    } 
    
    controlFails <- subset(temp, CF == 1)
    #assay input
    if(!is.null(input$assay2)) {
      controlFails <- subset(controlFails, Control_Failures %in% input$assay2)
    }
    controlFails$Control_Failures <- gsub(',','-',controlFails$Control_Failures)
    controlFails <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', controlFails, 'Control_Failures', startD,'Record', 'sum', 0)
    controlFails$Control_Failures <- gsub('-',',',controlFails$Control_Failures)
    controlFails.rate <- mergeCalSparseFrames(controlFails, allqcruns.denom, c('DateGroup'), c('DateGroup'), 'Record', 'Record', 0, 0)
    dateLabels <- as.character(unique(controlFails.rate[,'DateGroup']))[order(as.character(unique(controlFails.rate[,'DateGroup'])))]
    dateBreaks <- 1:length(as.character(unique(controlFails.rate[,'DateGroup'])))
    
    if(!is.null(input$runOb) & !('All' %in% input$runOb)){
      ggplot(controlFails.rate, aes(x=as.numeric(as.factor(DateGroup)), y=Rate, fill=Control_Failures)) + geom_area(stat='identity', position = 'stack') + scale_fill_manual(name='', values = createPaletteOfVariableLength(controlFails.rate, 'Control_Failures')) + scale_x_continuous(breaks=dateBreaks, labels=dateLabels) + scale_y_continuous(labels = percent)+ theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(size = 15, angle=90, vjust=0.5), plot.title = element_text(hjust=0.5), plot.caption = element_text(size=13, face = 'plain'), axis.title = element_text(size=16)) + labs(title='Control Failure Pattern', caption = paste0('Including: ', paste(input$runOb, sep='', collapse = ', '), '    Panels Included: ', paste(input$panel4, collapse=', ')), y='Anomaly Rate', x='Date\n(Year-Month)')  
    } else {
      ggplot(controlFails.rate, aes(x=as.numeric(as.factor(DateGroup)), y=Rate, fill=Control_Failures)) + geom_area(stat='identity', position = 'stack') + scale_fill_manual(name='', values = createPaletteOfVariableLength(controlFails.rate, 'Control_Failures')) + scale_x_continuous(breaks=dateBreaks, labels=dateLabels) + scale_y_continuous(labels = percent)+ theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(size = 15, angle=90, vjust=0.5), plot.title = element_text(hjust=0.5), plot.caption = element_text(size=13, face = 'plain'), axis.title = element_text(size=16)) + labs(title='Control Failure Pattern', y='Anomaly Rate', x='Date\n(Year-Month)', caption = paste0('Panels Included: ', paste(input$panel4, collapse=', ')))  
    }
  })
  
  generateChart3 <- eventReactive(input$goButton3, {
    makeControlFailurePattern()
  })
  
  output$cfpatternchart <- renderPlot({
    generateChart3()
  })
  
  # Permanently Exclude Pouch Serials ---------------------------------------------------------------------------------------------

  output$hot <- renderRHandsontable({
    if(!is.null(input$hot)) {
      DF <- hot_to_r(input$hot)
    } else {
      DF <- read.csv('C:/Users/pms_user/Documents/WebHub/PouchSPCExclude.csv')
    }
    rhandsontable(DF) %>%
      hot_cols(columnSorting=TRUE)
  })

  observe({
    input$savetable
    hot <- isolate(input$hot)
    if(!is.null(hot)) {
      write.csv(hot_to_r(input$hot), 'C:/Users/pms_user/Documents/WebHub/PouchSPCExclude.csv', row.names = FALSE)
    }
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
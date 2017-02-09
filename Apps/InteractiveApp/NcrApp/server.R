library(shiny)
library(shinyBS)
library(rCharts)

shinyServer(function(input, output, session) {

  #---------------Chart-----------------------------------------------------------------------------------------------------------------
  
  output$chartArea <- renderChart({
    if(is.null(input$dfName)) {
      df <- data.frame(DateGroup = 0, Record = 0)
      chart <- nPlot(Record~DateGroup, data = df, type = 'discreteBarChart')
      chart$xAxis(axisLabel = 'No Data')
      return(chart)
    } else
      # print(input$dfName) 
      # print(input$dateRange[1]) 
      # print(input$dateRange[2]) 
      # print(input$chartType) 
      # print(input$dateType)
      # print(input$fillVar)
      # print(input$partNum)
      # print(input$ncrType)
      # print(input$whereType)
      # print(input$problemType)
      # print(input$failType)
      if (input$chartType == 'Bar') {
       # chart <- makeRChart(input$dfName, input$dateRange[1], input$dateRange[2], input$chartType, input$dateType, input$fillVar, input$partNum, input$ncrType, input$whereType, input$cTitle, input$problemType, input$failType)
        data.agg <- makeRChartDataSet(input$dfName, input$dateRange[1], input$dateRange[2], input$chartType, input$dateType, input$fillVar, input$partNum, input$ncrType, input$whereType, input$problemType, input$failType, input$currWhere)
        chart <- nPlot(Record ~ DateGroup, group = input$fillVar, data = data.agg, type = 'multiBarChart', width = 1000, height = 600)
        chart$xAxis(axisLabel = paste('Date', paste0(paste0('(', input$dateType), ')')))
        chart$chart(stacked=TRUE, margin=list(left=75))
        chart$set(dom='chartArea')
        return(chart)
      } else if (input$chartType == 'Line') {
        data.agg <- makeRChartDataSet(input$dfName, input$dateRange[1], input$dateRange[2], input$chartType, input$dateType, input$fillVar, input$partNum, input$ncrType, input$whereType, input$problemType, input$failType, input$currWhere)
        chart <- nPlot(Record ~ Date, group = input$fillVar, data = data.agg, type = 'lineChart', width = 1000, height = 600)
        if(input$dateType == 'Year-Month') {
          #----month
          chart$xAxis(tickFormat =
                        "#!
                      function(d){
                      f =  d3.time.format.utc('%Y-%m');
                      return f(new Date( d*24*60*60*1000 ));
                      }
                      !#", 
                      axisLabel = paste('Date', paste0(paste0('(', input$dateType), ')')),
                      tickValues = "#!data[0].values.map(function(v){return v[opts.x]})
                      .filter(function(v){
                      return d3.time.format('%m')(new Date(v*60*60*24*1000)) % 2 == 0})
                      !#"
          )
        } else if(input$dateType == 'Year-Week') {
          #----week
          chart$xAxis(tickFormat =
                        "#!
                      function(d){
                      f =  d3.time.format.utc('%Y-%U');
                      return f(new Date( d*24*60*60*1000 ));
                      }
                      !#", 
                      axisLabel = paste('Date', paste0(paste0('(', input$dateType), ')')),
                      tickValues = "#!data[0].values.map(function(v){return v[opts.x]})
                      .filter(function(v){
                      return v % 4 == 0})
                      !#"
          )
        } else if(input$dateType == 'Year-Quarter') {
          #----quarter
          chart$xAxis(tickFormat =
                        "#!
                      function(d){
                      var date = new Date(d*24*60*60*1000);
                      var q = Math.floor((date.getMonth() + 3) / 3);
                      var y = date.getFullYear();
                      return ''+y+'-0'+q;
                      }
                      !#",
                      axisLabel = paste('Date', paste0(paste0('(', input$dateType), ')')),
                      tickValues = "#!data[0].values.map(function(v){return v[opts.x]})!#"
           )
        }
        
        chart$set(dom='chartArea')
        chart$chart(margin=list(right=100, left=75))
        return(chart)
      } else if (input$chartType == 'Area') {
          data.agg <- makeRChartDataSet(input$dfName, input$dateRange[1], input$dateRange[2], input$chartType, input$dateType, input$fillVar, input$partNum, input$ncrType, input$whereType, input$problemType, input$failType, input$currWhere)
          chart <- nPlot(Record ~ Date, group = input$fillVar, data = data.agg, type = 'stackedAreaChart', width = 1000, height = 600)
          if(input$dateType == 'Year-Month') {
            #----month
            chart$xAxis(tickFormat =
                          "#!
                        function(d){
                        f =  d3.time.format.utc('%Y-%m');
                        return f(new Date( d*24*60*60*1000 ));
                        }
                        !#", 
                        axisLabel = paste('Date', paste0(paste0('(', input$dateType), ')')),
                        tickValues = "#!data[0].values.map(function(v){return v[opts.x]})
                        .filter(function(v){
                        return d3.time.format('%m')(new Date(v*60*60*24*1000)) % 2 == 0})
                        !#"
            )
          } else if(input$dateType == 'Year-Week') {
            #----week
            chart$xAxis(tickFormat =
                          "#!
                        function(d){
                        f =  d3.time.format.utc('%Y-%U');
                        return f(new Date( d*24*60*60*1000 ));
                        }
                        !#", 
                        axisLabel = paste('Date', paste0(paste0('(', input$dateType), ')')),
                        tickValues = "#!data[0].values.map(function(v){return v[opts.x]})
                        .filter(function(v){
                        return v % 4 == 0})
                        !#"
            )
          } else if(input$dateType == 'Year-Quarter') {
            #----quarter
            chart$xAxis(tickFormat =
                          "#!
                        function(d){
                        var date = new Date(d*24*60*60*1000);
                        var q = Math.floor((date.getMonth() + 3) / 3);
                        var y = date.getFullYear();
                        return ''+y+'-0'+q;
                        }
                        !#",
                        axisLabel = paste('Date', paste0(paste0('(', input$dateType), ')')),
                        tickValues = "#!data[0].values.map(function(v){return v[opts.x]})!#"
            )
        }
          
          chart$set(dom='chartArea')
          chart$chart(margin=list(right=100, left = 75))
          return(chart)
      }
  })
  
  #--------Filters-------------------------------------------------------------------------------------------------------------
  
  #inital filters based on data set
  observe({
    if(is.null(input$dfName)) 
      return()
    
    output$filters <- renderUI({
      #NCR Parts
      if(input$dfName == 'NCRParts') {
        #print('in parts filter')
        list(checkboxGroupInput('ncrType','NCR Type:', choices = c('BioReagents','Cal/PM','FA1.5 Instrument WIP','FA2.0 Instrument WIP','HTFA Instrument WIP','Torch Instrument WIP','Instrument Production WIP','Raw Material'), selected=c('BioReagents','Cal/PM','FA1.5 Instrument WIP','FA2.0 Instrument WIP','HTFA Instrument WIP','Torch Instrument WIP','Instrument Production WIP','Raw Material'),inline=TRUE),
             actionLink('selectAll', label = 'Select All/Deselect All'),
             tags$div(class='mainFilters',textInput('partNum','Part Number(s):', placeholder = 'Comma separated list of parts')),
             radioButtons('fillVar', label = 'Color by: ', choices = list('Part Affected' = 'PartAffected', 'NCR Type' = 'Type'), selected = 'PartAffected',inline = TRUE))
      } 
      #NCR Where Found/Problem Area
      else if(input$dfName == 'NCRWhereProblem') {
        #print('in where filter')
        list(checkboxGroupInput('ncrType','NCR Type:', choices = c('BioReagents','Cal/PM','FA1.5 Instrument WIP','FA2.0 Instrument WIP','HTFA Instrument WIP','Torch Instrument WIP','Instrument Production WIP','Raw Material'), selected=c('BioReagents','Cal/PM','FA1.5 Instrument WIP','FA2.0 Instrument WIP','HTFA Instrument WIP','Torch Instrument WIP','Instrument Production WIP','Raw Material'),inline=TRUE),
             actionLink('selectAll', label = 'Select All/Deselect All'),
             tags$div(class='mainFilters', 
               selectizeInput('whereType', 'Where Found:', choices=currwhereFoundchoices(), multiple = TRUE, selected = 'All'),
               radioButtons('currWhere', label = NULL, choices = c('Current Where Found Categories', 'All Where Found Categories'), selected = 'Current Where Found Categories'),
               selectizeInput('problemType', 'Problem Area:', choices=problemAreaChoicesAllCurr(), multiple = TRUE)
             ),
             radioButtons('fillVar', label = 'Color by: ', choices = list('NCR Type' = 'Type','Where Found' = 'WhereFound','Problem Area' = 'ProblemArea'), selected = 'Type', inline=TRUE))
      }
      #NCR Fail/ SubFail Cat
      else if(input$dfName == 'NCRFail') {
         list(checkboxGroupInput('ncrType','NCR Type:', choices = c('BioReagents','Cal/PM','FA1.5 Instrument WIP','FA2.0 Instrument WIP','HTFA Instrument WIP','Torch Instrument WIP','Instrument Production WIP','Raw Material'), selected=c('BioReagents','Cal/PM','FA1.5 Instrument WIP','FA2.0 Instrument WIP','HTFA Instrument WIP','Torch Instrument WIP','Instrument Production WIP','Raw Material'),inline=TRUE),
              actionLink('selectAll', label = 'Select All/Deselect All'),
              tags$div(class = 'mainFilters',
                selectizeInput('whereType', 'Where Found:', choices=currwhereFoundchoices(), multiple = TRUE, selected = 'All'),
                radioButtons('currWhere', label = NULL, choices = c('Current Where Found Categories', 'All Where Found Categories'), selected = 'Current Where Found Categories'),
                selectizeInput('problemType', 'Problem Area:', choices=problemAreaChoicesAllCurr(), selected = 'All', multiple = TRUE),
                selectizeInput('failType', 'Failure Category:', choices=failCatChoicesAllCurr(), multiple = TRUE)
              ),
              radioButtons('fillVar', label = 'Color by: ', choices = list('NCR Type' = 'Type','Failure Category' = 'FailureCategory', 'SubFailure Category' = 'SubFailureCategory'), selected = 'Type', inline=TRUE))
      }  
    })  
  })
  
  #update NCR type based on select all/deselect all button
  observe({
    if(is.null(input$dfName) | is.null(input$selectAll))
      return()
    isolate({
      if (input$selectAll%%2 == 0) {
        updateCheckboxGroupInput(session,'ncrType','NCR Type:',choices = c('BioReagents','Cal/PM','FA1.5 Instrument WIP','FA2.0 Instrument WIP','HTFA Instrument WIP','Torch Instrument WIP','Instrument Production WIP','Raw Material'), selected=c('BioReagents','Cal/PM','FA1.5 Instrument WIP','FA2.0 Instrument WIP','HTFA Instrument WIP','Torch Instrument WIP','Instrument Production WIP','Raw Material'),inline=TRUE)
      } else {
        updateCheckboxGroupInput(session,'ncrType','NCR Type:',choices = c('BioReagents','Cal/PM','FA1.5 Instrument WIP','FA2.0 Instrument WIP','HTFA Instrument WIP','Torch Instrument WIP','Instrument Production WIP','Raw Material'),inline=TRUE)
      }
    })
  })
  
  #update Where Found based on radio button selection (all vs current categories)
  observe({
    if(is.null(input$dfName) | is.null(input$currWhere))
      return()
    isolate({
      if(input$currWhere == 'All Where Found Categories') {
        updateSelectizeInput(session, 'whereType', choices = allwhereFoundchoices(), selected = 'All')
      } else {
        updateSelectizeInput(session, 'whereType', choices = currwhereFoundchoices(), selected = 'All')
      }
    })
  })

  #update problem area based on where found selection
  observe({
    if(is.null(input$dfName) | is.null(input$whereType))
      return()
      if('All' %in% input$whereType) {
        if(input$currWhere == 'All Where Found Categories') {
          updateSelectizeInput(session, 'problemType', choices = problemAreaChoicesAllAll(), selected = 'All')
        } else {
          updateSelectizeInput(session, 'problemType', choices = problemAreaChoicesAllCurr(), selected = 'All')
        }
      } else {
        updateSelectizeInput(session, 'problemType', choices = problemAreaChoicesSelected(), selected = 'All')
      }
  })
   
  #update Failure category based on problem area and where found
  observe({
    if(is.null(input$dfName) | is.null(input$whereType) | is.null(input$problemType))
      return()
    #isolate({
      if('All' %in% input$whereType) {
        if(input$currWhere == 'All Where Found Categories') {
          if('All' %in% input$problemType) {
            # Where Found = All, All Where Found Cats, Problem Type = All
            updateSelectizeInput(session, 'failType', choices = failCatChoicesAllAll(), selected = 'All')
          } else {
            # Where Found = All, All Where Found Cats, Problem Type = specific
            updateSelectizeInput(session, 'failType', choices = problemAreaSpecificAllAll(), selected = 'All')
          }
        } else {
          if('All' %in% input$problemType) {
            # Where Found = All, Current Where Found Cats, Problem Type = All
            updateSelectizeInput(session, 'failType', choices = failCatChoicesAllCurr(), selected = 'All')
          } else {
            # Where Found = All, Current Where Found Cats, Problem Type = specific
            updateSelectizeInput(session, 'failType', choices = problemAreaSpecificAllCur(), selected = 'All')
          }
        }
      } else {
        if('All' %in% input$problemType){
          # Where Found = Specific, Problem Type = All
          updateSelectizeInput(session, 'failType', choices = failCatWFspecificPAll(), selected = 'All')
        } else {
          # Where Found = Specific, Problem Type = Specific
          updateSelectizeInput(session, 'failType', choices = failCatWFspecificPspecific(), selected = 'All')
        }
      }
    #})
  })

  currwhereFoundchoices <- reactive({
    #print('currWhere')
    # Current Where Found categories per NCR tracker
    currentWhereFoundCats <- c('Array Manufacture', 'Customer', 'Engineering', 'Final QC', 'Formulation', 'Functional Testing', 'Incoming Inspection',
                               'Instrument Service', 'Oligo Manufacture', 'Outgoing Inspection', 'Pouch Manufacture', 'SMI: Quality Inspection',
                               'Sniffing/Packaging', 'Tooling: WIP', 'Warehouse Receiving')
    activeWhereFound <- subset(NCRWhereProblem.df, WhereFound %in% currentWhereFoundCats)
    c('All', sort(unique(as.character(activeWhereFound$WhereFound))))
  })

  allwhereFoundchoices <- reactive({
    #print('allWhere')
    c('All', sort(unique(as.character(NCRWhereProblem.df$WhereFound))))
  })

  #Problem area choices filtered for current Where Found types only
  #Current Where Found Cats, All WF
  problemAreaChoicesAllCurr <- reactive({
    #print('in Problem Area Choices - AllCurr')
    # Current Where Found categories per NCR tracker
    currentWhereFoundCats <- c('Array Manufacture', 'Customer', 'Engineering', 'Final QC', 'Formulation', 'Functional Testing', 'Incoming Inspection',
                               'Instrument Service', 'Oligo Manufacture', 'Outgoing Inspection', 'Pouch Manufacture', 'SMI: Quality Inspection',
                               'Sniffing/Packaging', 'Tooling: WIP', 'Warehouse Receiving')
    temp <- subset(NCRWhereProblem.df, WhereFound %in% currentWhereFoundCats)
    c('All', sort(unique(as.character(temp$ProblemArea))))
  })

  #Problem area choices not filtered (all where founds)
  #All Where Found Cats, All WF
  problemAreaChoicesAllAll <- reactive({
    #print('in Problem Area Choices - AllAll')
    c('All', sort(unique(as.character(NCRWhereProblem.df$ProblemArea))))
  })

  #Problem area choices are filtered based on specific Where Found(s) selected
  problemAreaChoicesSelected <- reactive({
    #print('in Problem Area Choices - specific')
    temp <- subset(NCRWhereProblem.df, WhereFound %in% input$whereType)
    c('All', sort(unique(as.character(temp$ProblemArea))))
  })
  
  
  #Failure categories filtered by problem area and where found
  #Failure category choices filtered for all current Where Found types only, all problem areas
  failCatChoicesAllCurr <- reactive({
    # Current Where Found categories per NCR tracker
    currentWhereFoundCats <- c('Array Manufacture', 'Customer', 'Engineering', 'Final QC', 'Formulation', 'Functional Testing', 'Incoming Inspection',
                               'Instrument Service', 'Oligo Manufacture', 'Outgoing Inspection', 'Pouch Manufacture', 'SMI: Quality Inspection',
                               'Sniffing/Packaging', 'Tooling: WIP', 'Warehouse Receiving')
    temp <- subset(NCRFail.df, WhereFound %in% currentWhereFoundCats)
    c('All', sort(unique(as.character(temp$FailureCategory))))
  })
  
  #Failure category choices not filtered (all where founds)
  failCatChoicesAllAll <- reactive({
    c('All', sort(unique(as.character(NCRFail.df$FailureCategory))))
  })
   
  #Failure category choices are filtered based on specific Problem Area(s) selected
  #---Where Found = All, All Where Found Cats, Problem Type = specific
  problemAreaSpecificAllAll <- reactive({
    temp <- subset(NCRFail.df, ProblemArea %in% input$problemType)
    c('All', sort(unique(as.character(temp$FailureCategory))))
  })
  #---Where Found = All, Current Where Found Cats, Problem Type = specific
  problemAreaSpecificAllCur <- reactive({
    currentWhereFoundCats <- c('Array Manufacture', 'Customer', 'Engineering', 'Final QC', 'Formulation', 'Functional Testing', 'Incoming Inspection',
                               'Instrument Service', 'Oligo Manufacture', 'Outgoing Inspection', 'Pouch Manufacture', 'SMI: Quality Inspection',
                               'Sniffing/Packaging', 'Tooling: WIP', 'Warehouse Receiving')
    temp <- subset(NCRFail.df, WhereFound %in% currentWhereFoundCats)
    temp <- subset(temp, ProblemArea %in% input$problemType)
    c('All', sort(unique(as.character(temp$FailureCategory))))
  })
  
  #Failure category choices are filtered based on specific Where Found(s) selected
  #---Where Found = Specific, Problem Type = All
  failCatWFspecificPAll <- reactive({
    temp <- subset(NCRFail.df, WhereFound %in% input$whereType)
    c('All', sort(unique(as.character(temp$FailureCategory))))
  })
  
  #---Where Found = specific, Problem Type = specific
  failCatWFspecificPspecific <- reactive({
    #print('in specific, specific')
    temp <- subset(NCRFail.df, WhereFound %in% input$whereType)
    temp <- subset(temp, ProblemArea %in% input$problemType)
    c('All', sort(unique(as.character(temp$FailureCategory))))
  })
  
  #------------------------Downloads-------------------------------------------------------------------------------------------------------
  
  output$dataTableDownload <- downloadHandler(
    filename = function() {
      paste(input$dfName,'.csv', sep='')
    },
    content = function(file) {
      write.csv(makeDataTable(input$dfName, input$dateRange[1], input$dateRange[2], input$dateType, input$partNum, input$ncrType, input$whereType, input$problemType, input$failType), file, row.names=FALSE)
    }
  ) 
  
}) #end shinyServer
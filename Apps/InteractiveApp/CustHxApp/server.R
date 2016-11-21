library(shiny)
library(shinyBS)
library(DT)

shinyServer(function(input, output, session) {

    #Creates reactive drop down box - filtered by first letter of customer name
    observe({
      print(input$dfName)
      if(is.null(input$dfName))
        return()
      
      output$Filters <- renderUI ({
        list(
          tags$div(id='CustomerSelect', 
            h4('Customer Name: '),
            #action link to narrow down customer name list
            actionLink(class='aL', 'CustNum', label= '#'),
            actionLink(class='aL', 'CustAI', label= 'A-I'),
            actionLink(class='aL', 'CustJR', label= 'J-R'),
            actionLink(class='aL', 'CustSZ', label= 'S-Z'),
            actionLink(class='aL', 'CustAll', label= 'All'),
            selectizeInput('CustName',label = NULL, choices = sort(as.character(unique(CustHx.df[,'Customer Name'][CustHx.df[,'Customer Name'] != 'No Complaint Data']))), multiple = TRUE)
          ),
          tags$div(id='dateR', 
            h4('Date Range:'),
            dateRangeInput('dateRange', label=NULL, start = '2014-11-01', end = Sys.Date())
          )
        )
      })
    })
   
  
    observe({
      if(is.null(input$dfName) | is.null(input$CustAll))
        return()
      isolate({
          print('CustAll clicked')
          updateSelectizeInput(session, 'CustName', label = NULL, choices = sort(as.character(unique(CustHx.df[,'Customer Name'][CustHx.df[,'Customer Name'] != 'No Complaint Data']))))
      })
    })
    observe({
      if(is.null(input$dfName) | is.null(input$CustNum))
        return()
      isolate({
          print('# clicked')
          updateSelectizeInput(session, 'CustName', label = NULL,choices = sort(unique(grep('^[0-9]', CustHx.df[,'Customer Name'], value = TRUE))))
      })
    })
    observe({
      if(is.null(input$dfName) | is.null(input$CustAI))
        return()
      isolate({
          print('A-I clicked')
          updateSelectizeInput(session, 'CustName', label = NULL, choices = sort(unique(grep('^[A-Ia-i]', CustHx.df[,'Customer Name'], value = TRUE))))
      })
    })
    observe({
      if(is.null(input$dfName) | is.null(input$CustJR))
        return()
      isolate({
          print('J-R clicked')
          updateSelectizeInput(session, 'CustName', label = NULL, choices = sort(unique(grep('^[J-Rj-r]', CustHx.df[,'Customer Name'], value = TRUE))))
      })
    })
    observe({
      if(is.null(input$dfName) | is.null(input$CustSZ))
        return()
      isolate({
          print('S-Z clicked')
          updateSelectizeInput(session, 'CustName', label = NULL, choices = sort(unique(grep('^[S-Zs-z]', CustHx.df[,'Customer Name'], value = TRUE))))
      })
    })
    
    custData <- reactive({
      # print(input$CustName)
      # print(input$dateRange)
      CustHx.df[CustHx.df[ , 'Customer Name'] %in% input$CustName & as.character(CustHx.df[ , 'Date Created']) >= input$dateRange[1] & as.character(CustHx.df[ , 'Date Created']) <= input$dateRange[2], ]
    })  
    
    observe({
      if(is.null(input$dfName))
        return()
      output$dataTable <- renderDataTable(
        datatable(custData(), options = list(pageLength = 25), rownames=FALSE)
      )
    })
    
    output$dataTableDownload <- downloadHandler(
      filename = function() {
        paste(gsub(' ', '',input$CustName),'.csv', sep='')
      },
      content = function(file) {
        write.csv(custData(), file)
      }
    ) 
  
}) #end shinyServer
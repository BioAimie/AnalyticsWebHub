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
            h4('Customer Name:'),
            #action link to narrow down customer name list
            actionLink(class='aL', 'CustNum', label= '#'),
            actionLink(class='aL', 'CustAI', label= 'A-I'),
            actionLink(class='aL', 'CustJR', label= 'J-R'),
            actionLink(class='aL', 'CustSZ', label= 'S-Z'),
            actionLink(class='aL', 'CustAll', label= 'All'),
            selectizeInput('CustName',label = NULL, choices = sort(as.character(unique(CustHx.Names[,'Customer Name'][CustHx.Names[,'Customer Name'] != 'No Complaint Data']))), multiple = TRUE, options = list(placeholder = 'Type or select the Customer Name',  onInitialize = I('function() { this.setValue(""); }'))),
            h4('Customer ID:'),
            textInput('custID', label = NULL, value='', placeholder = 'Type the Customer ID'),
            h4('Serial Number:'),
            textInput('serialNo', label = NULL, value='', placeholder = 'Type the Instrument Serial Number')
          ),
          tags$div(id='dateR', 
            h4('Date Range:'),
            dateRangeInput('dateRange', label=NULL, start = '2014-11-01', end = Sys.Date())
          ),
          tags$div(id='cols',
            h4('Columns to show:'),
            checkboxGroupInput('columnsVisible', label = NULL, choices = colnames(CustHx.Names), selected = colnames(CustHx.Names)),
            actionLink('selectAll', label = 'Select All/Deselect All')
          )
        )
      })
    })
   
    observe({
      if(is.null(input$dfName) | is.null(input$selectAll))
        return()
      isolate({
        if (input$selectAll%%2 == 0) {
          updateCheckboxGroupInput(session,'columnsVisible',label = NULL,choices = colnames(CustHx.Names), selected = colnames(CustHx.Names))
        } else {
          updateCheckboxGroupInput(session,'columnsVisible',label = NULL,choices = colnames(CustHx.Names))
        }
      })
    })
  
    observe({
      if(is.null(input$dfName) | is.null(input$CustAll))
        return()
      isolate({
          #print('CustAll clicked')
          updateSelectizeInput(session, 'CustName', label = NULL, choices = sort(as.character(unique(CustHx.Names[,'Customer Name'][CustHx.Names[,'Customer Name'] != 'No Complaint Data']))))
      })
    })
    observe({
      if(is.null(input$dfName) | is.null(input$CustNum))
        return()
      isolate({
          #print('# clicked')
          updateSelectizeInput(session, 'CustName', label = NULL,choices = sort(unique(grep('^[0-9]', CustHx.Names[,'Customer Name'], value = TRUE))))
      })
    })
    observe({
      if(is.null(input$dfName) | is.null(input$CustAI))
        return()
      isolate({
          #print('A-I clicked')
          updateSelectizeInput(session, 'CustName', label = NULL, choices = sort(unique(grep('^[A-Ia-i]', CustHx.Names[,'Customer Name'], value = TRUE))))
      })
    })
    observe({
      if(is.null(input$dfName) | is.null(input$CustJR))
        return()
      isolate({
          #print('J-R clicked')
          updateSelectizeInput(session, 'CustName', label = NULL, choices = sort(unique(grep('^[J-Rj-r]', CustHx.Names[,'Customer Name'], value = TRUE))))
      })
    })
    observe({
      if(is.null(input$dfName) | is.null(input$CustSZ))
        return()
      isolate({
          #print('S-Z clicked')
          updateSelectizeInput(session, 'CustName', label = NULL, choices = sort(unique(grep('^[S-Zs-z]', CustHx.Names[,'Customer Name'], value = TRUE))))
      })
    })
    
    custData <- reactive({
      # print(input$CustName)
      # print(input$custID)
      # print(input$serialNo)
      # print('in reactive statement')
      # print(input$dateRange)
      # print(input$columnsVisible)
      #Find customer or serial number
      temp <- CustHx.Names
      
      if(!is.null(input$CustName)) 
        temp <- temp[temp[ , 'Customer Name'] %in% input$CustName, ]
      
      if(!is.null(input$custID) & input$custID != '') 
        temp <- temp[temp[ , 'Customer Id'] %in% grep(toupper(input$custID), temp[,'Customer Id'], value=TRUE), ] 
      
      if(!is.null(input$serialNo) & input$serialNo != '') 
        temp <- temp[temp[ , 'Serial Number'] %in% grep(toupper(input$serialNo), temp[,'Serial Number'], value=TRUE), ] 
      
      #subset based on date range
      temp <- temp[as.character(temp[ , 'Date Created']) >= input$dateRange[1] & as.character(temp[ , 'Date Created']) <= input$dateRange[2], ]
      
      #only show selected columns
      temp[, input$columnsVisible]
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
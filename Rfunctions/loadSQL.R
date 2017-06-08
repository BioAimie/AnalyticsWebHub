library(stringr)
library(readr)
library(RODBC)
library(tictoc);

# Function to run SQL query with ability to extract multiple outputs
loadSQL = function(cxn, filename, outputs){
  query = read_file(filename);
  querySplit = str_split(query, "\n--OUTPUT RESULT[^\\n\\r]*")[[1]];
  if(length(querySplit) != length(outputs)){
    stop(paste0("Number of OUTPUT tables does not agree with 'output' argument to loadSQL"));
  }
  cat(paste0("Loading ",filename,"\n"));
  for(i in seq_along(outputs)){
    tic();
    df = sqlQuery(cxn, querySplit[i], stringsAsFactors=FALSE);
    toc();
    if(class(df) != 'data.frame'){
      stop(df[1]); # Output error message
    }
    assign(outputs[i], df, envir=globalenv());
  }
}

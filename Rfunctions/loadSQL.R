library(stringr)
library(readr)
library(RODBC)

# Function to run SQL query with ability to extract multiple outputs
loadSQL = function(cxn, filename, outputs){
  query = read_file(filename);
  querySplit = str_split(query, "\n--OUTPUT RESULT[^\\n\\r]*")[[1]];
  if(length(querySplit) != length(outputs)){
    stop(paste0("Number of OUTPUT tables does not agree with 'output' argument to loadSQL"));
  }
  for(i in seq_along(outputs)){
    df = sqlQuery(cxn, querySplit[i], stringsAsFactors=FALSE);
    assign(outputs[i], df, envir=globalenv());
  }
}

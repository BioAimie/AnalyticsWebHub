library(RODBC)

# Open the connection to PMS1
PMScxn <- odbcConnect("PMS_PROD")

# Query failure RMAs
queryText <- readLines("SQL/MODEL_FailureRMAs.sql");
query <- paste(queryText,collapse="\n")
FailureRMAs <- sqlQuery(PMScxn,query)

# Close the connection to PMS1
odbcClose(PMScxn)

# Load predictions, models, and metrics
filenames = list.files(csvDir);
s = strsplit(filenames,'[\\.]')
predict_i = which(sapply(1:length(s), FUN=function(i){ length(s[[i]])>=4 & s[[i]][2]=='Predict'}));
model_i = which(sapply(1:length(s), FUN=function(i){ length(s[[i]])>=4 & s[[i]][2]=='Model'}));
metrics_i = which(sapply(1:length(s), FUN=function(i){ length(s[[i]])>=4 & s[[i]][2]=='Metrics'}));
predictions.df = do.call(rbind,lapply(predict_i,function(i){
  model = s[[i]][1];
  date = s[[i]][3];
  df = read.csv(paste(csvDir,filenames[i],sep=""), stringsAsFactors=FALSE)
  df %>% mutate(Model=model, Date=as.Date(date));
}));

modelfile.df = do.call(rbind,lapply(model_i,function(i){
  data.frame(File=filenames[i], Model=s[[i]][1], Date=s[[i]][3])
}));
latestModels = modelfile.df %>% group_by(Model) %>% arrange(Date) %>% top_n(1)
model.df = do.call(rbind,lapply(1:nrow(latestModels),function(i){
  df = read.csv(paste(csvDir,latestModels[i]$File,sep=""), stringsAsFactors=FALSE)
  df %>% mutate(Model=latestModels$Model[i], Date=as.Date(latestModels$Date[i]));
}));

metrics.df = do.call(rbind,lapply(metrics_i,function(i){
  model = s[[i]][1];
  date = s[[i]][3];
  df = read.csv(paste(csvDir,filenames[i],sep=""), stringsAsFactors=FALSE)
  df %>% mutate(Model=model, Date=as.Date(date));
}));

imgDir <- '~/WebHub/images/Dashboard_ReliabilityModeling'
workDir <- '~/WebHub/AnalyticsWebHub/'
csvDir = '\\\\Filer01/Data/Departments/PostMarket/DataScienceGroup/Data Science Products/ReliabilityModels/csv/'

setwd(workDir);
library(dplyr);
library(tidyr);
library(ggplot2);
library(gridExtra);
library(dateManip);
source("Portfolios/MODEL_load.R");
source('Rfunctions/makeTimeStamp.R')

# Chart parameters
startDate = as.Date("2017-04-20")
endDate = Sys.Date();
fontSize <- 20
fontFace <- 'bold'
calendar.week <- createCalendarLikeMicrosoft(2017, 'Week')

# Set ggplot theme
theme_set(theme_grey()+theme(plot.title=element_text(hjust=0.5), plot.subtitle=element_text(hjust=0.5), text=element_text(size=fontSize, face=fontFace), axis.text=element_text(color='black',size=fontSize,face=fontFace)))

# For efficient processing, store predictions into an environment (hash table) indexed by serial number
models = unique(predictions.df$Model);
serials = unique(predictions.df$SerialNo);
predictionsBySerial = split(predictions.df, predictions.df$SerialNo);
predictionsBySerialEnv = new.env(parent = emptyenv(), size=length(serials)*2);
for(i in 1:length(predictionsBySerial)){
  predictionsBySerialEnv[[ as.character(predictionsBySerial[[i]]$SerialNo[1]) ]] = predictionsBySerial[[i]];
}

# Select RMAs for new instrument failures
newInstFailHours = 
  FailureRMAs %>% filter(Failure==1, RMANo==1, !is.na(HoursRun)) %>% 
  select(SerialNo, HoursRunRecordedDate, HoursRun) %>%
  mutate(SerialNo = as.character(SerialNo))
#newInstFailHours$SerialNo = as.character(newInstFailHours$SerialNo);

# Score predictions for hours run at failure
predictedFailHours = function(model, serialNo, date){
  P = predictionsBySerialEnv[[ serialNo ]];
  preds = subset(P, P$Model == model & P$Date < date);
  if(nrow(preds)>0){
    k = which.max(preds$Date);
    return(preds$FailHours[k]);
  }else{
    return(NA);
  }
}
models.df = data.frame(Model = models);
failHours.df = newInstFailHours %>%  merge(models.df) %>% rowwise() %>% 
  mutate(FailHours = predictedFailHours(Model, SerialNo, HoursRunRecordedDate)) %>% ungroup()

# Scatterplot comparing recorded hours run vs. prediction at failure
p.predict.failhours.scatterplot = ggplot(failHours.df %>% filter(!is.na(FailHours))) + geom_point(aes(x=FailHours, y=HoursRun)) +
  geom_abline(intercept=0, slope=1) + facet_wrap(~Model) + labs(title = 'Predicted vs. recorded hours run at failure', y = 'Recorded hours run', x = 'Predicted hours run') 
  
# Empirical survival function of recorded hours run vs. prediction at failure
surv.df = 
  failHours.df %>% filter(!is.na(FailHours)) %>% group_by(Model) %>% 
  arrange(FailHours) %>% mutate(predSurv = 1-row_number()/n()) %>%
  arrange(HoursRun) %>% mutate(recSurv = 1-row_number()/n()) %>% ungroup()
surv.melted = 
  rbind(surv.df %>% select(Model, Hours=FailHours, Surv=predSurv) %>% mutate(variable='Predicted hours run'),
        surv.df %>% select(Model, Hours=HoursRun, Surv=recSurv) %>% mutate(variable='Recorded hours run')) %>%
  arrange(Hours, desc(Surv));
p.predict.failhours.survival = ggplot(surv.melted) + facet_wrap(~Model) + geom_step(aes(x=Hours, y=Surv, group=variable, linetype=variable)) + labs(x="Hours Run", y="Proportion of observed failures", title="Distribution of predicted vs. recorded hours run at FA2.0 first failure") + theme(legend.title=element_blank())

# Weekly average absolute error between predicted and recorded run hours at failure
weekly.df = 
  failHours.df %>% 
  inner_join(calendar.week, by=c('HoursRunRecordedDate'='Date')) %>%
  mutate(Error = abs(FailHours - HoursRun)) %>%
  group_by(Model, DateGroup) %>% summarize(AverageError = mean(Error)) %>%
  na.omit()
p.predict.failhours.score = ggplot(weekly.df, aes(x=DateGroup, y=AverageError, group=Model, color=Model)) + geom_line() + geom_point() + theme(axis.text.x=element_text(angle=90, vjust=0.5)) + labs(x="Date (Year-Week)", y="Average absolute error", title="Absolute error between predicted and recorded run hours at failure")

# Models for density function
p.model.density = ggplot(model.df %>% filter(HoursRun <= 3000), aes(x=HoursRun, y=Density, group=Model, color=Model)) + geom_line() + labs(x="Hours Run", y="Failure probability/hour run", title="Estimated density function of FA2.0 hours run to first failure") + ylim(0,max(model.df$Density))

# Models for hazard function
p.model.hazard = ggplot(model.df %>% filter(HoursRun <= 3000), aes(x=HoursRun, y=Hazard, group=Model, color=Model)) + geom_line() + labs(x="Hours Run", y="Failure probability/hour run", title="Estimated hazard function of FA2.0 hours run to first failure") + ylim(0,max(model.df$Hazard))

# Models for survival function
p.model.survival = ggplot(model.df %>% filter(HoursRun <= 3000), aes(x=HoursRun, y=Survival, group=Model, color=Model)) + geom_line() + labs(x="Hours Run", y="Survival probability", title="Estimated survival function of FA2.0 hours run to first failure") + ylim(0,1)

# Reliability metrics
setwd(imgDir)
metrics.tidy = metrics.df %>% spread(Metric, Estimate) %>% select(-Date)
png("reliability.metrics.png", width=450, height=(nrow(metrics.tidy)+1)*30)
grid.table(metrics.tidy, rows=NULL)
dev.off()

# Export Images for the Web Hub
plots <- ls()[grep('^p\\.', ls())]
for(i in 1:length(plots)) {
  imgName <- paste(substring(plots[i],3),'.png',sep='')
  
  png(file=imgName, width=1200, height=800, units='px')
  print(get(plots[i]))
  makeTimeStamp(author='Data Science')
  dev.off()
}

# Set the environment
workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <-  '~/WebHub/images/Dashboard_Trends/'
pdfDir <- '~/WebHub/pdfs/'

setwd(workDir)

# Load needed libraries
library(ggplot2)
library(scales)
library(grid)
library(gridExtra)
library(gtable)
library(lubridate)
library(RColorBrewer)
library(dplyr)
library(sendmailR)
library(RGoogleAnalytics)
library(EpiWeek)
library(devtools)
install_github('dateManip','BioAimie')
library(dateManip)

# load the data from SQL
source('Portfolios/F_TREND_load.R')
source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/normalizeBurnRate.R')
source('Rfunctions/makeTimeStamp.R')

# Determine a smart start date for each panel by figuring out when 3 sites have data for a consecutive amount of time
start.year <- 2014
panel.dates <- with(data.frame(unique(runs.df[,c('Date','Panel','CustomerSiteId')]), Record = 1), aggregate(Record~Date+Panel, FUN=sum))
rp.date <- min(panel.dates[panel.dates$Panel=='RP' & panel.dates$Record >= 3, 'Date'])
bcid.date <- min(panel.dates[panel.dates$Panel=='BCID' & panel.dates$Record >= 3, 'Date'])
gi.date <- min(panel.dates[panel.dates$Panel=='GI' & panel.dates$Record >= 3, 'Date'])
me.date <- min(panel.dates[panel.dates$Panel=='ME' & panel.dates$Record >= 3, 'Date'])

# create a calendar using RPs start year by month, and create a calendar by reporting weeks for the CDC
calendar.month <- createCalendarLikeMicrosoft(year(rp.date), 'Month')
calendar.week <- createCalendarLikeMicrosoft(year(rp.date), 'Week')
calendar.week <- transformToEpiWeeks(calendar.week)
calendar.week$YearWeek <- with(calendar.week, ifelse(Week < 10, paste(Year, Week, sep='-0'), paste(Year, Week, sep='-')))

# cumulative total run counts uploaded by panel
runs.month <- merge(runs.df, calendar.month, by='Date')
panel.runs.fill <- aggregateAndFillDateGroupGaps(calendar.month, 'Month', runs.month, c('Panel'), min(calendar.month$DateGroup), 'Record', 'sum', 0)
panel.runs.cumulative <- do.call(rbind, lapply(1:length(unique(panel.runs.fill$Panel)), function(x) data.frame(DateGroup = panel.runs.fill[panel.runs.fill$Panel == unique(panel.runs.fill$Panel)[x], 'DateGroup'], Panel = unique(panel.runs.fill$Panel)[x], Record = sapply(1:length(panel.runs.fill[panel.runs.fill$Panel == unique(panel.runs.fill$Panel)[x], 'DateGroup']), function(y) sum(panel.runs.fill[panel.runs.fill$Panel == unique(panel.runs.fill$Panel)[x], 'Record'][1:y])))))
sites.running.panel <- with(unique(runs.month[,c('DateGroup','Panel','CustomerSiteId','Record')]), aggregate(Record~DateGroup+Panel, FUN=sum))
panel.runs.cumulative.sites <- merge(panel.runs.cumulative, sites.running.panel, by=c('DateGroup','Panel'))
date.groups.month <- as.character(unique(panel.runs.cumulative.sites$DateGroup))[order(as.character(unique(panel.runs.cumulative.sites$DateGroup)))][seq(1, length(as.character(unique(panel.runs.cumulative.sites$DateGroup))), 8)]
p.panel.runs.cumulative <- ggplot(panel.runs.cumulative.sites, aes(x=DateGroup, y=Record.x, fill=as.factor(Record.y))) + geom_bar(stat='identity') + facet_wrap(~Panel, scale='free_y') + scale_x_discrete(breaks = date.groups.month) + theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_fill_manual(values=createPaletteOfVariableLength(panel.runs.cumulative.sites, 'Record.y', TRUE), name='Contributing\nSites') + labs(title='Cumulative Total Run Count at Participating Trend Sites by Panel', y='Cumulative Run Count', x='Year-Month')

# monthly data contribution trend - see above???
panel.runs.fill.sites <- merge(panel.runs.fill, sites.running.panel, by=c('DateGroup','Panel'))
p.panel.runs <- ggplot(panel.runs.fill.sites, aes(x=DateGroup, y=Record.x, fill=as.factor(Record.y))) + geom_bar(stat='identity') + facet_wrap(~Panel, scale='free_y') + scale_x_discrete(breaks = date.groups.month) + theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(angle=90, hjust=1)) + scale_fill_manual(values=createPaletteOfVariableLength(panel.runs.cumulative.sites, 'Record.y', TRUE), name='Contributing\nSites') + labs(title='Run Count at Participating Trend Sites by Panel', y='Monthly Run Count', x='Year-Month')

# # data contribution by site - COMMENT OUT BECAUSE THIS CANNOT BE ON THE WEBHUB
# p.rp.runs.site <- ggplot(subset(runs.month, Panel=='RP'), aes(x=DateGroup, y=Record, fill=Panel)) + geom_bar(stat='identity') + facet_wrap(~CustomerSiteId, scales='free_y') + scale_fill_manual(values=createPaletteOfVariableLength(subset(runs.month, Panel=='RP'), 'Panel'), guide=FALSE) + scale_x_discrete(breaks = date.groups.month) + theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(angle=90, hjust=1)) + labs(title='Run Count of RP Panel at Participating Trend Sites', y='Monthly Run Count', x='Year-Month')

# --------------------------------- RUN RATE AND PREVALENCE CHARTS ----------------------------------------------
calendar.df <- calendar.week[,c('Date','Year','Week','YearWeek')]
calendar.df$Days <- 1
runs.reg.date <- merge(runs.df, calendar.df, by='Date')
var <- 'CustomerSiteId'
sites <- unique(runs.reg.date$CustomerSiteId)

# update the dates now that the cumulative count doesn't need to be used
panel.dates <- panel.dates[year(panel.dates$Date) >= start.year, ]
rp.date <- min(panel.dates[panel.dates$Panel=='RP' & panel.dates$Record >= 3, 'Date'])
bcid.date <- min(panel.dates[panel.dates$Panel=='BCID' & panel.dates$Record >= 3, 'Date'])
gi.date <- min(panel.dates[panel.dates$Panel=='GI' & panel.dates$Record >= 3, 'Date'])
me.date <- min(panel.dates[panel.dates$Panel=='ME' & panel.dates$Record >= 3, 'Date'])
# ------------------
# Respiratory Panel:
rp.runs.reg <- runs.reg.date[runs.reg.date$Panel=='RP', ]
sites <- unique(rp.runs.reg$CustomerSiteId)
rp.runs.reg.norm <- c()
for(i in 1:length(sites)) {
  
  site.norm <- normalizeBurnRate(calendar.df, rp.runs.reg, var, sites[i])
  rp.runs.reg.norm <- rbind(rp.runs.reg.norm, site.norm)
}

sites <- unique(rp.runs.reg.norm$CustomerSiteId)

# make a season intenstity chart by showing normalized run rates in season-week format
rp.runs.norm.nat <- with(subset(rp.runs.reg.norm, CustomerSiteId %in% sites), aggregate(NormalizedBurn~YearWeek+Year+Week, FUN=mean))

# because the RP season spans two years, it's easier to offset the week by 26
rp.runs.norm.nat$SeasonYear <- with(rp.runs.norm.nat, ifelse(Week < 26, Year - 1, Year))
rp.runs.norm.nat$SeasonWeek <- with(rp.runs.norm.nat, ifelse(Week >= 26, Week - 25, 28 + Week))
rp.runs.norm.nat$Season <- paste(rp.runs.norm.nat$SeasonYear,rp.runs.norm.nat$SeasonYear+1,sep='-')
pal.season.overlay <- createPaletteOfVariableLength(subset(rp.runs.norm.nat, SeasonYear > 2012), 'Season')
pal.season.overlay[max(names(pal.season.overlay))] <- '#ff0000'
p.rp.season.overlay <- ggplot(subset(rp.runs.norm.nat, SeasonYear > 2012), aes(x=SeasonWeek, y=NormalizedBurn, group=Season, color=Season)) + geom_line(size=1.5) + scale_color_manual(values=pal.season.overlay, name='Respiratory Season') + theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, color='black', face='bold')) + scale_x_continuous(breaks=seq(1, 53, 4)) + labs(title='Normalized RP Burn Rate at Trend Sites', x='Season Week', y='Normalized Burn Rate')

# get percent detection of organisms in the RP panel
rp.bugs.reg <- c()
for(i in 1:length(sites)) {
  
  site <- sites[i]
  temp <- rp.runs.reg[rp.runs.reg$CustomerSiteId == site, ]
  rp.bugs.site <- merge(temp, bugs.df, by='RunDataId')
  rp.bugs.reg <- rbind(rp.bugs.reg, rp.bugs.site)
}

rp.bugs.reg <- rp.bugs.reg[rp.bugs.reg$Interpretation != 'Bocavirus', ]
sites <- sites[order(sites)]
bugs <- as.character(unique(rp.bugs.reg$Interpretation))[order(as.character(unique(rp.bugs.reg$Interpretation)))]

# make a combined category so that do.call can be used to fill in empty dates
colsToCat <- c('CustomerSiteId','Interpretation')
rp.bugs.reg.trim <- rp.bugs.reg[,c('YearWeek', colsToCat)]
rp.bugs.reg.trim$Record <- 1
rp.bugs.reg.trim <- rbind(rp.bugs.reg.trim, do.call(rbind, lapply(1:length(sites), function(x) data.frame(YearWeek=max(unique(rp.bugs.reg$YearWeek)), CustomerSiteId = sites[x], Interpretation = bugs, Record = 0))))
rp.bugs.reg.trim$combocat <- do.call(paste, c(rp.bugs.reg.trim[,colsToCat], sep=','))
rp.bugs.reg.combo <- do.call(rbind, lapply(1:length(unique(rp.bugs.reg.trim$combocat)), function(x) cbind(merge(unique(calendar.df[calendar.df$Date >= rp.date,c('YearWeek','Year')]), rp.bugs.reg.trim[rp.bugs.reg.trim$combocat == unique(rp.bugs.reg.trim$combocat)[x], c('YearWeek','Record')], by='YearWeek', all.x=TRUE), ComboCat = unique(rp.bugs.reg.trim$combocat)[x])))
deCombo <- as.data.frame(sapply(1:length(colsToCat), function(x) do.call(rbind, strsplit(as.character(rp.bugs.reg.combo$ComboCat), split=','))[,x]))
colnames(deCombo) <- colsToCat
rp.bugs.reg.fill <- cbind(rp.bugs.reg.combo[,c('YearWeek','Record')], deCombo)
rp.bugs.reg.fill[is.na(rp.bugs.reg.fill$Record),'Record'] <- 0
rp.bugs.reg.agg <- with(rp.bugs.reg.fill, aggregate(Record~YearWeek+CustomerSiteId+Interpretation, FUN=sum))
rp.bugs.reg.roll <- do.call(rbind, lapply(1:length(sites), function(x) do.call(rbind, lapply(1:length(bugs), function(y) data.frame(YearWeek = rp.bugs.reg.agg[rp.bugs.reg.agg$CustomerSiteId==sites[x] & rp.bugs.reg.agg$Interpretation==bugs[y], 'YearWeek'][2:(length(rp.bugs.reg.agg[rp.bugs.reg.agg$CustomerSiteId==sites[x] & rp.bugs.reg.agg$Interpretation==bugs[y], 'YearWeek'])-1)], CustomerSiteId = sites[x], Interpretation = bugs[y], Record = sapply(2:(length(rp.bugs.reg.agg[rp.bugs.reg.agg$CustomerSiteId==sites[x] & rp.bugs.reg.agg$Interpretation==bugs[y], 'YearWeek'])-1), function(z) sum(rp.bugs.reg.agg[rp.bugs.reg.agg$CustomerSiteId==sites[x] & rp.bugs.reg.agg$Interpretation==bugs[y],'Record'][(z-1):(z+1)])))))))
rp.runs.reg.roll <- rp.runs.reg.norm[,c('YearWeek','CustomerSiteId','RollRuns')]
colnames(rp.runs.reg.roll) <- c('YearWeek','CustomerSiteId','Runs')

# get the 3-week centered moving sum of bug positives and runs
rp.positives.count.all <- merge(rp.runs.reg.roll, rp.bugs.reg.roll, by=c('YearWeek','CustomerSiteId'))
decoder <- data.frame(Bug = bugs, Code = letters[1:length(bugs)])

# to find the national percent detection, first find it at each site, then average the sites (non-weighted)
rp.positives.count.all <- merge(rp.positives.count.all, decoder, by.x='Interpretation', by.y='Bug')
rp.positives.count.all <- rp.positives.count.all[with(rp.positives.count.all, order(CustomerSiteId, Code, YearWeek)), ]
rp.prevalence.reg.count <- data.frame(do.call(rbind, lapply(1:length(sites), function(x) do.call(cbind, lapply(1:length(bugs), function(y) rp.positives.count.all[rp.positives.count.all$CustomerSiteId==sites[x] & rp.positives.count.all$Code==letters[y], 'Record'])))))
colnames(rp.prevalence.reg.count) <- letters[1:length(rp.prevalence.reg.count[1,])]
rp.prev.reg.count <- data.frame(unique(rp.positives.count.all[,c('YearWeek','CustomerSiteId','Runs')]), rp.prevalence.reg.count)
rp.prev.reg.count[rp.prev.reg.count$Runs < 10, 'Runs'] <- NA
rp.prev.reg <- data.frame(do.call(cbind, lapply(1:length(grep(paste('^', paste(letters, collapse='|^'), sep=''), colnames(rp.prev.reg.count))), function(x) rp.prev.reg.count[,letters[x]]/rp.prev.reg.count$Runs)))
colnames(rp.prev.reg) <- letters[1:length(colnames(rp.prev.reg))]
rp.prev.reg <- data.frame(YearWeek = rp.prev.reg.count$YearWeek, CustomerSiteId = rp.prev.reg.count$CustomerSiteId, rp.prev.reg)
rp.prev <- with(rp.prev.reg, aggregate(as.formula(paste('cbind(', paste(colnames(rp.prev.reg)[grep(paste('^', paste(letters, collapse='|^'), sep=''), colnames(rp.prev.reg))], collapse = ','),')~YearWeek', sep='')), FUN=mean))
rp.prev <- rp.prev[as.character(rp.prev$YearWeek) >= '2014-01', ]
colnames(rp.prev)[grep(paste('^', paste(letters, collapse='|^'), sep=''), colnames(rp.prev))] <- bugs

# ----------------------------------------------------------
# PUT STUFF IN HERE TO AUTOMATE THE REPORT TO WADE EVERY THURSDAY
if(wday(Sys.Date())==5) {
  write.csv(rp.prev, '../TrendMetaData_RP.csv', row.names = FALSE)
  from <- 'aimie.faucett@biofiredx.com'
  to <- 'Wade.Stevenson@biofiredx.com'
  subject <- 'Trend Meta Data - RP Testing'
  body <- 'Please find the updated meta data attached for RP test runs at participating Trend sites. Thank you.'
  mailControl <- list(smtpServer="webmail.biofiredx.com")
  attachmentPath <- '../TrendMetaData_RP.csv'
  attachmentName <- 'TrendMetaData_RP.csv'
  attachmentObject <- mime_part(x=attachmentPath, name=attachmentName)
  bodyWithAttachment <- list(body, attachmentObject)
  sendmail(from=from,to=to,subject=subject,msg=bodyWithAttachment,control=mailControl)
}
# ----------------------------------------------------------

# Continue on with making charts, both the Trend and Pareto charts
colnames(calendar.week)[grep('YearWeek', colnames(calendar.week))] <- 'DateGroup'
start.week.rp <- ifelse(findStartDate(calendar.week, 'Week', 106, 1) > calendar.week[calendar.week$Date == rp.date, 'DateGroup'], findStartDate(calendar.week, 'Week', 106, 1), calendar.week[calendar.week$Date == rp.date, 'DateGroup'])
rp.count.trim <- rp.prev.reg.count[as.character(rp.prev.reg.count$YearWeek) >= start.week.rp, ]
rp.count.wrap <- do.call(rbind, lapply(1:length(grep(paste('^', paste(letters, collapse='|^'), sep=''), colnames(rp.count.trim))), function(x) data.frame(YearWeek = rp.count.trim$YearWeek, CustomerSiteId = rp.count.trim$CustomerSiteId, Runs = rp.count.trim$Runs, Code = letters[x], Positives = rp.count.trim[,letters[x]])))
rp.prev.wrap <- data.frame(YearWeek = rp.count.wrap$YearWeek, CustomerSiteId = rp.count.wrap$CustomerSiteId, Code = rp.count.wrap$Code, Prevalence = rp.count.wrap$Positives/rp.count.wrap$Runs)
rp.prev.wrap <- with(rp.prev.wrap, aggregate(Prevalence~YearWeek+Code, FUN=mean))
rp.prev.wrap <- merge(merge(rp.prev.wrap, decoder, by='Code'), shortnames.df, by.x='Bug', by.y='Interpretation')
p.rp.prev.trend <- ggplot(rp.prev.wrap[with(rp.prev.wrap, order(ShortName, decreasing=TRUE)), ], aes(x=YearWeek)) + geom_area(aes(y=Prevalence, group=ShortName, fill=ShortName, order=ShortName)) + scale_fill_manual(values=createPaletteOfVariableLength(rp.prev.wrap,'ShortName'), name='') + scale_y_continuous(labels=percent) + scale_x_discrete(breaks = as.character(unique(rp.prev.wrap$YearWeek))[order(as.character(unique(rp.prev.wrap$YearWeek)))][seq(1, length(as.character(unique(rp.prev.wrap$YearWeek))), 8)]) + theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(angle=90, hjust=1, vjust=0.5), legend.position='bottom') + labs(title='Percent Detection of Organisms in RP Tests', x='Year-Week', y='Percent Detection')
start.week.rp.pareto <- ifelse(findStartDate(calendar.week, 'Week', 16, 1) > calendar.week[calendar.week$Date == rp.date, 'DateGroup'], findStartDate(calendar.week, 'Week', 16, 1), calendar.week[calendar.week$Date == rp.date, 'DateGroup'])
rp.count.pareto <- rp.count.wrap[as.character(rp.count.wrap$YearWeek) >= start.week.rp.pareto, ]
rp.prev.pareto <- with(rp.count.pareto, aggregate(cbind(Runs, Positives)~CustomerSiteId+Code, FUN=sum))
rp.prev.pareto$Prevalence <- with(rp.prev.pareto, Positives/Runs)
rp.prev.pareto <- with(rp.prev.pareto, aggregate(Prevalence~Code, FUN=mean))
rp.prev.pareto <- merge(merge(rp.prev.pareto, decoder, by='Code'), shortnames.df, by.x='Bug', by.y='Interpretation')
rp.prev.pareto$Name <- factor(rp.prev.pareto$ShortName, levels = rp.prev.pareto[with(rp.prev.pareto, order(Prevalence, decreasing = TRUE)), 'ShortName']) 
p.rp.prev.pareto <- ggplot(rp.prev.pareto, aes(x=Name, y=Prevalence, fill='Bug')) + geom_bar(stat='identity') + geom_text(aes(x=Name, y=Prevalence+0.01, label=paste(round(Prevalence,3)*100, '%', sep='')), data=rp.prev.pareto) + scale_fill_manual(values = createPaletteOfVariableLength(data.frame(Key='Bug'), 'Key'), guide=FALSE) + scale_y_continuous(labels=percent) + theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(angle=60, hjust=1)) + labs(title='Organism Prevalence in RP Tests\n(Last 16 Weeks)', x='', y='Percent Detection')

# ------------------
# GI Panel:
gi.runs.reg <- runs.reg.date[runs.reg.date$Panel=='GI', ]
sites <- unique(gi.runs.reg$CustomerSiteId)
gi.runs.reg.norm <- c()
for(i in 1:length(sites)) {
  
  site.norm <- normalizeBurnRate(calendar.df, gi.runs.reg, var, sites[i], 'GI')
  gi.runs.reg.norm <- rbind(gi.runs.reg.norm, site.norm)
}
sites <- unique(gi.runs.reg.norm$CustomerSiteId)

# get percent detection of organisms in the gi panel
gi.bugs.reg <- c()
for(i in 1:length(sites)) {
  
  site <- sites[i]
  temp <- gi.runs.reg[gi.runs.reg$CustomerSiteId == site, ]
  gi.bugs.site <- merge(temp, bugs.df, by='RunDataId')
  gi.bugs.reg <- rbind(gi.bugs.reg, gi.bugs.site)
}

sites <- sites[order(sites)]
bugs <- as.character(unique(gi.bugs.reg$Interpretation))[order(as.character(unique(gi.bugs.reg$Interpretation)))]

# make a combined category so that do.call can be used to fill in empty dates
colsToCat <- c('CustomerSiteId','Interpretation')
gi.bugs.reg.trim <- gi.bugs.reg[,c('YearWeek', colsToCat)]
gi.bugs.reg.trim$Record <- 1
gi.bugs.reg.trim <- rbind(gi.bugs.reg.trim, do.call(rbind, lapply(1:length(sites), function(x) data.frame(YearWeek=max(unique(gi.bugs.reg$YearWeek)), CustomerSiteId = sites[x], Interpretation = bugs, Record = 0))))
gi.bugs.reg.trim$combocat <- do.call(paste, c(gi.bugs.reg.trim[,colsToCat], sep=','))
gi.bugs.reg.combo <- do.call(rbind, lapply(1:length(unique(gi.bugs.reg.trim$combocat)), function(x) cbind(merge(unique(calendar.df[calendar.df$Date >= gi.date,c('YearWeek','Year')]), gi.bugs.reg.trim[gi.bugs.reg.trim$combocat == unique(gi.bugs.reg.trim$combocat)[x], c('YearWeek','Record')], by='YearWeek', all.x=TRUE), ComboCat = unique(gi.bugs.reg.trim$combocat)[x])))
deCombo <- as.data.frame(sapply(1:length(colsToCat), function(x) do.call(rbind, strsplit(as.character(gi.bugs.reg.combo$ComboCat), split=','))[,x]))
colnames(deCombo) <- colsToCat
gi.bugs.reg.fill <- cbind(gi.bugs.reg.combo[,c('YearWeek','Record')], deCombo)
gi.bugs.reg.fill[is.na(gi.bugs.reg.fill$Record),'Record'] <- 0
gi.bugs.reg.agg <- with(gi.bugs.reg.fill, aggregate(Record~YearWeek+CustomerSiteId+Interpretation, FUN=sum))
gi.bugs.reg.roll <- do.call(rbind, lapply(1:length(sites), function(x) do.call(rbind, lapply(1:length(bugs), function(y) data.frame(YearWeek = gi.bugs.reg.agg[gi.bugs.reg.agg$CustomerSiteId==sites[x] & gi.bugs.reg.agg$Interpretation==bugs[y], 'YearWeek'][2:(length(gi.bugs.reg.agg[gi.bugs.reg.agg$CustomerSiteId==sites[x] & gi.bugs.reg.agg$Interpretation==bugs[y], 'YearWeek'])-1)], CustomerSiteId = sites[x], Interpretation = bugs[y], Record = sapply(2:(length(gi.bugs.reg.agg[gi.bugs.reg.agg$CustomerSiteId==sites[x] & gi.bugs.reg.agg$Interpretation==bugs[y], 'YearWeek'])-1), function(z) sum(gi.bugs.reg.agg[gi.bugs.reg.agg$CustomerSiteId==sites[x] & gi.bugs.reg.agg$Interpretation==bugs[y],'Record'][(z-1):(z+1)])))))))
gi.runs.reg.roll <- gi.runs.reg.norm[,c('YearWeek','CustomerSiteId','RollRuns')]
colnames(gi.runs.reg.roll) <- c('YearWeek','CustomerSiteId','Runs')

# get the 3-week centered moving sum of bug positives and runs
gi.positives.count.all <- merge(gi.runs.reg.roll, gi.bugs.reg.roll, by=c('YearWeek','CustomerSiteId'))
decoder <- data.frame(Bug = bugs, Code = letters[1:length(bugs)])

# to find the national percent detection, first find it at each site, then average the sites (non-weighted)
gi.positives.count.all <- merge(gi.positives.count.all, decoder, by.x='Interpretation', by.y='Bug')
gi.positives.count.all <- gi.positives.count.all[with(gi.positives.count.all, order(CustomerSiteId, Code, YearWeek)), ]
gi.prevalence.reg.count <- data.frame(do.call(rbind, lapply(1:length(sites), function(x) do.call(cbind, lapply(1:length(bugs), function(y) gi.positives.count.all[gi.positives.count.all$CustomerSiteId==sites[x] & gi.positives.count.all$Code==letters[y], 'Record'])))))
colnames(gi.prevalence.reg.count) <- letters[1:length(gi.prevalence.reg.count[1,])]
gi.prev.reg.count <- data.frame(unique(gi.positives.count.all[,c('YearWeek','CustomerSiteId','Runs')]), gi.prevalence.reg.count)
gi.prev.reg.count[gi.prev.reg.count$Runs < 10, 'Runs'] <- NA

# Continue on with making charts, both the Trend and Pareto charts
start.week.gi <- ifelse(findStartDate(calendar.week, 'Week', 106, 1) > calendar.week[calendar.week$Date == gi.date, 'DateGroup'], findStartDate(calendar.week, 'Week', 106, 1), calendar.week[calendar.week$Date == gi.date, 'DateGroup'])
gi.count.trim <- gi.prev.reg.count[as.character(gi.prev.reg.count$YearWeek) >= start.week.gi, ]
gi.count.wrap <- do.call(rbind, lapply(1:length(grep(paste('^', paste(letters, collapse='|^'), sep=''), colnames(gi.count.trim))), function(x) data.frame(YearWeek = gi.count.trim$YearWeek, CustomerSiteId = gi.count.trim$CustomerSiteId, Runs = gi.count.trim$Runs, Code = letters[x], Positives = gi.count.trim[,letters[x]])))
gi.prev.wrap <- data.frame(YearWeek = gi.count.wrap$YearWeek, CustomerSiteId = gi.count.wrap$CustomerSiteId, Code = gi.count.wrap$Code, Prevalence = gi.count.wrap$Positives/gi.count.wrap$Runs)
gi.prev.wrap <- with(gi.prev.wrap, aggregate(Prevalence~YearWeek+Code, FUN=mean))
gi.prev.wrap <- merge(merge(gi.prev.wrap, decoder, by='Code'), shortnames.df, by.x='Bug', by.y='Interpretation')
p.gi.prev.trend <- ggplot(gi.prev.wrap[with(gi.prev.wrap, order(ShortName, decreasing=TRUE)), ], aes(x=YearWeek)) + geom_area(aes(y=Prevalence, group=ShortName, fill=ShortName, order=ShortName)) + scale_fill_manual(values=createPaletteOfVariableLength(gi.prev.wrap,'ShortName'), name='') + scale_y_continuous(labels=percent) + scale_x_discrete(breaks = as.character(unique(gi.prev.wrap$YearWeek))[order(as.character(unique(gi.prev.wrap$YearWeek)))][seq(1, length(as.character(unique(gi.prev.wrap$YearWeek))), 8)]) + theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(angle=90, hjust=1, vjust=0.5), legend.position='bottom') + labs(title='Percent Detection of Organisms in GI Tests', x='Year-Week', y='Percent Detection')
start.week.gi.pareto <- ifelse(findStartDate(calendar.week, 'Week', 16, 1) > calendar.week[calendar.week$Date == gi.date, 'DateGroup'], findStartDate(calendar.week, 'Week', 16, 1), calendar.week[calendar.week$Date == gi.date, 'DateGroup'])
gi.count.pareto <- gi.count.wrap[as.character(gi.count.wrap$YearWeek) >= start.week.gi.pareto, ]
gi.prev.pareto <- with(gi.count.pareto, aggregate(cbind(Runs, Positives)~CustomerSiteId+Code, FUN=sum))
gi.prev.pareto$Prevalence <- with(gi.prev.pareto, Positives/Runs)
gi.prev.pareto <- with(gi.prev.pareto, aggregate(Prevalence~Code, FUN=mean))
gi.prev.pareto <- merge(merge(gi.prev.pareto, decoder, by='Code'), shortnames.df, by.x='Bug', by.y='Interpretation')
gi.prev.pareto$Name <- factor(gi.prev.pareto$ShortName, levels = gi.prev.pareto[with(gi.prev.pareto, order(Prevalence, decreasing = TRUE)), 'ShortName']) 
p.gi.prev.pareto <- ggplot(gi.prev.pareto, aes(x=Name, y=Prevalence, fill='Bug')) + geom_bar(stat='identity') + geom_text(aes(x=Name, y=Prevalence+0.01, label=paste(round(Prevalence,3)*100, '%', sep='')), data=gi.prev.pareto) + scale_fill_manual(values = createPaletteOfVariableLength(data.frame(Key='Bug'), 'Key'), guide=FALSE) + scale_y_continuous(labels=percent) + theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(angle=60, hjust=1)) + labs(title='Organism Prevalence in GI Tests\n(Last 16 Weeks)', x='', y='Percent Detection')

# ------------------
# ME Panel:
me.runs.reg <- runs.reg.date[runs.reg.date$Panel=='ME', ]
sites <- unique(me.runs.reg$CustomerSiteId)
# me.runs.reg.norm <- c()
# for(i in 1:length(sites)) {
# 
#   site.norm <- normalizeBurnRate(data.frame(calendar.df, Days=1), me.runs.reg, var, sites[i], 'ME')
#   me.runs.reg.norm <- rbind(me.runs.reg.norm, site.norm)
# }
# sites <- unique(me.runs.reg.norm$CustomerSiteId)

# # get percent detection of organisms in the me panel
# me.bugs.reg <- c()
# for(i in 1:length(sites)) {
# 
#   site <- sites[i]
#   temp <- me.runs.reg[me.runs.reg$CustomerSiteId == site, ]
#   me.bugs.site <- merge(temp, bugs.df, by='RunDataId')
#   me.bugs.reg <- rbind(me.bugs.reg, me.bugs.site)
# }
# 
# # make a combined category so that do.call can be used to fill in empty dates
# colsToCat <- c('CustomerSiteId','Interpretation')
# me.bugs.reg.trim <- me.bugs.reg[,c('YearWeek', colsToCat)]
# me.bugs.reg.trim <- rbind(me.bugs.reg.trim, do.call(rbind, lapply(1:length(sites), function(x) data.frame(YearWeek=max(unique(me.bugs.reg.agg$YearWeek)), CustomerSiteId = sites[x], Interpretation = bugs[!(bugs %in% unique(me.bugs.reg.agg[me.bugs.reg.agg$CustomerSiteId==sites[x],'Interpretation']))]))))
# me.bugs.reg.trim$combocat <- do.call(paste, c(me.bugs.reg.trim[,colsToCat], sep=','))
# me.bugs.reg.trim$Record <- 1
# me.bugs.reg.combo <- do.call(rbind, lapply(1:length(unique(me.bugs.reg.trim$combocat)), function(x) cbind(merge(unique(calendar.df[,c('YearWeek','Year')]), me.bugs.reg.trim[me.bugs.reg.trim$combocat == unique(me.bugs.reg.trim$combocat)[x], c('YearWeek','Record')], by='YearWeek', all.x=TRUE), ComboCat = unique(me.bugs.reg.trim$combocat)[x])))
# deCombo <- as.data.frame(sapply(1:length(colsToCat), function(x) do.call(rbind, strsplit(as.character(me.bugs.reg.combo$ComboCat), split=','))[,x]))
# colnames(deCombo) <- colsToCat
# me.bugs.reg.fill <- cbind(me.bugs.reg.combo[,c('YearWeek','Record')], deCombo)
# me.bugs.reg.fill[is.na(me.bugs.reg.fill$Record),'Record'] <- 0
# me.bugs.reg.agg <- with(me.bugs.reg.fill, aggregate(Record~YearWeek+CustomerSiteId+Interpretation, FUN=sum))
# me.bugs.reg.roll <- do.call(rbind, lapply(1:length(sites), function(x) do.call(rbind, lapply(1:length(bugs), function(y) data.frame(YearWeek = me.bugs.reg.agg[me.bugs.reg.agg$CustomerSiteId==sites[x] & me.bugs.reg.agg$Interpretation==bugs[y], 'YearWeek'][2:(length(me.bugs.reg.agg[me.bugs.reg.agg$CustomerSiteId==sites[x] & me.bugs.reg.agg$Interpretation==bugs[y], 'YearWeek'])-1)], CustomerSiteId = sites[x], Interpretation = bugs[y], Record = sapply(2:(length(me.bugs.reg.agg[me.bugs.reg.agg$CustomerSiteId==sites[x] & me.bugs.reg.agg$Interpretation==bugs[y], 'YearWeek'])-1), function(z) sum(me.bugs.reg.agg[me.bugs.reg.agg$CustomerSiteId==sites[x] & me.bugs.reg.agg$Interpretation==bugs[y],'Record'][(z-1):(z+1)])))))))
# me.runs.reg.roll <- me.runs.reg.norm[,c('YearWeek','CustomerSiteId','RollRuns')]
# colnames(me.runs.reg.roll) <- c('YearWeek','CustomerSiteId','Runs')
# 
# # get the 3-week centered moving sum of bug positives and runs
# me.positives.count.all <- merge(me.runs.reg.roll, me.bugs.reg.roll, by=c('YearWeek','CustomerSiteId'))
# decoder <- data.frame(Bug = bugs, Code = letters[1:length(bugs)])
# 
# # to find the national percent detection, first find it at each site, then average the sites (non-weighted)
# me.positives.count.all <- merge(me.positives.count.all, decoder, by.x='Interpretation', by.y='Bug')
# me.positives.count.all <- me.positives.count.all[with(me.positives.count.all, order(CustomerSiteId, Code, YearWeek)), ]
# me.prevalence.reg.count <- data.frame(do.call(rbind, lapply(1:length(sites), function(x) do.call(cbind, lapply(1:length(bugs), function(y) me.positives.count.all[me.positives.count.all$CustomerSiteId==sites[x] & me.positives.count.all$Code==letters[y], 'Record'])))))
# colnames(me.prevalence.reg.count) <- letters[1:length(me.prevalence.reg.count[1,])]
# me.prev.reg.count <- data.frame(unique(me.positives.count.all[,c('YearWeek','CustomerSiteId','Runs')]), me.prevalence.reg.count)
# 
# # Continue on with making charts, both the Trend and Pareto charts
# start.week.me <- ifelse(findStartDate(calendar.week, 'Week', 106, 1) > calendar.week[calendar.week$Date == me.date, 'DateGroup'], findStartDate(calendar.week, 'Week', 106, 1), calendar.week[calendar.week$Date == me.date, 'DateGroup'])
# me.count.trim <- me.prev.reg.count[as.character(me.prev.reg.count$YearWeek) >= start.week.me, ]
# me.count.wrap <- do.call(rbind, lapply(1:length(grep(paste('^', paste(letters, collapse='|^'), sep=''), colnames(me.count.trim))), function(x) data.frame(YearWeek = me.count.trim$YearWeek, CustomerSiteId = me.count.trim$CustomerSiteId, Runs = me.count.trim$Runs, Code = letters[x], Positives = me.count.trim[,letters[x]])))
# me.prev.wrap <- data.frame(YearWeek = me.count.wrap$YearWeek, CustomerSiteId = me.count.wrap$CustomerSiteId, Code = me.count.wrap$Code, Prevalence = me.count.wrap$Positives/me.count.wrap$Runs)
# me.prev.wrap <- with(me.prev.wrap, aggregate(Prevalence~YearWeek+Code, FUN=mean))
# me.prev.wrap <- merge(merge(me.prev.wrap, decoder, by='Code'), shortnames.df, by.x='Bug', by.y='Interpretation')
# p.me.prev.trend <- ggplot(me.prev.wrap[with(me.prev.wrap, order(ShortName, decreasing=TRUE)), ], aes(x=YearWeek)) + geom_area(aes(y=Prevalence, group=ShortName, fill=ShortName, order=ShortName)) + scale_fill_manual(values=createPaletteOfVariableLength(me.prev.wrap,'ShortName'), name='') + scale_y_continuous(labels=percent) + scale_x_discrete(breaks = as.character(unique(me.prev.wrap$YearWeek))[order(as.character(unique(me.prev.wrap$YearWeek)))][seq(1, length(as.character(unique(me.prev.wrap$YearWeek))), 8)]) + theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(angle=90, hjust=1, vjust=0.5), legend.position='bottom') + labs(title='Percent Detection of Organisms in ME Tests', x='Year-Week', y='Percent Detection')
# start.week.me.pareto <- ifelse(findStartDate(calendar.week, 'Week', 16, 1) > calendar.week[calendar.week$Date == me.date, 'DateGroup'], findStartDate(calendar.week, 'Week', 16, 1), calendar.week[calendar.week$Date == me.date, 'DateGroup'])
# me.count.pareto <- me.count.wrap[as.character(me.count.wrap$YearWeek) >= start.week.me.pareto, ]
# me.prev.pareto <- with(me.count.pareto, aggregate(cbind(Runs, Positives)~CustomerSiteId+Code, FUN=sum))
# me.prev.pareto$Prevalence <- with(me.prev.pareto, Positives/Runs)
# me.prev.pareto <- with(me.prev.pareto, aggregate(Prevalence~Code, FUN=mean))
# me.prev.pareto <- merge(merge(me.prev.pareto, decoder, by='Code'), shortnames.df, by.x='Bug', by.y='Interpretation')
# me.prev.pareto$Name <- factor(me.prev.pareto$ShortName, levels = me.prev.pareto[with(me.prev.pareto, order(Prevalence, decreasing = TRUE)), 'ShortName']) 
# p.me.prev.pareto <- ggplot(me.prev.pareto, aes(x=Name, y=Prevalence, fill='Bug')) + geom_bar(stat='identity') + geom_text(aes(x=Name, y=Prevalence+0.01, label=paste(round(Prevalence,3)*100, '%', sep='')), data=me.prev.pareto) + scale_fill_manual(values = createPaletteOfVariableLength(data.frame(Key='Bug'), 'Key'), guide=FALSE) + scale_y_continuous(labels=percent) + theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(angle=60, hjust=1)) + labs(title='Organism Prevalence in ME Tests\n(Last 16 Weeks)', x='', y='Percent Detection')

me.runs.reg.agg <- with(me.runs.reg, aggregate(Record~YearWeek+CustomerSiteId, FUN=sum))
me.bugs.reg <- merge(me.runs.reg, bugs.df, by='RunDataId')

sites <- sites[order(sites)]
bugs <- as.character(unique(me.bugs.reg$Interpretation))[order(as.character(unique(me.bugs.reg$Interpretation)))]

# make a combined category so that do.call can be used to fill in empty dates
colsToCat <- c('CustomerSiteId','Interpretation')
me.bugs.reg.trim <- me.bugs.reg[,c('YearWeek', colsToCat)]
me.bugs.reg.trim$Record <- 1
me.bugs.reg.trim <- rbind(me.bugs.reg.trim, do.call(rbind, lapply(1:length(sites), function(x) data.frame(YearWeek=max(unique(me.bugs.reg$YearWeek)), CustomerSiteId = sites[x], Interpretation = bugs, Record = 0))))
me.bugs.reg.trim$combocat <- do.call(paste, c(me.bugs.reg.trim[,colsToCat], sep=','))
me.bugs.reg.combo <- do.call(rbind, lapply(1:length(unique(me.bugs.reg.trim$combocat)), function(x) cbind(merge(unique(calendar.df[calendar.df$Date >= me.date,c('YearWeek','Year')]), me.bugs.reg.trim[me.bugs.reg.trim$combocat == unique(me.bugs.reg.trim$combocat)[x], c('YearWeek','Record')], by='YearWeek', all.x=TRUE), ComboCat = unique(me.bugs.reg.trim$combocat)[x])))
deCombo <- as.data.frame(sapply(1:length(colsToCat), function(x) do.call(rbind, strsplit(as.character(me.bugs.reg.combo$ComboCat), split=','))[,x]))
colnames(deCombo) <- colsToCat
me.bugs.reg.fill <- cbind(me.bugs.reg.combo[,c('YearWeek','Record')], deCombo)
me.bugs.reg.fill[is.na(me.bugs.reg.fill$Record),'Record'] <- 0
me.bugs.reg.agg <- with(me.bugs.reg.fill, aggregate(Record~YearWeek+CustomerSiteId+Interpretation, FUN=sum))
me.bugs.reg.roll <- do.call(rbind, lapply(1:length(sites), function(x) do.call(rbind, lapply(1:length(bugs), function(y) data.frame(YearWeek = me.bugs.reg.agg[me.bugs.reg.agg$CustomerSiteId==sites[x] & me.bugs.reg.agg$Interpretation==bugs[y], 'YearWeek'][2:(length(me.bugs.reg.agg[me.bugs.reg.agg$CustomerSiteId==sites[x] & me.bugs.reg.agg$Interpretation==bugs[y], 'YearWeek'])-1)], CustomerSiteId = sites[x], Interpretation = bugs[y], Record = sapply(2:(length(me.bugs.reg.agg[me.bugs.reg.agg$CustomerSiteId==sites[x] & me.bugs.reg.agg$Interpretation==bugs[y], 'YearWeek'])-1), function(z) sum(me.bugs.reg.agg[me.bugs.reg.agg$CustomerSiteId==sites[x] & me.bugs.reg.agg$Interpretation==bugs[y],'Record'][(z-1):(z+1)])))))))
# me.runs.reg.roll <- me.runs.reg.norm[,c('YearWeek','CustomerSiteId','RollRuns')]
# colnames(me.runs.reg.roll) <- c('YearWeek','CustomerSiteId','Runs')
colnames(me.runs.reg.agg)[grep('Record', colnames(me.runs.reg.agg))] <- 'Runs'
me.runs.reg.agg <- merge(unique(me.bugs.reg.agg[,c('YearWeek','CustomerSiteId')]), me.runs.reg.agg, by=c('YearWeek','CustomerSiteId'), all.x=TRUE)
me.runs.reg.agg[is.na(me.runs.reg.agg$Runs), 'Runs'] <- 0
me.runs.reg.roll <- do.call(rbind, lapply(1:length(sites), function(x) data.frame(YearWeek = me.runs.reg.agg[me.runs.reg.agg$CustomerSiteId==sites[x],'YearWeek'][2:(length(me.runs.reg.agg[me.runs.reg.agg$CustomerSiteId==sites[x],'YearWeek'])-1)], CustomerSiteId = sites[x], Runs = sapply(2:(length(me.runs.reg.agg[me.runs.reg.agg$CustomerSiteId==sites[x],'YearWeek'])-1 ), function(y) sum(me.runs.reg.agg[me.runs.reg.agg$CustomerSiteId==sites[x],'Runs'][(y-1):(y+1)])))))

# get the 3-week centered moving sum of bug positives and runs
me.positives.count.all <- merge(me.runs.reg.roll, me.bugs.reg.roll, by=c('YearWeek','CustomerSiteId'))
decoder <- data.frame(Bug = bugs, Code = letters[1:length(bugs)])

# to find the national percent detection, first find it at each site, then average the sites (non-weighted)
me.positives.count.all <- merge(me.positives.count.all, decoder, by.x='Interpretation', by.y='Bug')
me.positives.count.all <- me.positives.count.all[with(me.positives.count.all, order(CustomerSiteId, Code, YearWeek)), ]
me.prevalence.reg.count <- data.frame(do.call(rbind, lapply(1:length(sites), function(x) do.call(cbind, lapply(1:length(bugs), function(y) me.positives.count.all[me.positives.count.all$CustomerSiteId==sites[x] & me.positives.count.all$Code==letters[y], 'Record'])))))
colnames(me.prevalence.reg.count) <- letters[1:length(me.prevalence.reg.count[1,])]
me.prev.reg.count <- data.frame(unique(me.positives.count.all[,c('YearWeek','CustomerSiteId','Runs')]), me.prevalence.reg.count)
me.prev.reg.count[me.prev.reg.count$Runs < 5, 'Runs'] <- NA

# Continue on with making charts, both the Trend and Pareto charts
start.week.me <- ifelse(findStartDate(calendar.week, 'Week', 106, 1) > calendar.week[calendar.week$Date == me.date, 'DateGroup'], findStartDate(calendar.week, 'Week', 106, 1), calendar.week[calendar.week$Date == me.date, 'DateGroup'])
me.count.trim <- me.prev.reg.count[as.character(me.prev.reg.count$YearWeek) >= start.week.me, ]
me.count.wrap <- do.call(rbind, lapply(1:length(grep(paste('^', paste(letters, collapse='|^'), sep=''), colnames(me.count.trim))), function(x) data.frame(YearWeek = me.count.trim$YearWeek, CustomerSiteId = me.count.trim$CustomerSiteId, Runs = me.count.trim$Runs, Code = letters[x], Positives = me.count.trim[,letters[x]])))
me.prev.wrap <- data.frame(YearWeek = me.count.wrap$YearWeek, CustomerSiteId = me.count.wrap$CustomerSiteId, Code = me.count.wrap$Code, Prevalence = me.count.wrap$Positives/me.count.wrap$Runs)
me.prev.wrap <- with(me.prev.wrap, aggregate(Prevalence~YearWeek+Code, FUN=mean))
me.prev.wrap <- merge(merge(me.prev.wrap, decoder, by='Code'), shortnames.df, by.x='Bug', by.y='Interpretation')
p.me.prev.trend <- ggplot(me.prev.wrap[with(me.prev.wrap, order(ShortName, decreasing=TRUE)), ], aes(x=YearWeek)) + geom_area(aes(y=Prevalence, group=ShortName, fill=ShortName, order=ShortName)) + scale_fill_manual(values=createPaletteOfVariableLength(me.prev.wrap,'ShortName'), name='') + scale_y_continuous(labels=percent) + scale_x_discrete(breaks = as.character(unique(me.prev.wrap$YearWeek))[order(as.character(unique(me.prev.wrap$YearWeek)))][seq(1, length(as.character(unique(me.prev.wrap$YearWeek))), 8)]) + theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(angle=90, hjust=1, vjust=0.5), legend.position='bottom') + labs(title='Percent Detection of Organisms in ME Tests', x='Year-Week', y='Percent Detection')
start.week.me.pareto <- ifelse(findStartDate(calendar.week, 'Week', 16, 1) > calendar.week[calendar.week$Date == me.date, 'DateGroup'], findStartDate(calendar.week, 'Week', 16, 1), calendar.week[calendar.week$Date == me.date, 'DateGroup'])
me.count.pareto <- me.count.wrap[as.character(me.count.wrap$YearWeek) >= start.week.me.pareto, ]
me.prev.pareto <- with(me.count.pareto, aggregate(cbind(Runs, Positives)~CustomerSiteId+Code, FUN=sum))
me.prev.pareto$Prevalence <- with(me.prev.pareto, Positives/Runs)
me.prev.pareto <- with(me.prev.pareto, aggregate(Prevalence~Code, FUN=mean))
me.prev.pareto <- merge(merge(me.prev.pareto, decoder, by='Code'), shortnames.df, by.x='Bug', by.y='Interpretation')
me.prev.pareto$Name <- factor(me.prev.pareto$ShortName, levels = me.prev.pareto[with(me.prev.pareto, order(Prevalence, decreasing = TRUE)), 'ShortName'])
p.me.prev.pareto <- ggplot(me.prev.pareto, aes(x=Name, y=Prevalence, fill='Bug')) + geom_bar(stat='identity') + geom_text(aes(x=Name, y=Prevalence+0.01, label=paste(round(Prevalence,3)*100, '%', sep='')), data=me.prev.pareto) + scale_fill_manual(values = createPaletteOfVariableLength(data.frame(Key='Bug'), 'Key'), guide=FALSE) + scale_y_continuous(labels=percent) + theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(angle=60, hjust=1)) + labs(title='Organism Prevalence in ME Tests\n(Last 16 Weeks)', x='', y='Percent Detection')

# ------------------
# BCID Panel:
bcid.runs.reg <- runs.reg.date[runs.reg.date$Panel=='BCID', ]
sites <- unique(bcid.runs.reg$CustomerSiteId)
bcid.runs.reg.norm <- c()
for(i in 1:length(sites)) {
  
  site.norm <- normalizeBurnRate(calendar.df, bcid.runs.reg, var, sites[i], 'BCID')
  bcid.runs.reg.norm <- rbind(bcid.runs.reg.norm, site.norm)
}
sites <- unique(bcid.runs.reg.norm$CustomerSiteId)

# get percent detection of organisms in the bcid panel
bcid.bugs.reg <- c()
for(i in 1:length(sites)) {
  
  site <- sites[i]
  temp <- bcid.runs.reg[bcid.runs.reg$CustomerSiteId == site, ]
  bcid.bugs.site <- merge(temp, bugs.df, by='RunDataId')
  bcid.bugs.reg <- rbind(bcid.bugs.reg, bcid.bugs.site)
}

sites <- sites[order(sites)]
bugs <- as.character(unique(bcid.bugs.reg$Interpretation))[order(as.character(unique(bcid.bugs.reg$Interpretation)))]
resultTypes <- unique(bcid.bugs.reg[,c('Interpretation','ResultType')])
resultTypes <- resultTypes[with(resultTypes, order(Interpretation)), 'ResultType']

# make a combined category so that do.call can be used to fill in empty dates
colsToCat <- c('CustomerSiteId','Interpretation','ResultType')
bcid.bugs.reg.trim <- bcid.bugs.reg[,c('YearWeek', colsToCat)]
bcid.bugs.reg.trim$Record <- 1
bcid.bugs.reg.trim <- rbind(bcid.bugs.reg.trim, do.call(rbind, lapply(1:length(sites), function(x) data.frame(YearWeek=max(unique(bcid.bugs.reg$YearWeek)), CustomerSiteId = sites[x], Interpretation = bugs, ResultType = resultTypes, Record = 0))))
bcid.bugs.reg.trim$combocat <- do.call(paste, c(bcid.bugs.reg.trim[,colsToCat], sep=','))
bcid.bugs.reg.combo <- do.call(rbind, lapply(1:length(unique(bcid.bugs.reg.trim$combocat)), function(x) cbind(merge(unique(calendar.df[calendar.df$Date >= bcid.date,c('YearWeek','Year')]), bcid.bugs.reg.trim[bcid.bugs.reg.trim$combocat == unique(bcid.bugs.reg.trim$combocat)[x], c('YearWeek','Record')], by='YearWeek', all.x=TRUE), ComboCat = unique(bcid.bugs.reg.trim$combocat)[x])))
deCombo <- as.data.frame(sapply(1:length(colsToCat), function(x) do.call(rbind, strsplit(as.character(bcid.bugs.reg.combo$ComboCat), split=','))[,x]))
colnames(deCombo) <- colsToCat
bcid.bugs.reg.fill <- cbind(bcid.bugs.reg.combo[,c('YearWeek','Record')], deCombo)
bcid.bugs.reg.fill[is.na(bcid.bugs.reg.fill$Record),'Record'] <- 0
bcid.bugs.reg.agg <- with(subset(bcid.bugs.reg.fill, ResultType!='Gene'), aggregate(Record~YearWeek+CustomerSiteId+Interpretation, FUN=sum))
bcid.bugs.reg.agg$Interpretation <- as.character(bcid.bugs.reg.agg$Interpretation)
bcid.bugs.reg.agg[grep('Staphy', bcid.bugs.reg.agg$Interpretation), 'Interpretation'] <- 'Staphylococcus, S.aureus Not Detected'
bcid.bugs.reg.agg[grep('Strepto', bcid.bugs.reg.agg$Interpretation), 'Interpretation'] <- 'Streptococus, Species Not Detected'
bugs <- as.character(unique(bcid.bugs.reg.agg$Interpretation))[order(as.character(unique(bcid.bugs.reg.agg$Interpretation)))]
bcid.bugs.reg.roll <- do.call(rbind, lapply(1:length(sites), function(x) do.call(rbind, lapply(1:length(bugs), function(y) data.frame(YearWeek = bcid.bugs.reg.agg[bcid.bugs.reg.agg$CustomerSiteId==sites[x] & bcid.bugs.reg.agg$Interpretation==bugs[y], 'YearWeek'][2:(length(bcid.bugs.reg.agg[bcid.bugs.reg.agg$CustomerSiteId==sites[x] & bcid.bugs.reg.agg$Interpretation==bugs[y], 'YearWeek'])-1)], CustomerSiteId = sites[x], Interpretation = bugs[y], Record = sapply(2:(length(bcid.bugs.reg.agg[bcid.bugs.reg.agg$CustomerSiteId==sites[x] & bcid.bugs.reg.agg$Interpretation==bugs[y], 'YearWeek'])-1), function(z) sum(bcid.bugs.reg.agg[bcid.bugs.reg.agg$CustomerSiteId==sites[x] & bcid.bugs.reg.agg$Interpretation==bugs[y],'Record'][(z-1):(z+1)])))))))
bcid.runs.reg.roll <- bcid.runs.reg.norm[,c('YearWeek','CustomerSiteId','RollRuns')]
colnames(bcid.runs.reg.roll) <- c('YearWeek','CustomerSiteId','Runs')

# get the 3-week centered moving sum of bug positives and runs
bcid.positives.count.all <- merge(bcid.runs.reg.roll, bcid.bugs.reg.roll, by=c('YearWeek','CustomerSiteId'))
decoder <- data.frame(Bug = bugs, Code = letters[1:length(bugs)])

# to find the national percent detection, first find it at each site, then average the sites (non-weighted)
bcid.positives.count.all <- merge(bcid.positives.count.all, decoder, by.x='Interpretation', by.y='Bug')
bcid.positives.count.all <- bcid.positives.count.all[with(bcid.positives.count.all, order(CustomerSiteId, Code, YearWeek)), ]
bcid.prevalence.reg.count <- data.frame(do.call(rbind, lapply(1:length(sites), function(x) do.call(cbind, lapply(1:length(bugs), function(y) bcid.positives.count.all[bcid.positives.count.all$CustomerSiteId==sites[x] & bcid.positives.count.all$Code==letters[y], 'Record'])))))
colnames(bcid.prevalence.reg.count) <- letters[1:length(bcid.prevalence.reg.count[1,])]
bcid.prev.reg.count <- data.frame(unique(bcid.positives.count.all[,c('YearWeek','CustomerSiteId','Runs')]), bcid.prevalence.reg.count)
bcid.prev.reg.count[bcid.prev.reg.count$Runs < 10, 'Runs'] <- NA

# Continue on with making charts, both the Trend and Pareto charts
start.week.bcid <- ifelse(findStartDate(calendar.week, 'Week', 106, 1) > calendar.week[calendar.week$Date == bcid.date, 'DateGroup'], findStartDate(calendar.week, 'Week', 106, 1), calendar.week[calendar.week$Date == bcid.date, 'DateGroup'])
bcid.count.trim <- bcid.prev.reg.count[as.character(bcid.prev.reg.count$YearWeek) >= start.week.bcid, ]
bcid.count.wrap <- do.call(rbind, lapply(1:length(grep(paste('^', paste(letters, collapse='|^'), sep=''), colnames(bcid.count.trim))), function(x) data.frame(YearWeek = bcid.count.trim$YearWeek, CustomerSiteId = bcid.count.trim$CustomerSiteId, Runs = bcid.count.trim$Runs, Code = letters[x], Positives = bcid.count.trim[,letters[x]])))
bcid.prev.wrap <- data.frame(YearWeek = bcid.count.wrap$YearWeek, CustomerSiteId = bcid.count.wrap$CustomerSiteId, Code = bcid.count.wrap$Code, Prevalence = bcid.count.wrap$Positives/bcid.count.wrap$Runs)
bcid.prev.wrap <- with(bcid.prev.wrap, aggregate(Prevalence~YearWeek+Code, FUN=mean))
bcid.prev.wrap <- merge(merge(bcid.prev.wrap, decoder, by='Code'), shortnames.df, by.x='Bug', by.y='Interpretation')
p.bcid.prev.trend <- ggplot(bcid.prev.wrap[with(bcid.prev.wrap, order(ShortName, decreasing=TRUE)), ], aes(x=YearWeek)) + geom_area(aes(y=Prevalence, group=ShortName, fill=ShortName, order=ShortName)) + scale_fill_manual(values=createPaletteOfVariableLength(bcid.prev.wrap,'ShortName'), name='') + scale_y_continuous(labels=percent) + scale_x_discrete(breaks = as.character(unique(bcid.prev.wrap$YearWeek))[order(as.character(unique(bcid.prev.wrap$YearWeek)))][seq(1, length(as.character(unique(bcid.prev.wrap$YearWeek))), 8)]) + theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(angle=90, hjust=1, vjust=0.5), legend.position='bottom') + labs(title='Percent Detection of Organisms in BCID Tests', x='Year-Week', y='Percent Detection')
start.week.bcid.pareto <- ifelse(findStartDate(calendar.week, 'Week', 16, 1) > calendar.week[calendar.week$Date == bcid.date, 'DateGroup'], findStartDate(calendar.week, 'Week', 16, 1), calendar.week[calendar.week$Date == bcid.date, 'DateGroup'])
bcid.count.pareto <- bcid.count.wrap[as.character(bcid.count.wrap$YearWeek) >= start.week.bcid.pareto, ]
bcid.prev.pareto <- with(bcid.count.pareto, aggregate(cbind(Runs, Positives)~CustomerSiteId+Code, FUN=sum))
bcid.prev.pareto$Prevalence <- with(bcid.prev.pareto, Positives/Runs)
bcid.prev.pareto <- with(bcid.prev.pareto, aggregate(Prevalence~Code, FUN=mean))
bcid.prev.pareto <- merge(merge(bcid.prev.pareto, decoder, by='Code'), shortnames.df, by.x='Bug', by.y='Interpretation')
bcid.prev.pareto$Name <- factor(bcid.prev.pareto$ShortName, levels = bcid.prev.pareto[with(bcid.prev.pareto, order(Prevalence, decreasing = TRUE)), 'ShortName']) 
p.bcid.prev.pareto <- ggplot(bcid.prev.pareto, aes(x=Name, y=Prevalence, fill='Bug')) + geom_bar(stat='identity') + geom_text(aes(x=Name, y=Prevalence+0.01, label=paste(round(Prevalence,3)*100, '%', sep='')), data=bcid.prev.pareto) + scale_fill_manual(values = createPaletteOfVariableLength(data.frame(Key='Bug'), 'Key'), guide=FALSE) + scale_y_continuous(labels=percent) + theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(angle=70, hjust=1, size=16)) + labs(title='Organism Prevalence in BCID Tests\n(Last 16 Weeks)', x='', y='Percent Detection')

# GENE
bcid.gene.reg.agg <- with(subset(bcid.bugs.reg.fill, ResultType=='Gene'), aggregate(Record~YearWeek+CustomerSiteId+Interpretation, FUN=sum))
gene <- as.character(unique(bcid.gene.reg.agg$Interpretation))[order(as.character(unique(bcid.gene.reg.agg$Interpretation)))]
bcid.gene.reg.roll <- do.call(rbind, lapply(1:length(sites), function(x) do.call(rbind, lapply(1:length(gene), function(y) data.frame(YearWeek = bcid.gene.reg.agg[bcid.gene.reg.agg$CustomerSiteId==sites[x] & bcid.gene.reg.agg$Interpretation==gene[y], 'YearWeek'][2:(length(bcid.gene.reg.agg[bcid.gene.reg.agg$CustomerSiteId==sites[x] & bcid.gene.reg.agg$Interpretation==gene[y], 'YearWeek'])-1)], CustomerSiteId = sites[x], Interpretation = gene[y], Record = sapply(2:(length(bcid.gene.reg.agg[bcid.gene.reg.agg$CustomerSiteId==sites[x] & bcid.gene.reg.agg$Interpretation==gene[y], 'YearWeek'])-1), function(z) sum(bcid.gene.reg.agg[bcid.gene.reg.agg$CustomerSiteId==sites[x] & bcid.gene.reg.agg$Interpretation==gene[y],'Record'][(z-1):(z+1)])))))))

# get the 3-week centered moving sum of gene positives and runs
bcid.gene.count.all <- merge(bcid.runs.reg.roll, bcid.gene.reg.roll, by=c('YearWeek','CustomerSiteId'))
decoder <- data.frame(Bug = gene, Code = letters[1:length(gene)])

# to find the national percent detection, first find it at each site, then average the sites (non-weighted)
bcid.gene.count.all <- merge(bcid.gene.count.all, decoder, by.x='Interpretation', by.y='Bug')
bcid.gene.count.all <- bcid.gene.count.all[with(bcid.gene.count.all, order(CustomerSiteId, Code, YearWeek)), ]
bcid.gene.prevalence.reg.count <- data.frame(do.call(rbind, lapply(1:length(sites), function(x) do.call(cbind, lapply(1:length(gene), function(y) bcid.gene.count.all[bcid.gene.count.all$CustomerSiteId==sites[x] & bcid.gene.count.all$Code==letters[y], 'Record'])))))
colnames(bcid.gene.prevalence.reg.count) <- letters[1:length(bcid.gene.prevalence.reg.count[1,])]
bcid.gene.prev.reg.count <- data.frame(unique(bcid.gene.count.all[,c('YearWeek','CustomerSiteId','Runs')]), bcid.gene.prevalence.reg.count)
bcid.gene.prev.reg.count[bcid.gene.prev.reg.count$Runs < 10, 'Runs'] <- NA

# Continue on with making charts, both the Trend and Pareto charts
bcid.gene.count.trim <- bcid.gene.prev.reg.count[as.character(bcid.gene.prev.reg.count$YearWeek) >= start.week.bcid, ]
bcid.gene.count.wrap <- do.call(rbind, lapply(1:length(grep(paste('^', paste(letters, collapse='|^'), sep=''), colnames(bcid.gene.count.trim))), function(x) data.frame(YearWeek = bcid.gene.count.trim$YearWeek, CustomerSiteId = bcid.gene.count.trim$CustomerSiteId, Runs = bcid.gene.count.trim$Runs, Code = letters[x], gene = bcid.gene.count.trim[,letters[x]])))
bcid.gene.prev.wrap <- data.frame(YearWeek = bcid.gene.count.wrap$YearWeek, CustomerSiteId = bcid.gene.count.wrap$CustomerSiteId, Code = bcid.gene.count.wrap$Code, Prevalence = bcid.gene.count.wrap$gene/bcid.gene.count.wrap$Runs)
bcid.gene.prev.wrap <- with(bcid.gene.prev.wrap, aggregate(Prevalence~YearWeek+Code, FUN=mean))
bcid.gene.prev.wrap <- merge(merge(bcid.gene.prev.wrap, decoder, by='Code'), shortnames.df, by.x='Bug', by.y='Interpretation')
p.bcid.prev.gene.trend <- ggplot(bcid.gene.prev.wrap[with(bcid.gene.prev.wrap, order(ShortName, decreasing=TRUE)), ], aes(x=YearWeek)) + geom_area(aes(y=Prevalence, group=ShortName, fill=ShortName, order=ShortName)) + scale_fill_manual(values=createPaletteOfVariableLength(bcid.gene.prev.wrap,'ShortName'), name='') + scale_y_continuous(labels=percent) + scale_x_discrete(breaks = as.character(unique(bcid.gene.prev.wrap$YearWeek))[order(as.character(unique(bcid.gene.prev.wrap$YearWeek)))][seq(1, length(as.character(unique(bcid.gene.prev.wrap$YearWeek))), 8)]) + theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(angle=90, hjust=1, vjust=0.5), legend.position='bottom') + labs(title='Percent Detection of Genes in BCID Tests', x='Year-Week', y='Percent Detection')
bcid.gene.count.pareto <- bcid.gene.count.wrap[as.character(bcid.gene.count.wrap$YearWeek) >= start.week.bcid.pareto, ]
bcid.gene.prev.pareto <- with(bcid.gene.count.pareto, aggregate(cbind(Runs, gene)~CustomerSiteId+Code, FUN=sum))
bcid.gene.prev.pareto$Prevalence <- with(bcid.gene.prev.pareto, gene/Runs)
bcid.gene.prev.pareto <- with(bcid.gene.prev.pareto, aggregate(Prevalence~Code, FUN=mean))
bcid.gene.prev.pareto <- merge(merge(bcid.gene.prev.pareto, decoder, by='Code'), shortnames.df, by.x='Bug', by.y='Interpretation')
bcid.gene.prev.pareto$Name <- factor(bcid.gene.prev.pareto$ShortName, levels = bcid.gene.prev.pareto[with(bcid.gene.prev.pareto, order(Prevalence, decreasing = TRUE)), 'ShortName']) 
p.bcid.prev.gene.pareto <- ggplot(bcid.gene.prev.pareto, aes(x=Name, y=Prevalence, fill='Bug')) + geom_bar(stat='identity') + geom_text(aes(x=Name, y=Prevalence+0.01, label=paste(round(Prevalence,3)*100, '%', sep='')), data=bcid.gene.prev.pareto) + scale_fill_manual(values = createPaletteOfVariableLength(data.frame(Key='Bug'), 'Key'), guide=FALSE) + scale_y_continuous(labels=percent) + theme(text=element_text(size=20, face='bold'), axis.text=element_text(size=20, face='bold', color='black'), axis.text.x=element_text(angle=60, hjust=1)) + labs(title='Gene Prevalence in BCID Tests\n(Last 16 Weeks)', x='', y='Percent Detection')

# -----------------------------------------------------------------------------------------------------------
# RP ILI and BURN overlay charts by organism family
ili.nat.roll <- data.frame(YearWeek = with(ili.df, ifelse(Week < 10, paste(Year, Week, sep='-0'), paste(Year, Week, sep='-')))[2:(length(ili.df$Year)-1)], RateILI = sapply(2:(length(ili.df$Year)-1), function(x) sum(ili.df[(x-1):(x+1),'ILITotal'])/sum(ili.df[(x-1):(x+1),'TotalPatients'])))
rp.overlay <- merge(subset(rp.runs.norm.nat, as.character(YearWeek) >= start.week.rp), subset(ili.nat.roll, as.character(YearWeek) >= start.week.rp), by='YearWeek', all.x=TRUE)
rp.overlay <- merge(rp.prev.wrap[,c('YearWeek','ShortName','Prevalence')], rp.overlay[,c('YearWeek','RateILI','NormalizedBurn')], by='YearWeek')

bacterias <- c('B. pertussis','C. pneumoniae','M. pneumo')
rhino <- 'HRV/Entero'
fluAs <- as.character(unique(rp.overlay[grep('Flu A|FluA', rp.overlay$ShortName),'ShortName']))
fluBs <- 'FluB'
rsv <- 'RSV'
pivs <- as.character(unique(rp.overlay[grep('PIV', rp.overlay$ShortName),'ShortName']))
corona <- as.character(unique(rp.overlay[grep('CoV', rp.overlay$ShortName),'ShortName']))
adeno <- 'Adeno'
hmp <- 'hMPV'

# dual axes for overlay plots
hinvert_title_grob <- function(grob){
  
  # Swap the widths
  widths <- grob$widths
  grob$widths[1] <- widths[3]
  grob$widths[3] <- widths[1]
  grob$vp[[1]]$layout$widths[1] <- widths[3]
  grob$vp[[1]]$layout$widths[3] <- widths[1]
  
  # Fix the justification
  grob$children[[1]]$hjust <- 1 - grob$children[[1]]$hjust 
  grob$children[[1]]$vjust <- 1 - grob$children[[1]]$vjust 
  grob$children[[1]]$x <- unit(1, "npc") - grob$children[[1]]$x
  grob
}

# make time series percent detection by organism family with ILI and Normalized Utilization Overlays
rp.overlay <- rp.overlay[with(rp.overlay, order(ShortName, YearWeek)), ]
rp.Trend.Pal <- createPaletteOfVariableLength(rp.overlay, 'ShortName')
# - FLU As------------------------------------------------------------------------------------------------------
if(TRUE) {
  p1 <- ggplot(subset(rp.overlay[with(rp.overlay, order(ShortName, decreasing=TRUE)),], ShortName %in% fluAs), aes(x=YearWeek)) + geom_area(aes(y=Prevalence, fill=ShortName, group=ShortName, order=ShortName), stat='identity', position='stack') + scale_fill_manual(values=rp.Trend.Pal, name='') + scale_x_discrete(breaks = as.character(unique(rp.overlay$YearWeek))[order(as.character(unique(rp.overlay$YearWeek)))][seq(1, length(as.character(unique(rp.overlay$YearWeek))), 8)]) + scale_y_continuous(label=percent, breaks=c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7)) + theme(text=element_text(size=22, face='bold'), axis.text=element_text(size=22, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom', panel.background=element_rect(color='transparent', fill='white'), panel.grid=element_blank()) + labs(title='Percent Detection of Influenza A in Trend Population with ILI Overlay', y='Percent Detection of Organism', x='Year-Week') + expand_limits(y=0.7)
  p2 <- ggplot(subset(rp.overlay[with(rp.overlay, order(ShortName, decreasing=TRUE)),], ShortName %in% fluAs), aes(x=YearWeek, y=5*RateILI, group=1)) + geom_line(color='black', lwd=2) + geom_line(aes(x=YearWeek, y=5*NormalizedBurn/100, group=2), rp.overlay, color='red', lwd=2) + scale_x_discrete(breaks = as.character(unique(rp.overlay$YearWeek))[order(as.character(unique(rp.overlay$YearWeek)))][seq(1, length(as.character(unique(rp.overlay$YearWeek))), 8)]) + scale_y_continuous(limits=c(0,5*max(rp.overlay$RateILI)), breaks=c(0, 0.05, 0.10, 0.15, 0.2, 0.25), labels=c('0%','1%','2%','3%','4%','5%')) + theme(text=element_text(size=22, face='bold'), axis.text=element_text(size=22, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom', panel.background=element_rect(fill='transparent', color='transparent'), panel.grid=element_blank()) + labs(y='ILI (black), BURN/100 (red)')
  
  # Get the ggplot grobs
  g1 <- ggplotGrob(p1)
  g2 <- ggplotGrob(p2)
  
  # Get the location of the plot panel in g1.
  # These are used later when transformed elements of g2 are put back into g1
  pp <- c(subset(g1$layout, name == "panel", se = t:r))
  
  # Overlap panel for second plot on that of the first plot
  g1 <- gtable_add_grob(g1, g2$grobs[[which(g2$layout$name == "panel")]], pp$t, pp$l, pp$b, pp$l)
  
  # Get the y axis title from g2
  index <- which(g2$layout$name == "ylab-l") # Which grob contains the y axis title?
  ylab <- g2$grobs[[index]]                # Extract that grob
  ylab <- hinvert_title_grob(ylab)         # Swap margins and fix justifications
  
  # Put the transformed label on the right side of g1
  g1 <- gtable_add_cols(g1, g2$widths[g2$layout[index, ]$l], pp$r)
  g1 <- gtable_add_grob(g1, ylab, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "ylab-r")
  
  # Get the y axis from g2 (axis line, tick marks, and tick mark labels)
  index <- which(g2$layout$name == "axis-l")  # Which grob
  yaxis <- g2$grobs[[index]]                  # Extract the grob
  
  # yaxis is a complex of grobs containing the axis line, the tick marks, and the tick mark labels.
  # The relevant grobs are contained in axis$children:
  #   axis$children[[1]] contains the axis line;
  #   axis$children[[2]] contains the tick marks and tick mark labels.
  
  # First, move the axis line to the left
  yaxis$children[[1]]$x <- unit.c(unit(0, "npc"), unit(0, "npc"))
  
  # Second, swap tick marks and tick mark labels
  ticks <- yaxis$children[[2]]
  ticks$widths <- rev(ticks$widths)
  ticks$grobs <- rev(ticks$grobs)
  
  # Third, move the tick marks
  ticks$grobs[[1]]$x <- ticks$grobs[[1]]$x - unit(1, "npc") + unit(3, "pt")
  
  # Fourth, swap margins and fix justifications for the tick mark labels
  ticks$grobs[[2]] <- hinvert_title_grob(ticks$grobs[[2]])
  
  # Fifth, put ticks back into yaxis
  yaxis$children[[2]] <- ticks
  
  # Put the transformed yaxis on the right side of g1
  g1 <- gtable_add_cols(g1, g2$widths[g2$layout[index, ]$l], pp$r)
  overlay.fluAs <- gtable_add_grob(g1, yaxis, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "axis-r")
  
  # Draw it
  grid.newpage()
  png('../images/Dashboard_Trends/FluAPercentDetectionWithOverlayTrend.png', height=800, width=1400)
  grid.draw(overlay.fluAs)
  dev.off()
}
# - FLU B-------------------------------------------------------------------------------------------------------
if(TRUE) {
  p1 <- ggplot(subset(rp.overlay[with(rp.overlay, order(ShortName, decreasing=TRUE)),], ShortName %in% fluBs), aes(x=YearWeek)) + geom_area(aes(y=Prevalence, fill=ShortName, group=ShortName, order=ShortName), stat='identity', position='stack') + scale_fill_manual(values=rp.Trend.Pal, name='') + scale_x_discrete(breaks = as.character(unique(rp.overlay$YearWeek))[order(as.character(unique(rp.overlay$YearWeek)))][seq(1, length(as.character(unique(rp.overlay$YearWeek))), 8)]) + scale_y_continuous(label=percent, breaks=c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7)) + theme(text=element_text(size=22, face='bold'), axis.text=element_text(size=22, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom', panel.background=element_rect(color='transparent', fill='white'), panel.grid=element_blank()) + labs(title='Percent Detection of Influenza B in Trend Population with ILI Overlay', y='Percent Detection of Organism', x='Year-Week') + expand_limits(y=0.7)
  p2 <- ggplot(subset(rp.overlay[with(rp.overlay, order(ShortName, decreasing=TRUE)),], ShortName %in% fluBs), aes(x=YearWeek, y=2.5*RateILI, group=1))  + geom_line(color='black', lwd=2) + geom_line(aes(x=YearWeek, y=2.5*NormalizedBurn/100, group=2), rp.overlay, color='red', lwd=2) + scale_x_discrete(breaks = as.character(unique(rp.overlay$YearWeek))[order(as.character(unique(rp.overlay$YearWeek)))][seq(1, length(as.character(unique(rp.overlay$YearWeek))), 8)]) + scale_y_continuous(limits=c(0,2.5*max(rp.overlay$RateILI)), breaks=c(0, 0.025, 0.05, 0.075, 0.1, 0.125), labels=c('0%','1%','2%','3%','4%','5%')) + theme(text=element_text(size=22, face='bold'), axis.text=element_text(size=22, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom', panel.background=element_rect(fill='transparent', color='transparent'), panel.grid=element_blank()) + labs(y='ILI (black), BURN (red)')
  
  # Get the ggplot grobs
  g1 <- ggplotGrob(p1)
  g2 <- ggplotGrob(p2)
  
  # Get the location of the plot panel in g1.
  # These are used later when transformed elements of g2 are put back into g1
  pp <- c(subset(g1$layout, name == "panel", se = t:r))
  
  # Overlap panel for second plot on that of the first plot
  g1 <- gtable_add_grob(g1, g2$grobs[[which(g2$layout$name == "panel")]], pp$t, pp$l, pp$b, pp$l)
  
  # Get the y axis title from g2
  index <- which(g2$layout$name == "ylab-l") # Which grob contains the y axis title?
  ylab <- g2$grobs[[index]]                # Extract that grob
  ylab <- hinvert_title_grob(ylab)         # Swap margins and fix justifications
  
  # Put the transformed label on the right side of g1
  g1 <- gtable_add_cols(g1, g2$widths[g2$layout[index, ]$l], pp$r)
  g1 <- gtable_add_grob(g1, ylab, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "ylab-r")
  
  # Get the y axis from g2 (axis line, tick marks, and tick mark labels)
  index <- which(g2$layout$name == "axis-l")  # Which grob
  yaxis <- g2$grobs[[index]]                  # Extract the grob
  
  # yaxis is a complex of grobs containing the axis line, the tick marks, and the tick mark labels.
  # The relevant grobs are contained in axis$children:
  #   axis$children[[1]] contains the axis line;
  #   axis$children[[2]] contains the tick marks and tick mark labels.
  
  # First, move the axis line to the left
  yaxis$children[[1]]$x <- unit.c(unit(0, "npc"), unit(0, "npc"))
  
  # Second, swap tick marks and tick mark labels
  ticks <- yaxis$children[[2]]
  ticks$widths <- rev(ticks$widths)
  ticks$grobs <- rev(ticks$grobs)
  
  # Third, move the tick marks
  ticks$grobs[[1]]$x <- ticks$grobs[[1]]$x - unit(1, "npc") + unit(3, "pt")
  
  # Fourth, swap margins and fix justifications for the tick mark labels
  ticks$grobs[[2]] <- hinvert_title_grob(ticks$grobs[[2]])
  
  # Fifth, put ticks back into yaxis
  yaxis$children[[2]] <- ticks
  
  # Put the transformed yaxis on the right side of g1
  g1 <- gtable_add_cols(g1, g2$widths[g2$layout[index, ]$l], pp$r)
  overlay.fluBs <- gtable_add_grob(g1, yaxis, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "axis-r")
  
  # Draw it
  grid.newpage()
  png('../images/Dashboard_Trends/FluBPercentDetectionWithOverlayTrend.png', height=800, width=1400)
  grid.draw(overlay.fluBs)
  dev.off()
}  
# - RSV---------------------------------------------------------------------------------------------------------
if(TRUE) {
  p1 <- ggplot(subset(rp.overlay[with(rp.overlay, order(ShortName, decreasing=TRUE)),], ShortName %in% rsv), aes(x=YearWeek)) + geom_area(aes(y=Prevalence, fill=ShortName, group=ShortName, order=ShortName), stat='identity', position='stack') + scale_fill_manual(values=rp.Trend.Pal, name='') + scale_x_discrete(breaks = as.character(unique(rp.overlay$YearWeek))[order(as.character(unique(rp.overlay$YearWeek)))][seq(1, length(as.character(unique(rp.overlay$YearWeek))), 8)]) + scale_y_continuous(label=percent, breaks=c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7)) + theme(text=element_text(size=22, face='bold'), axis.text=element_text(size=22, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom', panel.background=element_rect(color='transparent', fill='white'), panel.grid=element_blank())  + labs(title='Percent Detection of RSV in Trend Population with ILI Overlay', y='Percent Detection of Organism', x='Year-Week') + expand_limits(y=0.7)
  p2 <- ggplot(subset(rp.overlay[with(rp.overlay, order(ShortName, decreasing=TRUE)),], ShortName %in% rsv), aes(x=YearWeek, y=6*RateILI, group=1)) + geom_line(color='black', lwd=2) + geom_line(aes(x=YearWeek, y=6*NormalizedBurn/100, group=2), rp.overlay, color='red', lwd=2) + scale_x_discrete(breaks = as.character(unique(rp.overlay$YearWeek))[order(as.character(unique(rp.overlay$YearWeek)))][seq(1, length(as.character(unique(rp.overlay$YearWeek))), 8)]) + scale_y_continuous(limits=c(0,6*max(rp.overlay$RateILI)), breaks=c(0, 0.06, 0.12, 0.18, 0.24, 0.30), labels=c('0%','1%','2%','3%','4%','5%')) + theme(text=element_text(size=22, face='bold'), axis.text=element_text(size=22, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom', panel.background=element_rect(fill='transparent', color='transparent'), panel.grid=element_blank()) + labs(y='ILI (black), BURN (red)')
  
  # Get the ggplot grobs
  g1 <- ggplotGrob(p1)
  g2 <- ggplotGrob(p2)
  
  # Get the location of the plot panel in g1.
  # These are used later when transformed elements of g2 are put back into g1
  pp <- c(subset(g1$layout, name == "panel", se = t:r))
  
  # Overlap panel for second plot on that of the first plot
  g1 <- gtable_add_grob(g1, g2$grobs[[which(g2$layout$name == "panel")]], pp$t, pp$l, pp$b, pp$l)
  
  # Get the y axis title from g2
  index <- which(g2$layout$name == "ylab-l") # Which grob contains the y axis title?
  ylab <- g2$grobs[[index]]                # Extract that grob
  ylab <- hinvert_title_grob(ylab)         # Swap margins and fix justifications
  
  # Put the transformed label on the right side of g1
  g1 <- gtable_add_cols(g1, g2$widths[g2$layout[index, ]$l], pp$r)
  g1 <- gtable_add_grob(g1, ylab, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "ylab-r")
  
  # Get the y axis from g2 (axis line, tick marks, and tick mark labels)
  index <- which(g2$layout$name == "axis-l")  # Which grob
  yaxis <- g2$grobs[[index]]                  # Extract the grob
  
  # yaxis is a complex of grobs containing the axis line, the tick marks, and the tick mark labels.
  # The relevant grobs are contained in axis$children:
  #   axis$children[[1]] contains the axis line;
  #   axis$children[[2]] contains the tick marks and tick mark labels.
  
  # First, move the axis line to the left
  yaxis$children[[1]]$x <- unit.c(unit(0, "npc"), unit(0, "npc"))
  
  # Second, swap tick marks and tick mark labels
  ticks <- yaxis$children[[2]]
  ticks$widths <- rev(ticks$widths)
  ticks$grobs <- rev(ticks$grobs)
  
  # Third, move the tick marks
  ticks$grobs[[1]]$x <- ticks$grobs[[1]]$x - unit(1, "npc") + unit(3, "pt")
  
  # Fourth, swap margins and fix justifications for the tick mark labels
  ticks$grobs[[2]] <- hinvert_title_grob(ticks$grobs[[2]])
  
  # Fifth, put ticks back into yaxis
  yaxis$children[[2]] <- ticks
  
  # Put the transformed yaxis on the right side of g1
  g1 <- gtable_add_cols(g1, g2$widths[g2$layout[index, ]$l], pp$r)
  overlay.rsv <- gtable_add_grob(g1, yaxis, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "axis-r")
  
  # Draw it
  grid.newpage()
  png('../images/Dashboard_Trends/RSVPercentDetectionWithOverlayTrend.png', height=800, width=1400)
  grid.draw(overlay.rsv)
  dev.off()
}
# - PIVs--------------------------------------------------------------------------------------------------------
if(TRUE) {
  
  p1 <- ggplot(subset(rp.overlay[with(rp.overlay, order(ShortName, decreasing=TRUE)),], ShortName %in% pivs), aes(x=YearWeek)) + geom_area(aes(y=Prevalence, fill=ShortName, group=ShortName, order=ShortName), stat='identity', position='stack') + scale_fill_manual(values=rp.Trend.Pal, name='') + scale_x_discrete(breaks = as.character(unique(rp.overlay$YearWeek))[order(as.character(unique(rp.overlay$YearWeek)))][seq(1, length(as.character(unique(rp.overlay$YearWeek))), 8)]) + scale_y_continuous(label=percent, breaks=c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7)) + theme(text=element_text(size=22, face='bold'), axis.text=element_text(size=22, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom', panel.background=element_rect(color='transparent', fill='white'), panel.grid=element_blank())  + labs(title='Percent Detection of Parainfluenza in Trend Population with ILI Overlay', y='Percent Detection of Organism', x='Year-Week') + expand_limits(y=0.7)
  p2 <- ggplot(subset(rp.overlay[with(rp.overlay, order(ShortName, decreasing=TRUE)),], ShortName %in% pivs), aes(x=YearWeek, y=3*RateILI, group=1)) + geom_line(color='black', lwd=2) + geom_line(aes(x=YearWeek, y=3*NormalizedBurn/100, group=2), rp.overlay, color='red', lwd=2) + scale_x_discrete(breaks = as.character(unique(rp.overlay$YearWeek))[order(as.character(unique(rp.overlay$YearWeek)))][seq(1, length(as.character(unique(rp.overlay$YearWeek))), 8)]) + scale_y_continuous(limits=c(0,3*max(rp.overlay$RateILI)), breaks=c(0, 0.03, 0.06, 0.09, 0.12, 0.15), labels=c('0%','1%','2%','3%','4%','5%')) + theme(text=element_text(size=22, face='bold'), axis.text=element_text(size=22, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom', panel.background=element_rect(fill='transparent', color='transparent'), panel.grid=element_blank()) + labs(y='ILI (black), BURN (red)')
  
  # Get the ggplot grobs
  g1 <- ggplotGrob(p1)
  g2 <- ggplotGrob(p2)
  
  # Get the location of the plot panel in g1.
  # These are used later when transformed elements of g2 are put back into g1
  pp <- c(subset(g1$layout, name == "panel", se = t:r))
  
  # Overlap panel for second plot on that of the first plot
  g1 <- gtable_add_grob(g1, g2$grobs[[which(g2$layout$name == "panel")]], pp$t, pp$l, pp$b, pp$l)
  
  # Get the y axis title from g2
  index <- which(g2$layout$name == "ylab-l") # Which grob contains the y axis title?
  ylab <- g2$grobs[[index]]                # Extract that grob
  ylab <- hinvert_title_grob(ylab)         # Swap margins and fix justifications
  
  # Put the transformed label on the right side of g1
  g1 <- gtable_add_cols(g1, g2$widths[g2$layout[index, ]$l], pp$r)
  g1 <- gtable_add_grob(g1, ylab, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "ylab-r")
  
  # Get the y axis from g2 (axis line, tick marks, and tick mark labels)
  index <- which(g2$layout$name == "axis-l")  # Which grob
  yaxis <- g2$grobs[[index]]                  # Extract the grob
  
  # yaxis is a complex of grobs containing the axis line, the tick marks, and the tick mark labels.
  # The relevant grobs are contained in axis$children:
  #   axis$children[[1]] contains the axis line;
  #   axis$children[[2]] contains the tick marks and tick mark labels.
  
  # First, move the axis line to the left
  yaxis$children[[1]]$x <- unit.c(unit(0, "npc"), unit(0, "npc"))
  
  # Second, swap tick marks and tick mark labels
  ticks <- yaxis$children[[2]]
  ticks$widths <- rev(ticks$widths)
  ticks$grobs <- rev(ticks$grobs)
  
  # Third, move the tick marks
  ticks$grobs[[1]]$x <- ticks$grobs[[1]]$x - unit(1, "npc") + unit(3, "pt")
  
  # Fourth, swap margins and fix justifications for the tick mark labels
  ticks$grobs[[2]] <- hinvert_title_grob(ticks$grobs[[2]])
  
  # Fifth, put ticks back into yaxis
  yaxis$children[[2]] <- ticks
  
  # Put the transformed yaxis on the right side of g1
  g1 <- gtable_add_cols(g1, g2$widths[g2$layout[index, ]$l], pp$r)
  overlay.pivs <- gtable_add_grob(g1, yaxis, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "axis-r")
  
  # Draw it
  grid.newpage()
  png('../images/Dashboard_Trends/PIVsPercentDetectionWithOverlayTrend.png', height=800, width=1400)
  grid.draw(overlay.pivs)
  dev.off()
}
# - CoVs--------------------------------------------------------------------------------------------------------
if(TRUE) {
  
  p1 <- ggplot(subset(rp.overlay[with(rp.overlay, order(ShortName, decreasing=TRUE)),], ShortName %in% corona), aes(x=YearWeek)) + geom_area(aes(y=Prevalence, fill=ShortName, group=ShortName, order=ShortName), stat='identity', position='stack') + scale_fill_manual(values=rp.Trend.Pal, name='') + scale_x_discrete(breaks = as.character(unique(rp.overlay$YearWeek))[order(as.character(unique(rp.overlay$YearWeek)))][seq(1, length(as.character(unique(rp.overlay$YearWeek))), 8)]) + scale_y_continuous(label=percent, breaks=c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7)) + theme(text=element_text(size=22, face='bold'), axis.text=element_text(size=22, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom', panel.background=element_rect(color='transparent', fill='white'), panel.grid=element_blank())  + labs(title='Percent Detection of Coronavirus in Trend Population with ILI Overlay', y='Percent Detection of Organism', x='Year-Week') + expand_limits(y=0.7)
  p2 <- ggplot(subset(rp.overlay[with(rp.overlay, order(ShortName, decreasing=TRUE)),], ShortName %in% corona), aes(x=YearWeek, y=3*RateILI, group=1)) + geom_line(color='black', lwd=2) + geom_line(aes(x=YearWeek, y=3*NormalizedBurn/100, group=2), rp.overlay, color='red', lwd=2) + scale_x_discrete(breaks = as.character(unique(rp.overlay$YearWeek))[order(as.character(unique(rp.overlay$YearWeek)))][seq(1, length(as.character(unique(rp.overlay$YearWeek))), 8)]) + scale_y_continuous(limits=c(0,3*max(rp.overlay$RateILI)), breaks=c(0, 0.03, 0.06, 0.09, 0.12, 0.15), labels=c('0%','1%','2%','3%','4%','5%')) + theme(text=element_text(size=22, face='bold'), axis.text=element_text(size=22, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom', panel.background=element_rect(fill='transparent', color='transparent'), panel.grid=element_blank()) + labs(y='ILI (black), BURN (red)')
  
  # Get the ggplot grobs
  g1 <- ggplotGrob(p1)
  g2 <- ggplotGrob(p2)
  
  # Get the location of the plot panel in g1.
  # These are used later when transformed elements of g2 are put back into g1
  pp <- c(subset(g1$layout, name == "panel", se = t:r))
  
  # Overlap panel for second plot on that of the first plot
  g1 <- gtable_add_grob(g1, g2$grobs[[which(g2$layout$name == "panel")]], pp$t, pp$l, pp$b, pp$l)
  
  # Get the y axis title from g2
  index <- which(g2$layout$name == "ylab-l") # Which grob contains the y axis title?
  ylab <- g2$grobs[[index]]                # Extract that grob
  ylab <- hinvert_title_grob(ylab)         # Swap margins and fix justifications
  
  # Put the transformed label on the right side of g1
  g1 <- gtable_add_cols(g1, g2$widths[g2$layout[index, ]$l], pp$r)
  g1 <- gtable_add_grob(g1, ylab, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "ylab-r")
  
  # Get the y axis from g2 (axis line, tick marks, and tick mark labels)
  index <- which(g2$layout$name == "axis-l")  # Which grob
  yaxis <- g2$grobs[[index]]                  # Extract the grob
  
  # yaxis is a complex of grobs containing the axis line, the tick marks, and the tick mark labels.
  # The relevant grobs are contained in axis$children:
  #   axis$children[[1]] contains the axis line;
  #   axis$children[[2]] contains the tick marks and tick mark labels.
  
  # First, move the axis line to the left
  yaxis$children[[1]]$x <- unit.c(unit(0, "npc"), unit(0, "npc"))
  
  # Second, swap tick marks and tick mark labels
  ticks <- yaxis$children[[2]]
  ticks$widths <- rev(ticks$widths)
  ticks$grobs <- rev(ticks$grobs)
  
  # Third, move the tick marks
  ticks$grobs[[1]]$x <- ticks$grobs[[1]]$x - unit(1, "npc") + unit(3, "pt")
  
  # Fourth, swap margins and fix justifications for the tick mark labels
  ticks$grobs[[2]] <- hinvert_title_grob(ticks$grobs[[2]])
  
  # Fifth, put ticks back into yaxis
  yaxis$children[[2]] <- ticks
  
  # Put the transformed yaxis on the right side of g1
  g1 <- gtable_add_cols(g1, g2$widths[g2$layout[index, ]$l], pp$r)
  overlay.covs <- gtable_add_grob(g1, yaxis, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "axis-r")
  
  # Draw it
  grid.newpage()
  png('../images/Dashboard_Trends/CoVsPercentDetectionWithOverlayTrend.png', height=800, width=1400)
  grid.draw(overlay.covs)
  dev.off()
}
# - Rhino-------------------------------------------------------------------------------------------------------
if(TRUE) {
  
  p1 <- ggplot(subset(rp.overlay[with(rp.overlay, order(ShortName, decreasing=TRUE)),], ShortName %in% rhino), aes(x=YearWeek)) + geom_area(aes(y=Prevalence, fill=ShortName, group=ShortName, order=ShortName), stat='identity', position='stack') + scale_fill_manual(values=rp.Trend.Pal, name='') + scale_x_discrete(breaks = as.character(unique(rp.overlay$YearWeek))[order(as.character(unique(rp.overlay$YearWeek)))][seq(1, length(as.character(unique(rp.overlay$YearWeek))), 8)]) + scale_y_continuous(label=percent, breaks=c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7)) + theme(text=element_text(size=22, face='bold'), axis.text=element_text(size=22, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom', panel.background=element_rect(color='transparent', fill='white'), panel.grid=element_blank())  + labs(title='Percent Detection of Human Rhino/Enterovirus in Trend Population with ILI Overlay', y='Percent Detection of Organism', x='Year-Week') + expand_limits(y=0.7)
  p2 <- ggplot(subset(rp.overlay[with(rp.overlay, order(ShortName, decreasing=TRUE)),], ShortName %in% rhino), aes(x=YearWeek, y=12*RateILI, group=1)) + geom_line(color='black', lwd=2) + geom_line(aes(x=YearWeek, y=12*NormalizedBurn/100, group=2), rp.overlay, color='red', lwd=2) + scale_x_discrete(breaks = as.character(unique(rp.overlay$YearWeek))[order(as.character(unique(rp.overlay$YearWeek)))][seq(1, length(as.character(unique(rp.overlay$YearWeek))), 8)]) + scale_y_continuous(limits=c(0,12*max(rp.overlay$RateILI)), breaks=c(0, 0.12, 0.24, 0.36, 0.48, 0.6), labels=c('0%','1%','2%','3%','4%','5%')) + theme(text=element_text(size=22, face='bold'), axis.text=element_text(size=22, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom', panel.background=element_rect(fill='transparent', color='transparent'), panel.grid=element_blank()) + labs(y='ILI (black), BURN (red)')
  
  # Get the ggplot grobs
  g1 <- ggplotGrob(p1)
  g2 <- ggplotGrob(p2)
  
  # Get the location of the plot panel in g1.
  # These are used later when transformed elements of g2 are put back into g1
  pp <- c(subset(g1$layout, name == "panel", se = t:r))
  
  # Overlap panel for second plot on that of the first plot
  g1 <- gtable_add_grob(g1, g2$grobs[[which(g2$layout$name == "panel")]], pp$t, pp$l, pp$b, pp$l)
  
  # Get the y axis title from g2
  index <- which(g2$layout$name == "ylab-l") # Which grob contains the y axis title?
  ylab <- g2$grobs[[index]]                # Extract that grob
  ylab <- hinvert_title_grob(ylab)         # Swap margins and fix justifications
  
  # Put the transformed label on the right side of g1
  g1 <- gtable_add_cols(g1, g2$widths[g2$layout[index, ]$l], pp$r)
  g1 <- gtable_add_grob(g1, ylab, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "ylab-r")
  
  # Get the y axis from g2 (axis line, tick marks, and tick mark labels)
  index <- which(g2$layout$name == "axis-l")  # Which grob
  yaxis <- g2$grobs[[index]]                  # Extract the grob
  
  # yaxis is a complex of grobs containing the axis line, the tick marks, and the tick mark labels.
  # The relevant grobs are contained in axis$children:
  #   axis$children[[1]] contains the axis line;
  #   axis$children[[2]] contains the tick marks and tick mark labels.
  
  # First, move the axis line to the left
  yaxis$children[[1]]$x <- unit.c(unit(0, "npc"), unit(0, "npc"))
  
  # Second, swap tick marks and tick mark labels
  ticks <- yaxis$children[[2]]
  ticks$widths <- rev(ticks$widths)
  ticks$grobs <- rev(ticks$grobs)
  
  # Third, move the tick marks
  ticks$grobs[[1]]$x <- ticks$grobs[[1]]$x - unit(1, "npc") + unit(3, "pt")
  
  # Fourth, swap margins and fix justifications for the tick mark labels
  ticks$grobs[[2]] <- hinvert_title_grob(ticks$grobs[[2]])
  
  # Fifth, put ticks back into yaxis
  yaxis$children[[2]] <- ticks
  
  # Put the transformed yaxis on the right side of g1
  g1 <- gtable_add_cols(g1, g2$widths[g2$layout[index, ]$l], pp$r)
  overlay.rhino <- gtable_add_grob(g1, yaxis, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "axis-r")
  
  # Draw it
  grid.newpage()
  png('../images/Dashboard_Trends/RhinoPercentDetectionWithOverlayTrend.png', height=800, width=1400)
  grid.draw(overlay.rhino)
  dev.off()
}
# - Adeno-------------------------------------------------------------------------------------------------------
if(TRUE) {
  
  p1 <- ggplot(subset(rp.overlay[with(rp.overlay, order(ShortName, decreasing=TRUE)),], ShortName %in% adeno), aes(x=YearWeek)) + geom_area(aes(y=Prevalence, fill=ShortName, group=ShortName, order=ShortName), stat='identity', position='stack') + scale_fill_manual(values=rp.Trend.Pal, name='') + scale_x_discrete(breaks = as.character(unique(rp.overlay$YearWeek))[order(as.character(unique(rp.overlay$YearWeek)))][seq(1, length(as.character(unique(rp.overlay$YearWeek))), 8)]) + scale_y_continuous(label=percent, breaks=c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7)) + theme(text=element_text(size=22, face='bold'), axis.text=element_text(size=22, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom', panel.background=element_rect(color='transparent', fill='white'), panel.grid=element_blank())  + labs(title='Percent Detection of Adenovirus in Trend Population with ILI Overlay', y='Percent Detection of Organism', x='Year-Week') + expand_limits(y=0.7)
  p2 <- ggplot(subset(rp.overlay[with(rp.overlay, order(ShortName, decreasing=TRUE)),], ShortName %in% adeno), aes(x=YearWeek, y=3*RateILI, group=1))+ geom_line(color='black', lwd=2) + geom_line(aes(x=YearWeek, y=3*NormalizedBurn/100, group=2), rp.overlay, color='red', lwd=2) + scale_x_discrete(breaks = as.character(unique(rp.overlay$YearWeek))[order(as.character(unique(rp.overlay$YearWeek)))][seq(1, length(as.character(unique(rp.overlay$YearWeek))), 8)]) + scale_y_continuous(limits=c(0,3*max(rp.overlay$RateILI)), breaks=c(0, 0.03, 0.06, 0.09, 0.12, 0.15), labels=c('0%','1%','2%','3%','4%','5%')) + theme(text=element_text(size=22, face='bold'), axis.text=element_text(size=22, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom', panel.background=element_rect(fill='transparent', color='transparent'), panel.grid=element_blank()) + labs(y='ILI (black), BURN (red)')
  
  # Get the ggplot grobs
  g1 <- ggplotGrob(p1)
  g2 <- ggplotGrob(p2)
  
  # Get the location of the plot panel in g1.
  # These are used later when transformed elements of g2 are put back into g1
  pp <- c(subset(g1$layout, name == "panel", se = t:r))
  
  # Overlap panel for second plot on that of the first plot
  g1 <- gtable_add_grob(g1, g2$grobs[[which(g2$layout$name == "panel")]], pp$t, pp$l, pp$b, pp$l)
  
  # Get the y axis title from g2
  index <- which(g2$layout$name == "ylab-l") # Which grob contains the y axis title?
  ylab <- g2$grobs[[index]]                # Extract that grob
  ylab <- hinvert_title_grob(ylab)         # Swap margins and fix justifications
  
  # Put the transformed label on the right side of g1
  g1 <- gtable_add_cols(g1, g2$widths[g2$layout[index, ]$l], pp$r)
  g1 <- gtable_add_grob(g1, ylab, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "ylab-r")
  
  # Get the y axis from g2 (axis line, tick marks, and tick mark labels)
  index <- which(g2$layout$name == "axis-l")  # Which grob
  yaxis <- g2$grobs[[index]]                  # Extract the grob
  
  # yaxis is a complex of grobs containing the axis line, the tick marks, and the tick mark labels.
  # The relevant grobs are contained in axis$children:
  #   axis$children[[1]] contains the axis line;
  #   axis$children[[2]] contains the tick marks and tick mark labels.
  
  # First, move the axis line to the left
  yaxis$children[[1]]$x <- unit.c(unit(0, "npc"), unit(0, "npc"))
  
  # Second, swap tick marks and tick mark labels
  ticks <- yaxis$children[[2]]
  ticks$widths <- rev(ticks$widths)
  ticks$grobs <- rev(ticks$grobs)
  
  # Third, move the tick marks
  ticks$grobs[[1]]$x <- ticks$grobs[[1]]$x - unit(1, "npc") + unit(3, "pt")
  
  # Fourth, swap margins and fix justifications for the tick mark labels
  ticks$grobs[[2]] <- hinvert_title_grob(ticks$grobs[[2]])
  
  # Fifth, put ticks back into yaxis
  yaxis$children[[2]] <- ticks
  
  # Put the transformed yaxis on the right side of g1
  g1 <- gtable_add_cols(g1, g2$widths[g2$layout[index, ]$l], pp$r)
  overlay.adeno <- gtable_add_grob(g1, yaxis, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "axis-r")
  
  # Draw it
  grid.newpage()
  png('../images/Dashboard_Trends/AdenoPercentDetectionWithOverlayTrend.png', height=800, width=1400)
  grid.draw(overlay.adeno)
  dev.off()
}
# - HMPV_-------------------------------------------------------------------------------------------------------
if(TRUE) {
  
  p1 <- ggplot(subset(rp.overlay[with(rp.overlay, order(ShortName, decreasing=TRUE)),], ShortName %in% hmp), aes(x=YearWeek)) + geom_area(aes(y=Prevalence, fill=ShortName, group=ShortName, order=ShortName), stat='identity', position='stack') + scale_fill_manual(values=rp.Trend.Pal, name='') + scale_x_discrete(breaks = as.character(unique(rp.overlay$YearWeek))[order(as.character(unique(rp.overlay$YearWeek)))][seq(1, length(as.character(unique(rp.overlay$YearWeek))), 8)]) + scale_y_continuous(label=percent, breaks=c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7)) + theme(text=element_text(size=22, face='bold'), axis.text=element_text(size=22, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom', panel.background=element_rect(color='transparent', fill='white'), panel.grid=element_blank())  + labs(title='Percent Detection of Human Metapneumovirus in Trend Population with ILI Overlay', y='Percent Detection of Organism', x='Year-Week') + expand_limits(y=0.7)
  p2 <- ggplot(subset(rp.overlay[with(rp.overlay, order(ShortName, decreasing=TRUE)),], ShortName %in% hmp), aes(x=YearWeek, y=3*RateILI, group=1)) + geom_line(color='black', lwd=2) + geom_line(aes(x=YearWeek, y=3*NormalizedBurn/100, group=2), rp.overlay, color='red', lwd=2) + scale_x_discrete(breaks = as.character(unique(rp.overlay$YearWeek))[order(as.character(unique(rp.overlay$YearWeek)))][seq(1, length(as.character(unique(rp.overlay$YearWeek))), 8)]) + scale_y_continuous(limits=c(0,3*max(rp.overlay$RateILI)), breaks=c(0, 0.03, 0.06, 0.09, 0.12, 0.15), labels=c('0%','1%','2%','3%','4%','5%')) + theme(text=element_text(size=22, face='bold'), axis.text=element_text(size=22, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom', panel.background=element_rect(fill='transparent', color='transparent'), panel.grid=element_blank()) + labs(y='ILI (black), BURN (red)')
  
  # Get the ggplot grobs
  g1 <- ggplotGrob(p1)
  g2 <- ggplotGrob(p2)
  
  # Get the location of the plot panel in g1.
  # These are used later when transformed elements of g2 are put back into g1
  pp <- c(subset(g1$layout, name == "panel", se = t:r))
  
  # Overlap panel for second plot on that of the first plot
  g1 <- gtable_add_grob(g1, g2$grobs[[which(g2$layout$name == "panel")]], pp$t, pp$l, pp$b, pp$l)
  
  # Get the y axis title from g2
  index <- which(g2$layout$name == "ylab-l") # Which grob contains the y axis title?
  ylab <- g2$grobs[[index]]                # Extract that grob
  ylab <- hinvert_title_grob(ylab)         # Swap margins and fix justifications
  
  # Put the transformed label on the right side of g1
  g1 <- gtable_add_cols(g1, g2$widths[g2$layout[index, ]$l], pp$r)
  g1 <- gtable_add_grob(g1, ylab, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "ylab-r")
  
  # Get the y axis from g2 (axis line, tick marks, and tick mark labels)
  index <- which(g2$layout$name == "axis-l")  # Which grob
  yaxis <- g2$grobs[[index]]                  # Extract the grob
  
  # yaxis is a complex of grobs containing the axis line, the tick marks, and the tick mark labels.
  # The relevant grobs are contained in axis$children:
  #   axis$children[[1]] contains the axis line;
  #   axis$children[[2]] contains the tick marks and tick mark labels.
  
  # First, move the axis line to the left
  yaxis$children[[1]]$x <- unit.c(unit(0, "npc"), unit(0, "npc"))
  
  # Second, swap tick marks and tick mark labels
  ticks <- yaxis$children[[2]]
  ticks$widths <- rev(ticks$widths)
  ticks$grobs <- rev(ticks$grobs)
  
  # Third, move the tick marks
  ticks$grobs[[1]]$x <- ticks$grobs[[1]]$x - unit(1, "npc") + unit(3, "pt")
  
  # Fourth, swap margins and fix justifications for the tick mark labels
  ticks$grobs[[2]] <- hinvert_title_grob(ticks$grobs[[2]])
  
  # Fifth, put ticks back into yaxis
  yaxis$children[[2]] <- ticks
  
  # Put the transformed yaxis on the right side of g1
  g1 <- gtable_add_cols(g1, g2$widths[g2$layout[index, ]$l], pp$r)
  overlay.hmp <- gtable_add_grob(g1, yaxis, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "axis-r")
  
  # Draw it
  grid.newpage()
  png('../images/Dashboard_Trends/HMPvPercentDetectionWithOverlayTrend.png', height=800, width=1400)
  grid.draw(overlay.hmp)
  dev.off()
}
# - Bacteria-------------------------------------------------------------------------------------------------------
if(TRUE) {
  
  p1 <- ggplot(subset(rp.overlay[with(rp.overlay, order(ShortName, decreasing=TRUE)),], ShortName %in% bacterias), aes(x=YearWeek)) + geom_area(aes(y=Prevalence, fill=ShortName, group=ShortName, order=ShortName), stat='identity', position='stack') + scale_fill_manual(values=rp.Trend.Pal, name='') + scale_x_discrete(breaks = as.character(unique(rp.overlay$YearWeek))[order(as.character(unique(rp.overlay$YearWeek)))][seq(1, length(as.character(unique(rp.overlay$YearWeek))), 8)]) + scale_y_continuous(label=percent, breaks=c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7)) + theme(text=element_text(size=22, face='bold'), axis.text=element_text(size=22, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom', panel.background=element_rect(color='transparent', fill='white'), panel.grid=element_blank())  + labs(title='Percent Detection of Human Metapneumovirus in Trend Population with ILI Overlay', y='Percent Detection of Organism', x='Year-Week') + expand_limits(y=0.7)
  p2 <- ggplot(subset(rp.overlay[with(rp.overlay, order(ShortName, decreasing=TRUE)),], ShortName %in% bacterias), aes(x=YearWeek, y=2.5*RateILI, group=1)) + geom_line(color='black', lwd=2) + geom_line(aes(x=YearWeek, y=2.5*NormalizedBurn/100, group=2), rp.overlay, color='red', lwd=2) + scale_x_discrete(breaks = as.character(unique(rp.overlay$YearWeek))[order(as.character(unique(rp.overlay$YearWeek)))][seq(1, length(as.character(unique(rp.overlay$YearWeek))), 8)]) + scale_y_continuous(limits=c(0,2.5*max(rp.overlay$RateILI)), breaks=c(0, 0.025, 0.05, 0.075, 0.1, 0.125), labels=c('0%','1%','2%','3%','4%','5%')) + theme(text=element_text(size=22, face='bold'), axis.text=element_text(size=22, color='black', face='bold'), axis.text.x=element_text(angle=90, hjust=1), legend.position='bottom', panel.background=element_rect(fill='transparent', color='transparent'), panel.grid=element_blank()) + labs(y='ILI (black), BURN (red)')
  
  # Get the ggplot grobs
  g1 <- ggplotGrob(p1)
  g2 <- ggplotGrob(p2)
  
  # Get the location of the plot panel in g1.
  # These are used later when transformed elements of g2 are put back into g1
  pp <- c(subset(g1$layout, name == "panel", se = t:r))
  
  # Overlap panel for second plot on that of the first plot
  g1 <- gtable_add_grob(g1, g2$grobs[[which(g2$layout$name == "panel")]], pp$t, pp$l, pp$b, pp$l)
  
  # Get the y axis title from g2
  index <- which(g2$layout$name == "ylab-l") # Which grob contains the y axis title?
  ylab <- g2$grobs[[index]]                # Extract that grob
  ylab <- hinvert_title_grob(ylab)         # Swap margins and fix justifications
  
  # Put the transformed label on the right side of g1
  g1 <- gtable_add_cols(g1, g2$widths[g2$layout[index, ]$l], pp$r)
  g1 <- gtable_add_grob(g1, ylab, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "ylab-r")
  
  # Get the y axis from g2 (axis line, tick marks, and tick mark labels)
  index <- which(g2$layout$name == "axis-l")  # Which grob
  yaxis <- g2$grobs[[index]]                  # Extract the grob
  
  # yaxis is a complex of grobs containing the axis line, the tick marks, and the tick mark labels.
  # The relevant grobs are contained in axis$children:
  #   axis$children[[1]] contains the axis line;
  #   axis$children[[2]] contains the tick marks and tick mark labels.
  
  # First, move the axis line to the left
  yaxis$children[[1]]$x <- unit.c(unit(0, "npc"), unit(0, "npc"))
  
  # Second, swap tick marks and tick mark labels
  ticks <- yaxis$children[[2]]
  ticks$widths <- rev(ticks$widths)
  ticks$grobs <- rev(ticks$grobs)
  
  # Third, move the tick marks
  ticks$grobs[[1]]$x <- ticks$grobs[[1]]$x - unit(1, "npc") + unit(3, "pt")
  
  # Fourth, swap margins and fix justifications for the tick mark labels
  ticks$grobs[[2]] <- hinvert_title_grob(ticks$grobs[[2]])
  
  # Fifth, put ticks back into yaxis
  yaxis$children[[2]] <- ticks
  
  # Put the transformed yaxis on the right side of g1
  g1 <- gtable_add_cols(g1, g2$widths[g2$layout[index, ]$l], pp$r)
  overlay.bacteria <- gtable_add_grob(g1, yaxis, pp$t, pp$r + 1, pp$b, pp$r + 1, clip = "off", name = "axis-r")
  
  # Draw it
  grid.newpage()
  png('../images/Dashboard_Trends/BacteriaPercentDetectionWithOverlayTrend.png', height=800, width=1400)
  grid.draw(overlay.bacteria)
  dev.off()
}

# map of connected sites
map.sites.df <- merge(unique(runs.df[,c('CustomerSiteId','StateAbv')]), regions.df[,c('State','StateAbv','CensusRegionLocal')], by='StateAbv')
map.sites.df$region <- tolower(map.sites.df$State)
map.sites.df$Record <- 1
map.sites.df <- merge(map.sites.df, with(map.sites.df, aggregate(Record~CensusRegionLocal, FUN=sum)), by='CensusRegionLocal')[,c('CensusRegionLocal','region','Record.y')]
us <- map_data('state')
map.sites.us <- merge(us, map.sites.df, by='region', all.x=TRUE)
map.sites.us[is.na(map.sites.us$Record.y), 'Record.y'] <- 0
map.sites.us$Color <- with(map.sites.us, ifelse(Record.y == 0, 'No Data', ifelse(Record.y < 5, 'Less than 5', ifelse(Record.y < 10, 'Less than 10', 'More than 10'))))
map.pal <- c('honeydew4','paleturquoise','turquoise3','turquoise4')
names(map.pal) <- c('No Data', 'Less than 5', 'Less than 10', 'More than 10')
p.site.map <- ggplot(map.sites.us) + geom_map(map=us, aes(x=long, y=lat, map_id=region), fill='white', color='white', size=0.5) + geom_map(data=map.sites.us, map=us, aes(fill=Color, map_id=region), color='white', size=0.5) + scale_fill_manual(values=map.pal, name='Site Count') + theme(panel.border=element_blank(), panel.background=element_blank(), axis.ticks=element_blank(), axis.text=element_blank(), text=element_text(size=22, face='bold')) + labs(title='Map of FilmArray Trend Participating Sites', x='',y='')

# trend of number of users accessing the site by month and user type... TBD
# client.id <- "234454757476-28em153g8egihh2p0a7usq674uvcv9h5.apps.googleusercontent.com"
# client.secret <- "T4Wa0o8z0qra9hpIwKB-rErc"
# token <- Auth(client.id, client.secret)
# save(token, file='./token_file')
# query.list <- Init(start.date = '2016-01-01',
#                    end.date = as.character(Sys.Date()),
#                    dimensions = 'ga:sourceMedium',
#                    metrics = 'ga:sessions, ga:transactions',
#                    max.results=10000,
#                    sort='-ga:transactions',
#                    table.id = 'ga:123456')
# ga.query <- QueryBuilder(query.list)
# ga.data <- GetReportData(ga.query, token)

# make images for the Web Hub
setwd(imgDir)
plots <- ls()[grep('^p\\.', ls())]
for(i in 1:length(plots)) {
  
  imgName <- paste(substring(plots[i],3),'.png',sep='')
  
  png(file=imgName, width=1200, height=800, units='px')
  print(eval(parse(text = plots[i])))
  makeTimeStamp(timeStamp = Sys.time(), author='Data Science')
  dev.off()
}

# Make pdf report for the web hub
setwd(pdfDir)
pdf("Trends.pdf", width = 11, height = 8)
for(i in 1:length(plots)) {
  
  print(eval(parse(text = plots[i])))
}
dev.off()

rm(list=ls())
# setwd('G:/Departments/PostMarket/DataScienceGroup/Data Science Products/InProcess/Amber/20160321_ExectuiveLevelReportingPlatform/ELRapp')
#
# # load the libraries needed for the analyses
# library(RODBC)
# library(ggmap)
# library(maps)
# library(leaflet)
# library(colorRamps)
# library(rgeos)
# library(ggplot2)
# library(rgdal)
# library(maptools)
# library(zoo)
# library(scales)
# library(lubridate)
# library(RColorBrewer)

setwd('~/WebHub/AnalyticsWebHub/ELRapp/')

# load the data
db <- odbcConnect("PMS_PROD")
queryVector <- scan('SQL/ComplaintsByGeoLocation.txt',what=character(),quote="")
query <- paste(queryVector,collapse=" ")
complaints.df <- sqlQuery(db,query)
queryVector <- scan('SQL/GeoCustomers.txt',what=character(),quote="")
query <- paste(queryVector,collapse=" ")
customers.geo <- sqlQuery(db,query)
queryVector <- scan('SQL/Calendar.txt',what=character(),quote="")
query <- paste(queryVector,collapse=" ")
calendar.df <- sqlQuery(db,query)
queryVector <- scan('SQL/salesOverview.txt',what=character(),quote="")
query <- paste(queryVector,collapse=" ")
sales.df <- sqlQuery(db,query)
queryVector <- scan('SQL/pouchShipments_summary.txt',what=character(),quote="")
query <- paste(queryVector,collapse=" ")
ship.summary.df <- sqlQuery(db,query)
query.charVec = scan("SQL/R_CC_CustPouchesShippedDetailed.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
pouches.df = sqlQuery(db,query)
query.charVec = scan("SQL/R_CC_HighLevelFailures.txt", what=character(),quote="")
query = paste(query.charVec,collapse=" ")
failures.df = sqlQuery(db,query)
query.charVec <- scan('SQL/R_IRMA_HoursAtFailures.txt',what=character(),quote="")
query <- paste(query.charVec,collapse=" ")
hours.df <- sqlQuery(db,query)
queryText <- scan("SQL/O_IMAN_InstShipments.txt",what=character(),quote="")
query <- paste(queryText,collapse=" ")
shipments.inst <- sqlQuery(db,query)
odbcClose(db)
FADWcxn <- odbcConnect(dsn = 'FA_DW', uid = 'lmeyers', pwd = 'Idaho1Tech')
queryVector <- scan('SQL/calendarDates.txt',what=character(),quote="")
query <- paste(queryVector,collapse=" ")
bugCal.df <- sqlQuery(FADWcxn,query)
queryVector <- scan('SQL/rpRuns.txt',what=character(),quote="")
query <- paste(queryVector,collapse=" ")
runs.df <- sqlQuery(FADWcxn,query)
queryVector <- scan('SQL/bugs.txt',what=character(),quote="")
query <- paste(queryVector,collapse=" ")
bugs.df <- sqlQuery(FADWcxn,query)
odbcClose(FADWcxn)

source('Rfunctions/makeDateGroupAndFillGaps.R')
source('Rfunctions/dataForHighLevelCharts.R')
source('Rfunctions/markForReview.R')
source('Rfunctions/findStartDate.R')
source('Rfunctions/computeRollingRateAndAddStats.R')
source('Rfunctions/findStartDateinMonths.r')
source('Rfunctions/formatForBugBarsWithOverlay.R')
source('Rfunctions/makeEvenWeeks.R')
source('Rfunctions/normalizeRunsAndOverlay.R')
source('Rfunctions/reformatBugsForAnova.R')
source('Rfunctions/integrateToFindSeason.R')

#update lng and lat for NY and oR- these are incorrect in table
customers.geo$lon[customers.geo$Region == 'NY'] <- -74.958868
customers.geo$lat[customers.geo$Region == 'NY'] <- 42.963548
customers.geo$lon[customers.geo$Region == 'OR'] <- -120.705938
customers.geo$lat[customers.geo$Region == 'OR'] <- 44.260043


#Read in shape file
states.shp <- readShapeSpatial("shapeFile/cb_2015_us_state_20m.shp")
#----------------------------------------------Complaints map-------------------------------------------------------------------------------------
# for maps, a latitude and longitude must be added for each location in order for it to work with the map layout
# so make sure that all customers have a matching longitude and latitude in customers.geo
existingRegions <- as.character(customers.geo[,'Region'])
us <- as.character(unique(complaints.df[complaints.df[,'Country']=='USA', 'Region']))[!(as.character(unique(complaints.df[complaints.df[,'Country']=='USA', 'Region'])) %in% existingRegions)]
# if(length(us) > 0) {
#   state.usa <- paste(us, 'USA', sep=', ')
# }
ous <- as.character(unique(complaints.df[complaints.df[,'Region']=='Int', 'Country']))[!(as.character(unique(complaints.df[complaints.df[,'Region']=='Int', 'Country'])) %in% existingRegions)]
missingRegions <- c(us, ous)
# if there are missing regions, use the ggmap library to query goolge and get the coordinates for the missing regions
if(length(missingRegions) > 0) {

  missingCoords <- geocode(missingRegions)
  geoLocations <- data.frame(Region = missingRegions, lon = missingCoords$lon, lat = missingCoords$lat)

  # add these looked up coordinates to the SQL database so that the look up can be avoided in the future
  # db <- odbcConnect("PMS_PROD")
  # sqlSave(db, geoLocations, tablename = 'tGeoCustomers', append = TRUE, rownames = FALSE)
  # odbcClose(db)

  #append these new locations to the customers.geo dataframe
  customers.geo <- rbind(customers.geo, geoLocations)
}

# give a new merge by column to complaints.df
complaints.df$Region <- ifelse(as.character(complaints.df$Country)=='USA', as.character(complaints.df$Region), as.character(complaints.df$Country))
complaints.map <- merge(complaints.df, customers.geo, by='Region')
complaints.us <- complaints.map[complaints.map[,'Country']=='USA', ]
complaints.us$Count <- 1
colnames(complaints.us)[grep('^lon', colnames(complaints.us))] <- 'lng'
regionLink <- data.frame(StateAbb = state.abb, StateName = state.name)
dc <- data.frame(StateAbb = 'DC', StateName = 'District of Columbia')
regionLink <- merge(regionLink, dc, by=c('StateAbb', 'StateName'), all=TRUE)
complaints.us <- merge(complaints.us, regionLink, by.x='Region', by.y='StateAbb')

#group territorties
for (i in 1:length(complaints.us$Territory)) {
  if (grepl('NE', as.character(complaints.us$Territory[i]))) {
    complaints.us$TerritoryGroup[i] <- "North East"
  } else if (grepl('SE', as.character(complaints.us$Territory[i]))) {
    complaints.us$TerritoryGroup[i] <- 'South East'
  } else if (grepl('W', as.character(complaints.us$Territory[i]))) {
    complaints.us$TerritoryGroup[i] <- 'West'
  } else if (grepl('GL', as.character(complaints.us$Territory[i]))) {
    complaints.us$TerritoryGroup[i] <- 'Great Lakes'
  } else if (grepl('C', as.character(complaints.us$Territory[i]))) {
    complaints.us$TerritoryGroup[i] <- 'Central'
  } else if (grepl('Related', as.character(complaints.us$Territory[i]))) {
    complaints.us$TerritoryGroup[i] <- 'Other'
  } else {
    complaints.us$TerritoryGroup[i] <- as.character(complaints.us$Territory[i])
  }
}

#group Cust Types
for (i in 1:length(complaints.us$CustClass)) {
  if (grepl('CLIN 1-150', as.character(complaints.us$CustClass[i]))) {
    complaints.us$CustomerType[i] <- 'Small Clinical Hospital'
  } else if (grepl('CLIN 151-400', as.character(complaints.us$CustClass[i]))) {
    complaints.us$CustomerType[i] <- 'Medium Clinical Hospital'
  } else if (grepl('CLIN 400+', as.character(complaints.us$CustClass[i]))) {
    complaints.us$CustomerType[i] <- 'Large Clinical Hospital'
  } else if (grepl('CLINMilitary', as.character(complaints.us$CustClass[i]))) {
    complaints.us$CustomerType[i] <- 'Military'
  } else if (grepl('LBCLIN0-150', as.character(complaints.us$CustClass[i]))) {
    complaints.us$CustomerType[i] <- 'Laboratory'
  } else {
    complaints.us$CustomerType[i] <- 'Other'
  }
}

mapStates <- map("state", fill=TRUE, plot = FALSE, region = complaints.us[,'StateName'])

mapDenom <- with(sales.df, aggregate(QtyShipped~State+Product, FUN=sum))
mapDenom <- subset(mapDenom, Product != 'Service' & Product != 'Verification')

#---------------------------------Sales /Shipments Map-----------------------------------------------------------------------------------
existingRegions <- as.character(customers.geo[,'Region'])
sales.map <- subset(sales.df, as.Date(ShipDate) >= Sys.Date()-90)
sales.map <- subset(sales.map, select=c('Product','CustClass','State','SalesTerritoryID','TradeDiscAmt','SalesOrderExtAmt','ItemsShipped','QtyShipped'))
colnames(sales.map)[grep('State', colnames(sales.map))] <- 'Region'
# for maps, a latitude and longitude must be added for each location in order for it to work with the map layout
# so make sure that all customers have a matching longitude and latitude in customers.geo
missingRegions <- as.character(unique(sales.df$Region))[!as.character(unique(sales.df$Region)) %in% existingRegions]
# if there are missing regions, use the ggmap library to query goolge and get the coordinates for the missing regions
if(length(missingRegions) > 0) {

  missingCoords <- geocode(missingRegions)
  geoLocations <- data.frame(Region = missingRegions, lon = missingCoords$lon, lat = missingCoords$lat)

  # add these looked up coordinates to the SQL database so that the look up can be avoided in the future
  # db <- odbcConnect("PMS_PROD")
  # sqlSave(db, geoLocations, tablename = 'tGeoCustomers', append = TRUE, rownames = FALSE)
  # odbcClose(db)

  #append these new locations to the customers.geo dataframe
  customers.geo <- rbind(customers.geo, geoLocations)
}

sales.map <- merge(sales.map, customers.geo, by='Region')
colnames(sales.map)[grep('^lon', colnames(sales.map))] <- 'lng'
sales.map <- merge(sales.map, regionLink, by.x='Region', by.y='StateAbb')

#calculate revenue by SalesOrderExtAmt - TradeDiscAmt
sales.map$Revenue <- sales.map$SalesOrderExtAmt - sales.map$TradeDiscAmt

#group territorties
for (i in 1:length(sales.map$SalesTerritoryID)) {
  if (grepl('NE', as.character(sales.map$SalesTerritoryID[i]))) {
    sales.map$TerritoryGroup[i] <- "North East"
  } else if (grepl('SE', as.character(sales.map$SalesTerritoryID[i]))) {
    sales.map$TerritoryGroup[i] <- 'South East'
  } else if (grepl('W', as.character(sales.map$SalesTerritoryID[i]))) {
    sales.map$TerritoryGroup[i] <- 'West'
  } else if (grepl('GL', as.character(sales.map$SalesTerritoryID[i]))) {
    sales.map$TerritoryGroup[i] <- 'Great Lakes'
  } else if (grepl('C', as.character(sales.map$SalesTerritoryID[i]))) {
    sales.map$TerritoryGroup[i] <- 'Central'
  } else if (grepl('Related', as.character(sales.map$SalesTerritoryID[i]))) {
    sales.map$TerritoryGroup[i] <- 'Other'
  } else {
    sales.map$TerritoryGroup[i] <- as.character(sales.map$SalesTerritoryID[i])
  }
}

#group Cust Types
for (i in 1:length(sales.map$CustClass)) {
  if (grepl('CLIN 1-150', as.character(sales.map$CustClass[i]))) {
    sales.map$CustomerType[i] <- 'Small Clinical Hospital'
  } else if (grepl('CLIN 151-400', as.character(sales.map$CustClass[i]))) {
    sales.map$CustomerType[i] <- 'Medium Clinical Hospital'
  } else if (grepl('CLIN 400+', as.character(sales.map$CustClass[i]))) {
    sales.map$CustomerType[i] <- 'Large Clinical Hospital'
  } else if (grepl('CLINMilitary', as.character(sales.map$CustClass[i]))) {
    sales.map$CustomerType[i] <- 'Military'
  } else if (grepl('LBCLIN0-150', as.character(sales.map$CustClass[i]))) {
    sales.map$CustomerType[i] <- 'Laboratory'
  } else {
    sales.map$CustomerType[i] <- 'Other'
  }
}


#Prep data for functions
colnames(sales.map)[grep('Revenue', colnames(sales.map))] <- 'Qty'
colnames(sales.map)[grep('QtyShipped', colnames(sales.map))] <- 'Count'

#-------------------------------Product Usage by Site---------------------------------------------------------------------------------------
#-----------Chart
#Make Dategroup with Year-Quarter
prod.summ.df <- ship.summary.df[ship.summary.df$Year > 2013 & ship.summary.df$Panel != 'BT', ]
prod.summ.df$DateGroup <- paste(prod.summ.df$Year, prod.summ.df$Quarter, sep="-")

breaks <- as.character(unique(prod.summ.df$DateGroup))[order(as.character(unique(prod.summ.df$DateGroup)))]
panels <- as.character(unique(prod.summ.df$Panel))

out <- c()

for(i in 1:length(breaks)) {

  subTest <- prod.summ.df[as.character(prod.summ.df$DateGroup) == breaks[i], ]
  subTest$Record <- 1
  subTest <- unique(subTest[,c('DateGroup','CustName','Panel','Record')])
  subTest.agg <- with(subTest, aggregate(Record~CustName+Panel, FUN=sum))

  customers <- as.character(unique(subTest.agg$CustName))

  for(j in 1:length(customers)) {

    custName <- customers[j]
    subCust <- subTest.agg[subTest.agg$CustName == custName, ]
    productString <- sapply(1:length(subCust[,'Panel']), function(x) paste(subCust[x,'Panel']))
    productString <- paste(productString, collapse=', ')
    temp <- data.frame(DateGroup = breaks[i],
                       Customer = custName,
                       Code = productString,
                       Record = 1)
    out <- rbind(out, temp)
  }
}

out.agg <- with(out, aggregate(Record~DateGroup+Code, FUN=sum))

orderedCodes <- c('RP','BCID','GI','ME','BCID, RP','BCID, GI','BCID, ME','GI, RP','ME, RP','GI, ME','BCID, GI, RP','BCID, ME, RP','BCID, GI, ME','GI, ME, RP','BCID, GI, ME, RP')

#Reorder factors to make chart have 1 product, 2 products, 3 products, and then 4 products
out.agg$Code <- factor(out.agg$Code, levels = orderedCodes, ordered=TRUE)
out.agg <- out.agg[with(out.agg, order(Code)), ]

#------------------Sales/Shipment charts----------------------------------------------------------------------
sales.chart <- sales.df
sales.chart$Revenue <- sales.chart$SalesOrderExtAmt - sales.chart$TradeDiscAmt

orderedProducts <- c('FA1.5', 'FA1.5R','FA2.0R','FA2.0','RP','GI','BCID','ME')
#Reorder factors
sales.chart$Product <- factor(sales.chart$Product, levels = orderedProducts, ordered=TRUE)
sales.chart <- sales.chart[with(sales.chart, order(Product)), ]

#------------------ Product Reliability Trending -----------------------------------------------------
bigGroup <- 'Year'
smallGroup <- 'Week'
periods <- 4
lagPeriods <- 4
sdFactor <- 3
titleSize <- 18
fontSizeStandard <- 16
validateDate <- '2015-50'

# get a lag date after which data are not used to calculate historical average and standard deviation
lag <-calendar.df[length(calendar.df[,1])-lagPeriods, ]
lag <- with(lag, ifelse(lag[,smallGroup] < 10, paste(lag[,bigGroup], lag[,smallGroup], sep='-0'), paste(lag[,bigGroup], lag[,smallGroup], sep='-')))

# get a start date for thumbnails and paretos
startDate <- findStartDate(calendar.df, bigGroup, smallGroup, 'OneYear')

# Refill non-numeric values with NA
failures.df[,'Record'] <- as.numeric(as.character(failures.df[,'Record']))

# get the denominator for all high level charts (total pouches shipped)
pouches.all <- makeDateGroupAndFillGaps(calendar.df, pouches.df, bigGroup, smallGroup, 'Key', startDate)

# find discrete breaks for x-axis of moving average charts
dateBreaks <- as.character(unique(pouches.all[,'DateGroup']))[seq(1,length(as.character(unique(pouches.all[,'DateGroup']))),4)]

# All complaints per Pouches Shipped -----------------------------------------
complaints.all.mvgavg <- dataForHighLevelCharts(pouches.all, NULL, NULL, bigGroup, smallGroup, startDate, periods, lag, sdFactor)

# associated charts:
x.val <- which(as.character(unique(complaints.all.mvgavg[,'DateGroup']))==validateDate)

# this piece makes the chart:
p.allCmplt.mavg <- ggplot(complaints.all.mvgavg, aes(x=DateGroup, y=RollingRate, color=Color, group=Key)) + geom_line(color='black') + geom_point() + scale_color_manual(values=c('blue','red'), guide=FALSE) + geom_hline(aes(yintercept=Limits), color='red',lty='dashed') + scale_y_continuous(labels=percent) + labs(title='Customer Complaints per Pouches Shipped', x='Date', y='4 Week Rolling Average') + scale_x_discrete(breaks=dateBreaks) + theme(plot.title=element_text(size=titleSize), axis.text.x=element_text(angle=90, hjust=1,face='bold',color='black'), axis.text.y=element_text(hjust=1,face='bold',color='black'), text=element_text(size=fontSizeStandard)) + geom_vline(aes(xintercept=x.val),color='mediumseagreen')

#------------------ Instrument Reliability Trend -----------------------------------------------------
# add code to plot the cumulative average hours run between failures in the install base
hours.df[,'YearMonth'] <- with(hours.df, ifelse(Month < 10, paste(Year,'-0',Month,sep=''), paste(Year,'-',Month,sep='')))
yearMonths <- unique(hours.df[,c('YearMonth')])
yearMonths <- yearMonths[order(yearMonths)]

x <- seq(1,length(hours.df$MTBF),1)
y <- hours.df$MTBF
y <- y[order(y)]
fit <- lm(y~x)
hoursBad <- cbind(y, dfbetas(fit))
hoursBad <- hoursBad[abs(hoursBad[,'x']) > 1,'y']
failures.clean <- hours.df[!(hours.df$MTBF %in% hoursBad), ]

avgMTBF <- c()
for (i in 1:length(yearMonths)) {

  periodFail <- failures.clean[failures.clean[,'YearMonth'] <= yearMonths[i], ]
  periodMTBF <- data.frame(YearMonth = yearMonths[i], MTBF_cum=mean(periodFail$MTBF))
  avgMTBF <- rbind(avgMTBF, periodMTBF)
}

# make the chart... add bars with average hours by month under the line chart
qtrBreaks <- yearMonths[seq(1,i,3)]
barMTBF <- with(failures.clean, aggregate(MTBF~YearMonth, FUN=mean))

# make the chart
p <- ggplot(barMTBF, aes(x=YearMonth, y=MTBF)) + geom_bar(stat='identity', fill='dodgerblue') + geom_line(aes(x=YearMonth, y=MTBF_cum, group=1), color='blue', data = avgMTBF) + geom_point(aes(x=YearMonth, y=MTBF_cum), color='blue', data = avgMTBF)
p <- p + scale_x_discrete(breaks=qtrBreaks)
p <- p + theme(text=element_text(size=18, color='black'), plot.title=element_text(size=20), axis.text=element_text(color='black',size=16), axis.text.x=element_text(angle=90))
p.mtbf <- p + labs(title='Average Hours Run Between Failures:\nCummulative Field Population', x='Date', y='Average Hours Between Failures')

#------------------ Instrument Shipments Trend -----------------------------------------------------
bigGroup <- 'Year'
smallGroup <- 'Month'
# Find start date for Year-Month charts
startString.month <- ifelse(month(Sys.Date()) < 10,
                            paste(year(Sys.Date()-365),paste0('0',month(Sys.Date())), sep='-'),
                            paste(year(Sys.Date()-365), month(Sys.Date()), sep='-'))

shipSource.df <- subset(shipments.inst, Product %in% c('FA1.5','FA2.0','HTFA'), select=c('Product','SalesType','Year','Month','Record'))

# Fill in gaps
shipSource.df <- makeDateGroupAndFillGaps(calendar.df, shipSource.df, bigGroup, smallGroup, c('SalesType'), startString.month)

#Order factors
shipSource.df$SalesType <- factor(shipSource.df$SalesType, levels = c('Domestic Sale','International Sale','Trade-Up','EAP','Replacement','Loaner','Demo','Short Term Rental','Internal','Other'), ordered=TRUE)
shipSource.df<- shipSource.df[with(shipSource.df, order(SalesType)), ]

# Make Chart
ship.Source <- ggplot(shipSource.df, aes(x=DateGroup, y=Record, fill=SalesType)) + geom_bar(stat="identity", position="stack") +
  xlab('Date\n(Year-Month)') + ylab('Shipments') + theme(text=element_text(size=20, face='bold'),
  axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), axis.text.y=element_text(hjust=1, color='black', size=20)) +
  ggtitle('New Instrument Shipments by Sales Type\nFA 1.5, FA 2.0, and HTFA') + scale_fill_manual(values=brewer.pal(10,'Paired'), name='Sales Type') +
  scale_y_continuous(breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30))

#------------------ FilArray RP Field Trending -----------------------------------------------------
cdc.df <- read.csv('SQL/cdcRegionData.csv', header = TRUE, sep= ',')
cdc.df <- data.frame(Year = cdc.df[,'YEAR'], Week = cdc.df[,'WEEK'], Region = cdc.df[,'REGION'], iliTotal = cdc.df[,'ILITOTAL'], totalPatients = cdc.df[,'TOTAL.PATIENTS'])
keepSites <- c(2,5,7)
region.key <- data.frame(CustomerSiteId = c(5, 2, 7, 13, 9), Region = c('Region 2', 'Region 5', 'Region 4', 'Region 5', 'Region 5'))
keepRegions <- as.character(region.key[region.key[,'CustomerSiteId'] %in% keepSites, 'Region'])
cdc.df <- cdc.df[cdc.df[,'Region'] %in% keepRegions, ]
cdc.agg <- with(cdc.df, aggregate(cbind(iliTotal, totalPatients)~Year+Week, FUN=sum))
cdc.agg[,'iliRate'] <- with(cdc.agg, iliTotal/totalPatients)

bugCal.df <- makeEvenWeeks(bugCal.df)
runs.df <- merge(runs.df, bugCal.df, by = c('Date'))
nation.overlay <- normalizeRunsAndOverlay(runs.df[runs.df[,'CustomerSiteId'] %in% keepSites, ], bugCal.df, cdc.df, region.key, TRUE, TRUE)

bugs.df <- merge(bugs.df, runs.df[runs.df$CustomerSiteId %in% keepSites ,c('RunDataId','SiteName','Year','Week','YearWeek')], by=c('RunDataId'))
bugs.anova <- reformatBugsForAnova(runs.df, bugs.df, bugCal.df)
bug.names <- as.character(unique(bugs.df[,'Bug']))
colnames(bugs.anova)[colnames(bugs.anova) %in% bug.names] <- letters[1:length(bug.names)]
decoder <- data.frame(bugName = bug.names, bugId = letters[1:length(bug.names)])

ili.nat <- merge(cdc.agg[,c('Year','Week','iliRate')], nation.overlay[,c('YearWeek','Year','Week','NormRunRate')], by=c('Year','Week'))
# bugs.anova.nat <- with(bugs.anova[bugs.anova$CustomerSiteId %in% keepSites & bugs.anova$Year %in% c(2013, 2014, 2015), ], aggregate(cbind(Runs, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u)~YearWeek, FUN=sum))
bugs.anova.nat <- with(bugs.anova[bugs.anova$CustomerSiteId %in% keepSites & bugs.anova$Year %in% c(2013, 2014, 2015, 2016), ], aggregate(cbind(Runs, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u)~YearWeek, FUN=sum))
master.nat <- merge(ili.nat, bugs.anova.nat, by=c('YearWeek'), all.y=TRUE)
colnames(master.nat)[grep('iliRate', colnames(master.nat))] <- 'NormRuns' # IT IS VERY IMPORTANT TO NOTE THAT THE NormRuns COLUMN IS ACTUALLY ILI RATE!!!!

cols <- letters[1:21]
cols <- c('Runs',cols)
bugs.anova.nat <- with(bugs.anova[bugs.anova$CustomerSiteId %in% keepSites & bugs.anova$Year %in% c(2013, 2014, 2015, 2016), ], aggregate(cbind(Runs, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u)~YearWeek, FUN=sum))
master.nat <- merge(ili.nat, bugs.anova.nat, by=c('YearWeek'), all.y=TRUE)
master.nat <- master.nat[with(master.nat, order(as.character(YearWeek))), ]
master.nat.roll <- master.nat[,!(colnames(master.nat) %in% cols)]
master.nat.roll <- master.nat.roll[with(master.nat.roll, order(as.character(YearWeek))), ]
# master.nat.adj <- c()
for(i in 1:length(cols)) {

  # print(cols[i])
  # print(as.character(decoder[decoder$bugId == cols[i], 'bugName']))
  roll <- sapply(2:(length(master.nat[,cols[i]])-1), function(x) sum(master.nat[(x-1):(x+1),cols[i]]))
  roll <- c(roll[1], roll, roll[length(roll)])
  master.nat.roll <- cbind(master.nat.roll, roll)
  colnames(master.nat.roll)[grep('roll', colnames(master.nat.roll))] <- cols[i]
}
master.nat.roll[,7:27] <- master.nat.roll[,7:27]/master.nat.roll$Runs
colnames(master.nat.roll)[grep('iliRate', colnames(master.nat.roll))] <- 'NormRuns'
bug.overlay <- formatForBugBarsWithOverlay(master.nat.roll, decoder)
bug.overlay$YearWeek <- factor(bug.overlay$YearWeek, levels = bug.overlay[with(bug.overlay, order(as.character(YearWeek))),'YearWeek'])

dateBreaks <- as.character(unique(bug.overlay$YearWeek))
noRhino <- c('Human Rhinovirus/Enterovirus')
pneumons <- bug.names[grep('pneumoniae', bug.names)]
bacteria <- c(pneumons, 'Bordetella pertussis')
justVirus <- c('Human Rhinovirus/Enterovirus', bacteria, 'Influenza A', 'Influenza A (no subtype detected)')
justVirus <- bug.names[!(bug.names %in% justVirus)]
justVirus <- justVirus[order(justVirus)]
myPal <- colorRampPalette(c('red','blue','orange','green','grey','yellow','purple','cyan','magenta','chocolate3','mediumseagreen','pink','dodgerblue','gold','darkgreen','violet','lightskyblue'))(15)
names(myPal) <- factor(justVirus, levels = justVirus[order(justVirus)])
# this makes the chart
p.area.justvirus <- ggplot(subset(bug.overlay, Key %in% justVirus), aes(YearWeek)) + geom_area(aes(y=Positivity, fill=Key, group=Key, order=Key), stat='identity', position='stack') + geom_line(aes(x=YearWeek, y=10*iliRate, group=1), data=bug.overlay, color='black', size=1.25) + scale_x_discrete(breaks = as.character(unique(bug.overlay$YearWeek))[seq(1, length(as.character(unique(bug.overlay$YearWeek))),8)]) + theme(text=element_text(size=20, color='black', face='bold'), axis.text.x=element_text(angle=90), axis.text=element_text(color='black', face='bold')) + labs(title='RP Virus Prevalence (no HRV/Entero) overlaid with CDC ILI Rate', x='Year-Week', y='RP Prevalence, ILI Cases per 10 Patients') + scale_fill_manual(values=myPal, name='')

# ----------------------------------------------------------------------------
# clear out the workspace other than what is needed for the app
rm(list = ls()[!(ls() %in% c("mapStates","complaints.us","sales.map","sales.chart","out.agg","states.shp","calendar.df","mapDenom","p.mtbf","ship.Source",
                             "p.area.justvirus","p.allCmplt.mavg","justVirus","bug.overlay","myPal","shipSource.df",
                             "complaints.all.mvgavg","x.val","dateBreaks","titleSize","fontSizeStandard","barMTBF","avgMTBF","qtrBreaks"))])


# # merge the geographic coordinates onto the complaints.df so that a map can be made in the app... for now, limit to USA
# complaints.us <- complaints.map[complaints.map[,'Country']=='USA', ]
#
# # use leaflet to make some charts... leaflet function will take a data frame, but wants longitude to look like 'lng'
# colnames(complaints.us)[grep('lon', colnames(complaints.us))] <- 'lng'
# # try using just rp product first
# rp.us <- complaints.us[complaints.us[,'Product']=='RP', ]
# rp.us.agg <- with(rp.us, aggregate(Qty~Region+lng+lat, FUN=sum))
# qty.max <- with(rp.us.agg, max(Qty))
# rp.us.agg[,'radius'] <- rp.us.agg[,'Qty']/qty.max * 20
# regionLink <- data.frame(StateAbb = state.abb, StateName = state.name)
# rp.us.agg <- merge(rp.us.agg, regionLink, by.x='Region', by.y='StateAbb')
#
# # http://www.r-bloggers.com/interactive-mapping-with-leaflet-in-r/
# mapStates <- map("state", fill=TRUE, plot = FALSE, region = rp.us.agg$StateName)
# lng1 <- rp.us.agg[rp.us.agg$StateName=='California','lng']
# lat1 <- rp.us.agg[rp.us.agg$StateName=='Washington','lat']
# lng2 <- max(rp.us.agg$lng)
# lat2 <- rp.us.agg[rp.us.agg$StateName=='Florida','lat']
# leaflet(mapStates) %>% addTiles() %>%
#   addPolygons(fillColor=gray(0.25, alpha = NULL), stroke = FALSE) %>%
#   addCircleMarkers(radius=~radius, color='red', stroke =FALSE, fillOpacity = 1, data = rp.us.agg, popup = paste(rp.us.agg$StateName,": ",rp.us.agg$Qty," complaints\n(last 90 days)",sep='')) %>%
#   fitBounds(lng1, lat1, lng2, lat2)

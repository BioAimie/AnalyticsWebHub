workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <-  '~/WebHub/images/Dashboard_GoLiveToThrive/'
pdfDir <- '~/WebHub/pdfs/'

setwd(workDir)

# Load needed libraries
library(ggplot2)
library(dateManip)
library(scales)

# load the data from SQL
source('Portfolios/S_LIVE_load.R')

source('Rfunctions/createPaletteOfVariableLength.R')
source('Rfunctions/makeTimeStamp.R')

calendar.month <- createCalendarLikeMicrosoft(2014,'Month')
calendar.quarter <- createCalendarLikeMicrosoft(2014, 'Quarter')
start <- findStartDate(calendar.month, 'Month', 12,0, keepPeriods=0)
start.quarter <- findStartDate(calendar.quarter, 'Quarter', 5, keepPeriods=0)

theme_set(theme_gray() + theme(plot.title = element_text(hjust = 0.5)))

#limit scope of data to 1 year              
recentCust <- subset(firsts.df, as.Date(InstrumentSale) >= Sys.Date()-365)

#Find time between each step
#Instrument Sale to Instrument Ship
recentCust$deltaSaleToShip <- difftime(as.Date(recentCust$InstrumentShip), as.Date(recentCust$InstrumentSale), units='days')
recentCust$deltaSaleToShip <- ifelse(recentCust$deltaSaleToShip < 0, NA, recentCust$deltaSaleToShip)
#Instrument Ship to Verification
recentCust$deltaShipToVer <- difftime(as.Date(recentCust$Verification), as.Date(recentCust$InstrumentShip), units='days')
recentCust$deltaShipToVer <- ifelse(recentCust$deltaShipToVer < 0, NA, recentCust$deltaShipToVer)
#Instrument to Pouch
recentCust$deltaShipToPch <- difftime(as.Date(recentCust$Pouch), as.Date(recentCust$InstrumentShip), units='days')
recentCust$deltaShipToPch <- ifelse(recentCust$deltaShipToPch < 0, NA, recentCust$deltaShipToPch)
#Verification to Pouch
recentCust$deltaVerToPch <- difftime(as.Date(recentCust$Pouch), as.Date(recentCust$Verification), units='days')
recentCust$deltaVerToPch <- ifelse(recentCust$deltaVerToPch < 0, NA, recentCust$deltaVerToPch)
#Sale to Verification
recentCust$deltaSaleToVer <- difftime(as.Date(recentCust$Verification), as.Date(recentCust$InstrumentSale), units='days')
recentCust$deltaSaleToVer <- ifelse(recentCust$deltaSaleToVer < 0, NA, recentCust$deltaSaleToVer)
#Sale to Pouch
recentCust$deltaSaleToPch <- difftime(as.Date(recentCust$Pouch), as.Date(recentCust$InstrumentSale), units='days')
recentCust$deltaSaleToPch <- ifelse(recentCust$deltaSaleToPch < 0, NA, recentCust$deltaSaleToPch)
#Sale to 3rdPouch
recentCust$deltaSaleTo3Pch <- difftime(as.Date(recentCust$ThirdPouch), as.Date(recentCust$InstrumentSale), units='days')
recentCust$deltaSaleTo3Pch <- ifelse(recentCust$deltaSaleTo3Pch < 0, NA, recentCust$deltaSaleTo3Pch)

#dateGroup
recentCust$InstrumentSale <- as.Date(recentCust$InstrumentSale)
recentCust.mon <- merge(recentCust, calendar.month, by.x='InstrumentSale', by.y = 'Date')
recentCust.mon$Record <- 1

#get average for each month - all data
months <- as.character(unique(recentCust.mon$DateGroup))
AvgDeltas <- c()
for(i in 1:length(months)) {
  temp <- subset(recentCust.mon, DateGroup == months[i])
  AvgSaleToShip <- sum(as.numeric(temp$deltaSaleToShip), na.rm=TRUE) / length(temp$deltaSaleToShip[!is.na(temp$deltaSaleToShip)])
  AvgVerToPch <- sum(as.numeric(temp$deltaVerToPch), na.rm=TRUE) / length(temp$deltaVerToPch[!is.na(temp$deltaVerToPch)])
  AvgSaleToPch <- sum(as.numeric(temp$deltaSaleToPch), na.rm=TRUE) / length(temp$deltaSaleToPch[!is.na(temp$deltaSaleToPch)])
  AvgSaleTo3Pch <- sum(as.numeric(temp$deltaSaleTo3Pch), na.rm=TRUE) / length(temp$deltaSaleTo3Pch[!is.na(temp$deltaSaleTo3Pch)])
  #add to dataframe
  temp2 <- data.frame(
    DateGroup = months[i],
    AvgSaleToShip=AvgSaleToShip,
    AvgSaleToPch=AvgSaleToPch,
    AvgSaleTo3Pch=AvgSaleTo3Pch,
    AvgVerToPch=AvgVerToPch)
  AvgDeltas <- rbind(AvgDeltas, temp2)
}

# get average by region per month
regions <- as.character(unique(recentCust.mon$SalesRegion))
Regions.avg <- c()
for(i in 1:length(months)) {
  temp <- subset(recentCust.mon, DateGroup == months[i])
  for(j in 1:length(regions)) {
    temp2 <- subset(temp, as.character(SalesRegion) == regions[j])
    if(nrow(temp2) > 0) {
      AvgSaleToShip <- ifelse(length(temp2$deltaSaleToShip[!is.na(temp2$deltaSaleToShip)]) > 0, sum(as.numeric(temp2$deltaSaleToShip), na.rm=TRUE) / length(temp2$deltaSaleToShip[!is.na(temp2$deltaSaleToShip)]), NA)
      AvgVerToPch <- ifelse(length(temp2$deltaVerToPch[!is.na(temp2$deltaVerToPch)]) > 0, sum(as.numeric(temp2$deltaVerToPch), na.rm=TRUE) / length(temp2$deltaVerToPch[!is.na(temp2$deltaVerToPch)]), NA)
      AvgSaleToPch <- ifelse(length(temp2$deltaSaleToPch[!is.na(temp2$deltaSaleToPch)]) > 0, sum(as.numeric(temp2$deltaSaleToPch), na.rm=TRUE) / length(temp2$deltaSaleToPch[!is.na(temp2$deltaSaleToPch)]), NA)
      AvgSaleTo3Pch <- ifelse(length(temp2$deltaSaleTo3Pch[!is.na(temp2$deltaSaleTo3Pch)]) > 0, sum(as.numeric(temp2$deltaSaleTo3Pch), na.rm=TRUE) / length(temp2$deltaSaleTo3Pch[!is.na(temp2$deltaSaleTo3Pch)]), NA)
    } else {
      AvgSaleToShip <- NA
      AvgVerToPch <- NA
      AvgSaleToPch <- NA
      AvgSaleTo3Pch <- NA
    }
    #add to dataframe
    temp3 <- data.frame(
      DateGroup = months[i],
      SalesRegion = regions[j],
      AvgSaleToShip=AvgSaleToShip,
      AvgSaleToPch=AvgSaleToPch,
      AvgSaleTo3Pch=AvgSaleTo3Pch,
      AvgVerToPch=AvgVerToPch)
    Regions.avg <- rbind(Regions.avg, temp3)
  }
}

Region.pal <- createPaletteOfVariableLength(Regions.avg, 'SalesRegion')

# get average by territory per quarter
recentCust.qt <- merge(recentCust, calendar.quarter, by.x='InstrumentSale', by.y = 'Date')
recentCust.qt$Record <- 1
quarters <- as.character(unique(recentCust.qt$DateGroup))
territories <- as.character(unique(recentCust.mon$SalesTerritoryID))
Territories.qt.avg <- c()
for(i in 1:length(quarters)) {
  temp <- subset(recentCust.qt, DateGroup == quarters[i])
  for(j in 1:length(territories)) {
    temp2 <- subset(temp, as.character(SalesTerritoryID) == territories[j])
    if(nrow(temp2) > 0) {
      AvgVerToPch <- ifelse(length(temp2$deltaVerToPch[!is.na(temp2$deltaVerToPch)]) > 0, sum(as.numeric(temp2$deltaVerToPch), na.rm=TRUE) / length(temp2$deltaVerToPch[!is.na(temp2$deltaVerToPch)]), NA)
      AvgSaleToPch <- ifelse(length(temp2$deltaSaleToPch[!is.na(temp2$deltaSaleToPch)]) > 0, sum(as.numeric(temp2$deltaSaleToPch), na.rm=TRUE) / length(temp2$deltaSaleToPch[!is.na(temp2$deltaSaleToPch)]), NA)
      AvgSaleTo3Pch <- ifelse(length(temp2$deltaSaleTo3Pch[!is.na(temp2$deltaSaleTo3Pch)]) > 0, sum(as.numeric(temp2$deltaSaleTo3Pch), na.rm=TRUE) / length(temp2$deltaSaleTo3Pch[!is.na(temp2$deltaSaleTo3Pch)]), NA)
    } else {
      AvgVerToPch <- NA
      AvgSaleToPch <- NA
      AvgSaleTo3Pch <- NA
    }
    #add to dataframe
    temp3 <- data.frame(
      DateGroup = quarters[i],
      SalesTerritory = territories[j],
      AvgSaleToPch=AvgSaleToPch,
      AvgSaleTo3Pch=AvgSaleTo3Pch,
      AvgVerToPch=AvgVerToPch)
    Territories.qt.avg <- rbind(Territories.qt.avg, temp3)
  }
}
Territories.qt.avg$SalesTerritory <- factor(Territories.qt.avg$SalesTerritory, levels = sort(unique(as.character(Territories.qt.avg$SalesTerritory))), ordered=TRUE)
Territories.qt.avg <- Territories.qt.avg[with(Territories.qt.avg, order(SalesTerritory)),]
# Terr.pal <- c('#051461','#071d88','#0925ae','#0c31e9','#3d5cf5','#778df8',
#               '#1b371b','#285328','#356e35','#499749','#68b668','#91ca91',
#               '#440d0d','#661414','#881b1b','#bb2525','#da4444','#e47777',
#               '#ae0a9a','#d40cbd','#f32dbd','#f551e2','#f778e8','#f99fef',
#               '#4e0887','#640aae','#7a0cd4','#8f18f2','#a23ef4','#be78f7')
Terr.pal <- createPaletteOfVariableLength(Territories.qt.avg, 'SalesTerritory')
# Territories.qt.avg <- merge(Territories.qt.avg, SalesManagers, by.x='SalesTerritory', by.y='Territory')
# Territories.qt.avg$TerrManager <- paste(Territories.qt.avg$SalesTerritory, Territories.qt.avg$SalesManager, sep='-')

# get average by territory over the last year
Territories.year.avg <- c()
for(i in 1:length(territories)) {
  temp2 <- subset(recentCust.mon, as.character(SalesTerritoryID) == territories[i])
  if(nrow(temp2) > 0) {
    AvgVerToPch <- ifelse(length(temp2$deltaVerToPch[!is.na(temp2$deltaVerToPch)]) > 0, round(sum(as.numeric(temp2$deltaVerToPch), na.rm=TRUE) / length(temp2$deltaVerToPch[!is.na(temp2$deltaVerToPch)])), NA)
    AvgSaleToPch <- ifelse(length(temp2$deltaSaleToPch[!is.na(temp2$deltaSaleToPch)]) > 0, round(sum(as.numeric(temp2$deltaSaleToPch), na.rm=TRUE) / length(temp2$deltaSaleToPch[!is.na(temp2$deltaSaleToPch)])), NA)
    AvgSaleTo3Pch <- ifelse(length(temp2$deltaSaleTo3Pch[!is.na(temp2$deltaSaleTo3Pch)]) > 0, round(sum(as.numeric(temp2$deltaSaleTo3Pch), na.rm=TRUE) / length(temp2$deltaSaleTo3Pch[!is.na(temp2$deltaSaleTo3Pch)])), NA)
  } else {
    AvgVerToPch <- NA
    AvgSaleToPch <- NA
    AvgSaleTo3Pch <- NA
  }
  #add to dataframe
  temp3 <- data.frame(
    SalesTerritory = territories[i],
    AvgSaleToPch=AvgSaleToPch,
    AvgSaleTo3Pch=AvgSaleTo3Pch,
    AvgVerToPch=AvgVerToPch)
  Territories.year.avg <- rbind(Territories.year.avg, temp3)
}
Territories.year.avg$SaleToPch <- ifelse(is.na(Territories.year.avg$AvgSaleToPch), 0, Territories.year.avg$AvgSaleToPch)
Territories.year.avg$SaleTo3Pch <- ifelse(is.na(Territories.year.avg$AvgSaleTo3Pch), 0, Territories.year.avg$AvgSaleTo3Pch)
Territories.year.avg$VerToPch <- ifelse(is.na(Territories.year.avg$AvgVerToPch), 0, Territories.year.avg$AvgVerToPch)
Territories.year.avg$SalesTerritory <- factor(Territories.year.avg$SalesTerritory, levels = sort(unique(as.character(Territories.year.avg$SalesTerritory))), ordered=TRUE)
Territories.year.avg <- Territories.year.avg[with(Territories.year.avg, order(SalesTerritory)),]
# Territories.year.avg <- merge(Territories.year.avg, SalesManagers, by.x='SalesTerritory', by.y='Territory')
# Territories.year.avg$TerrManager <- paste(Territories.year.avg$SalesTerritory, Territories.year.avg$SalesManager, sep='-')

# get average by customer type per month
types <- as.character(unique(recentCust.mon$CustomerType))
CustType.avg <- c()
for(i in 1:length(months)) {
  temp <- subset(recentCust.mon, DateGroup == months[i])
  for(j in 1:length(types)) {
    temp2 <- subset(temp, as.character(CustomerType) == types[j])
    if(nrow(temp2) > 0) {
      AvgVerToPch <- ifelse(length(temp2$deltaVerToPch[!is.na(temp2$deltaVerToPch)]) > 0, sum(as.numeric(temp2$deltaVerToPch), na.rm=TRUE) / length(temp2$deltaVerToPch[!is.na(temp2$deltaVerToPch)]), NA)
      AvgSaleToPch <- ifelse(length(temp2$deltaSaleToPch[!is.na(temp2$deltaSaleToPch)]) > 0, sum(as.numeric(temp2$deltaSaleToPch), na.rm=TRUE) / length(temp2$deltaSaleToPch[!is.na(temp2$deltaSaleToPch)]), NA)
      AvgSaleTo3Pch <- ifelse(length(temp2$deltaSaleTo3Pch[!is.na(temp2$deltaSaleTo3Pch)]) > 0, sum(as.numeric(temp2$deltaSaleTo3Pch), na.rm=TRUE) / length(temp2$deltaSaleTo3Pch[!is.na(temp2$deltaSaleTo3Pch)]), NA)
    } else {
      AvgVerToPch <- NA
      AvgSaleToPch <- NA
      AvgSaleTo3Pch <- NA
    }
    #add to dataframe
    temp3 <- data.frame(
      DateGroup = months[i],
      CustomerType = types[j],
      AvgSaleToPch=AvgSaleToPch,
      AvgSaleTo3Pch=AvgSaleTo3Pch,
      AvgVerToPch=AvgVerToPch)
    CustType.avg <- rbind(CustType.avg, temp3)
  }
}

Type.pal <- createPaletteOfVariableLength(CustType.avg, 'CustomerType')

#Data point counts
data.count <- c()
for(i in 1:length(months)) {
  temp <- subset(recentCust.mon, as.character(DateGroup) == months[i])
  #AvgSaleToShip - Instruments Sold and Shipped to New Customers
  SaleToShip <- length(temp$deltaSaleToShip[!is.na(temp$deltaSaleToShip)])
  #AvgSaleToPch - First Pouch purchases by New Customers
  SaleToPch <- length(temp$deltaSaleToPch[!is.na(temp$deltaSaleToPch)])
  #AvgSaleTo3Pch - Third Pouch purchases by New Customers
  SaleTo3Pch <- length(temp$deltaSaleTo3Pch[!is.na(temp$deltaSaleTo3Pch)])
  #AvgVerToPch - New Customers who purchased a Verification Kit and subsequent Pouches
  VerToPch <- length(temp$deltaVerToPch[!is.na(temp$deltaVerToPch)])
  temp2 <- data.frame(
    DateGroup = months[i], 
    SaleToShip = SaleToShip,
    SaleToPch = SaleToPch,
    SaleTo3Pch = SaleTo3Pch,
    VerToPch = VerToPch
  )
  data.count <- rbind(data.count, temp2)
}

# Average Sale to Ship----------------------------------------------------------------------------------------------------

# ---aggregated graph

p.AvgSaleToShip <- ggplot(AvgDeltas, aes(x=DateGroup, y=AvgSaleToShip, group=1)) + geom_point() + geom_line() + 
  geom_point(data=recentCust.mon, aes(x=DateGroup, y=deltaSaleToShip), inherit.aes=FALSE, color = 'steelblue2') +
  xlab('Date of Instrument Sale\n(Year-Month)') + ylab('Delta Days') + scale_y_continuous(breaks=pretty_breaks(n=10)) +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Instrument Sale and Instrument Shipment\n*Count of Data Points at the Top') +
  annotate('text', x=data.count$DateGroup, y=max(recentCust.mon$deltaSaleToShip, na.rm=TRUE) + 1, label=data.count$SaleToShip, fontface='bold')

# ---By region (faceted)
p.AvgSaleToShip.Region <- ggplot(Regions.avg, aes(x=DateGroup, y=AvgSaleToShip, group=SalesRegion)) + geom_point() + geom_line() + 
  facet_wrap(~SalesRegion, scale='free_y') + xlab('Date of Instrument Sale\n(Year-Month)') + ylab('Delta Days') +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Instrument Sale and Instrument Shipment\nBy Sales Region')

# Average Sale To 1st Pouch ------------------------------------------------------------------------------------------

# ---aggregated graph

p.AvgSaleToPouch <- ggplot(AvgDeltas, aes(x=DateGroup, y=AvgSaleToPch, group=1)) + geom_point() + geom_line() + 
  geom_point(data=recentCust.mon, aes(x=DateGroup, y=deltaSaleToPch), inherit.aes=FALSE, colour='steelblue2') +
  scale_y_continuous(breaks=pretty_breaks(n=20)) + xlab('Date of Instrument Sale\n(Year-Month)') + ylab('Delta Days') + 
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Instrument Sale and First Purchase of Pouch\n*Count of Data Points at the Top') +
  annotate('text', x=data.count$DateGroup, y=max(recentCust.mon$deltaSaleToPch, na.rm=TRUE) + 7, label=data.count$SaleToPch, fontface='bold')

# ---by region
# ------together
p.AvgSaleToPouch.Reg.1 <- ggplot(Regions.avg, aes(x=DateGroup, y=AvgSaleToPch, group=SalesRegion, color=SalesRegion)) + geom_point(size=1.5) + geom_line(size=1) + 
  scale_y_continuous(breaks=pretty_breaks(n=10)) + xlab('Date of Instrument Sale\n(Year-Month)') + ylab('Delta Days') + 
  scale_color_manual(values = Region.pal, name = 'Sales Region') +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Instrument Sale and \nFirst Purchase of Pouch By Sales Region')

# ------faceted
p.AvgSaleToPouch.Reg.2 <- ggplot(Regions.avg, aes(x=DateGroup, y=AvgSaleToPch, group=SalesRegion)) + geom_point() + geom_line() + 
  xlab('Date of Instrument Sale\n(Year-Month)') + ylab('Delta Days') + 
  scale_color_manual(values = Region.pal, name = 'Sales Region') + facet_wrap(~SalesRegion, scales='free_y') +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Instrument Sale and \nFirst Purchase of Pouch By Sales Region')

# ---by territory
# ------together
p.AvgSaleToPouch.Terr <- ggplot(Territories.qt.avg, aes(x=DateGroup, y=AvgSaleToPch, group=SalesTerritory, color=SalesTerritory)) + geom_point(size=1.5) + geom_line(size=1) + 
  scale_y_continuous(breaks=pretty_breaks(n=10)) + xlab('Date of Instrument Sale\n(Year-Quarter)') + ylab('Delta Days') + 
  scale_color_manual(values = Terr.pal, name = 'Sales Territory') +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Instrument Sale and \nFirst Purchase of Pouch By Sales Territory')

Territories.SaleToPch <- c()
for(i in 1:length(territories)) {
  temp <- subset(Territories.qt.avg, as.character(SalesTerritory)==territories[i])
  if(length(temp$AvgSaleToPch[!is.na(temp$AvgSaleToPch)]) == 0) {
    temp$SalesTerritory <- paste(as.character(temp$SalesTerritory), '- No Data')
    temp$AvgSaleToPch <- 0
  }
  Territories.SaleToPch <- rbind(Territories.SaleToPch, temp)
}
Territories.SaleToPch$SalesTerritory <- factor(Territories.SaleToPch$SalesTerritory, levels = sort(unique(as.character(Territories.SaleToPch$SalesTerritory))), ordered=TRUE)
Territories.SaleToPch <- Territories.SaleToPch[with(Territories.SaleToPch, order(SalesTerritory)),]

# -----------Central
p.AvgSaleToPouch.Central <- ggplot(subset(Territories.SaleToPch, grepl('C', Territories.SaleToPch$SalesTerritory)), aes(x=DateGroup, y=AvgSaleToPch, group=SalesTerritory)) + geom_point() + geom_line() + 
  facet_wrap(~SalesTerritory, scales='free_y') + xlab('Date of Instrument Sale\n(Year-Quarter)') + ylab('Delta Days') + 
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Central Territory\nAverage Days between Instrument Sale and First Purchase of Pouch')

# -----------Great Lakes
p.AvgSaleToPouch.GreatLakes <- ggplot(subset(Territories.SaleToPch, grepl('GL', Territories.SaleToPch$SalesTerritory)), aes(x=DateGroup, y=AvgSaleToPch, group=SalesTerritory)) + geom_point() + geom_line() + 
  facet_wrap(~SalesTerritory, scales='free_y') + xlab('Date of Instrument Sale\n(Year-Quarter)') + ylab('Delta Days') + 
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Great Lakes Territory\nAverage Days between Instrument Sale and First Purchase of Pouch')

# -----------North East
p.AvgSaleToPouch.NorthEast <- ggplot(subset(Territories.SaleToPch, grepl('NE', Territories.SaleToPch$SalesTerritory)), aes(x=DateGroup, y=AvgSaleToPch, group=SalesTerritory)) + geom_point() + geom_line() + 
  facet_wrap(~SalesTerritory, scales='free_y') + xlab('Date of Instrument Sale\n(Year-Quarter)') + ylab('Delta Days') + 
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('North East Territory\nAverage Days between Instrument Sale and First Purchase of Pouch')

# -----------South East
p.AvgSaleToPouch.SouthEast <- ggplot(subset(Territories.SaleToPch, grepl('SE', Territories.SaleToPch$SalesTerritory)), aes(x=DateGroup, y=AvgSaleToPch, group=SalesTerritory)) + geom_point() + geom_line() + 
  facet_wrap(~SalesTerritory, scales='free_y') + xlab('Date of Instrument Sale\n(Year-Quarter)') + ylab('Delta Days') + 
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('South East Territory\nAverage Days between Instrument Sale and First Purchase of Pouch')

# -----------West
p.AvgSaleToPouch.West <- ggplot(subset(Territories.SaleToPch, grepl('W', Territories.SaleToPch$SalesTerritory)), aes(x=DateGroup, y=AvgSaleToPch, group=SalesTerritory)) + geom_point() + geom_line() + 
  facet_wrap(~SalesTerritory, scales='free_y') + xlab('Date of Instrument Sale\n(Year-Quarter)') + ylab('Delta Days') + 
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('West Territory\nAverage Days between Instrument Sale and First Purchase of Pouch')

# ---Avg over whole year per territory
p.AvgSaleToPouch.Year <- ggplot(Territories.year.avg, aes(x=SalesTerritory, y=SaleToPch, fill=SalesTerritory)) + geom_bar(stat='identity') + 
  scale_fill_manual(values = Terr.pal, guide = FALSE) + xlab('Sales Territory') + ylab('Avgerage Delta Days') + geom_text(aes(label=AvgSaleToPch), vjust=-1, fontface = 'bold') +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Instrument Sale and First Purchase of Pouch\nOver the Last Year') 

# ---by type
# ------together
p.AvgSaleToPouch.Type.1 <- ggplot(CustType.avg, aes(x=DateGroup, y=AvgSaleToPch, group=CustomerType, color=CustomerType)) + geom_point(size=1.5) + geom_line(size=1) + 
  scale_y_continuous(breaks=pretty_breaks(n=10)) + xlab('Date of Instrument Sale\n(Year-Month)') + ylab('Delta Days') + scale_color_manual(values = Type.pal, name = 'Customer Type') +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Instrument Sale and\nFirst Purchase of Pouch By Customer Type')

# ------faceted
p.AvgSaleToPouch.Type.2 <- ggplot(CustType.avg, aes(x=DateGroup, y=AvgSaleToPch, group=CustomerType)) + geom_point() + geom_line() + 
  xlab('Date of Instrument Sale\n(Year-Month)') + ylab('Delta Days') + facet_wrap(~CustomerType, scales='free_y') +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Instrument Sale and\nFirst Purchase of Pouch By Customer Type')

# Average Sale To 3rd Pouch ------------------------------------------------------------------------------------------

# ---aggregated graph

p.AvgSaleTo3rdPouch <- ggplot(AvgDeltas, aes(x=DateGroup, y=AvgSaleTo3Pch, group=1)) + geom_point() + geom_line() + 
  geom_point(data=recentCust.mon, aes(x=DateGroup, y=deltaSaleTo3Pch), inherit.aes=FALSE, colour='steelblue2') +
  scale_y_continuous(breaks=pretty_breaks(n=20)) + xlab('Date of Instrument Sale\n(Year-Month)') + ylab('Delta Days') + 
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Instrument Sale and Third Purchase of Pouch\n*Count of Data Points at the Top') +
  annotate('text', x=data.count$DateGroup, y=max(recentCust.mon$deltaSaleTo3Pch, na.rm=TRUE) + 7, label=data.count$SaleTo3Pch, fontface='bold')

# ---by region
# ------together
p.AvgSaleTo3rdPouch.Reg.1 <- ggplot(Regions.avg, aes(x=DateGroup, y=AvgSaleTo3Pch, group=SalesRegion, color=SalesRegion)) + geom_point(size=1.5) + geom_line(size=1) + 
  scale_y_continuous(breaks=pretty_breaks(n=10)) + xlab('Date of Instrument Sale\n(Year-Month)') + ylab('Delta Days') + 
  scale_color_manual(values = Region.pal, name = 'Sales Region') +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Instrument Sale and \nThird Purchase of Pouch By Sales Region')

# ------faceted
p.AvgSaleTo3rdPouch.Reg.2 <- ggplot(Regions.avg, aes(x=DateGroup, y=AvgSaleTo3Pch, group=SalesRegion)) + geom_point() + geom_line() + 
  xlab('Date of Instrument Sale\n(Year-Month)') + ylab('Delta Days') + 
  scale_color_manual(values = Region.pal, name = 'Sales Region') + facet_wrap(~SalesRegion, scales='free_y') +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Instrument Sale and \nThird Purchase of Pouch By Sales Region')

# ---by territory
# ------together
p.AvgSaleTo3rdPouch.Terr <- ggplot(Territories.qt.avg, aes(x=DateGroup, y=AvgSaleTo3Pch, group=SalesTerritory, color=SalesTerritory)) + geom_point(size=1.5) + geom_line(size=1) + 
  scale_y_continuous(breaks=pretty_breaks(n=10)) + xlab('Date of Instrument Sale\n(Year-Quarter)') + ylab('Delta Days') + 
  scale_color_manual(values = Terr.pal, name = 'Sales Territory') +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Instrument Sale and \nThird Purchase of Pouch By Sales Territory')

Territories.SaleTo3Pch <- c()
for(i in 1:length(territories)) {
  temp <- subset(Territories.qt.avg, as.character(SalesTerritory)==territories[i])
  if(length(temp$AvgSaleTo3Pch[!is.na(temp$AvgSaleTo3Pch)]) == 0) {
    temp$SalesTerritory <- paste(as.character(temp$SalesTerritory), '- No Data')
    temp$AvgSaleTo3Pch <- 0
  }
  Territories.SaleTo3Pch <- rbind(Territories.SaleTo3Pch, temp)
}
Territories.SaleTo3Pch$SalesTerritory <- factor(Territories.SaleTo3Pch$SalesTerritory, levels = sort(unique(as.character(Territories.SaleTo3Pch$SalesTerritory))), ordered=TRUE)
Territories.SaleTo3Pch <- Territories.SaleTo3Pch[with(Territories.SaleTo3Pch, order(SalesTerritory)),]

# -----------Central
p.AvgSaleTo3rdPouch.Central <- ggplot(subset(Territories.SaleTo3Pch, grepl('C', Territories.SaleTo3Pch$SalesTerritory)), aes(x=DateGroup, y=AvgSaleTo3Pch, group=SalesTerritory)) + geom_point() + geom_line() + 
  facet_wrap(~SalesTerritory, scales='free_y') + xlab('Date of Instrument Sale\n(Year-Quarter)') + ylab('Delta Days') + 
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Central Territory\nAverage Days between Instrument Sale and Third Purchase of Pouch')

# -----------Great Lakes
p.AvgSaleTo3rdPouch.GreatLakes <- ggplot(subset(Territories.SaleTo3Pch, grepl('GL', Territories.SaleTo3Pch$SalesTerritory)), aes(x=DateGroup, y=AvgSaleTo3Pch, group=SalesTerritory)) + geom_point() + geom_line() + 
  facet_wrap(~SalesTerritory, scales='free_y') + xlab('Date of Instrument Sale\n(Year-Quarter)') + ylab('Delta Days') + 
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Great Lakes Territory\nAverage Days between Instrument Sale and Third Purchase of Pouch')

# -----------North East
p.AvgSaleTo3rdPouch.NorthEast <- ggplot(subset(Territories.SaleTo3Pch, grepl('NE', Territories.SaleTo3Pch$SalesTerritory)), aes(x=DateGroup, y=AvgSaleTo3Pch, group=SalesTerritory)) + geom_point() + geom_line() + 
  facet_wrap(~SalesTerritory, scales='free_y') + xlab('Date of Instrument Sale\n(Year-Quarter)') + ylab('Delta Days') + 
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('North East Territory\nAverage Days between Instrument Sale and Third Purchase of Pouch')

# -----------South East
p.AvgSaleTo3rdPouch.SouthEast <- ggplot(subset(Territories.SaleTo3Pch, grepl('SE', Territories.SaleTo3Pch$SalesTerritory)), aes(x=DateGroup, y=AvgSaleTo3Pch, group=SalesTerritory)) + geom_point() + geom_line() + 
  facet_wrap(~SalesTerritory, scales='free_y') + xlab('Date of Instrument Sale\n(Year-Quarter)') + ylab('Delta Days') + 
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('South East Territory\nAverage Days between Instrument Sale and Third Purchase of Pouch')

# -----------West
p.AvgSaleTo3rdPouch.West <- ggplot(subset(Territories.SaleTo3Pch, grepl('W', Territories.SaleTo3Pch$SalesTerritory)), aes(x=DateGroup, y=AvgSaleTo3Pch, group=SalesTerritory)) + geom_point() + geom_line() + 
  facet_wrap(~SalesTerritory, scales='free_y') + xlab('Date of Instrument Sale\n(Year-Quarter)') + ylab('Delta Days') + 
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('West Territory\nAverage Days between Instrument Sale and Third Purchase of Pouch')

# ---Avg over whole year per territory
p.AvgSaleTo3rdPouch.Year <- ggplot(Territories.year.avg, aes(x=SalesTerritory, y=SaleTo3Pch, fill=SalesTerritory)) + geom_bar(stat='identity') + 
  scale_fill_manual(values = Terr.pal, guide = FALSE) + xlab('Sales Territory') + ylab('Avgerage Delta Days') + geom_text(aes(label=AvgSaleTo3Pch), vjust=-1, fontface = 'bold') +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Instrument Sale and Third Purchase of Pouch\nOver the Last Year') 

# ---by type
# ------together
p.AvgSaleTo3rdPouch.Type.1 <- ggplot(CustType.avg, aes(x=DateGroup, y=AvgSaleTo3Pch, group=CustomerType, color=CustomerType)) + geom_point(size=1.5) + geom_line(size=1) + 
  scale_y_continuous(breaks=pretty_breaks(n=10)) + xlab('Date of Instrument Sale\n(Year-Month)') + ylab('Delta Days') + scale_color_manual(values = Type.pal, name = 'Customer Type') +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Instrument Sale and\nThird Purchase of Pouch By Customer Type')

# ------faceted
p.AvgSaleTo3rdPouch.Type.2 <- ggplot(CustType.avg, aes(x=DateGroup, y=AvgSaleTo3Pch, group=CustomerType)) + geom_point() + geom_line() + 
  xlab('Date of Instrument Sale\n(Year-Month)') + ylab('Delta Days') + facet_wrap(~CustomerType, scales='free_y') +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Instrument Sale and\nThird Purchase of Pouch By Customer Type')

# Average Verification to Pouch ------------------------------------------------------------------------------------------

# ---aggregated graph
p.AvgVerificationToPouch <- ggplot(AvgDeltas, aes(x=DateGroup, y=AvgVerToPch, group=1)) + geom_point() + geom_line() +
  geom_point(data=recentCust.mon, aes(x=DateGroup, y=deltaVerToPch), inherit.aes=FALSE, colour='steelblue2') +
  xlab('Date of Instrument Sale\n(Year-Month)') + ylab('Delta Days') + scale_y_continuous(breaks=pretty_breaks(n=20)) +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20),
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Purchase of Verification Kit and Purchase of Pouch\n*Count of Data Points at the Top') +
  annotate('text', x=data.count$DateGroup, y=max(recentCust.mon$deltaVerToPch, na.rm=TRUE) + 7, label=data.count$VerToPch, fontface='bold')

# ---by region
# ------together
p.AvgVerToPouch.Reg.1 <- ggplot(Regions.avg, aes(x=DateGroup, y=AvgVerToPch, group=SalesRegion, color=SalesRegion)) + geom_point(size=1.5) + geom_line(size=1) + 
  scale_y_continuous(breaks=pretty_breaks(n=10)) + xlab('Date of Instrument Sale\n(Year-Month)') + ylab('Delta Days') + 
  scale_color_manual(values = Region.pal, name = 'Sales Region') +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Purchase of Verification Kit and\nFirst Purchase of Pouch By Sales Region')

# ------faceted
p.AvgVerToPouch.Reg.2 <- ggplot(Regions.avg, aes(x=DateGroup, y=AvgVerToPch, group=SalesRegion)) + geom_point() + geom_line() + 
  xlab('Date of Instrument Sale\n(Year-Month)') + ylab('Delta Days') + 
  facet_wrap(~SalesRegion, scales='free_y') +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Purchase of Verification Kit and\nFirst Purchase of Pouch By Sales Region')

# ---by territory
# ------together
p.AvgVerToPouch.Terr <- ggplot(Territories.qt.avg, aes(x=DateGroup, y=AvgVerToPch, group=SalesTerritory, color=SalesTerritory)) + geom_point(size=1.5) + geom_line(size=1) + 
  scale_y_continuous(breaks=pretty_breaks(n=10)) + xlab('Date of Instrument Sale\n(Year-Quarter)') + ylab('Delta Days') + 
  scale_color_manual(values = Terr.pal, name = 'Sales Territory') +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Purchase of Verification Kit and \nFirst Purchase of Pouch By Sales Territory')

Territories.VerToPch <- c()
for(i in 1:length(territories)) {
  temp <- subset(Territories.qt.avg, as.character(SalesTerritory)==territories[i])
  if(length(temp$AvgVerToPch[!is.na(temp$AvgVerToPch)]) == 0) {
    temp$SalesTerritory <- paste(as.character(temp$SalesTerritory), '- No Data')
    temp$AvgVerToPch <- 0
  }
  Territories.VerToPch <- rbind(Territories.VerToPch, temp)
}
Territories.VerToPch$SalesTerritory <- factor(Territories.VerToPch$SalesTerritory, levels = sort(unique(as.character(Territories.VerToPch$SalesTerritory))), ordered=TRUE)
Territories.VerToPch <- Territories.VerToPch[with(Territories.VerToPch, order(SalesTerritory)),]

# -----------Central
p.AvgVerToPouch.Central <- ggplot(subset(Territories.VerToPch, grepl('C', Territories.VerToPch$SalesTerritory)), aes(x=DateGroup, y=AvgVerToPch, group=SalesTerritory)) + geom_point() + geom_line() + 
  facet_wrap(~SalesTerritory, scales='free_y') + xlab('Date of Instrument Sale\n(Year-Quarter)') + ylab('Delta Days') + 
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Central Territory\nAverage Days between Purchase of Verification Kit and First Purchase of Pouch')

# -----------Great Lakes
p.AvgVerToPouch.GreatLakes <- ggplot(subset(Territories.VerToPch, grepl('GL', Territories.VerToPch$SalesTerritory)), aes(x=DateGroup, y=AvgVerToPch, group=SalesTerritory)) + geom_point() + geom_line() + 
  facet_wrap(~SalesTerritory, scales='free_y') + xlab('Date of Instrument Sale\n(Year-Quarter)') + ylab('Delta Days') + 
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Great Lakes Territory\nAverage Days between Purchase of Verification Kit and First Purchase of Pouch')

# -----------North East
p.AvgVerToPouch.NorthEast <- ggplot(subset(Territories.VerToPch, grepl('NE', Territories.VerToPch$SalesTerritory)), aes(x=DateGroup, y=AvgVerToPch, group=SalesTerritory)) + geom_point() + geom_line() + 
  facet_wrap(~SalesTerritory, scales='free_y') + xlab('Date of Instrument Sale\n(Year-Quarter)') + ylab('Delta Days') + 
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('North East Territory\nAverage Days between Purchase of Verification Kit and First Purchase of Pouch')

# -----------South East
p.AvgVerToPouch.SouthEast <- ggplot(subset(Territories.VerToPch, grepl('SE', Territories.VerToPch$SalesTerritory)), aes(x=DateGroup, y=AvgVerToPch, group=SalesTerritory)) + geom_point() + geom_line() + 
  facet_wrap(~SalesTerritory, scales='free_y') + xlab('Date of Instrument Sale\n(Year-Quarter)') + ylab('Delta Days') + 
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('South East Territory\nAverage Days between Purchase of Verification Kit and First Purchase of Pouch')

# -----------West
p.AvgVerToPouch.West <- ggplot(subset(Territories.VerToPch, grepl('W', Territories.VerToPch$SalesTerritory)), aes(x=DateGroup, y=AvgVerToPch, group=SalesTerritory)) + geom_point() + geom_line() + 
  facet_wrap(~SalesTerritory, scales='free_y') + xlab('Date of Instrument Sale\n(Year-Quarter)') + ylab('Delta Days') + 
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('West Territory\nAverage Days between Purchase of Verification Kit and First Purchase of Pouch')

# ---Avg over whole year per territory
p.AvgVerToPouch.Year <- ggplot(Territories.year.avg, aes(x=SalesTerritory, y=VerToPch, fill=SalesTerritory)) + geom_bar(stat='identity') + 
  scale_fill_manual(values = Terr.pal, guide = FALSE) + xlab('Sales Territory') + ylab('Avgerage Delta Days') + geom_text(aes(label=AvgVerToPch), vjust=-1, fontface = 'bold') +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Purchase of Verification Kit\nand First Purchase of Pouch Over the Last Year') 

# ---by type
# ------together
p.AvgVerToPouch.Type.1 <- ggplot(CustType.avg, aes(x=DateGroup, y=AvgVerToPch, group=CustomerType, color=CustomerType)) + geom_point(size=1.5) + geom_line(size=1) + 
  scale_y_continuous(breaks=pretty_breaks(n=10)) + xlab('Date of Instrument Sale\n(Year-Month)') + ylab('Delta Days') + scale_color_manual(values = Type.pal, name = 'Customer Type') +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Purchase of Verification Kit and\nFirst Purchase of Pouch By Customer Type')

# ------faceted
p.AvgVerToPouch.Type.2 <- ggplot(CustType.avg, aes(x=DateGroup, y=AvgVerToPch, group=CustomerType)) + geom_point() + geom_line() + 
  xlab('Date of Instrument Sale\n(Year-Month)') + ylab('Delta Days') + facet_wrap(~CustomerType, scales='free_y') +
  theme(text=element_text(size=20, face='bold'),axis.text.x=element_text(angle=90, vjust=0.5,color='black', size=20), 
  axis.text.y=element_text(hjust=1, color='black', size=20)) + ggtitle('Average Days between Purchase of Verification Kit and\nFirst Purchase of Pouch By Customer Type')

#Print charts
setwd(imgDir)
plots <- ls()[grep('^p\\.', ls())]
for(i in 1:length(plots)) {
  
  imgName <- paste(substring(plots[i],3),'.png',sep='')
  
  png(file=imgName, width=1200, height=800, units='px')
  print(get(plots[i]))
  makeTimeStamp(author='Data Science')
  dev.off()
}

#Print PDF
setwd(pdfDir)
pdf("GoLiveToThrive.pdf", width = 11, height = 8)
for(i in 1:length(plots)) {
  
  print(get(plots[i]))
}
dev.off()

rm(list=ls())

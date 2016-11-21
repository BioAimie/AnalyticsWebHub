workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_SupplierReliability'
pdfDir <- '~/WebHub/pdfs/'

setwd(workDir)

# Load needed libraries
library(ggplot2)
library(scales)
library(lubridate)
library(dateManip)

# load the data from SQL
source('Portfolios/O_SUPP_load.R')

source('Rfunctions/createPaletteOfVariableLength.R')

calendar.week <- createCalendarLikeMicrosoft(2007, 'Week')


#Find suppliers who have dropped below 90% acceptance rate in last 90 days (3 months)

all <- c('Raw Material','Instrument Production WIP','BioReagents')

filteredData <- subset(ncrParts.df, Type %in% all)
colnames(filteredData)[colnames(filteredData) == 'Qty'] <- 'Record'
lnd.ncr <- subset(filteredData, Date >= Sys.Date()-90 & VendName != 'N/A')
ncrVendors <- unique(lnd.ncr$VendName)
filteredData <- subset(filteredData, VendName %in% ncrVendors)

suppReceipts <- subset(receipts.df, VendName %in% ncrVendors & !is.na(Date))
colnames(suppReceipts)[colnames(suppReceipts) == 'RcvQty'] <- 'Record'

outNCR <- c()
#for each vendor in ncrVendors, add to data frame
for(i in 1:length(ncrVendors)) {
  num <- subset(filteredData, as.character(VendName) == ncrVendors[i])
  den <- subset(suppReceipts, as.character(VendName) == ncrVendors[i])
  
  if(nrow(num)==0 || nrow(den)==0){
    next()
  }
  
  startYear <- unique(den$Year[den$Date == min(as.numeric(den$Date))]) 
  startWeek <- unique(den$Week[den$Date == min(den$Date)])  
  startDate <- ifelse(startWeek < 10,
                      paste(startYear, paste('0', startWeek, sep=''), sep='-'),
                      paste(startYear, startWeek, sep='-'))
  
  #make dategroups
  num <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', num, 'VendName', startDate, 'Record', 'sum', 0)
  num <- num[with(num, order(DateGroup)),]
  colnames(num)[colnames(num) == 'Record'] <- 'NCRQty'
  num$NCRsum <- with(num, cumsum(NCRQty))
  
  den <- aggregateAndFillDateGroupGaps(calendar.week, 'Week', den, 'VendName', startDate, 'Record', 'sum', 0)
  den <- den[with(den, order(DateGroup)),]
  colnames(den)[colnames(den) == 'Record'] <- 'TotalQty'
  den$Totalsum <- with(den, cumsum(TotalQty))
  
  #Acceptance Rate
  supp.part <- merge(num,den, by='DateGroup')
  supp.part$RejectionRate <- supp.part$NCRsum / supp.part$Totalsum
  supp.part$ARate <- ifelse(supp.part$RejectionRate < 1, 1-supp.part$RejectionRate, 0)
  
  #subset last 13 weeks and add to table
  outNCR <- rbind(outNCR,tail(supp.part, 13))
}

#Find bottom 10 vendors
a <- subset(outNCR, select=c('DateGroup','VendName.x','ARate'),DateGroup == min(outNCR$DateGroup))
b.out <- unique(subset(a, ARate < 0.9)[,'VendName.x'])
b <- subset(outNCR, select=c('DateGroup','VendName.x','ARate'), !(VendName.x %in% b.out))
b<- b[with(b, order(ARate)), ]
vendors <- unique(subset(b, ARate < 0.9)[,'VendName.x'])

if (length(vendors) < 10) {
  vendors <- unique(b$VendName.x)[1:10]
} else if (length(vendors > 10)) {
  vendors <- vendors[1:10]
}

# # Fail if below 90% acceptance rate
# b$Review <- 'Pass'
# for(i in 1:length(b$ARate)) {
#   if(b$ARate[i] < 0.9) {
#     b$Review[i] <- 'Fail'
#   }
# }
# 
# reviewColors <- c('red','blue')
# names(reviewColors) <- c('Fail','Pass')

#Make the charts

#x scale
sub1 <- subset(b, VendName.x == vendors[1])
xScale <- scale_x_discrete(breaks=as.character(unique(sub1[,'DateGroup']))[order(as.character(unique(sub1[,'DateGroup'])))][seq(1,length(as.character(unique(sub1[,'DateGroup']))), 12)])
chart.1 <- ggplot(sub1, aes(x=DateGroup, y=ARate, group=1, color=Review)) + 
  geom_line(color='black') + geom_point(size=1.5, color='black') + xlab('Date\n(Year-Week)') + ylab('Vendor Acceptance Rate') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20),
  axis.text.y=element_text(hjust=1, color='black', size=20),legend.position='none') + 
  ggtitle(paste('Acceptance Rate of Supplier:\n', vendors[1])) + 
  scale_y_continuous(labels=percent,breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30), limits=c(0,1)) + 
  geom_hline(yintercept=.9, linetype='dashed', color='blue') + xScale

sub2 <- subset(b, VendName.x == vendors[2])
xScale <- scale_x_discrete(breaks=as.character(unique(sub2[,'DateGroup']))[order(as.character(unique(sub2[,'DateGroup'])))][seq(1,length(as.character(unique(sub2[,'DateGroup']))), 12)])
chart.2 <- ggplot(sub2, aes(x=DateGroup, y=ARate, group=1, color=Review)) + 
  geom_line(color='black') + geom_point(size=1.5, color='black') + xlab('Date\n(Year-Week)') + ylab('Vendor Acceptance Rate') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20),
        axis.text.y=element_text(hjust=1, color='black', size=20),legend.position='none') + 
  ggtitle(paste('Acceptance Rate of Supplier:\n', vendors[2])) + 
  scale_y_continuous(labels=percent,breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30), limits=c(0,1)) + 
  geom_hline(yintercept=.9, linetype='dashed', color='blue') + xScale

sub3 <- subset(b, VendName.x == vendors[3])
xScale <- scale_x_discrete(breaks=as.character(unique(sub3[,'DateGroup']))[order(as.character(unique(sub3[,'DateGroup'])))][seq(1,length(as.character(unique(sub3[,'DateGroup']))), 12)])
chart.3 <- ggplot(sub3, aes(x=DateGroup, y=ARate, group=1, color=Review)) + 
  geom_line(color='black') + geom_point(size=1.5, color='black') + xlab('Date\n(Year-Week)') + ylab('Vendor Acceptance Rate') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20),
        axis.text.y=element_text(hjust=1, color='black', size=20),legend.position='none') + 
  ggtitle(paste('Acceptance Rate of Supplier:\n', vendors[3])) + 
  scale_y_continuous(labels=percent,breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30), limits=c(0,1)) + 
  geom_hline(yintercept=.9, linetype='dashed', color='blue') + xScale

sub4 <- subset(b, VendName.x == vendors[4])
xScale <- scale_x_discrete(breaks=as.character(unique(sub4[,'DateGroup']))[order(as.character(unique(sub4[,'DateGroup'])))][seq(1,length(as.character(unique(sub4[,'DateGroup']))), 12)])
chart.4 <- ggplot(sub4, aes(x=DateGroup, y=ARate, group=1, color=Review)) + 
  geom_line(color='black') + geom_point(size=1.5, color='black') + xlab('Date\n(Year-Week)') + ylab('Vendor Acceptance Rate') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20),
        axis.text.y=element_text(hjust=1, color='black', size=20),legend.position='none') + 
  ggtitle(paste('Acceptance Rate of Supplier:\n', vendors[4])) + 
  scale_y_continuous(labels=percent,breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30), limits=c(0,1)) + 
  geom_hline(yintercept=.9, linetype='dashed', color = 'blue') + xScale

sub5 <- subset(b, VendName.x == vendors[5])
xScale <- scale_x_discrete(breaks=as.character(unique(sub5[,'DateGroup']))[order(as.character(unique(sub5[,'DateGroup'])))][seq(1,length(as.character(unique(sub5[,'DateGroup']))), 12)])
chart.5 <- ggplot(sub5, aes(x=DateGroup, y=ARate, group=1, color=Review)) + 
  geom_line(color='black') + geom_point(size=1.5, color='black') + xlab('Date\n(Year-Week)') + ylab('Vendor Acceptance Rate') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20),
        axis.text.y=element_text(hjust=1, color='black', size=20),legend.position='none') + 
  ggtitle(paste('Acceptance Rate of Supplier:\n', vendors[5])) + 
  scale_y_continuous(labels=percent,breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30), limits=c(0,1)) + 
  geom_hline(yintercept=.9, linetype='dashed', color='blue') + xScale

sub6 <- subset(b, VendName.x == vendors[6])
xScale <- scale_x_discrete(breaks=as.character(unique(sub6[,'DateGroup']))[order(as.character(unique(sub6[,'DateGroup'])))][seq(1,length(as.character(unique(sub6[,'DateGroup']))), 12)])
chart.6 <- ggplot(sub6, aes(x=DateGroup, y=ARate, group=1, color=Review)) + 
  geom_line(color='black') + geom_point(size=1.5, color='black') + xlab('Date\n(Year-Week)') + ylab('Vendor Acceptance Rate') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20),
        axis.text.y=element_text(hjust=1, color='black', size=20),legend.position='none') + 
  ggtitle(paste('Acceptance Rate of Supplier:\n', vendors[6])) + 
  scale_y_continuous(labels=percent,breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30), limits=c(0,1)) + 
  geom_hline(yintercept=.9, linetype='dashed', color='blue') + xScale

sub7 <- subset(b, VendName.x == vendors[7])
xScale <- scale_x_discrete(breaks=as.character(unique(sub7[,'DateGroup']))[order(as.character(unique(sub7[,'DateGroup'])))][seq(1,length(as.character(unique(sub7[,'DateGroup']))), 12)])
chart.7 <- ggplot(sub7, aes(x=DateGroup, y=ARate, group=1, color=Review)) + 
  geom_line(color='black') + geom_point(size=1.5, color='black') + xlab('Date\n(Year-Week)') + ylab('Vendor Acceptance Rate') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20),
        axis.text.y=element_text(hjust=1, color='black', size=20),legend.position='none') + 
  ggtitle(paste('Acceptance Rate of Supplier:\n', vendors[7])) + 
  scale_y_continuous(labels=percent,breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30), limits=c(0,1)) + 
  geom_hline(yintercept=.9, linetype='dashed', color='blue') + xScale

sub8 <- subset(b, VendName.x == vendors[8])
xScale <- scale_x_discrete(breaks=as.character(unique(sub8[,'DateGroup']))[order(as.character(unique(sub8[,'DateGroup'])))][seq(1,length(as.character(unique(sub8[,'DateGroup']))), 12)])
chart.8 <- ggplot(sub8, aes(x=DateGroup, y=ARate, group=1, color=Review)) + 
  geom_line(color='black') + geom_point(size=1.5, color='black') + xlab('Date\n(Year-Week)') + ylab('Vendor Acceptance Rate') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20),
        axis.text.y=element_text(hjust=1, color='black', size=20),legend.position='none') + 
  ggtitle(paste('Acceptance Rate of Supplier:\n', vendors[8])) + 
  scale_y_continuous(labels=percent,breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30), limits=c(0,1)) + 
  geom_hline(yintercept=.9, linetype='dashed', color='blue') + xScale

sub9 <- subset(b, VendName.x == vendors[9])
xScale <- scale_x_discrete(breaks=as.character(unique(sub9[,'DateGroup']))[order(as.character(unique(sub9[,'DateGroup'])))][seq(1,length(as.character(unique(sub9[,'DateGroup']))), 12)])
chart.9 <- ggplot(sub9, aes(x=DateGroup, y=ARate, group=1, color=Review)) + 
  geom_line(color='black') + geom_point(size=1.5,color='black') + xlab('Date\n(Year-Week)') + ylab('Vendor Acceptance Rate') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20),
        axis.text.y=element_text(hjust=1, color='black', size=20),legend.position='none') + 
  ggtitle(paste('Acceptance Rate of Supplier:\n', vendors[9])) + 
  scale_y_continuous(labels=percent,breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30), limits=c(0,1)) + 
  geom_hline(yintercept=.9, linetype='dashed', color='blue') + xScale

sub10 <- subset(b, VendName.x == vendors[10])
xScale <- scale_x_discrete(breaks=as.character(unique(sub10[,'DateGroup']))[order(as.character(unique(sub10[,'DateGroup'])))][seq(1,length(as.character(unique(sub10[,'DateGroup']))), 12)])
chart.10 <- ggplot(sub10, aes(x=DateGroup, y=ARate, group=1, color=Review)) + 
  geom_line(color='black') + geom_point(size=1.5, color='black') + xlab('Date\n(Year-Week)') + ylab('Vendor Acceptance Rate') + 
  theme(text=element_text(size=20, face='bold'), axis.text.x=element_text(angle=90, vjust=0.5,color='black',size=20),
        axis.text.y=element_text(hjust=1, color='black', size=20),legend.position='none') + 
  ggtitle(paste('Acceptance Rate of Supplier:\n', vendors[10])) + 
  scale_y_continuous(labels=percent,breaks=pretty_breaks(n=10), minor_breaks = pretty_breaks(n=30), limits=c(0,1)) + 
  geom_hline(yintercept=.9, linetype='dashed', color='blue') + xScale

#-----------------------------------------------------------------------------------------------------------------------------

# Export Images for the Web Hub
setwd(imgDir)
png(file="image0.png",width=1200,height=800,units='px')
print(chart.1)
dev.off()
png(file="image1.png",width=1200,height=800,units='px')
print(chart.2)
dev.off()
png(file="image2.png",width=1200,height=800,units='px')
print(chart.3)
dev.off()
png(file="image3.png",width=1200,height=800,units='px')
print(chart.4)
dev.off()
png(file="image4.png",width=1200,height=800,units='px')
print(chart.5)
dev.off()
png(file="image5.png",width=1200,height=800,units='px')
print(chart.6)
dev.off()
png(file="image6.png",width=1200,height=800,units='px')
print(chart.7)
dev.off()
png(file="image7.png",width=1200,height=800,units='px')
print(chart.8)
dev.off()
png(file="image8.png",width=1200,height=800,units='px')
print(chart.9)
dev.off()
png(file="image9.png",width=1200,height=800,units='px')
print(chart.10)
dev.off()

# Export PDF for the Web Hub
setwd(pdfDir)
pdf("SupplierReliability.pdf", width = 11, height = 8)
print(chart.1)
print(chart.2)
print(chart.3)
print(chart.4)
print(chart.5)
print(chart.6)
print(chart.7)
print(chart.8)
print(chart.9)
print(chart.10)
dev.off()

rm(list = ls())

#create some global variables
library(dateManip)

calendar <- createCalendarLikeMicrosoft(2007,'Month')
calendar.week <- createCalendarLikeMicrosoft(2007, 'Week')
all <- c('Raw Material','Instrument Production WIP','BioReagents', 'HTFA Instrument WIP', 'FA2.0 Instrument WIP','FA1.5 Instrument WIP')
iNcrType <- c('Instrument Production WIP','HTFA Instrument WIP', 'FA2.0 Instrument WIP','FA1.5 Instrument WIP')

# for materials management group: paretos of defects (sub failure category), parts, and rate of NCR by part/vendor
defects.date <- merge(defects.df[defects.df$Key=='Failure Details', ], filters.df[,c('TicketId','Date')], by='TicketId')
affParts.date <- merge(defects.df[defects.df$Key=='Parts Affected', ], filters.df[,c('TicketId','Date')], by='TicketId')
colnames(affParts.date)[grep('Class|Order', colnames(affParts.date))] <- c('PartNumber','LotNumber')
filters.df[is.na(filters.df$Vendor), 'Vendor'] <- 'N/A'

# create alerts for the material management group:
# 1. If there is a yield lower than 95% by part then send an alert with the related NCR (last 7 days???)
# 2. If there are 3+ NCRs with the same failure mode in the last 180 days
# 3. If there are 3+ SCARs in the last 365 days for a given part
yields.lsd <- yields.df[yields.df$Date >= Sys.Date()-7, ]
yields.lsd$Yield <- with(yields.lsd, QtyAffected/LotSize)
bad.yeild.lsd <- yields.lsd[yields.lsd$Yield > 0.95, ]
defects.lsm <- with(defects.date[defects.date$Date >= Sys.Date()-180, ], aggregate(Record~Order, FUN=sum))
bad.defects.lsm <- defects.lsm[defects.lsm$Record >=3, ]
bad.defects.lsm <- do.call(rbind, lapply(1:length(bad.defects.lsm$Order), function(x) data.frame(Defect = bad.defects.lsm$Order[x], OccurencesLSM = bad.defects.lsm$Record[x], Tickets = paste(as.character(merge(data.frame(TicketId = defects.date[defects.date$Date >= Sys.Date() - 180 & as.character(defects.date$Order) == bad.defects.lsm$Order[x], 'TicketId']), index.df, by='TicketId')[,'TicketString']), collapse=', '))))
scars.ltm <- merge(filters.df[filters.df$Date >= Sys.Date()-365 & filters.df$SCAR=='Yes', c('TicketId','Date')], affParts.date[ ,c('TicketId','PartNumber')], by='TicketId')
scars.ltm <- data.frame(unique(scars.ltm[,c('TicketId','Date','PartNumber')]), Count = 1)
scars.ltm <- with(scars.ltm, aggregate(Count~PartNumber, FUN=sum))
scars.ltm <- scars.ltm[scars.ltm$Count >= 3, ]

# CREATE AN EXCEL FILE TO SEND TO FRANKIE... THEN EMAIL IT TO HER
write.xlsx(bad.yeild.lsd, file = '../../../MaterialsManagementAlerts.xlsx', sheetName = 'Lot Yield < 95%', row.names = FALSE)
write.xlsx(bad.defects.lsm, file = '../../../MaterialsManagementAlerts.xlsx', sheetName = '3+ Defects in Last Six Months', row.names = FALSE, append = TRUE)
write.xlsx(scars.ltm, file = '../../../MaterialsManagementAlerts.xlsx', sheetName = '3+ SCAR Parts in Last 12 Months', row.names = FALSE, append = TRUE)

if(wday(Sys.Date()) == 4) {
  
  from <- 'aimie.faucett@biofiredx.com'
  to <- 'Frankie.Tate@biofiredx.com'
  subject <- 'Materials Management NCR Alerts'
  body <- 'Based on analysis of NCR and MAS receipt data, the attached report has been generated. Thank you.'
  mailControl <- list(smtpServer="webmail.biofiredx.com")
  attachmentPath <- '../../../MaterialsManagementAlerts.xlsx'
  attachmentName <- 'DataAlerts.xlsx'
  attachmentObject <- mime_part(x=attachmentPath, name=attachmentName)
  bodyWithAttachment <- list(body, attachmentObject)
  sendmail(from=from,to=to,subject=subject,msg=bodyWithAttachment,control=mailControl)
}

# empty.vendor.fix <- merge(filters.df[,c('TicketId','Vendor')], affParts.date[,c('TicketId','PartNumber')], by='TicketId')
# empty.vendor.fix <- merge(unique(empty.vendor.fix[,c('Vendor','PartNumber')]), unique(receipts.df[,c('VendName','PartNumber')]), by='PartNumber')
# empty.vendor.fix$Record <- 1
# unique.vendor.parts <- with(empty.vendor.fix, aggregate(Record~PartNumber, FUN=sum))
# unique.vendor.parts <- unique.vendor.parts[unique.vendor.parts$Record==1,'PartNumber']
# empty.vendor.fix.unique <- empty.vendor.fix[empty.vendor.fix$PartNumber %in% unique.vendor.parts, c('PartNumber','VendName')]
# empty.vendor.fix.alt <- empty.vendor.fix[!(empty.vendor.fix$PartNumber %in% unique.vendor.parts) & as.character(empty.vendor.fix$Vendor)==as.character(empty.vendor.fix$VendName), ]
# empty.vendor.fix.alt <- empty.vendor.fix.alt[!(is.na(empty.vendor.fix.alt$PartNumber)), ]
# empty.vendor.fix.alt$Record <- 1
# alt.vendor.parts <- with(empty.vendor.fix.alt, aggregate(Record~PartNumber, FUN=sum))
# alt.vendor.parts <- alt.vendor.parts[alt.vendor.parts$Record==1, 'PartNumber']
# empty.vendor.fix.alt <- empty.vendor.fix.alt[empty.vendor.fix.alt$PartNumber %in% alt.vendor.parts, c('PartNumber','VendName')]
# empty.vendor.fix <- rbind(empty.vendor.fix.unique, empty.vendor.fix.alt)
# affParts.date.fix <- merge(affParts.date, filters.df[,c('TicketId','Vendor')], by='TicketId', all.x=TRUE)
# affParts.date.fix <- merge(affParts.date.fix[is.na(affParts.date.fix$Vendor) & affParts.date.fix$PartNumber %in% empty.vendor.fix$PartNumber, c('TicketId','Key','PartNumber','Order','Record','Date')], empty.vendor.fix, by='PartNumber')
# filters.fix <- merge(filters.df, affParts.date.fix[,c('TicketId','VendName')], by='TicketId')
# filters.fix <- filters.fix[,c('TicketId','Date','Type','WhereFound','ProblemArea','VendName','SCAR','SupplierAtFault')]
# colnames(filters.fix)[grep('Vend',colnames(filters.fix))] <- 'Vendor'
# filters.df.fix <- rbind(filters.df[!(filters.df$TicketId %in% filters.fix$TicketId), ], filters.fix)
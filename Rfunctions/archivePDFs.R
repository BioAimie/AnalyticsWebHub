dateStamp <- Sys.Date()

copyPath <- '\\\\Filer01/Data/Departments/PostMarket/~Shared_PostMarket/FilmArray_SPCMonitoring/ArchivedWebHubReports/'
copyWebPath <- '\\\\Filer01/Data/Departments/PostMarket/~Dashboards/WebHub/pdfs/'
copyWebPath.it <- '\\\\biofirestation/WebHub/WebHub/pdfs/'

# fileToCopy <- '\\\\Filer01/Data/Departments/PostMarket/~Dashboards/WebHub/pdfs/PouchQC.pdf'
# fileCopier <- '\\\\biofirestation/WebHub/WebHub/pdfs/PouchQC.pdf'
# file.copy(fileToCopy, fileCopier, overwrite = TRUE)

path <- '~/WebHub/pdfs/'
files <- list.files(path=path)
l <- length(files)

for(i in 1:l) {
  
  fileToCopy <- paste(path,files[i],sep='')
  
  archiveFile <- paste(paste(as.character(strsplit(files[i],'.pdf')), dateStamp, sep='-'),'pdf',sep='.')
  copyToArchive <- paste(copyPath,archiveFile,sep='')
  copyToWebHub <- paste(copyWebPath,files[i],sep='')
  copyToITWeb <- paste(copyWebPath.it,files[i],sep='')
  
  file.copy(fileToCopy, copyToArchive, overwrite=TRUE)
  file.copy(fileToCopy, copyToWebHub, overwrite=TRUE)
  file.copy(fileToCopy, copyToITWeb, overwrite=TRUE)
}

rm(list=ls())
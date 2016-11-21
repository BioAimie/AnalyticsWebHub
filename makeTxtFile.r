# Compiles all .bat, .R, .txt, and .html files from Web Hub Folders, including BatchFiles,
# Portfolios, Rfunctions, SQL, and WebHub. Creates final txt file, containing all source 
# code for Web Hub.

#Instructions:
# 1. Save source code zip file to desktop. Extract folder.
# 2. Set working directory to correct folder.

#set working directory
setwd('C:/Users/amber_kiser/Desktop/AnalyticsWebHub-1.7.0')

#create vector of folder names
folders <- c('./BatchFiles', './Portfolios', './Rfunctions', './SQL', './WebHub')

#name of output text file
out_file <- 'C:/Users/amber_kiser/Desktop/TRND-SFW-0001.txt'

#write WebHub home page to out_file
write('WebHub.html', file=out_file, append = TRUE)
write(" ", file=out_file, append = TRUE)
scannedFile <- scan('WebHub.html', what='list', sep = '\n', blank.lines.skip=FALSE)
write(scannedFile, file=out_file, append = TRUE, sep="\n")
write(" ", file=out_file, append = TRUE)
write(" ", file=out_file, append = TRUE)
write("_______________________________________________________________________________________________", file=out_file, append = TRUE)
write(" ", file=out_file, append = TRUE)

#loop through folders, except Apps
for (i in folders)
{
  listFiles <- (list.files(i))
  write(paste("Folder: ", i), file=out_file, append = TRUE)
  write(" ", file=out_file, append = TRUE)
  write("_______________________________________________________________________________________________", file=out_file, append = TRUE)
  write(" ", file=out_file, append = TRUE)
  
  #scan in .bat, .r, .txt, and .html files and write new .txt file
  for (j in listFiles)
  {
    if(grepl('.bat$', j, ignore.case = TRUE) || grepl('.r$', j, ignore.case = TRUE) || 
       grepl('.txt$', j, ignore.case = TRUE) || grepl('.html$', j, ignore.case = TRUE)) {
      write(j, file=out_file, append = TRUE)
      write(" ", file=out_file, append = TRUE)
      scannedFile <- scan(paste(i, '/',j, sep=''), what='list', sep = '\n', blank.lines.skip=FALSE)
      write(scannedFile, file=out_file, append = TRUE, sep="\n")
      write(" ", file=out_file, append = TRUE)
      write(" ", file=out_file, append = TRUE)
      write("_______________________________________________________________________________________________", file=out_file, append = TRUE)
      write(" ", file=out_file, append = TRUE)
    }
  }
}


# Compiles all .m and .prj files from Pouch Final QC Folders, including Configs, DataControl, DataRetrieval, GraphicalResources,
# ReportingResources, and the root folder. Adds to final txt file all source 
# code for Pouch Final QC Dashboard, validated by BioMath and incorporated into the Web Hub.

#set working directory
setwd('G:/Departments/PostMarket/WebHubBuildFiles/v1.7.0/WebHubHome-1/Validation/Portfolios/Pouch Final QC/FilmArray_PouchMfg_PostMarketCmdLineTrends')

#create vector of folder names
folders <- c('./Configs', './DataControl', './DataRetrieval', './GraphicalResources', './ReportingResources')

write("Folder: Pouch Final QC", file=out_file, append = TRUE)

#loop through files in root folder
listFiles <- (list.files())
write("Folder: FilmArray_PouchMfg_PostMarketCmdLineTrends", file=out_file, append = TRUE)
write(" ", file=out_file, append = TRUE)
write("_______________________________________________________________________________________________", file=out_file, append = TRUE)
write(" ", file=out_file, append = TRUE)

#scan in .bat, .r, .txt, and .html files and write new .txt file
for (k in listFiles)
{
  if(grepl('.m$', k, ignore.case = TRUE) || grepl('.prj$', k, ignore.case = TRUE)) {
    write(k, file=out_file, append = TRUE)
    write(" ", file=out_file, append = TRUE)
    scannedFile <- scan(k, what='list', sep = '\n', blank.lines.skip=FALSE)
    write(scannedFile, file=out_file, append = TRUE, sep="\n")
    write(" ", file=out_file, append = TRUE)
    write(" ", file=out_file, append = TRUE)
    write("_______________________________________________________________________________________________", file=out_file, append = TRUE)
    write(" ", file=out_file, append = TRUE)
  }
}

#loop through folders
for (l in folders)
{
  listFiles <- (list.files(l))
  write(paste("Folder: ", l), file=out_file, append = TRUE)
  write(" ", file=out_file, append = TRUE)
  write("_______________________________________________________________________________________________", file=out_file, append = TRUE)
  write(" ", file=out_file, append = TRUE)
  
  #scan in files and write new .txt file
  for (m in listFiles)
  {
    if(grepl('.m$', m, ignore.case = TRUE) || grepl('.prj$', m, ignore.case = TRUE)) {
      write(m, file=out_file, append = TRUE)
      write(" ", file=out_file, append = TRUE)
      scannedFile <- scan(paste(l, '/',m, sep=''), what='list', sep = '\n', blank.lines.skip=FALSE)
      write(scannedFile, file=out_file, append = TRUE, sep="\n")
      write(" ", file=out_file, append = TRUE)
      write(" ", file=out_file, append = TRUE)
      write("_______________________________________________________________________________________________", file=out_file, append = TRUE)
      write(" ", file=out_file, append = TRUE)
    }
  }
}

rm(list=ls())
workDir <- '~/WebHub/AnalyticsWebHub/'
imgDir <- '~/WebHub/images/Dashboard_PouchSPC/'
pdfDir <- '~/WebHub/pdfs/'
bioDir <- '\\\\Filer01/Data/Departments/PostMarket/~Dashboards/WebHub/images/Dashboard_PouchQCTrend'

# set the working directory
setwd(workDir)

library(png)
library(grid)

source('Rfunctions/makeTimestamp.R')

setwd(imgDir)
#timestamp biomath plots
# first, read in the images created by BioMath
# list folders
folders <- list.dirs(path=bioDir)
# loop through all folders and pull any .png files
for(i in 1:length(folders)) {
  bioFiles <- list.files(path=folders[i])[grep('png', list.files(path=folders[i]))]
  if(length(bioFiles) > 0) {
    panel <- substr(substr(folders[i],regexpr('Dashboard_PouchQCTrend', folders[i])[1]+23, nchar(folders[i])), 1, regexpr('\\/',substr(folders[i],regexpr('Dashboard_PouchQCTrend', folders[i])[1]+23, nchar(folders[i])))-1)
    for(j in 1:length(bioFiles)) {
      timeCreated <- file.mtime(paste(folders[i],'/',bioFiles[j],sep=''))
      imgName <- paste(panel,bioFiles[j], sep='-')
      png(file=imgName, width=1200, height=900, units='px') 
      img <- as.raster(readPNG(paste(folders[i], bioFiles[j], sep='/'))) 
      grid.newpage()
      grid.raster(img, interpolate = FALSE)
      makeTimeStamp(timeStamp = paste(panel,timeCreated, sep='    '), author='BioMath')
      dev.off()
    }
  }
}

# Create the pdf
setwd(pdfDir)
pdf("PouchSPC.pdf", width=11, height=8)
for(i in 1:length(folders)) {
  bioFiles <- list.files(path=folders[i])[grep('png', list.files(path=folders[i]))]
  if(length(bioFiles) > 0) {
    panel <- substr(substr(folders[i],regexpr('Dashboard_PouchQCTrend', folders[i])[1]+23, nchar(folders[i])), 1, regexpr('\\/',substr(folders[i],regexpr('Dashboard_PouchQCTrend', folders[i])[1]+23, nchar(folders[i])))-1)
    plot(0:10, type = "n", xaxt="n", yaxt="n", bty="n", xlab = "", ylab = "")
    text(5.7, 8, panel, cex=5)
    for(j in 1:length(bioFiles)) {
      img <- as.raster(readPNG(paste(folders[i], bioFiles[j], sep='/')))
      grid.newpage()
      grid.raster(img, interpolate = FALSE)
    }
  }
}
dev.off()

#create separate pdfs for each panel
pdf("PouchSPC_RP.pdf", width=11, height=8)
for(i in 1:length(folders)) {
  bioFiles <- list.files(path=folders[i])[grep('png', list.files(path=folders[i]))]
  if(length(bioFiles) > 0) {
    panel <- substr(substr(folders[i],regexpr('Dashboard_PouchQCTrend', folders[i])[1]+23, nchar(folders[i])), 1, regexpr('\\/',substr(folders[i],regexpr('Dashboard_PouchQCTrend', folders[i])[1]+23, nchar(folders[i])))-1)
    if(panel == 'RP') {
      for(j in 1:length(bioFiles)) {
        img <- as.raster(readPNG(paste(folders[i], bioFiles[j], sep='/')))
        grid.newpage()
        grid.raster(img, interpolate = FALSE)
      }
    }
  }
}
dev.off()

pdf("PouchSPC_IQC.pdf", width=11, height=8)
for(i in 1:length(folders)) {
  bioFiles <- list.files(path=folders[i])[grep('png', list.files(path=folders[i]))]
  if(length(bioFiles) > 0) {
    panel <- substr(substr(folders[i],regexpr('Dashboard_PouchQCTrend', folders[i])[1]+23, nchar(folders[i])), 1, regexpr('\\/',substr(folders[i],regexpr('Dashboard_PouchQCTrend', folders[i])[1]+23, nchar(folders[i])))-1)
    if(panel == 'IQC') {
      for(j in 1:length(bioFiles)) {
        img <- as.raster(readPNG(paste(folders[i], bioFiles[j], sep='/')))
        grid.newpage()
        grid.raster(img, interpolate = FALSE)
      }
    }
  }
}
dev.off()

pdf("PouchSPC_GI.pdf", width=11, height=8)
for(i in 1:length(folders)) {
  bioFiles <- list.files(path=folders[i])[grep('png', list.files(path=folders[i]))]
  if(length(bioFiles) > 0) {
    panel <- substr(substr(folders[i],regexpr('Dashboard_PouchQCTrend', folders[i])[1]+23, nchar(folders[i])), 1, regexpr('\\/',substr(folders[i],regexpr('Dashboard_PouchQCTrend', folders[i])[1]+23, nchar(folders[i])))-1)
    if(panel == 'GI') {
      for(j in 1:length(bioFiles)) {
        img <- as.raster(readPNG(paste(folders[i], bioFiles[j], sep='/')))
        grid.newpage()
        grid.raster(img, interpolate = FALSE)
      }
    }
  }
}
dev.off()

pdf("PouchSPC_BCID.pdf", width=11, height=8)
for(i in 1:length(folders)) {
  bioFiles <- list.files(path=folders[i])[grep('png', list.files(path=folders[i]))]
  if(length(bioFiles) > 0) {
    panel <- substr(substr(folders[i],regexpr('Dashboard_PouchQCTrend', folders[i])[1]+23, nchar(folders[i])), 1, regexpr('\\/',substr(folders[i],regexpr('Dashboard_PouchQCTrend', folders[i])[1]+23, nchar(folders[i])))-1)
    if(panel == 'BCID') {
      for(j in 1:length(bioFiles)) {
        img <- as.raster(readPNG(paste(folders[i], bioFiles[j], sep='/')))
        grid.newpage()
        grid.raster(img, interpolate = FALSE)
      }
    }
  }
}
dev.off()

pdf("PouchSPC_ME.pdf", width=11, height=8)
for(i in 1:length(folders)) {
  bioFiles <- list.files(path=folders[i])[grep('png', list.files(path=folders[i]))]
  if(length(bioFiles) > 0) {
    panel <- substr(substr(folders[i],regexpr('Dashboard_PouchQCTrend', folders[i])[1]+23, nchar(folders[i])), 1, regexpr('\\/',substr(folders[i],regexpr('Dashboard_PouchQCTrend', folders[i])[1]+23, nchar(folders[i])))-1)
    if(panel == 'ME') {
      for(j in 1:length(bioFiles)) {
        img <- as.raster(readPNG(paste(folders[i], bioFiles[j], sep='/')))
        grid.newpage()
        grid.raster(img, interpolate = FALSE)
      }
    }
  }
}
dev.off()

rm(list = ls())
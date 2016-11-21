markForReview <- function(dataFrame, sdFactor, partitionVec, alternative = FALSE, alternativeLim = 0.01) {
  
  out <- c()
  
  if(alternative) {
    
    # if there are three levels in the partition vector (i.e. Version, Key, RecordedValue)
    if(length(partitionVec)==3) {
      # the top level is Version, get all versions
      topCol <- partitionVec[1]
      topVars <- as.character(unique(dataFrame[ ,topCol]))
      
      for (i in 1:length(topVars)) {
        # for each version, make a sub-frame of each key
        top <- dataFrame[dataFrame[,topCol]==topVars[i], ]
        midCol <- partitionVec[2]
        midVars <- as.character(unique(top[ ,midCol]))
        
        for (j in 1:length(midVars)) {
          # for each key, make a sub-frame of each recorded value
          mid <- top[top[,midCol]==midVars[j], ]
          botCol <- partitionVec[3]
          botVars <- as.character(unique(mid[,botCol]))
          
          for (k in 1:length(botVars)) {
            # iterate for the unique combo of Version+Key+RecordedValue and mark for review (remove NaN and NA entries!)
            bot <- mid[mid[,botCol]==botVars[k], ]
            biggest <- max(bot[ ,'RollingRate'], na.rm=TRUE)
            
            if(biggest <= alternativeLim) {
              
              bot[ ,'Color'] <- 'Pass'
              bot[ ,'Limits'] <- alternativeLim
              out <- rbind(out, bot)
            }
            
            else {
              
              bot[,'Limits'] <- with(bot, average + sdFactor*sdev)
              
              if (sdFactor >= 0) {
                
                bot[,'Color'] <- with(bot, ifelse(RollingRate > Limits, 'Review', 'Pass'))
              }
              
              else if (sdFactor < 0) {
                
                bot[,'Color'] <- with(bot, ifelse(RollingRate < Limits, 'Review', 'Pass'))
              }
              out <- rbind(out, bot)
            }
          }
        }
      }
      return(out)
    }
    
    # do the same thing as the if statement above, but only for two levels, not three
    else if(length(partitionVec)==2) {
      
      topCol <- partitionVec[1]
      topVars <- as.character(unique(dataFrame[ ,topCol]))
      
      for (i in 1:length(topVars)) {
        top <- dataFrame[dataFrame[,topCol]==topVars[i], ]
        botCol <- partitionVec[2]
        botVars <- as.character(unique(top[ ,botCol]))
        
        for (j in 1:length(botVars)) {
          bot <- top[top[,botCol]==botVars[j], ]
          biggest <- max(bot[ ,'RollingRate'], na.rm=TRUE)
          
          if(biggest <= alternativeLim) {
            
            bot[ ,'Color'] <- 'Pass'
            bot[ ,'Limits'] <- alternativeLim
            out <- rbind(out, bot)
          }
          
          else {
            
            bot[,'Limits'] <- with(bot, average + sdFactor*sdev)
            
            if (sdFactor >= 0) {
              
              bot[,'Color'] <- with(bot, ifelse(RollingRate > Limits, 'Review', 'Pass'))
            }
            
            else if (sdFactor < 0) {
              
              bot[,'Color'] <- with(bot, ifelse(RollingRate < Limits, 'Review', 'Pass'))
            }
            out <- rbind(out, bot)
          }
        }
      }
      return(out)
    }
    
    # do the same thing as above, but for only one level
    else if(length(partitionVec)==1) {
      topCol <- partitionVec[1]
      topVars <- as.character(unique(dataFrame[ ,topCol]))
      
      for (i in 1:length(topVars)) {
        bot <- dataFrame[dataFrame[,topCol]==topVars[i], ]
        biggest <- max(bot[ ,'RollingRate'], na.rm=TRUE)
        
        if(biggest <= alternativeLim) {
          
          bot[ ,'Color'] <- 'Pass'
          bot[ ,'Limits'] <- alternativeLim
          out <- rbind(out, bot)
        }
        
        else {
          
          bot[,'Limits'] <- with(bot, average + sdFactor*sdev)
          
          if (sdFactor >= 0) {
            
            bot[,'Color'] <- with(bot, ifelse(RollingRate > Limits, 'Review', 'Pass'))
          }
          
          else if (sdFactor < 0) {
            
            bot[,'Color'] <- with(bot, ifelse(RollingRate < Limits, 'Review', 'Pass'))
          }
          out <- rbind(out, bot)
        }
      }
      return(out)
    }
  }
  
  else {
    
    # if there are three levels in the partition vector (i.e. Version, Key, RecordedValue)
    if(length(partitionVec)==3) {
      # the top level is Version, get all versions
      topCol <- partitionVec[1]
      topVars <- as.character(unique(dataFrame[ ,topCol]))
      
      for (i in 1:length(topVars)) {
        # for each version, make a sub-frame of each key
        top <- dataFrame[dataFrame[,topCol]==topVars[i], ]
        midCol <- partitionVec[2]
        midVars <- as.character(unique(top[ ,midCol]))
        
        for (j in 1:length(midVars)) {
          # for each key, make a sub-frame of each recorded value
          mid <- top[top[,midCol]==midVars[j], ]
          botCol <- partitionVec[3]
          botVars <- as.character(unique(mid[,botCol]))
          
          for (k in 1:length(botVars)) {
            # iterate for the unique combo of Version+Key+RecordedValue and mark for review
            bot <- mid[mid[,botCol]==botVars[k], ]
            bot[,'Limits'] <- with(bot, average + sdFactor*sdev)
            
            if (sdFactor >= 0) {
              
              bot[,'Color'] <- with(bot, ifelse(RollingRate > Limits, 'Review', 'Pass'))
            }
            else if (sdFactor < 0) {
              
              bot[,'Color'] <- with(bot, ifelse(RollingRate < Limits, 'Review', 'Pass'))
            }
            out <- rbind(out, bot)
          }
        }
      }
      return(out)
    }
    
    # do the same thing as the if statement above, but only for two levels, not three
    else if(length(partitionVec)==2) {
      topCol <- partitionVec[1]
      topVars <- as.character(unique(dataFrame[ ,topCol]))
      
      for (i in 1:length(topVars)) {
        top <- dataFrame[dataFrame[,topCol]==topVars[i], ]
        botCol <- partitionVec[2]
        botVars <- as.character(unique(top[ ,botCol]))
        
        for (j in 1:length(botVars)) {
          bot <- top[top[,botCol]==botVars[j], ]
          bot[,'Limits'] <- with(bot, average + sdFactor*sdev)
          
          if (sdFactor >= 0) {
            
            bot[,'Color'] <- with(bot, ifelse(RollingRate > Limits, 'Review', 'Pass'))
          }
          else if (sdFactor < 0) {
            
            bot[,'Color'] <- with(bot, ifelse(RollingRate < Limits, 'Review', 'Pass'))
          }
          out <- rbind(out, bot)
        }
      }
      return(out)
    }
    
    # do the same thing as above, but for only one level
    else if(length(partitionVec)==1) {
      topCol <- partitionVec[1]
      topVars <- as.character(unique(dataFrame[ ,topCol]))
      
      for (i in 1:length(topVars)) {
        bot <- dataFrame[dataFrame[,topCol]==topVars[i], ]
        bot[,'Limits'] <- with(bot, average + sdFactor*sdev)
        
        if (sdFactor >= 0) {
          
          bot[,'Color'] <- with(bot, ifelse(RollingRate > Limits, 'Review', 'Pass'))
        }
        else if (sdFactor < 0) {
          
          bot[,'Color'] <- with(bot, ifelse(RollingRate < Limits, 'Review', 'Pass'))
        }
        out <- rbind(out, bot)
      }
      return(out)
    }
  }
}   

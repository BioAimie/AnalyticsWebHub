makeTimeStamp <- function(timeStamp = Sys.time(), author=NULL, size = 1, color = 'black')
{
  library(grid)
  
  stamp <- ifelse(is.null(author), as.character(timeStamp), paste(timeStamp, paste('Created by', author)))
  
  pushViewport(viewport())
  
  grid.text(label = stamp,
            x = unit(1,"npc") - unit(2, "mm"),
            y = unit(2, "mm"),
            just = c("right", "bottom"),
            gp = gpar(cex = size, col = color))
  
  popViewport()
}


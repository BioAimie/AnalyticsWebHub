createPaletteOfVariableLength <- function(dataFrame, colorVariable, greyscale=FALSE) {
  
  colorNames <- unique(dataFrame[,colorVariable])[order(unique(dataFrame[,colorVariable]))]
  numberOfColors <- length(colorNames)
  if(greyscale == FALSE & numberOfColors > 10) {
    
    colorVector <- c('midnightblue','steelblue4','royalblue1','steelblue1','slategray3','orangered3','tomato2','orange','sienna1','mediumorchid3','mediumpurple4','orchid',
                     'plum3','green4','limegreen','seagreen3','seagreen1','palegreen','turquoise4','lightseagreen','cyan','mediumvioletred','maroon1','hotpink','lightcoral','goldenrod',
                     'khaki','lightgoldenrodyellow','red4','red','firebrick1','lightslateblue','lightskyblue4','grey29','grey47','seashell4','grey80')
    myPal <- colorRampPalette(colorVector[1:numberOfColors])(numberOfColors)
  } else if(greyscale == TRUE) {
    
    myPal <- grey.colors(numberOfColors, start=0.8, end=0.2)
  } else {
    
    colorVector <- c('cornflowerblue','chocolate1','blueviolet','gold','darkred','forestgreen','dodgerblue','coral1','darkmagenta','olivedrab3')
    myPal <- colorRampPalette(colorVector[1:numberOfColors])(numberOfColors)
  }

  names(myPal) <- colorNames
  return(myPal)
}
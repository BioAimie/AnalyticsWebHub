createPaletteOfVariableLength <- function(dataFrame, colorVariable) {
  
  colorNames <- unique(dataFrame[,colorVariable])[order(unique(dataFrame[,colorVariable]))]
  numberOfColors <- length(colorNames)
  colorVector <- c('steelblue4','steelblue2','aquamarine','chocolate1','peachpuff4','darkorchid','forestgreen','gold','darkturquoise','deeppink',
                   'moccasin','darkred','mediumpurple1','midnightblue','orangered','seagreen3','royalblue1','thistle1','tomato','yellow1','slategrey',
                   'springgreen3','violet','orange1','darkolivegreen','cyan','brown1','blue','chartreuse2','darkmagenta','dimgrey','darksalmon')
  myPal <- colorRampPalette(colorVector[1:numberOfColors])(numberOfColors)
  names(myPal) <- colorNames
  return(myPal)
}
getPartNumber <- function(partDescrip) {
  
  partNumber <- switch(partDescrip,
                       'FLM1-GAS-0015: Urethane Hard Seal Sheet' = 'FLM1-GAS-0015',
                       'FLM1-MOD-0014: Manifold Hard Seal Gasket' = 'FLM1-MOD-0014',
                       'FLM1-MOL-0023: Molded Bladder' = 'FLM1-MOL-0023',
                       'WIRE-HAR-0554: Crimped Individual Valve' = 'WIRE-HAR-0554',
                       'FLM1-SUB-0029: Peltier Subassembly' = 'FLM1-SUB-0029',
                       'FLM1-GAS-0006: End Plate Gasket' = 'FLM1-GAS-0006',
                       'FLM1-GAS-0009: Manifold Gasket' = 'FLM1-GAS-0009',
                       'FLM1-MAC-0285: Sample Plunger' = 'FLM1-MAC-0285',
                       'WIRE-HAR-0211: 1.5 LED' = 'WIRE-HAR-0211',
                       'PCBA-SUB-0856: 2.0 LED' = 'PCBA-SUB-0856',
                       'FLM1-SUB-0044: Window Bladder' = 'FLM1-SUB-0044'
                       )
  
  return(partNumber)
}

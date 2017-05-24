SELECT
       S.[PouchSerialNumber] AS [PouchSerialNumber],
       iif(D.[Run Observation] is not null, 1, 0) as [Anomaly]
FROM [PMS1].[dbo].[SPC2014] S WITH(NOLOCK) LEFT JOIN [PMS1].[dbo].[SPC2014RunObservations] R WITH(NOLOCK)
       ON S.[PouchSerialNumber] = R.[PouchSerialNumber]
       LEFT JOIN [PMS1].[dbo].[SPC2014_DL_RunObservation] D WITH(NOLOCK) 
              ON R.[RunObservations] = D.[ID]
ORDER BY [StartTime] DESC


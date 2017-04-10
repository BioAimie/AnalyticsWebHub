SELECT
	S.[StartTime] AS [Start Time],
	S.[PouchLotNumber] AS [Pouch Lot Number],
	S.[PouchSerialNumber] AS [Pouch Serial Number],
	S.[SampleId] AS [Sample ID],
	CASE RTRIM(LTRIM(S.[Control_Failures]))
		WHEN 'PCR2, yeastDNA' THEN 'yeastDNA, PCR2'		
		WHEN 'PCR2, yeastRNA' THEN 'yeastRNA, PCR2'
		WHEN 'yeastDNA, yeastRNA' THEN 'yeastRNA, yeastDNA'
		WHEN 'yeastRNA, PCR2, yeastDNA' THEN 'yeastRNA, yeastDNA, PCR2'
		WHEN 'yeastDNA, yeastRNA, PCR2' THEN 'yeastRNA, yeastDNA, PCR2'
		WHEN 'yeastDNA, PCR2, yeastRNA' THEN 'yeastRNA, yeastDNA, PCR2'
		WHEN 'PCR2, yeastRNA, yeastDNA' THEN 'yeastRNA, yeastDNA, PCR2'
		WHEN 'PCR2, yeastDNA, yeastRNA' THEN 'yeastRNA, yeastDNA, PCR2'
	ELSE RTRIM(LTRIM(S.[Control_Failures])) 
	END AS [Control Failures],
	S.[False_Negatives] AS [False Negatives],
	S.[False_Positives] AS [False Positives],
	S.[PouchTitle] AS [PouchTitle],
	S.[InstrumentSerialNumber] AS [Instrument Serial Number],
	S.[UserId] AS [User ID],
	D.[Run Observation],
	S.[PouchCode] AS [Pouch Code],
	S.[PouchLine] AS [Pouch Line],
	R.[RunObservations] AS [Run Observation ID]
FROM [PMS1].[dbo].[SPC2014] S WITH(NOLOCK) LEFT JOIN [PMS1].[dbo].[SPC2014RunObservations] R WITH(NOLOCK)
	ON S.[PouchSerialNumber] = R.[PouchSerialNumber]
	LEFT JOIN [PMS1].[dbo].[SPC2014_DL_RunObservation] D WITH(NOLOCK) 
		ON R.[RunObservations] = D.[ID]
ORDER BY [StartTime] DESC

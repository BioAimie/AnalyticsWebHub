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
	D.[RunObservation] AS [Run Observation],
	S.[PouchCode] AS [Pouch Code],
	S.[PouchLine] AS [Pouch Line],
	R.[RunObservation] AS [Run Observation ID]
FROM [PMS1].[dbo].[SPCSummary] S WITH(NOLOCK) LEFT JOIN [PMS1].[dbo].[SPCRunObservations] R WITH(NOLOCK)
	ON S.[PouchSerialNumber] = R.[PouchSerialNumber]
	LEFT JOIN [PMS1].[dbo].[SPC_DL_RunObservations] D WITH(NOLOCK) 
		ON R.[RunObservation] = D.[ID]
ORDER BY [StartTime] DESC

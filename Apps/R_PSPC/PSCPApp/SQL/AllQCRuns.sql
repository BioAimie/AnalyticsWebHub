SET NOCOUNT ON

SELECT
	[Id],
	[PouchSerialNumber],
	[StartTime],
	[PouchLotNumber],
	[PouchTitle],
	[InstrumentSerialNumber],
	IIF([PouchTitle] LIKE 'Respiratory %', 'RP',
		IIF([PouchTitle] LIKE 'BCID %', 'BCID',
		IIF([PouchTitle] LIKE 'ME %', 'ME',
		IIF([PouchTitle] LIKE 'GI %', 'GI', [PouchTitle])))) AS [Panel],
	[SampleId]
INTO #FA15
FROM [FILMARRAYDB].[FilmArray1].[FilmArray].[ExperimentRun] WITH(NOLOCK)
WHERE CAST([StartTime] AS DATE) >= '2012-01-01' AND [SampleId] LIKE 'QC[_]%' AND
(
	[PouchTitle] LIKE 'Respiratory Panel v%' OR 
	[PouchTitle] LIKE 'BCID Panel v%' OR 
	[PouchTitle] LIKE 'ME Panel v%' OR 
	[PouchTitle] LIKE 'GI Panel v%' OR
	[PouchTitle] LIKE 'Respiratory Panel IVD v1.6' OR
	[PouchTitle] LIKE 'Respiratory Panel RUO v1.6'
) AND [PouchLotNumber] NOT LIKE '%[^0-9]%' AND [ExperimentStatus] LIKE 'Completed'

SELECT 
	[Id],
	[PouchSerialNumber],
	[StartTime],
	[PouchLotNumber],
	[PouchTitle],
	[InstrumentSerialNumber],
	IIF([PouchTitle] LIKE 'Respiratory %', 'RP',
		IIF([PouchTitle] LIKE 'BCID %', 'BCID',
		IIF([PouchTitle] LIKE 'ME %', 'ME',
		IIF([PouchTitle] LIKE 'GI %', 'GI', [PouchTitle])))) AS [Panel],
	[SampleId]
INTO #FA20
FROM [FILMARRAYDB].[FilmArray2].[dbo].[ExperimentRun] WITH(NOLOCK)
WHERE CAST([StartTime] AS DATE) >= '2012-01-01' AND [SampleId] LIKE 'QC[_]%' AND
(
	[PouchTitle] LIKE 'Respiratory Panel v%' OR 
	[PouchTitle] LIKE 'BCID Panel v%' OR 
	[PouchTitle] LIKE 'ME Panel v%' OR 
	[PouchTitle] LIKE 'GI Panel v%' OR
	[PouchTitle] LIKE 'Respiratory Panel IVD v1.6' OR
	[PouchTitle] LIKE 'Respiratory Panel RUO v1.6'
) AND [PouchLotNumber] NOT LIKE '%[^0-9]%' AND [ExperimentStatus] LIKE 'Completed'

SELECT 
	[Id],
	[PouchSerialNumber],
	[StartTime],
	[PouchLotNumber],
	[PouchTitle],
	[InstrumentSerialNumber],
	[Panel],
	[SampleId],
	IIF(CAST([StartTime] AS DATE) >= CAST(GETDATE() - 30 AS DATE), 1, 0) AS [ThirtyDayRun],
	IIF(CAST([StartTime] AS DATE) >= CAST(GETDATE() - 90 AS DATE), 1, 0) AS [NinetyDayRun],
	IIF(CAST([StartTime] AS DATE) >= CAST(GETDATE() - 90 AS DATE) AND CAST([StartTime] AS DATE) < CAST(GETDATE() - 30 AS DATE), 1, 0) AS [NinetyDayRunNet],
	1 AS [Record]
INTO #AllQCRuns
FROM #FA15
WHERE [PouchLotNumber] NOT IN ('00076473','00105714','00212947')
UNION
SELECT
	[Id],
	[PouchSerialNumber],
	[StartTime],
	[PouchLotNumber],
	[PouchTitle],
	[InstrumentSerialNumber],
	[Panel],
	[SampleId],
	IIF(CAST([StartTime] AS DATE) >= CAST(GETDATE() - 30 AS DATE), 1, 0) AS [ThirtyDayRun],
	IIF(CAST([StartTime] AS DATE) >= CAST(GETDATE() - 90 AS DATE), 1, 0) AS [NinetyDayRun],
	IIF(CAST([StartTime] AS DATE) >= CAST(GETDATE() - 90 AS DATE) AND CAST([StartTime] AS DATE) < CAST(GETDATE() - 30 AS DATE), 1, 0) AS [NinetyDayRunNet],
	1 AS [Record]
FROM #FA20
WHERE [PouchLotNumber] NOT IN ('00076473','00105714','00212947')

SELECT
	YEAR(Q.[StartTime]) AS [Year],
	MONTH(Q.[StartTime]) AS [Month],
	DATEPART(ww, Q.[StartTime]) AS [Week],
	Q.[StartTime],
	Q.[PouchSerialNumber],
	Q.[PouchLotNumber],
	Q.[PouchTitle],
	Q.[InstrumentSerialNumber],
	Q.[Panel],
	Q.[SampleId],
	IIF(Q.[SampleId] LIKE '%Alpha%', 'Alpha',
		IIF(Q.[SampleId] LIKE '%Beta%', 'Beta',
		IIF(Q.[SampleId] LIKE '%Gamma%', 'Gamma',
		IIF(Q.[SampleId] LIKE '%Negative%', 'Negative',
		IIF(Q.[SampleId] LIKE '%Omega%', 'Omega', 'Other'))))) AS [Mix],
	RTRIM(LTRIM(S.[Control_Failures])) AS [Control_Failures],
	S.[False_Negatives],
	S.[False_Positives],
	IIF(S.[Control_Failures] IS NOT NULL, 1, 0) AS [CF],
	IIF(S.[False_Negatives] IS NOT NULL, 1, 0) AS [FN],
	IIF(S.[False_Positives] IS NOT NULL, 1, 0) AS [FP],
	D.[Run Observation] AS [RunObservation],
	Q.[ThirtyDayRun],
	Q.[NinetyDayRun],
	Q.[NinetyDayRunNet],
	'PouchQC' AS [Key],
	Q.[Record]
INTO #Master
FROM #AllQCRuns Q LEFT JOIN [PMS1].[dbo].[SPC2014] S WITH(NOLOCK)
	ON Q.[Id] = S.[ExperimentId]
	LEFT JOIN [PMS1].[dbo].[SPC2014RunObservations] R WITH(NOLOCK)
		ON S.[PouchSerialNumber] = R.[PouchSerialNumber] 
		LEFT JOIN [PMS1].[dbo].[SPC2014_DL_RunObservation] D WITH(NOLOCK) 
			ON R.[RunObservations] = D.[ID]

SELECT
	[Year],
	[Month],
	[Week],
	[StartTime],
	[PouchSerialNumber],
	[PouchLotNumber],
	[PouchTitle],
	[InstrumentSerialNumber],
	[Panel],
	[SampleId],
	[Mix],
	CASE [Control_Failures]
		WHEN 'PCR2, yeastDNA' THEN 'yeastDNA, PCR2'		
		WHEN 'PCR2, yeastRNA' THEN 'yeastRNA, PCR2'
		WHEN 'yeastDNA, yeastRNA' THEN 'yeastRNA, yeastDNA'
		WHEN 'yeastRNA, PCR2, yeastDNA' THEN 'yeastRNA, yeastDNA, PCR2'
		WHEN 'yeastDNA, yeastRNA, PCR2' THEN 'yeastRNA, yeastDNA, PCR2'
		WHEN 'yeastDNA, PCR2, yeastRNA' THEN 'yeastRNA, yeastDNA, PCR2'
		WHEN 'PCR2, yeastRNA, yeastDNA' THEN 'yeastRNA, yeastDNA, PCR2'
		WHEN 'PCR2, yeastDNA, yeastRNA' THEN 'yeastRNA, yeastDNA, PCR2'
	ELSE [Control_Failures] 
	END AS [Control_Failures],
	[False_Negatives],
	[False_Positives],
	[CF],
	[FN],
	[FP],
	[RunObservation],
	[ThirtyDayRun],
	[NinetyDayRun],
	[NinetyDayRunNet],
	[Key],
	[Record]
FROM #Master
ORDER BY [StartTime] DESC

DROP TABLE #FA15, #FA20, #AllQCRuns, #Master


SET NOCOUNT ON

SELECT
	R.[StartTime],
	R.[PouchSerialNumber],
	R.[PouchLotNumber],
	R.[PouchTitle],
	R.[SampleId],
	R.[InstrumentSerialNumber],
	R.[RunStatus],
	RR.[Cp],
	A.[Result],
	S.[Name]
INTO #fa1
FROM [FILMARRAYDB].[FilmArray1].[FilmArray].[ExperimentRun] R WITH(NOLOCK) INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[MetaAnalysis] M WITH(NOLOCK) ON R.[Id] = M.[experiment_id] 
	INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[ReactionResult] RR WITH(NOLOCK) ON M.[Id] = RR.[analysis_id]
	INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[AssayResult_ReactionResult] AR WITH(NOLOCK) ON RR.[Id] = AR.[reaction_result_id]
	INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[AssayResult] A WITH(NOLOCK) ON AR.[assay_result_id] = A.[Id]
	INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[Assay] S WITH(NOLOCK) ON A.[assay_id] = S.[Id]
WHERE [RunStatus] LIKE 'Completed' AND [SampleId] LIKE '%BR_Pool%' AND [StartTime] >= GETDATE()-500

SELECT
	R.[StartTime],
	R.[PouchSerialNumber],
	R.[PouchLotNumber],
	R.[PouchTitle],
	R.[SampleId],
	R.[InstrumentSerialNumber],
	R.[RunStatus],
	RR.[Cp],
	A.[Result],
	S.[Name]
INTO #fa2
FROM [FILMARRAYDB].[FilmArray2].[dbo].[ExperimentRun] R WITH(NOLOCK) INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[MetaAnalysis] M WITH(NOLOCK) ON R.[Id] = M.[experiment_id] 
	INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[ReactionResult] RR WITH(NOLOCK) ON M.[Id] = RR.[analysis_id]
	INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[AssayResult_ReactionResult] AR WITH(NOLOCK) ON RR.[Id] = AR.[reaction_result_id]
	INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[AssayResult] A WITH(NOLOCK) ON AR.[assay_result_id] = A.[Id]
	INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[Assay] S WITH(NOLOCK) ON A.[assay_id] = S.[Id]
WHERE [RunStatus] LIKE 'Completed' AND [SampleId] LIKE '%BR_Pool%' AND [StartTime] >= GETDATE()-500

SELECT	
	CAST([StartTime] AS DATE) AS [Date],
	[PouchSerialNumber],
	[InstrumentSerialNumber],
	IIF([PouchTitle] LIKE '%Respiratory Panel%', 'RP',
		IIF([PouchTitle] LIKE '%GI%', 'GI',
		IIF([PouchTitle] LIKE '%BCID%','BCID',
		IIF([PouchTitle] LIKE '%ME%', 'ME', 'Other')))) AS [Panel],
	IIF([Name] LIKE '%HRV%', 'HRV', [Name]) AS [Name],
	[Result],
	[Cp], 
	SUBSTRING([SampleId], 8, CHARINDEX('_', [SampleId], 8)-8) AS [Pool], 
	IIF([Name] LIKE 'PCR%' OR [Name] LIKE 'yeast%', 'No Contamination',
		IIF([Result] LIKE 'Positive', 'Contamination', 'No Contamination')) AS [ConStatus],
	'fa1' as [DB]
INTO #allRuns
FROM #fa1
UNION ALL
SELECT	
	CAST([StartTime] AS DATE) AS [Date],
	[PouchSerialNumber],
	[InstrumentSerialNumber],
	IIF([PouchTitle] LIKE '%Respiratory Panel%', 'RP',
		IIF([PouchTitle] LIKE '%GI%', 'GI',
		IIF([PouchTitle] LIKE '%BCID%','BCID',
		IIF([PouchTitle] LIKE '%ME%', 'ME', 'Other')))) AS [Panel],
	IIF([Name] LIKE '%HRV%', 'HRV', [Name]) AS [Name],
	[Result],
	[Cp], 
	SUBSTRING([SampleId], 8, CHARINDEX('_', [SampleId], 8)-8) AS [Pool], 
	IIF([Name] LIKE 'PCR%' OR [Name] LIKE 'yeast%', 'No Contamination',
		IIF([Result] LIKE 'Positive', 'Contamination', 'No Contamination')) AS [ConStatus],
	'fa2' as [DB]
FROM #fa2
ORDER BY [Date] 

SELECT 
	YEAR([Date]) AS [Year],
	MONTH([Date]) AS [Month],
	DATEPART(ww, [Date]) AS [Week],
	[PouchSerialNumber] AS [PouchSerial],
	[InstrumentSerialNumber] AS [InstrumentSerial],
	[Panel],
	[Name] AS [Assay],
	[Result],
	[Cp],
	UPPER(RTRIM(LTRIM([Pool]))) AS [Pool],
	[ConStatus],
	'Pool' AS [Key],
	1 AS [Record],
	[DB]  
FROM #allRuns
ORDER BY [PouchSerial], [Assay]  

DROP TABLE #fa1, #fa2, #allRuns

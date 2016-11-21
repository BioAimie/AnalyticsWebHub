SET NOCOUNT ON

SELECT 
	[PouchSerialNumber]
INTO #filteredRuns
FROM [FILMARRAYDB].[FilmArray2].[dbo].[ExperimentRun] E WITH(NOLOCK)
WHERE E.[StartTime] > GETDATE() - 400 AND E.[PouchTitle] LIKE '%Panel%' AND E.[SampleType] NOT LIKE 'Custom' AND E.[SampleId] NOT LIKE 'Anonymous'

SELECT
	[PouchSerialNumber],
	[Name],
	AVG([Cp]) AS [AvgCp],
	AVG([Tm1]) AS [AvgTm1],
	AVG([Tm2]) AS [AvgTm2],
	AVG([MaxFluor]) AS [AvgFluor]
FROM [FILMARRAYDB].[FilmArray2].[dbo].[ExperimentRun] E WITH(NOLOCK) INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[MetaAnalysis] A WITH(NOLOCK)
	ON E.[Id] = A.[experiment_id] INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[AssayResult] R WITH(NOLOCK)
		ON A.[Id] = R.[analysis_id] INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[Assay] Y WITH(NOLOCK)
			ON R.[assay_id] = Y.[Id] INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[AssayResult_ReactionResult] S WITH(NOLOCK)
				ON R.[Id] = S.[assay_result_id] INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[ReactionResult] X WITH(NOLOCK)
					ON S.[reaction_result_id] = X.[Id]
WHERE [PouchSerialNumber] IN (SELECT [PouchSerialNumber] FROM #filteredRuns) AND [Name] IN ('PCR1','PCR2','yeastRNA','yeastDNA') AND [Cp] IS NOT NULL
GROUP BY 
	[PouchSerialNumber],
	[Name]

DROP TABLE #filteredRuns

SET NOCOUNT ON

SELECT
	[PouchSerialNumber],
	[Name],
	[Cp],
	[Tm1],
	[Tm2],
	[MaxFluor]
INTO #raw
FROM [FILMARRAYDB].[FilmArray1].[FilmArray].[ExperimentRun] E WITH(NOLOCK) INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[MetaAnalysis] A WITH(NOLOCK)
	ON E.[Id] = A.[experiment_id] INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[AssayResult] R WITH(NOLOCK)
		ON A.[Id] = R.[analysis_id] INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[Assay] Y WITH(NOLOCK)
			ON R.[assay_id] = Y.[Id] INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[AssayResult_ReactionResult] S WITH(NOLOCK)
				ON R.[Id] = S.[assay_result_id] INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[ReactionResult] X WITH(NOLOCK)
					ON S.[reaction_result_id] = X.[Id]
WHERE [Name] LIKE 'yeast%' AND [Cp] IS NOT NULL AND [StartTime] > GETDATE() - 400

SELECT 
	[PouchSerialNumber],
	[Name],
	AVG([Cp]) AS [AvgCp],
	AVG([Tm1]) AS [AvgTm1],
	AVG([Tm2]) AS [AvgTm2],
	AVG([MaxFluor]) AS [AvgFluor]
FROM #raw
GROUP BY [PouchSerialNumber], [Name]

DROP TABLE #raw
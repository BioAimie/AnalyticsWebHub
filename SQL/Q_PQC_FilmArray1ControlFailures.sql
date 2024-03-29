SET NOCOUNT ON

SELECT
	R.[StartTime] AS [Date],
	R.[PouchSerialNumber] AS [SerialNo],
	R.[PouchLotNumber] AS [LotNo],
	R.[SampleId] AS [SampleId],
	T.[Name] AS [ControlName],
	TR.[Result] AS [Result]
INTO #fa1
FROM [FILMARRAYDB].[FilmArray1].[FilmArray].[Target_Assay] TA WITH(NOLOCK) INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[Target] T WITH(NOLOCK)
	ON TA.[target_id] = T.[Id] INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[TargetResult] TR WITH(NOLOCK)
		ON T.[Id] = TR.[target_id] INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[MetaAnalysis] A WITH(NOLOCK)
			ON TR.[analysis_id] = A.[Id] INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[ExperimentRun] R WITH(NOLOCK)
				ON A.[experiment_id] = R.[Id]
WHERE TR.[TypeCode] = 'control' AND 
(
	R.[SampleId] LIKE 'QC_RP%' OR 
	R.[SampleId] LIKE 'QC_BCID%' OR 
	R.[SampleId] LIKE 'QC_GI%' OR
	R.[SampleId] LIKE 'QC_ME%'
) AND R.[StartTime] >= GETDATE() - 800

SELECT
	YEAR([Date]) AS [Year],
	DATEPART(ww,[Date]) AS [Week],
	[SerialNo],
	[LotNo],
	[SampleId],
	SUM([FailFlag]) AS [ControlsFailing]
INTO #qcRunsWithFailFlag
FROM
(
	SELECT *,
		IIF([Result] LIKE 'Pass', 0, 1) AS [FailFlag]
	FROM #fa1
) T
GROUP BY
	YEAR([Date]),
	DATEPART(ww,[Date]),
	[SerialNo],
	[LotNo],
	[SampleId]

SELECT
	[Year],
	[Week],
	[SerialNo],
	IIF([SampleId] LIKE '%_RP%', 'RP',
		IIF([SampleId] LIKE '%_GI%', 'GI',
		IIF([SampleId] LIKE '%_BCID%', 'BCID',
		IIF([SampleId] LIKE '%_ME%', 'ME', 'Other')))) AS [Version],
	IIF([ControlsFailing] > 0, 'ControlFailure', 'NoFailure') AS [Key],
	[LotNo],
	1 AS [Record]
FROM #qcRunsWithFailFlag

DROP TABLE #fa1, #qcRunsWithFailFlag

SET NOCOUNT ON

SELECT 
	R.[StartTime] AS [Date], --Remove
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
WHERE TR.[TypeCode] LIKE 'control' AND R.[RunStatus] LIKE 'Completed' AND R.[SampleId] LIKE 'QC[_]%' AND RIGHT(R.[PouchLotNumber],2) IN ('15','16')


SELECT
	YEAR([Date]) AS [Year], --Remove
	DATEPART(ww,[Date]) AS [Week], --Remove
	[SerialNo],
	[LotNo],
	[SampleId],
	SUM([FailFlag]) AS [ControlsFailing]
INTO #qcRunsWithFailFlag
FROM
(
	SELECT *,
	DATEPART(ww,[Date]) AS [Week],
		IIF([Result] LIKE 'Pass', 0, 1) AS [FailFlag]
	FROM #fa1
	WHERE [ControlName] NOT LIKE 'PCR1 Control'
) T
GROUP BY
	YEAR([Date]), --Remove
	DATEPART(ww,[Date]), --Remove
	[SerialNo],
	[LotNo],
	[SampleId]

SELECT
	[Year], --Remove
	[Week], --Remove
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
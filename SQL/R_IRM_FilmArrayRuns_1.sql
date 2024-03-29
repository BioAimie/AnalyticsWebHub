SELECT
	[PouchSerialNumber],
	[PouchTitle],
	[SampleId],
	[SampleType],
	[RunStatus],
	[StartTime],
	YEAR([StartTime]) AS [Year],
	DATEPART(ww,[StartTime]) AS [Week],
	DATEDIFF(n,[StartTime],[EndTime]) AS [MinutesRun],
	[UserID],
	[InstrumentSerialNumber],
	[InstrumentProtocolVersion],
	[ComputerName]
FROM [FILMARRAYDB].[FilmArray1].[FilmArray].[ExperimentRun] R WITH(NOLOCK)
WHERE LEFT([InstrumentSerialNumber],2) IN ('FA','2F','HT') AND [StartTime] > GETDATE() - 400 AND [SampleId] NOT LIKE 'Anonymous' 
		AND [SampleType] NOT LIKE 'Custom'
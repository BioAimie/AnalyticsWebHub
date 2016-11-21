SET NOCOUNT ON

SELECT DISTINCT 
	[SerialNo],
	[LotNo],
	[Status],
	[SampId],
	[Date],
	[Instrument],
	[PouchType]
INTO #base15
FROM [PMS1].[dbo].[tFluorQC_1_5] R WITH(NOLOCK) 
WHERE [Date] > GETDATE() - 400

SELECT 
	B.[SerialNo],
	B.[BaselineFluor] AS [BaselineFluorArray],
	M.[MaximumFluor] AS [MaximumFluorArray]
INTO #fluor15
FROM [PMS1].[dbo].[tFluorQC_1_5_baseline] B WITH(NOLOCK) INNER JOIN [PMS1].[dbo].[tFluorQC_1_5_maximum] M WITH(NOLOCK)
	ON B.[SerialNo] = M.[SerialNo]
GROUP BY 
	B.[SerialNo],
	B.[BaselineFluor],
	M.[MaximumFluor]

SELECT 
	R.[SerialNo],
	R.[LotNo],
	R.[Status],
	R.[SampId],
	R.[Date],
	R.[Instrument],
	R.[PouchType],
	F.[BaselineFluorArray],
	F.[MaximumFluorArray]
INTO #oneFive
FROM #base15 R INNER JOIN #fluor15 F
	ON R.[SerialNo] = F.[SerialNo]
WHERE [PouchType] LIKE 'Instrument QC v1.%'

SELECT
	[SerialNo],
	[LotNo],
	[Status],
	[SampId],
	[Date],
	[Instrument],
	[PouchType],
	[BaselineFluorArray],
	[MaximumFluorArray]
INTO #twoOh
FROM [PMS1].[dbo].[tFluorQC_2_0] WITH(NOLOCK)
WHERE [PouchType] LIKE 'Instrument QC v1.%' AND [Date] > GETDATE() - 400

SELECT 
	[dbKey],
	[PouchVersion],
	IIF([SampId] LIKE '%NewBuild%','Production',
		IIF([SampId] LIKE '%PouchQC%','PouchQC','Service')) AS [Department],
	[SerialNo],
	[LotNo],
	[SampId],
	[Year],
	[Month],
	[Week],
	[Instrument],
	[BaselineFluorArray],
	[MaximumFluorArray]
INTO #master
FROM
(
	SELECT 
		[SerialNo],
		[LotNo],
		[Status],
		[SampId],
		YEAR([Date]) AS [Year],
		MONTH([Date]) AS [Month],
		DATEPART(ww,[Date]) AS [Week],
		[Instrument],
		[PouchType],
		RIGHT([PouchType],3) AS [PouchVersion],
		'2.0' AS [dbKey],
		[BaselineFluorArray],
		[MaximumFluorArray]
	FROM #twoOh
	UNION
	SELECT 
		[SerialNo],
		[LotNo],
		[Status],
		[SampId],
		YEAR([Date]) AS [Year],
		MONTH([Date]) AS [Month],
		DATEPART(ww,[Date]) AS [Week],
		[Instrument],
		[PouchType],
		RIGHT([PouchType],3) AS [PouchVersion],
		'1.5' AS [dbKey],
		[BaselineFluorArray],
		[MaximumFluorArray]
	FROM #oneFive
) D
WHERE [SampId] LIKE '%NewBuild%' OR [SampId] LIKE '%PostRepair%' OR [SampId] LIKE '%PouchQC%'

SELECT *
INTO #protocolNo
FROM
(
	SELECT
		[PouchSerialNumber] AS [SerialNo],
		[SampleType] AS [Protocol]
	FROM [FILMARRAYDB].[FilmArray2].[dbo].[ExperimentRun] WITH(NOLOCK)
	WHERE [PouchSerialNumber] IN (SELECT [SerialNo] FROM #master)
	UNION
	SELECT
		[PouchSerialNumber] AS [SerialNo],
		[SampleType] AS [Protocol]
	FROM [FILMARRAYDB].[FilmArray1].[FilmArray].[ExperimentRun] WITH(NOLOCK)
	WHERE [PouchSerialNumber] IN (SELECT [SerialNo] FROM #master)
) D

SELECT 
	[dbKey],
	[PouchVersion],
	[Department],
	[Instrument],
	IIF(LEFT([Instrument],2) IN ('FA','2F') AND [Protocol] LIKE 'QC v3.0', 'FA2.0',
		IIF([Protocol] LIKE 'QC v2.0', 'FA1.5', 
		IIF(LEFT([Instrument],2) IN ('HT','TM') AND [Protocol] LIKE 'QC v3.0', 'Torch', 'Other')))  AS [InstVersion],
	[LotNo],
	[Year],
	[Week],
	[BaselineFluorArray],
	[MaximumFluorArray]
FROM #master M LEFT JOIN #protocolNo P
	ON M.[SerialNo] = P.[SerialNo]
WHERE LEFT([Instrument],2) IN ('FA','2F','HT','TM') AND [Protocol] IS NOT NULL
ORDER BY [Year], [Week]

DROP TABLE #base15, #oneFive, #twoOh, #fluor15, #master, #protocolNo
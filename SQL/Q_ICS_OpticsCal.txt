SET NOCOUNT ON

SELECT
	[SerialNo],
	CAST(MIN([TranDate]) AS DATE) AS [BreakDate]
INTO #location
FROM [PMS1].[dbo].[vSerialTransactions] WITH(NOLOCK)
WHERE [TranType] LIKE 'SH' OR ([TranType] IN ('IS','SA') AND [DistQty] = -1)
GROUP BY [SerialNo]

SELECT
	[DateCalibrated],
	DATEADD(s, CONVERT(BIGINT, [lastUpdate]), CONVERT(DATETIME, '1-1-1970 00:00:00')) AS [lastUpdate],
	REPLACE(REPLACE(REPLACE([DateCalibrated], '/',''),'\',''),'-','') AS [DateStrip],
	RIGHT([DateCalibrated], 4) AS [Year],
	[SerialNumber],
	[DCID],
	[ChangeOrder],
	[LP65],
	[calcLP65],
	[LP65CoeffVerify.Result]
INTO #opticsRaw
FROM
(
	SELECT
		[id],
		[lastUpdate],
		[propertyName],
		[recordedValue]
	FROM [PMS1].[dbo].[tMongoICS_OpticsCal] WITH(NOLOCK)
	WHERE [propertyName] IN ('SerialNumber','DateCalibrated','ChangeOrder','DCID') OR [propertyName] LIKE '%LP65%'
) P PIVOT 
(
	MAX([recordedValue])
	FOR [propertyName]
	IN
	(
		[LP65],
		[LP65CoeffVerify.Actual],
		[LP65CoeffVerify.Result],
		[SerialNumber],
		[ChangeOrder],
		[LP65dac.value],
		[DateCalibrated],
		[LP65CoeffVerify.Expected],
		[LP65current.value],
		[DCID],
		[calcLP65]
	)
) PIV

SELECT
	*,
	IIF(CHARINDEX('-', [DateCalibrated], 1) <> 0, CAST([DateCalibrated] AS DATE),
		IIF([lastUpdate] < CONVERT(DATETIME, '2016-09-08'), CAST([DateCalibrated] AS DATE),
		IIF([lastUpdate] > CONVERT(DATETIME, '2016-11-29'), CAST([DateCalibrated] AS DATE), CAST('1900-01-01' AS DATE)))) AS [DateCalibratedInt]
INTO #byLastUpdate
FROM #opticsRaw
WHERE [DateCalibrated] IS NOT NULL AND CHARINDEX('/', [Year], 1) = 0

SELECT 
	[DateCalibrated],
	[lastUpdate],
	[DateStrip],
	[DateCalibratedInt],
	[SerialNumber],
	[DCID],
	[ChangeOrder],
	[LP65],
	[calcLP65],
	[LP65CoeffVerify.Result],
	IIF([DateCalibratedInt] = CONVERT(DATE, '1900-01-01') AND CAST(SUBSTRING([DateStrip], 1, 1) AS INT) > 1, CAST(SUBSTRING([DateStrip], 1, 1) AS INT), CAST(SUBSTRING([DateStrip], 1, 2) AS INT)) AS [Month],
	IIF([DateCalibratedInt] = CONVERT(DATE, '1900-01-01') AND CAST(SUBSTRING([DateStrip], 1, 1) AS INT) > 1 AND LEN([DateStrip]) = 6, CAST(SUBSTRING([DateStrip], 2, 1) AS INT),
		IIF([DateCalibratedInt] = CONVERT(DATE, '1900-01-01') AND CAST(SUBSTRING([DateStrip], 1, 1) AS INT) > 1 AND LEN([DateStrip]) = 7, CAST(SUBSTRING([DateStrip], 2, 2) AS INT), 
		IIF([DateCalibratedInt] = CONVERT(DATE, '1900-01-01') AND LEN([DateStrip]) = 7, CAST(SUBSTRING([DateStrip], 3, 1) AS INT), CAST(SUBSTRING([DateStrip], 3, 2) AS INT)))) AS [Day],
	IIF([DateCalibratedInt] = CONVERT(DATE, '1900-01-01'), CAST(RIGHT([DateStrip], 4) AS INT), 0) AS [Year]
INTO #fixedDate
FROM #byLastUpdate

SELECT
	IIF([DateCalibratedInt] = CONVERT(DATE, '1900-01-01'), CAST(CONCAT([Year],'-',[Month],'-',[Day]) AS DATE), [DateCalibrated]) AS [Date],
	[SerialNumber],
	[DCID],
	[ChangeOrder],
	[LP65],
	[calcLP65],
	[LP65CoeffVerify.Result]
INTO #optics
FROM #fixedDate

SELECT 
	YEAR(CAST([Date] AS DATE)) AS [Year],
	DATEPART(ww, CAST([Date] AS DATE)) AS [Week],
	[SerialNumber] AS [SerialNo],
	IIF(LEFT([SerialNumber], 2) IN ('FA','2F'), 'FA2.0', 'Torch') AS [Version], 
	[DCID],
	[ChangeOrder],
	[LP65],
	[calcLP65],
	[LP65CoeffVerify.Result] AS [LPResult],
	IIF(CAST([Date] AS DATE) < [BreakDate], 'Production',
		IIF([BreakDate] IS NULL, 'Production', 'Service')) AS [Location]
FROM #optics ICS LEFT JOIN #location L
	ON ICS.[SerialNumber] = L.[SerialNo]
WHERE [LP65CoeffVerify.Result] IS NOT NULL
ORDER BY [Date]

DROP TABLE #location, #opticsRaw, #byLastUpdate, #fixedDate, #optics
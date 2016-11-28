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
	--CAST([DateCalibrated] AS DATE) AS [Date],
	DATEADD(s, CONVERT(BIGINT, [lastUpdate]), CONVERT(DATETIME, '1-1-1970 00:00:00')) AS [lastUpdate],
	REPLACE(REPLACE(REPLACE([DateCalibrated], '/',''),'\',''),'-','') AS [DateStrip],
	[SerialNumber],
	[DCID],
	[ChangeOrder],
	[fluke_temp.Actual],
	[fluke_temp.Result],
	[sealbarCalibration.value],
	[Thermocouple.intercept],
	[Thermocouple.slope],
	[adc_value.Actual]
INTO #sealBarRaw
FROM
(
	SELECT *
	FROM [PMS1].[dbo].[tMongoICS_sealBarCal] WITH(NOLOCK)
	WHERE [propertyName] IN ('SerialNumber','DateCalibrated','ChangeOrder','DCID') OR [propertyName] LIKE '%fluke%' OR [propertyName] LIKE '%seal%'
		OR [propertyName] LIKE '%thermocouple%' OR [propertyName] LIKE 'adc_value.Actual'
) P PIVOT
(
	MAX([recordedValue])
	FOR [propertyName]
	IN
	(
		[ChangeOrder],
		[DateCalibrated],
		[DCID],
		[fluke_temp.Actual],
		[fluke_temp.Result],
		[sealbarCalibration.value],
		[SealBarFinalize.name],
		[sealBarStart.value],
		[SealPlungeTest.value],
		[SealTestPouch.value],
		[SerialNumber],
		[Thermocouple.intercept],
		[Thermocouple.name],
		[Thermocouple.slope],
		[adc_value.Actual]
	) 
) PIV

SELECT
	*,
	IIF(CHARINDEX('-', [DateCalibrated], 1) <> 0, CAST([DateCalibrated] AS DATE),
		IIF([lastUpdate] < CONVERT(DATETIME, '2016-09-08'), CAST([DateCalibrated] AS DATE),
		IIF([lastUpdate] > CONVERT(DATETIME, '2016-11-29'), CAST([DateCalibrated] AS DATE), CAST('1900-01-01' AS DATE)))) AS [DateCalibratedInt]
INTO #byLastUpdate
FROM #sealBarRaw
WHERE [DateCalibrated] IS NOT NULL

SELECT *,
	IIF([DateCalibratedInt] = CONVERT(DATE, '1900-01-01') AND CAST(SUBSTRING([DateStrip], 1, 1) AS INT) > 1, CAST(SUBSTRING([DateStrip], 1, 1) AS INT), CAST(SUBSTRING([DateStrip], 1, 2) AS INT)) AS [Month],
	IIF([DateCalibratedInt] = CONVERT(DATE, '1900-01-01') AND CAST(SUBSTRING([DateStrip], 1, 1) AS INT) > 1 AND LEN([DateStrip]) = 6, CAST(SUBSTRING([DateStrip], 2, 1) AS INT),
		IIF([DateCalibratedInt] = CONVERT(DATE, '1900-01-01') AND CAST(SUBSTRING([DateStrip], 1, 1) AS INT) > 1 AND LEN([DateStrip]) = 7, CAST(SUBSTRING([DateStrip], 2, 2) AS INT), 
		IIF([DateCalibratedInt] = CONVERT(DATE, '1900-01-01') AND LEN([DateStrip]) = 7, CAST(SUBSTRING([DateStrip], 3, 1) AS INT), CAST(SUBSTRING([DateStrip], 3, 2) AS INT)))) AS [Day],
	IIF([DateCalibratedInt] = CONVERT(DATE, '1900-01-01'), CAST(RIGHT([DateStrip], 4) AS INT), 0) AS [Year]
INTO #fixedDate
FROM #byLastUpdate

SELECT
	IIF([DateCalibratedInt] = CONVERT(DATE, '1900-01-01'), CAST(CONCAT([Year],'-',[Month],'-',[Day]) AS DATE), [DateCalibrated]) AS [Date],
	[lastUpdate],
	[SerialNumber],
	[DCID],
	[ChangeOrder],
	[fluke_temp.Actual],
	[fluke_temp.Result],
	[sealbarCalibration.value],
	[Thermocouple.intercept],
	[Thermocouple.slope],
	[adc_value.Actual]
INTO #sealBar
FROM #fixedDate

SELECT 
	YEAR([Date]) AS [Year],
	DATEPART(ww, [Date]) AS [Week],
	[SerialNumber] AS [SerialNo],
	IIF(LEFT([SerialNumber], 2) IN ('FA','2F'), 'FA2.0', 'Torch') AS [Version], 
	[DCID],
	[ChangeOrder],
	[fluke_temp.Actual] AS [flukeTemp],
	[fluke_temp.Result] AS [flukeResult],
	[sealbarCalibration.value] AS [sealBarResult],
	[Thermocouple.intercept] AS [intercept],
	[Thermocouple.slope] AS [slope],
	[adc_value.Actual] AS [ADC],
	IIF([Date] < [BreakDate], 'Production',
		IIF([BreakDate] IS NULL, 'Production', 'Service')) AS [Location]
FROM #sealBar ICS LEFT JOIN #location L
	ON ICS.[SerialNumber] = L.[SerialNo]
WHERE [Date] > GETDATE() - 400 AND [sealbarCalibration.value] IS NOT NULL
ORDER BY [Date]

DROP TABLE #location, #byLastUpdate, #fixedDate, #sealBar, #sealBarRaw
SET NOCOUNT ON

SELECT
	[SerialNo],
	CAST(MIN([TranDate]) AS DATE) AS [BreakDate]
INTO #location
FROM [PMS1].[dbo].[vSerialTransactions] WITH(NOLOCK)
WHERE [TranType] LIKE 'SH' OR ([TranType] IN ('IS','SA') AND [DistQty] = -1)
GROUP BY [SerialNo]

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
FROM
(
	SELECT
		CAST([DateCalibrated] AS DATE) AS [Date],
		[SerialNumber],
		[DCID],
		[ChangeOrder],
		[fluke_temp.Actual],
		[fluke_temp.Result],
		[sealbarCalibration.value],
		[Thermocouple.intercept],
		[Thermocouple.slope],
		[adc_value.Actual]
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
	WHERE CAST([DateCalibrated] AS DATETIME) > GETDATE() - 400 AND [sealbarCalibration.value] IS NOT NULL
) ICS LEFT JOIN #location L
	ON ICS.[SerialNumber] = L.[SerialNo]
ORDER BY [Date]

DROP TABLE #location
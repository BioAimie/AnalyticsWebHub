SET NOCOUNT ON

SELECT 
	[SerialNumber],
	CAST([DateCalibrated] AS DATE) AS [Date],
	[DCID],
	[ChangeOrder],
	[pcr1check_50.thermocouple] AS [pcr1_50therm],
	[pcr1check_50.instrumenttemp] AS [pcr1_50inst],
	[pcr1check_50.error] AS [pcr1_50error],
	50 AS [pcr1_50target],
	[pcr1check_60.thermocouple] AS [pcr1_60therm],
	[pcr1check_60.instrumenttemp] AS [pcr1_60inst],
	[pcr1check_60.error] AS [pcr1_60error],
	60 AS [pcr1_60target],
	[pcr1check_70.thermocouple] AS [pcr1_70therm],
	[pcr1check_70.instrumenttemp] AS [pcr1_70inst],
	[pcr1check_70.error] AS [pcr1_70error],
	70 AS [pcr1_70target],
	[pcr1check_80.thermocouple] AS [pcr1_80therm],
	[pcr1check_80.instrumenttemp] AS [pcr1_80inst],
	[pcr1check_80.error] AS [pcr1_80error],
	80 AS [pcr1_80target],
	[pcr1check_90.thermocouple] AS [pcr1_90therm],
	[pcr1check_90.instrumenttemp] AS [pcr1_90inst],
	[pcr1check_90.error] AS [pcr1_90error],
	90 AS [pcr1_90target],
	[pcr2check_50.thermocouple] AS [pcr2_50therm],
	[pcr2check_50.instrumenttemp] AS [pcr2_50inst],
	[pcr2check_50.error] AS [pcr2_50error],
	50 AS [pcr2_50target],
	[pcr2check_60.thermocouple] AS [pcr2_60therm],
	[pcr2check_60.instrumenttemp] AS [pcr2_60inst],
	[pcr2check_60.error] AS [pcr2_60error],
	60 AS [pcr2_60target],
	[pcr2check_70.thermocouple] AS [pcr2_70therm],
	[pcr2check_70.instrumenttemp] AS [pcr2_70inst],
	[pcr2check_70.error] AS [pcr2_70error],
	70 AS [pcr2_70target],
	[pcr2check_80.thermocouple] AS [pcr2_80therm],
	[pcr2check_80.instrumenttemp] AS [pcr2_80inst],
	[pcr2check_80.error] AS [pcr2_80error],
	80 AS [pcr2_80target],
	[pcr2check_90.thermocouple] AS [pcr2_90therm],
	[pcr2check_90.instrumenttemp] AS [pcr2_90inst],
	[pcr2check_90.error] AS [pcr2_90error],
	90 AS [pcr2_90target]
INTO #tempCal
FROM
(
	SELECT *
	FROM [PMS1].[dbo].[tMongoICS_TempCal] WITH(NOLOCK)
	WHERE [propertyName] IN ('SerialNumber','DateCalibrated','ChangeOrder','DCID') OR [propertyName] LIKE 'pcr%check_%.%'
) P 
PIVOT
(
	MAX([recordedValue])
	FOR [propertyName]
	IN
	(
		[SerialNumber],
		[ChangeOrder],
		[DateCalibrated],
		[DCID],
		[pcr1check_50.error],
		[pcr1check_50.instrumenttemp],
		[pcr1check_50.thermocouple],
		[pcr1check_60.error],
		[pcr1check_60.instrumenttemp],
		[pcr1check_60.thermocouple],
		[pcr1check_70.error],
		[pcr1check_70.instrumenttemp],
		[pcr1check_70.thermocouple],
		[pcr1check_80.error],
		[pcr1check_80.instrumenttemp],
		[pcr1check_80.thermocouple],
		[pcr1check_90.error],
		[pcr1check_90.instrumenttemp],
		[pcr1check_90.thermocouple],
		[pcr2check_50.error],
		[pcr2check_50.instrumenttemp],
		[pcr2check_50.thermocouple],
		[pcr2check_60.error],
		[pcr2check_60.instrumenttemp],
		[pcr2check_60.thermocouple],
		[pcr2check_70.error],
		[pcr2check_70.instrumenttemp],
		[pcr2check_70.thermocouple],
		[pcr2check_80.error],
		[pcr2check_80.instrumenttemp],
		[pcr2check_80.thermocouple],
		[pcr2check_90.error],
		[pcr2check_90.instrumenttemp],
		[pcr2check_90.thermocouple]
	)
) PIV

SELECT
	[SerialNo],
	CAST(MIN([TranDate]) AS DATE) AS [BreakDate]
INTO #location
FROM [PMS1].[dbo].[vSerialTransactions] WITH(NOLOCK)
WHERE [TranType] LIKE 'SH' OR ([TranType] IN ('IS','SA') AND [DistQty] = -1)
GROUP BY [SerialNo]

SELECT 
	[SerialNumber] AS [SerialNo],
	IIF(LEFT([SerialNumber],2) IN ('FA','2F'), 'FA2.0', 'Torch') AS [Version],
	YEAR([Date]) AS [Year],
	DATEPART(ww, [Date]) AS [Week],
	[DCID],
	[ChangeOrder],
	[Test],
	[pcr1_50therm] AS [ThermoCouple],
	[pcr1_50inst] AS [Instrument],
	[pcr1_50error] AS [Error],
	[pcr1_50target] AS [Target],
	IIF([Date] < [BreakDate], 'Production',
		IIF([BreakDate] IS NULL, 'Production', 'Service')) AS [Location]
FROM
(
	SELECT 
		[SerialNumber],
		[Date],
		[DCID],
		[ChangeOrder],
		'PCR1_50' AS [Test],
		[pcr1_50therm],
		[pcr1_50inst],
		[pcr1_50error],
		[pcr1_50target]
	FROM #tempCal
	UNION ALL
	SELECT 
		[SerialNumber],
		[Date],
		[DCID],
		[ChangeOrder],
		'PCR1_60' AS [Test],
		[pcr1_60therm],
		[pcr1_60inst],
		[pcr1_60error],
		[pcr1_60target]
	FROM #tempCal
	UNION ALL
	SELECT 
		[SerialNumber],
		[Date],
		[DCID],
		[ChangeOrder],
		'PCR1_70' AS [Test],
		[pcr1_70therm],
		[pcr1_70inst],
		[pcr1_70error],
		[pcr1_70target]
	FROM #tempCal
	UNION ALL
	SELECT 
		[SerialNumber],
		[Date],
		[DCID],
		[ChangeOrder],
		'PCR1_80' AS [Test],
		[pcr1_80therm],
		[pcr1_80inst],
		[pcr1_80error],
		[pcr1_80target]
	FROM #tempCal
	UNION ALL
	SELECT 
		[SerialNumber],
		[Date],
		[DCID],
		[ChangeOrder],
		'PCR1_90' AS [Test],
		[pcr1_90therm],
		[pcr1_90inst],
		[pcr1_90error],
		[pcr1_90target]
	FROM #tempCal
	UNION ALL
	SELECT 
		[SerialNumber],
		[Date],
		[DCID],
		[ChangeOrder],
		'PCR2_50' AS [Test],
		[pcr2_50therm],
		[pcr2_50inst],
		[pcr2_50error],
		[pcr2_50target]
	FROM #tempCal
	UNION ALL
	SELECT 
		[SerialNumber],
		[Date],
		[DCID],
		[ChangeOrder],
		'PCR2_60' AS [Test],
		[pcr2_60therm],
		[pcr2_60inst],
		[pcr2_60error],
		[pcr2_60target]
	FROM #tempCal
	UNION ALL
	SELECT 
		[SerialNumber],
		[Date],
		[DCID],
		[ChangeOrder],
		'PCR2_70' AS [Test],
		[pcr2_70therm],
		[pcr2_70inst],
		[pcr2_70error],
		[pcr2_70target]
	FROM #tempCal
	UNION ALL
	SELECT 
		[SerialNumber],
		[Date],
		[DCID],
		[ChangeOrder],
		'PCR2_80' AS [Test],
		[pcr2_80therm],
		[pcr2_80inst],
		[pcr2_80error],
		[pcr2_80target]
	FROM #tempCal
	UNION ALL
	SELECT 
		[SerialNumber],
		[Date],
		[DCID],
		[ChangeOrder],
		'PCR2_90' AS [Test],
		[pcr2_90therm],
		[pcr2_90inst],
		[pcr2_90error],
		[pcr2_90target]
	FROM #tempCal
) T LEFT JOIN #location L
	ON T.[SerialNumber] = L.[SerialNo]
WHERE T.[Date] > GETDATE() - 400 AND [pcr1_50therm] IS NOT NULL
ORDER BY [Date], [SerialNumber]

DROP TABLE #tempCal, #location
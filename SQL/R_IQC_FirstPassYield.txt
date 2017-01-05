SET NOCOUNT ON

SELECT ROW_NUMBER() OVER(PARTITION BY [Instrument] ORDER BY [Date]) AS [RunNo],
	[Instrument],
	[Date],
	CASE
		WHEN [PouchResult] <> 'Pass' AND [PCR1]  = 'Pass' AND [PCR2]  = 'Pass' AND [RNA] = 'Pass' AND [60TmRange] = 'Pass' AND [60DFMed] = 'Pass' AND [Noise] = 'Pass' THEN 'Pass'
		WHEN [PouchResult] <> 'Pass' AND [PCR1]  <> 'Pass' AND [PCR2]  <> 'Pass' AND [RNA] <> 'Pass' AND [60TmRange] <> 'Pass' AND [60DFMed] <> 'Pass' AND [Noise] <> 'Pass' THEN 'Pouch-All Metrics'
		WHEN [PouchResult] <> 'Pass' AND [PCR1]  <> 'Pass' AND [PCR2]  <> 'Pass' AND [RNA] <> 'Pass' AND [60TmRange] <> 'Pass' AND [60DFMed] <> 'Pass' THEN 'Pouch-Controls, MP'
		WHEN [PouchResult] <> 'Pass' AND [PCR1]  <> 'Pass' AND [PCR2]  <> 'Pass' AND [RNA] <> 'Pass' AND [60TmRange] <> 'Pass' THEN 'Pouch-Controls, MP Tm'
		WHEN [PouchResult] <> 'Pass' AND [PCR1]  <> 'Pass' AND [PCR2]  <> 'Pass' AND [RNA] <> 'Pass' AND [60DFMed] <> 'Pass' THEN 'Pouch-Controls, MP DF'
		WHEN [PouchResult] <> 'Pass' AND [PCR1]  <> 'Pass' AND [PCR2]  <> 'Pass' AND [RNA] <> 'Pass' AND [Noise] <> 'Pass' THEN 'Pouch-Controls, Noise'
		WHEN [PouchResult] <> 'Pass' AND [PCR1]  <> 'Pass' AND [PCR2]  <> 'Pass' AND [RNA] <> 'Pass' THEN 'Pouch-Controls'
		WHEN [PouchResult] <> 'Pass' AND [PCR1]  <> 'Pass' AND [PCR2]  <> 'Pass' THEN 'Pouch-PCR Controls'
		WHEN [PouchResult] <> 'Pass' AND [PCR1]  <> 'Pass' THEN 'Pouch-PCR1 Control'
		WHEN [PouchResult] <> 'Pass' AND [PCR2]  <> 'Pass' THEN 'Pouch-PCR2 Control'
		WHEN [PouchResult] <> 'Pass' AND [RNA]  <> 'Pass' THEN 'Pouch-Yeast Controls'
		WHEN [PouchResult] <> 'Pass' AND [60DFMed] <> 'Pass' THEN 'Pouch-MP DF'
		WHEN [PouchResult] <> 'Pass' AND [60TmRange] <> 'Pass' THEN 'Pouch-MP Tm'
		WHEN [PouchResult] <> 'Pass' AND [RNA]  <> 'Pass' AND [60TmRange] <> 'Pass' AND [60DFMed] <> 'Pass' AND [Noise] <> 'Pass' THEN 'Pouch-Yeast, MP, Noise'
		WHEN [PouchResult] <> 'Pass' AND [RNA]  <> 'Pass' AND [60TmRange] <> 'Pass' AND [60DFMed] <> 'Pass' THEN 'Pouch-Yeast, MP'
		WHEN [PouchResult] <> 'Pass' AND [Noise] <> 'Pass' THEN 'Pouch-Noise'
		WHEN [PouchResult] <> 'Pass' THEN 'Pouch-Pouch Other'
		WHEN [PouchResult] = 'Pass' THEN 'Pass'
		ELSE 'Other'
	END
	AS [Result]
INTO #qcBuild
FROM [PMS1].[dbo].[tIQC_Overview] WITH(NOLOCK)
WHERE [SampId] LIKE '%NewBuild%' AND [Date] > GETDATE() - 400

SELECT ROW_NUMBER() OVER(PARTITION BY [Instrument] ORDER BY [Date]) AS [RunNo],
	[Instrument],
	[Date],
	CASE
		WHEN [PouchResult] <> 'Pass' AND [PCR1]  = 'Pass' AND [PCR2]  = 'Pass' AND [RNA] = 'Pass' AND [60TmRange] = 'Pass' AND [60DFMed] = 'Pass' AND [Noise] = 'Pass' THEN 'Pass'
		WHEN [PouchResult] <> 'Pass' AND [PCR1]  <> 'Pass' AND [PCR2]  <> 'Pass' AND [RNA] <> 'Pass' AND [60TmRange] <> 'Pass' AND [60DFMed] <> 'Pass' AND [Noise] <> 'Pass' THEN 'Pouch-All Metrics'
		WHEN [PouchResult] <> 'Pass' AND [PCR1]  <> 'Pass' AND [PCR2]  <> 'Pass' AND [RNA] <> 'Pass' AND [60TmRange] <> 'Pass' AND [60DFMed] <> 'Pass' THEN 'Pouch-Controls, MP'
		WHEN [PouchResult] <> 'Pass' AND [PCR1]  <> 'Pass' AND [PCR2]  <> 'Pass' AND [RNA] <> 'Pass' AND [60TmRange] <> 'Pass' THEN 'Pouch-Controls, MP Tm'
		WHEN [PouchResult] <> 'Pass' AND [PCR1]  <> 'Pass' AND [PCR2]  <> 'Pass' AND [RNA] <> 'Pass' AND [60DFMed] <> 'Pass' THEN 'Pouch-Controls, MP DF'
		WHEN [PouchResult] <> 'Pass' AND [PCR1]  <> 'Pass' AND [PCR2]  <> 'Pass' AND [RNA] <> 'Pass' AND [Noise] <> 'Pass' THEN 'Pouch-Controls, Noise'
		WHEN [PouchResult] <> 'Pass' AND [PCR1]  <> 'Pass' AND [PCR2]  <> 'Pass' AND [RNA] <> 'Pass' THEN 'Pouch-Controls'
		WHEN [PouchResult] <> 'Pass' AND [PCR1]  <> 'Pass' AND [PCR2]  <> 'Pass' THEN 'Pouch-PCR Controls'
		WHEN [PouchResult] <> 'Pass' AND [PCR1]  <> 'Pass' THEN 'Pouch-PCR1 Control'
		WHEN [PouchResult] <> 'Pass' AND [PCR2]  <> 'Pass' THEN 'Pouch-PCR2 Control'
		WHEN [PouchResult] <> 'Pass' AND [RNA]  <> 'Pass' THEN 'Pouch-Yeast Controls'
		WHEN [PouchResult] <> 'Pass' AND [60DFMed] <> 'Pass' THEN 'Pouch-MP DF'
		WHEN [PouchResult] <> 'Pass' AND [60TmRange] <> 'Pass' THEN 'Pouch-MP Tm'
		WHEN [PouchResult] <> 'Pass' AND [RNA]  <> 'Pass' AND [60TmRange] <> 'Pass' AND [60DFMed] <> 'Pass' AND [Noise] <> 'Pass' THEN 'Pouch-Yeast, MP, Noise'
		WHEN [PouchResult] <> 'Pass' AND [RNA]  <> 'Pass' AND [60TmRange] <> 'Pass' AND [60DFMed] <> 'Pass' THEN 'Pouch-Yeast, MP'
		WHEN [PouchResult] <> 'Pass' AND [Noise] <> 'Pass' THEN 'Pouch-Noise'
		WHEN [PouchResult] <> 'Pass' THEN 'Pouch-Pouch Other'
		WHEN [PouchResult] = 'Pass' THEN 'Pass'
		ELSE 'Other'
	END
	AS [Result]
INTO #qcRepair
FROM [PMS1].[dbo].[tIQC_Overview] WITH(NOLOCK)
WHERE [SampId] LIKE '%PostRepair%' AND [Date] > GETDATE() - 400

SELECT 
	R.[InstrumentSerialNumber] AS [Instrument],
	R.[StartTime] AS [Date],
	IIF(R.[SampleId] LIKE '%NewBuild%', 'Production', 'Service') AS [Key], 
	IIF(E.[error] LIKE '3003%', SUBSTRING(E.[error], CHARINDEX('V0', E.[error],1), 4),
		IIF(E.[error] LIKE '3006%', SUBSTRING(E.[error], CHARINDEX('T0', E.[error],1), 4), SUBSTRING(E.[error], 1, 4))) AS [Result]
INTO #fa2 
FROM [FILMARRAYDB].[FilmArray2].[dbo].[ExperimentRun] R WITH(NOLOCK) LEFT JOIN [FILMARRAYDB].[FilmArray2].[dbo].[Experiment_Errors] E WITH(NOLOCK)
	ON R.[Id] = E.[experiment_id]
WHERE [ExperimentStatus] LIKE 'Instrument Error' AND ([SampleId] LIKE '%NewBuild%' OR [SampleId] LIKE '%PostRepair%') AND 
		([error] NOT LIKE 'IdahoTech%' OR [error] IS NULL) AND R.[StartTime] > GETDATE() - 400

SELECT
	R.[InstrumentSerialNumber] AS [Instrument],
	R.[StartTime] AS [Date],
	IIF(R.[SampleId] LIKE '%NewBuild%', 'Production', 'Service') AS [Key],
	SUBSTRING(E.[error], 1, 4) AS [Result]
INTO #fa1
FROM [FILMARRAYDB].[FilmArray1].[FilmArray].[ExperimentRun] R WITH(NOLOCK) LEFT JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[Experiment_Errors] E WITH(NOLOCK)
	ON R.[Id] = E.[experiment_id]
WHERE [ExperimentStatus] LIKE 'Instrument Error' AND ([SampleId] LIKE '%NewBuild%' OR [SampleId] LIKE '%PostRepair%') AND ([error] NOT LIKE 'IdahoTech%' OR [error] IS NULL) AND
		R.[PouchSerialNumber] NOT IN (SELECT [PouchSerialNumber] FROM #fa2) AND R.[StartTime] > GETDATE() - 400

SELECT *
INTO #qcErrors
FROM
(
	SELECT *
	FROM #fa1
	UNION
	SELECT *
	FROM #fa2
) T

SELECT ROW_NUMBER() OVER(PARTITION BY [Instrument] ORDER BY [Date]) AS [TestNo],
	[Instrument],
	[Date],
	[Result],
	[Desc]
INTO #production
FROM
(
	SELECT 
		[Instrument],
		[Date],
		[Result] AS [Result],
		[Result] AS [Desc]
	FROM #qcBuild 
	UNION ALL
	SELECT 
		[Instrument],
		[Date],
		CASE [Result]
			WHEN 'T003' THEN 'Invalid Parameter'
			WHEN 'T003' THEN 'Unknown Command' 
			WHEN 'T031' THEN 'LED Excitation'
			WHEN 'T032' THEN 'Thermocycler Timeout'
			WHEN 'T034' THEN 'Temperature Error'
			WHEN 'V019' THEN 'Valve Low Pressue'
			WHEN 'V030' THEN 'System Pressurization'
			WHEN 'V033' THEN 'Seal Bar Error'
			WHEN 'V039' THEN 'Regulated Pressure out of Range'
			WHEN 'V041' THEN 'Static Pressure out of Range'
			WHEN 'V043' THEN 'Seal Bar Current too Low'
			WHEN '1000' THEN 'Unknown'
			WHEN '1005' THEN 'LUA Execution Error'
			WHEN '1011' THEN 'Loading Error'
			WHEN '1012' THEN 'Loading Error'
			WHEN '3001' THEN 'Valve Board Response Timeout'
			WHEN '3003' THEN 'Valve Board Command Error'
			WHEN '3004' THEN 'Thermocycler Timeout'
			WHEN '3006' THEN 'Thermocycler Timeout'
			WHEN '4001' THEN 'System Pressurization'
			WHEN '7003' THEN 'LED Excitation'
			WHEN '90%' THEN 'Unknown'
			WHEN 'NoError' THEN 'NoError'
		ELSE 'Other'
		END AS [Result],
		[Result] AS [Desc]
	FROM #qcErrors
	WHERE [Key] LIKE 'Production'
) T

SELECT ROW_NUMBER() OVER(PARTITION BY [Instrument] ORDER BY [Date]) AS [TestNo],
	[Instrument],
	[Date],
	[Result]
INTO #service
FROM
(
	SELECT 
		[Instrument],
		[Date],
		[Result] AS [Result],
		[Result] AS [Desc]
	FROM #qcRepair
	UNION ALL
	SELECT 
		[Instrument],
		[Date],
		CASE [Result]
			WHEN 'T003' THEN 'Invalid Parameter'
			WHEN 'T003' THEN 'Unknown Command' 
			WHEN 'T031' THEN 'LED Excitation'
			WHEN 'T032' THEN 'Thermocycler Timeout'
			WHEN 'T034' THEN 'Temperature Error'
			WHEN 'V019' THEN 'Valve Low Pressue'
			WHEN 'V030' THEN 'System Pressurization'
			WHEN 'V033' THEN 'Seal Bar Error'
			WHEN 'V039' THEN 'Regulated Pressure out of Range'
			WHEN 'V041' THEN 'Static Pressure out of Range'
			WHEN 'V043' THEN 'Seal Bar Current too Low'
			WHEN '1000' THEN 'Unknown'
			WHEN '1005' THEN 'LUA Execution Error'
			WHEN '1011' THEN 'Loading Error'
			WHEN '1012' THEN 'Loading Error'
			WHEN '3001' THEN 'Valve Board Response Timeout'
			WHEN '3003' THEN 'Valve Board Command Error'
			WHEN '3004' THEN 'Thermocycler Timeout'
			WHEN '3006' THEN 'Thermocycler Timeout'
			WHEN '4001' THEN 'System Pressurization'
			WHEN '7003' THEN 'LED Excitation'
			WHEN '9011' THEN 'Unknown'
			WHEN 'NoError' THEN 'NoError'
		ELSE 'Other'
		END AS [Result],
		[Result] AS [Desc]
	FROM #qcErrors
	WHERE [Key] LIKE 'Service'
) T

SELECT 
	[TicketId],
	UPPER(REPLACE(REPLACE(REPLACE(REPLACE([RecordedValue],' ',''),'.',''),'-',''),'_','')) AS [Instrument]
INTO #rmas
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Part Information' AND [PropertyName] LIKE 'Lot/Serial Number' AND [CreatedDate] > GETDATE() - 430

SELECT 
	[TicketId],
	MAX([RecordedValue]) AS [RecordedValue]
INTO #qcs
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Qc Date' AND [CreatedDate] > GETDATE() - 430
GROUP BY [TicketId]

SELECT
	R.[Instrument],
	R.[TicketId],
	Q.[RecordedValue] AS [QcDate]
INTO #rmaQC
FROM #rmas R INNER JOIN #qcs Q
	ON R.[TicketId] = Q.[TicketId]
WHERE LEFT(R.[Instrument], 2) IN ('FA','2F','TM','HT')

SELECT 
	[TestNo],
	[Instrument],
	[Date],
	[Result],
	(
		SELECT 
			MAX([QcDate]) AS [LastQC]
		FROM #rmaQC S2
		WHERE S2.[Instrument] = S1.[Instrument] AND S2.[QcDate] BETWEEN (S1.[Date]-14) AND (S1.[Date] + 14)
		GROUP BY [Instrument]
	) AS [NearQcDate]
INTO #serviceMany
FROM #service S1

SELECT 
	YEAR([Date]) AS [Year],
	DATEPART(ww, [Date]) AS [Week],
	[TestNo],
	[Key],
	[Result],
	SUM([Record]) AS [Record]
FROM
(
	SELECT 
		[Instrument],
		CAST([Date] AS DATE) AS [Date],
		[TestNo],
		'Service' AS [Key],
		[Result],
		1 AS [Record]
	FROM
	(
		SELECT ROW_NUMBER() OVER(PARTITION BY [Instrument], [NearQcDate] ORDER BY [Date]) AS [TestNo],
			[Instrument],
			[Date],
			[NearQcDate],
			[Result]
		FROM #serviceMany
	) T
	WHERE [NearQcDate] IS NOT NULL
	UNION ALL
	SELECT 
		[Instrument],
		CAST([Date] AS DATE) AS [Date],
		[TestNo],
		'Production' AS [Key],
		[Result],
		1 AS [Record]
	FROM #production
) T
GROUP BY
	YEAR([Date]),
	DATEPART(ww, [Date]),
	[TestNo],
	[Key],
	[Result]
ORDER BY
	YEAR([Date]),
	DATEPART(ww, [Date]),
	[TestNo],
	[Key],
	[Result]

DROP TABLE #fa1, #fa2, #qcBuild, #qcRepair, #qcErrors, #production, #qcs, #rmas, #service, #rmaQC, #serviceMany
SET NOCOUNT ON

SELECT
	R.[PouchSerialNumber],
	R.[StartTime],
	IIF(LEFT(R.[InstrumentSerialNumber],2) IN ('HT','TM'), 'Torch',
		IIF(R.[SampleType] LIKE 'QC v3.0', 'FA2.0', 
		IIF(R.[SampleType] LIKE 'QC v2.0', 'FA1.5', 'Other'))) AS [Version],
	IIF(R.[SampleId] LIKE '%NewBuild%', 'Production', 'Service') AS [Key],
	IIF(E.[error] IS NULL, 'NoError', 
		IIF(E.[error] LIKE '3003%', SUBSTRING(E.[error], CHARINDEX('V0', E.[error],1), 4), 
		IIF(E.[error] LIKE '3006%', SUBSTRING(E.[error], CHARINDEX('T0', E.[error],1), 4), SUBSTRING(E.[error], 1, 4)))) AS [RecordedValue],
	IIF(R.[ExperimentStatus] LIKE 'Instrument Error', 1, 0) AS [Record]
INTO #fa2 
FROM [FILMARRAYDB].[FilmArray2].[dbo].[ExperimentRun] R WITH(NOLOCK) LEFT JOIN [FILMARRAYDB].[FilmArray2].[dbo].[Experiment_Errors] E WITH(NOLOCK)
	ON R.[Id] = E.[experiment_id]
WHERE [ExperimentStatus] IN ('Instrument Error','Completed') AND ([SampleId] LIKE '%NewBuild%' OR [SampleId] LIKE '%PostRepair%') AND 
		([error] NOT LIKE 'IdahoTech%' OR [error] IS NULL) AND R.[StartTime] > GETDATE() - 400

SELECT
	R.[PouchSerialNumber],
	R.[StartTime],
	'FA1.5' AS [Version],
	IIF(R.[SampleId] LIKE '%NewBuild%', 'Production', 'Service') AS [Key],
	IIF(E.[error] IS NULL, 'NoError', SUBSTRING(E.[error], 1, 4)) AS [RecordedValue],
	IIF(R.[ExperimentStatus] LIKE 'Instrument Error', 1, 0) AS [Record]
INTO #fa1
FROM [FILMARRAYDB].[FilmArray1].[FilmArray].[ExperimentRun] R WITH(NOLOCK) LEFT JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[Experiment_Errors] E WITH(NOLOCK)
	ON R.[Id] = E.[experiment_id]
WHERE [ExperimentStatus] IN ('Instrument Error','Completed') AND ([SampleId] LIKE '%NewBuild%' OR [SampleId] LIKE '%PostRepair%') AND 
		([error] NOT LIKE 'IdahoTech%' OR [error] IS NULL) AND 
	R.[PouchSerialNumber] NOT IN (SELECT [PouchSerialNumber] FROM #fa2) AND R.[StartTime] > GETDATE() - 400

SELECT *
INTO #master
FROM
(
	SELECT 
		[StartTime],
		[Version],
		[Key],
		MAX([RecordedValue]) AS [RecordedValue],
		MAX([Record]) AS [Record]	
	FROM #fa1
	GROUP BY [StartTime], [Version], [Key]
	UNION
	SELECT 
		[StartTime],
		[Version],
		[Key],
		MAX([RecordedValue]) AS [RecordedValue],
		MAX([Record]) AS [Record]	
	FROM #fa2
	GROUP BY [StartTime], [Version], [Key]
) T

SELECT
	YEAR([StartTime]) AS [Year],
	DATEPART(ww, [StartTime]) AS [Week],
	[Version],
	[Key],
	CASE [RecordedValue]
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
	END AS [RecordedValue],
	IIF([RecordedValue] LIKE 'NoError', 0, [Record]) AS [RunError]
FROM #master

DROP TABLE #fa2, #fa1, #master
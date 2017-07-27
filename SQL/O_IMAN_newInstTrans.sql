--This query uses Production Web to find out when an instrument was passed or released from QC.

SET NOCOUNT ON

SELECT 
	[PartNumber],
	IIF([SerialNo] LIKE 'K%R', SUBSTRING([SerialNo], 2, PATINDEX('%R', [SerialNo])-2),
		IIF([SerialNo] LIKE '%R', SUBSTRING([SerialNo], 1, PATINDEX('%R',[SerialNo])-1), 
		IIF([SerialNo] LIKE 'K%', SUBSTRING([SerialNo], 2, LEN([SerialNo])), [SerialNo]))) AS [SerialNo],
	[LotNumber],
	[DateOfManufacturing],
	[TimeOfChange],
	[Value] AS [QCState]
INTO #Lots
FROM
(
	SELECT 
		[PartNumber],
		UPPER(REPLACE(REPLACE(REPLACE(REPLACE([LotNumber],' ',''),'_',''),'-',''),'.','')) AS [SerialNo],
		[LotNumber],
		[DateOfManufacturing],
		[TimeOfChange],
		[Value] 
	FROM [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[Parts] P WITH(NOLOCK) RIGHT JOIN [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[Lots] L WITH(NOLOCK)
		ON P.[PartNumberId] = L.[PartNumberId]
		LEFT JOIN [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[QcStatusHistories] Q WITH(NOLOCK) 
			ON L.[LotNumberId] = Q.[LotNumberId]
			LEFT JOIN [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[StatusHistories] S WITH(NOLOCK)
				ON Q.[StatusHistoryId] = S.[StatusHistoryId]
				LEFT JOIN [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[QcStates] QS WITH(NOLOCK)
					ON Q.[QcStateId] = QS.[QcStateId]
	WHERE [PartNumber] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-ASY-0001','HTFA-ASY-0003')
) A
ORDER BY [SerialNo], [TimeOfChange]

SELECT 
	[PartNumber],
	[SerialNo],
	[DateOfManufacturing],
	[TimeOfChange] 
INTO #Master
FROM 
(
	SELECT 
		ROW_NUMBER() OVER(PARTITION BY [SerialNo] ORDER BY [TimeOfChange] DESC) AS [Row],
		*
	FROM #Lots
) A
WHERE [Row] = 1 AND [QCState] IN ('Released', 'Passed')
ORDER BY [TimeOfChange]

SELECT 
	YEAR([TimeOfChange]) AS [Year],
	MONTH([TimeOfChange]) AS [Month],
	IIF([PartNumber] LIKE 'FLM1-%', 'FA1.5',
		IIF([PartNumber] LIKE 'FLM2-%', 'FA2.0',
		IIF([PartNumber] LIKE 'HTFA-ASY-0001%', 'Torch Base',
		IIF([PartNumber] LIKE 'HTFA-ASY-0003%', 'Torch Module', [PartNumber])))) AS [Version],
	'Instruments Released' AS [Key],
	1 AS [Record] 
FROM #Master

DROP TABLE #Lots, #Master

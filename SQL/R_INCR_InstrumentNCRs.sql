SET NOCOUNT ON

SELECT
	[TicketId], 
	YEAR([CreatedDate]) AS [Year],
	DATEPART(ww,[CreatedDate]) AS [Week],
	CASE [RecordedValue] 
		WHEN 'Instrument Production WIP' THEN 'All Instrument WIP'
		WHEN 'Torch Instrument WIP' THEN 'Torch'
		WHEN 'HTFA Instrument WIP' THEN 'Torch'
		WHEN 'FA2.0 Instrument WIP' THEN 'FA2.0'
		WHEN 'FA1.5 Instrument WIP' THEN 'FA1.5'
		ELSE 'Other'
	END AS [Key],
	1 AS [Record]
INTO #WIP
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'NCR Type' AND [RecordedValue] LIKE '%Instrument %WIP'

SELECT 
	[Year],
	[Week],
	[Key],
	[Record]
INTO #NotTorch
FROM #WIP
WHERE [Key] NOT LIKE 'Torch' 

SELECT *
INTO #Torch
FROM #WIP
WHERE [Key] LIKE 'Torch' 

SELECT 
	[TicketId],
	[RecordedValue] AS [PartAffected]
INTO #torchNCR
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] NCR WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Part Affected' AND [TicketId] IN (SELECT [TicketId] FROM #Torch)

SELECT 
	IIF(MAX([ItemID]) LIKE 'HTFA-ASY-0003', 'Torch Module', 'Torch Base') AS [TorchType],
	[ComponentItemID]
INTO #torchBOM
FROM [PMS1].[dbo].[vInstrumentBillOfMaterials] WITH(NOLOCK)
WHERE [ItemID] IN ('HTFA-ASY-0001', 'HTFA-ASY-0003')
GROUP BY [ComponentItemID]

SELECT
	[Year],
	[Week],
	[TorchType] AS [Key],
	[Record]
INTO #TorchWIP
FROM #Torch t LEFT JOIN
(
	SELECT
		[TicketId],
		[TorchType]
	FROM #torchNCR n LEFT JOIN #torchBOM b
		ON n.[PartAffected] = b.[ComponentItemID]
	WHERE [TorchType] IS NOT NULL
	GROUP BY [TicketId], [TorchType]
) n
	ON t.[TicketId] = n.TicketId
WHERE [TorchType] IS NOT NULL

SELECT DISTINCT
	NCR.[TicketId]
INTO #NCRsWithInst
FROM [PMS1].[dbo].[vInstrumentBillOfMaterials] BOM WITH(NOLOCK) INNER JOIN [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] NCR WITH(NOLOCK)
	ON BOM.[ComponentItemId] = NCR.[RecordedValue]
WHERE NCR.[PropertyName] LIKE 'Part Affected'

SELECT
	[TicketId],
	YEAR([CreatedDate]) AS [Year],
	DATEPART(ww,[CreatedDate]) AS [Week],
	'Raw Material' AS [Key],
	1 AS [Record]
INTO #RAW
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'NCR Type' AND [RecordedValue] LIKE 'Raw Material'

SELECT 
	[Year],
	[Week],
	[Key],
	[Record]
INTO #ADD
FROM #RAW R INNER JOIN #NCRsWithInst N
	ON R.[TicketId] = N.[TicketId]

SELECT 
	[Year],
	[Week],
	[Key] AS [Version],
	'InstNCR' AS [Key],
	SUM([Record]) AS [Record]
FROM
(
	SELECT
		[Year],
		[Week],
		[Key],
		[Record]
	FROM #NotTorch
	UNION ALL
	SELECT
		[Year],
		[Week],
		[Key],
		[Record]
	FROM #TorchWIP
	UNION ALL
	SELECT
		[Year],
		[Week],
		[Key],
		[Record]
	FROM #ADD
) D
WHERE [Year] >= 2015
GROUP BY [Year], [Week], [Key]
ORDER BY [Year], [Week]

DROP TABLE #NCRsWithInst, #RAW, #WIP, #ADD, #NotTorch, #Torch, #torchBOM, #torchNCR, #TorchWIP
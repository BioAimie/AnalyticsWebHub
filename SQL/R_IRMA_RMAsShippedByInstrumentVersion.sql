SET NOCOUNT ON

SELECT 
	[TicketId],
	[TicketString],
	MAX([RecordedValue]) AS [QcDate]
INTO #qcDate
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] = 'RMA' AND [ObjectName] = 'QC Check' AND [PropertyName] = 'QC Date' AND [RecordedValue] IS NOT NULL
GROUP BY [TicketId], [TicketString]

SELECT
	[TicketId],
	[RecordedValue] AS [PartNo]
INTO #partNo
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] = 'RMA' AND [ObjectName] = 'Part Information' AND [PropertyName] = 'Part Number'

SELECT 
	YEAR(CAST(Q.[QcDate] AS DATE)) AS [Year],
	MONTH(CAST(Q.[QcDate] AS DATE)) AS [Month],
	DATEPART(ww, CAST(Q.[QcDate] AS DATE)) AS [Week],
	IIF(LEFT([PartNo],4) LIKE 'FLM1', 'FA1.5',
		IIF(LEFT([PartNo],4) LIKE 'FLM2', 'FA2.0', 'Torch')) AS [Version],
	'ShippedRMA' AS [Key],
	COUNT(DISTINCT Q.[TicketId]) AS [Record]
FROM #qcDate Q INNER JOIN #partNo P
	ON Q.[TicketId] = P.[TicketId]
WHERE ([PartNo] LIKE 'FLM%-ASY-0001%' OR [PartNo] LIKE 'HTFA-ASY-0003%' OR [PartNo] LIKE 'HTFA-SUB-0103%') AND CAST([qcDate] AS DATE) >= GETDATE() - 400
GROUP BY YEAR(CAST([QcDate] AS DATE)), MONTH(CAST([QcDate] AS DATE)), DATEPART(ww, CAST([QcDate] AS DATE)), [PartNo]
ORDER BY YEAR(CAST([QcDate] AS DATE)), DATEPART(ww, CAST([QcDate] AS DATE))

DROP TABLE #partNo, #qcDate
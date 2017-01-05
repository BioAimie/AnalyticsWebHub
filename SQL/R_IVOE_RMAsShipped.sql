SET NOCOUNT ON

SELECT 
	[TicketId],
	[TicketString],
	MAX([RecordedValue]) AS [QcDate]
INTO #qcDate
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'QC Check' AND [PropertyName] LIKE 'QC Date'
GROUP BY [TicketId], [TicketString]

SELECT
	[TicketId],
	[RecordedValue] AS [PartNo]
INTO #partNo
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Part Information' AND [PropertyName] LIKE 'Part Number'

SELECT 
	YEAR(Q.[QcDate]) AS [Year],
	MONTH(Q.[QcDate]) AS [Month],
	DATEPART(ww,Q.[QcDate]) AS [Week],
	IIF(LEFT([PartNo],4) LIKE 'FLM1', 'FA1.5',
		IIF(LEFT([PartNo],4) LIKE 'FLM2', 'FA2.0', 'Torch')) AS [Version],
	'ShippedRMA' AS [Key],
	COUNT(DISTINCT Q.[TicketId]) AS [Record]
FROM #qcDate Q INNER JOIN #partNo P
	ON Q.[TicketId] = P.[TicketId]
WHERE ([PartNo] LIKE 'FLM%-ASY-0001%' OR [PartNo] LIKE 'HTFA-ASY-0003%' OR [PartNo] LIKE 'HTFA-SUB-0103%')
GROUP BY YEAR([QcDate]), MONTH([QcDate]), DATEPART(ww,[QcDate]), [PartNo]
ORDER BY YEAR([QcDate]), DATEPART(ww,[QcDate])

DROP TABLE #partNo, #qcDate
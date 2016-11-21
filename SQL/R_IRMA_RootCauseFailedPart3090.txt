SET NOCOUNT ON

SELECT
	[TicketId],
	[TicketString],
	[RecordedValue]
INTO #date
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Service Completed' AND [RecordedValue] IS NOT NULL

SELECT
	[ComponentItemID],
	[ComponentItemShortDesc]
INTO #bom
FROM [PMS1].[dbo].[vInstrumentBillOfMaterials] WITH(NOLOCK)

SELECT
	[TicketId],
	[RecordedValue] AS [FailedPart],
	[ComponentItemShortDesc]
INTO #fail
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] P WITH(NOLOCK) INNER JOIN #bom B
	ON P.[RecordedValue] = B.[ComponentItemID]
WHERE [ObjectName] LIKE 'Root Causes' AND [PropertyName] LIKE 'Part Number'

SELECT *,
	CAST([RecordedValue] AS DATETIME) AS [ServiceDate]
INTO #date2
FROM #date
	
SELECT 
	[TicketString],
	[FailedPart],
	[ComponentItemShortDesc] AS [FailedPartDesc],
	IIF([ServiceDate] > GETDATE() - 30, 1, 0) AS [thirtyDay],
	IIF([ServiceDate] BETWEEN GETDATE() - 60 AND GETDATE() - 31, 1, 0) AS [netSixtyDay],
	IIF([ServiceDate] BETWEEN GETDATE() - 90 AND GETDATE() - 61, 1, 0) AS [netNinetyDay],
	1 AS [Record]
FROM #date2 D INNER JOIN #fail F
	ON D.[TicketId] = F.[TicketId]
WHERE [ServiceDate] > GETDATE() - 90
GROUP BY 
	[TicketString],
	[FailedPart],
	[ComponentItemShortDesc],
	[ServiceDate]
ORDER BY [TicketString]

DROP TABLE #date, #fail, #bom, #date2
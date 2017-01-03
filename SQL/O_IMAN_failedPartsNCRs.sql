SET NOCOUNT ON

SELECT 
	[TicketID],
	[TicketString],
	[CreatedDate]
INTO #TicketsA
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'NCR Type' AND [RecordedValue] LIKE '%Instrument%'

SELECT DISTINCT [ComponentItemID]
INTO #bomParts
FROM [PMS1].[dbo].[vInstrumentBillOfMaterials]

SELECT  
	[TicketId],
	[TicketString]
INTO #MasClassParts
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] N WITH(NOLOCK) INNER JOIN #bomParts B
	ON N.[RecordedValue] = B.[ComponentItemID]
WHERE [ObjectName] LIKE 'Parts Affected' AND [PropertyName] LIKE 'Part Affected'

SELECT 
	[TicketId],
	[CreatedDate]
INTO #Raw
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'NCR Type' AND [RecordedValue] LIKE 'Raw Material'

SELECT 
	DISTINCT R.[TicketId],
	[TicketString],
	[CreatedDate] 
INTO #TicketsB
FROM #Raw R INNER JOIN #MasClassParts M
	ON R.[TicketId] = M.[TicketId]

SELECT *
INTO #Tickets
FROM #TicketsA
UNION ALL
SELECT *
FROM #TicketsB

SELECT 
	[TicketID],
	MAX([TicketString]) AS [TicketString],
	YEAR(MAX([CreatedDate])) AS [Year],
	MONTH(MAX([CreatedDate])) AS [Month],
	DATEPART(ww, MAX([CreatedDate])) AS [Week],
	[RecordedValue] AS [FailedPart]
INTO #Fail
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Parts Affected' AND [PropertyName] LIKE 'Part Affected' 
	AND [TicketID] IN (SELECT [TicketID] FROM #Tickets)
	AND [RecordedValue] NOT LIKE 'N/A' AND [RecordedValue] NOT LIKE 'NA'
GROUP BY [TicketID], [RecordedValue]

SELECT
	[Year],
	[Month],
	[Week],
	UPPER([FailedPart]) AS [FailedPart],
	1 AS [Record]
FROM #Fail f 
ORDER BY [TicketString]

DROP TABLE #TicketsA, #MasClassParts, #TicketsB, #Raw, #Tickets, #Fail, #bomParts

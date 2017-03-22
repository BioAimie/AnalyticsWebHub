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
	YEAR([CreatedDate]) AS [Year],
	MONTH([CreatedDate]) AS [Month],
	DATEPART(ww, [CreatedDate]) AS [Week],
	REPLACE([RecordedValue],',','-') AS [FailureCat],
	1 AS [Record] 
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Failure Details' AND [PropertyName] LIKE 'Failure Category' 
	AND [TicketId] IN (SELECT [TicketId] FROM #Tickets)
	AND [RecordedValue] IS NOT NULL
ORDER BY [CreatedDate]

DROP TABLE #bomParts, #MasClassParts, #Raw, #Tickets, #TicketsA, #TicketsB

SET NOCOUNT ON

SELECT
	[TicketID],
	[TicketString],
	[CreatedDate]
INTO #TicketsA
FROM [RO_TRACKERS].[Trackers].[dbo].[vAllPopertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'NCR Type' AND [RecordedValue] LIKE '%Instrument%'

SELECT *
INTO #MasClass
FROM [PMS1].[dbo].[vTracker_MAS_ItemClass] WITH(NOLOCK)
WHERE [ItemClassID] LIKE 'I-%'

SELECT  
	[TicketId],
	[TicketString]
INTO #MasClassParts
FROM [RO_TRACKERS].[Trackers].[dbo].[vAllObjectPropertiesByStatus] N WITH(NOLOCK) INNER JOIN #MasClass M
	ON N.[RecordedValue] = M.[ItemID]
WHERE [ObjectName] LIKE 'Parts Affected' AND [PropertyName] LIKE 'Part Affected'

SELECT 
	[TicketId],
	[CreatedDate]
INTO #Raw
FROM [RO_TRACKERS].[Trackers].[dbo].[vAllPopertiesByStatus] WITH(NOLOCK)
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
	[RecordedValue] AS [WhereFound]
INTO #Where
FROM [RO_TRACKERS].[Trackers].[dbo].[vAllPopertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Where Found' AND [TicketID] IN (SELECT [TicketID] FROM #Tickets)
	AND [RecordedValue] IS NOT NULL AND [RecordedValue] NOT LIKE 'CM'
GROUP BY [TicketID], [RecordedValue]

SELECT 
	[TicketID],
	[RecordedValue] AS [ProblemArea]
INTO #Prob
FROM [RO_TRACKERS].[Trackers].[dbo].[vAllPopertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Problem Area' AND [TicketID] IN (SELECT [TicketID] FROM #Tickets)
	AND [RecordedValue] IS NOT NULL AND [RecordedValue] NOT LIKE 'N/A'
GROUP BY [TicketID], [RecordedValue]

SELECT 
	YEAR([CreatedDate]) AS [Year],
	MONTH([CreatedDate]) AS [Month],
	DATEPART(ww, [CreatedDate]) AS [Week],
	[WhereFound],
	[ProblemArea]
FROM #Tickets t LEFT JOIN #Where w ON t.[TicketID] = w.[TicketID]
	LEFT JOIN #Prob p ON w.[TicketID] = p.[TicketID]
ORDER BY [TicketString] 

DROP TABLE #TicketsA, #MasClass, #MasClassParts, #Raw, #TicketsB, #Tickets, #Where, #Prob

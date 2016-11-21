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
	MAX([TicketString]) AS [TicketString],
	YEAR(MAX([CreatedDate])) AS [Year],
	MONTH(MAX([CreatedDate])) AS [Month],
	DATEPART(ww, MAX([CreatedDate])) AS [Week],
	[RecordedValue] AS [FailedPart]
INTO #Fail
FROM [RO_TRACKERS].[Trackers].[dbo].[vAllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Parts Affected' AND [PropertyName] LIKE 'Part Affected' 
	AND [TicketID] IN (SELECT [TicketID] FROM #Tickets)
	AND [RecordedValue] NOT LIKE 'N/A' AND [RecordedValue] NOT LIKE 'NA'
GROUP BY [TicketID], [RecordedValue]
/*
SELECT 
	[PartNumber],
	[Name] 
INTO #Pnames
FROM [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[Parts] WITH(NOLOCK)
*/
SELECT
	--[TicketString],
	[Year],
	[Month],
	[Week],
	UPPER([FailedPart]) AS [FailedPart]--,
	--[PartNumber],
	--[Name] AS [FailedPart]
FROM #Fail f --INNER JOIN #Pnames p
--	ON f.[FailedPart] = p.[PartNumber]
ORDER BY [TicketString]

DROP TABLE #TicketsA, #MasClass, #MasClassParts, #TicketsB, #Raw, #Tickets, #Fail--, #Pnames
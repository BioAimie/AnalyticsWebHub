SET NOCOUNT ON

SELECT
	[TicketID],
	[TicketString],
	[CreatedDate]
INTO #TicketsA
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'NCR Type' AND [RecordedValue] LIKE '%Instrument%'

SELECT [ComponentItemID]
INTO #bomParts
FROM [PMS1].[dbo].[vInstrumentBillOfMaterials] WITH(NOLOCK)

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
	REPLACE([RecordedValue], 'Instrument ','') AS [WhereFound]
INTO #Where
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Where Found' AND [TicketID] IN (SELECT [TicketID] FROM #Tickets)
	AND [RecordedValue] IS NOT NULL AND [RecordedValue] NOT LIKE 'CM'
GROUP BY [TicketID], [RecordedValue]

SELECT 
	[TicketID],
	REPLACE([RecordedValue], 'Instrument ','') AS [ProblemArea]
INTO #Prob
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Problem Area' AND [TicketID] IN (SELECT [TicketID] FROM #Tickets)
	AND [RecordedValue] IS NOT NULL AND [RecordedValue] NOT LIKE 'N/A'
GROUP BY [TicketID], [RecordedValue]

SELECT 
	YEAR([CreatedDate]) AS [Year],
	MONTH([CreatedDate]) AS [Month],
	DATEPART(ww, [CreatedDate]) AS [Week],
	[WhereFound],
	[ProblemArea],
	1 AS [Record]
FROM #Tickets t LEFT JOIN #Where w ON t.[TicketID] = w.[TicketID]
	LEFT JOIN #Prob p ON w.[TicketID] = p.[TicketID]
ORDER BY [TicketString] 

DROP TABLE #TicketsA, #bomParts, #MasClassParts, #Raw, #TicketsB, #Tickets, #Where, #Prob

SET NOCOUNT ON

SELECT [TicketId]
INTO #Keep
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'NCR Type' AND [RecordedValue] LIKE 'BioReagents'

SELECT
	[TicketId],
	[RecordedValue]
INTO #StringQty
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Quantity Affected' AND [TicketId] IN (SELECT [TicketId] FROM #Keep)

SELECT 
	[TicketId],
	IIF(ISNUMERIC([RecordedValue]) = 0, 0, REPLACE([RecordedValue],',','')) AS [RecordedValue]
INTO #Qty
FROM #StringQty

SELECT 
	[TicketId],
	SUM([RecordedValue]) AS [Record]
INTO #Record
FROM #Qty
GROUP BY [TicketId]

SELECT
	[TicketId],
	[Year],
	[Month],
	[Week],
	[Key],
	[RecordedValue]
INTO #wpfs
FROM
(
	SELECT 
		[TicketId],
		YEAR([CreatedDate]) AS [Year],
		MONTH([CreatedDate]) AS [Month],  
		DATEPART(ww, [CreatedDate]) AS [Week],
		[PropertyName] AS [Key],
		[RecordedValue]
	FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
	WHERE [PropertyName] LIKE 'Where Found' AND [Stage] LIKE 'Reporting' AND [TicketId] IN (SELECT [TicketId] FROM #Keep)
	UNION ALL
	SELECT 
		[TicketId],
		YEAR([CreatedDate]) AS [Year],
		MONTH([CreatedDate]) AS [Month],
		DATEPART(ww, [CreatedDate]) AS [Week],
		[PropertyName] AS [Key],
		[RecordedValue]
	FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
	WHERE [PropertyName] LIKE 'Problem Area' AND [TicketId] IN (SELECT [TicketId] FROM #Keep)
) D 

SELECT 
	[Year],
	[Month],
	[Week],
	[Key],
	[RecordedValue],
	[Record]
FROM #wpfs W LEFT JOIN #Record R 
	ON W.[TicketId] = R.[TicketId]

DROP TABLE #Keep, #Qty, #StringQty, #Record, #wpfs
SET NOCOUNT ON

SELECT
	[TicketId]
INTO #problemAreaTickets
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus]
WHERE [Tracker]='NCR' AND [PropertyName]='Problem Area' AND [RecordedValue] LIKE '%Seal Bar%'

SELECT DISTINCT
	[TicketId],
	[TicketString],
	[CreatedDate],
	[RecordedValue] AS [SubfailureCategory]
INTO #tickets
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus]
WHERE [Tracker]='NCR' 
	AND [ObjectName]='Failure Details'
	AND [PropertyName]='Sub-failure Category'
	AND [RecordedValue] LIKE '%alignment%'
	AND [TicketId] IN (SELECT [TicketId] FROM #problemAreaTickets)

SELECT
	T.[TicketId],
	T.[TicketString],
	T.[CreatedDate],
	T.[SubfailureCategory],
	P.[RecordedValue] AS [PartNumber],
	CASE
		WHEN [RecordedValue] LIKE '%FLM2-%' THEN 'FA2.0'
		WHEN [RecordedValue] LIKE '%HTFA-%' THEN 'Torch'
		ELSE 'Other'
	END AS [Version],
	DATEPART(ww, T.[CreatedDate]) AS [Week],
	MONTH(T.[CreatedDate]) AS [Month],
	YEAR(T.[CreatedDate]) AS [Year],
	1 AS [Record]
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] P
	INNER JOIN #tickets T ON T.[TicketId] = P.[TicketId]
WHERE [Tracker]='NCR'
	AND [ObjectName]='Part Numbers'
	AND [PropertyName]='Component Part Number'
	AND ([RecordedValue] LIKE 'FLM2%' OR [RecordedValue] LIKE 'HTFA%')
	
DROP TABLE #problemAreaTickets, #tickets

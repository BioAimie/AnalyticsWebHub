SET NOCOUNT ON

SELECT 
	[TicketId],
	[TicketString],
	[RecordedValue] AS [Code]
INTO #allcodes
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Service Code' 
	AND [RecordedValue] IS NOT NULL

SELECT DISTINCT 
	[TicketId] 
INTO #Tickets
FROM #allcodes
WHERE [Code] LIKE '20'

SELECT
	[TicketId],
	[TicketString],
	[ObjectId],
	[PropertyName],
	[RecordedValue] 
INTO #QCInfo
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'QC Check' AND [TicketId] IN (SELECT [TicketId] FROM #Tickets)

SELECT 
	[TicketId],
	[TicketString],
	MIN(CAST([QC Date] AS DATE)) AS [QCDate]
INTO #QCdate
FROM 
(
	SELECT *
	FROM #QCInfo
	PIVOT
	(
		MAX([RecordedValue]) 
		FOR [PropertyName] 
		IN
		(
			[QC Date],
			[DHR Complete]
		)
	) PIV
) Q
WHERE [DHR Complete] LIKE 'Yes'
GROUP BY [TicketId], [TicketString] 

SELECT 
	YEAR([QCDate]) AS [Year],
	DATEPART(ww, [QCDate]) AS [Week],
	MONTH([QCdate]) AS [Month],
	'FA1.5-2.0 Conversion' AS [Key],
	1 AS [Record]
INTO #final
FROM #QCdate
ORDER BY [QCDate]

SELECT
	[Year],
	[Month],
	[Key],
	SUM([Record]) AS [Record]
FROM #final
GROUP BY [Year], [Month], [Key] 

DROP TABLE #allcodes, #Tickets, #QCInfo, #QCdate, #final
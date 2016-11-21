SET NOCOUNT ON

SELECT [TicketId]
INTO #Keep
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'NCR Type' AND [RecordedValue] LIKE 'BioReagents'

SELECT
	[Year],
	[Week],
	[Key],
	[RecordedValue],
	SUM([Record]) AS [Record]
FROM
(
	SELECT 
		[CreatedDate],
		YEAR([CreatedDate]) AS [Year],
		DATEPART(ww, [CreatedDate]) AS [Week],
		[PropertyName] AS [Key],
		[RecordedValue],
		1 AS [Record]
	FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
	WHERE [PropertyName] LIKE 'Where Found' AND [Stage] LIKE 'Reporting' AND [TicketId] IN (SELECT [TicketId] FROM #Keep)
	UNION ALL
	SELECT 
		[CreatedDate],
		YEAR([CreatedDate]) AS [Year],
		DATEPART(ww, [CreatedDate]) AS [Week],
		[PropertyName] AS [Key],
		[RecordedValue],
		1 AS [Record]
	FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
	WHERE [PropertyName] LIKE 'Problem Area' AND [TicketId] IN (SELECT [TicketId] FROM #Keep)
) D
WHERE [CreatedDate] > GETDATE() - 400
GROUP BY 
	[Year],
	[Week],
	[Key],
	[RecordedValue]

DROP TABLE #Keep
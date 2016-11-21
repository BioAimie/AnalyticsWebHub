SET NOCOUNT ON

SELECT 
	[TicketId],
	[TicketString],
	YEAR([CreatedDate]) AS [Year],
	DATEPART(ww,[CreatedDate]) AS [Week],
	'Complaint' AS [Key],
	[RecordedValue] AS [ComplaintId]
INTO #C
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK) 
WHERE [PropertyName] LIKE 'Complaint Number' AND [CreatedDate] >= (GETDATE() - 400)

SELECT 
	[TicketId],
	[RecordedValue]
INTO #D
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK) 
WHERE [PropertyName] LIKE 'Part Disposition' AND [CreatedDate] >= (GETDATE() - 400)

SELECT
	[TicketId],
	[RecordedValue]
INTO #I
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Part Information' AND [PropertyName] LIKE 'Part Number'

SELECT
	[Year],
	[Week],
	IIF(LEFT(I.[RecordedValue],4) LIKE 'FLM1' AND D.[RecordedValue] LIKE 'FLM2-ASY-0001R', 'FA2.0',
		IIF(LEFT(I.[RecordedValue],4) LIKE 'FLM1', 'FA1.5',
		IIF(LEFT(I.[RecordedValue],4) LIKE 'FLM2', 'FA2.0', 'Torch'))) AS [Version],
	'Complaints' AS [Key],
	SUM(IIF(ISNUMERIC([ComplaintId]) = 1, 1, 0)) AS [Record]
FROM #C C INNER JOIN #I I
	ON C.[TicketId] = I.[TicketId] LEFT JOIN #D D
		ON C.[TicketId] = D.[TicketId]
WHERE (I.[RecordedValue] LIKE 'FLM%-ASY-0001%' OR I.[RecordedValue] LIKE 'HTFA-ASY-0003%')
GROUP BY 
	[Year],
	[Week],
	I.[RecordedValue],
	D.[RecordedValue]

DROP TABLE #C, #I, #D
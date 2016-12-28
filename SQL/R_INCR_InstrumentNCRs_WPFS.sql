SET NOCOUNT ON

SELECT
	[TicketId],
	[CreatedDate],
	CASE [RecordedValue]
		WHEN 'Instrument Production WIP' THEN 'All Instrument WIP'
		WHEN 'Torch Instrument WIP' THEN 'Torch'
		WHEN 'HTFA Instrument WIP' THEN 'Torch'
		WHEN 'FA2.0 Instrument WIP' THEN 'FA2.0'
		WHEN 'FA1.5 Instrument WIP' THEN 'FA1.5'
		ELSE 'Other'
	END AS [Key]
INTO #A
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'NCR Type' AND [RecordedValue] LIKE '%Instrument %WIP'

SELECT 
	[TicketId],
	[CreatedDate]
INTO #B
FROM [PMS1].[dbo].[vInstrumentBillOfMaterials] BOM WITH(NOLOCK) INNER JOIN [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] NCR WITH(NOLOCK)
	ON BOM.[ComponentItemId] = NCR.[RecordedValue]
WHERE NCR.[PropertyName] LIKE 'Part Affected'

SELECT DISTINCT [TicketId]
INTO #C
FROM
(
	SELECT [TicketId], [CreatedDate]
	FROM #A
	UNION
	SELECT [TicketId], [CreatedDate]
	FROM #B
) C
WHERE [CreatedDate] > GETDATE() - 400

SELECT 
	YEAR(D.[CreatedDate]) AS [Year],
	DATEPART(ww,D.[CreatedDate]) AS [Week],
	ISNULL(A.[Key],'Raw Material') AS [Version],
	D.[Key],
	REPLACE(REPLACE([RecordedValue],'Instrument ',''),',','-') AS [RecordedValue],
	[Record]
INTO #D
FROM
(
	SELECT
		[TicketId],
		[CreatedDate],
		[PropertyName] AS [Key],
		[RecordedValue],
		1 AS [Record]
	FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
	WHERE [Tracker] LIKE 'NCR' AND [PropertyName] LIKE 'Problem Area' AND [TicketId] IN (SELECT [TicketId] FROM #C)
) D LEFT JOIN #A A
	ON D.[TicketId] = A.[TicketId]

SELECT 
	[Year],
	[Week],
	[Version],
	[Key],
	[RecordedValue],
	SUM([Record]) AS [Record]
FROM #D 
WHERE [RecordedValue] IS NOT NULL
GROUP BY 
	[Year],
	[Week],
	[Version],
	[Key],
	[RecordedValue]
ORDER BY [Year],[Week]

DROP TABLE #A, #B, #C, #D
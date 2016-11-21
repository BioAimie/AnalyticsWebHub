SET NOCOUNT ON

SELECT
	[TicketId],
	[CreatedDate],
	[PropertyName] AS [Key],
	[RecordedValue]
INTO #InInspec
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Where Found' AND [RecordedValue] LIKE 'Incoming Inspection'

SELECT 
	[TicketId],
	[CreatedDate],
	[PropertyName] AS [Key],
	[RecordedValue]
INTO #ProbArea
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Problem Area' AND [TicketId] IN (SELECT [TicketId] FROM #InInspec)

SELECT 
	[TicketId]
INTO #BoM
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] N WITH(NOLOCK) INNER JOIN [PMS1].[dbo].[vInstrumentBillOfMaterials] B WITH(NOLOCK)
	ON N.[RecordedValue] = B.[ComponentItemID]
WHERE [ObjectName] LIKE 'Parts Affected' AND [PropertyName] LIKE 'Part Affected'

SELECT
	[TicketId]
INTO #Raw
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'NCR Type' AND [RecordedValue] LIKE 'Raw Material'

/*
When the NCR tracker is changed, will Incoming Inspection also include Board Testing? Will any other Where Founds be included in Incoming Inspection?
What will the children of Raw Material NCR Type be?

SELECT DISTINCT [RecordedValue]
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'NCR Type'
ORDER BY [RecordedValue]

SELECT DISTINCT [RecordedValue]
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Where Found' AND [TicketId] IN (SELECT [TicketId] FROM #Raw)
ORDER BY [RecordedValue]
*/

SELECT 
	R.[TicketId]
INTO #keep
FROM #Raw R INNER JOIN #BoM B
	ON R.[TicketId] = B.[TicketId]

SELECT
	[TicketId],
	YEAR([CreatedDate]) AS [Year],
	DATEPART(ww,[CreatedDate]) AS [Week],
	[Key],
	REPLACE([RecordedValue], 'Instrument ','') AS [RecordedValue],
	1 AS [Record]
INTO #Final
FROM
(
	SELECT *
	FROM #ProbArea
) D
WHERE [TicketId] IN (SELECT [TicketId] FROM #keep) 
	
SELECT 
	[Year],
	[Week],
	[Key],
	[RecordedValue],
	SUM([Record]) AS [Record]
FROM #Final
GROUP BY 
	[Year],
	[Week],
	[Key],
	[RecordedValue]
ORDER BY [Year], [Week]

DROP TABLE #InInspec, #ProbArea, #BoM, #Raw, #keep, #Final
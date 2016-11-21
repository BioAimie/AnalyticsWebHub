SET NOCOUNT ON

SELECT 
	[TicketId],
	[RecordedValue]
INTO #A
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'NCR Type' AND [RecordedValue] LIKE 'Instrument Production WIP'

SELECT
	[TicketId]
INTO #B
FROM [PMS1].[dbo].[vInstrumentBillOfMaterials] BOM WITH(NOLOCK) INNER JOIN [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] NCR WITH(NOLOCK)
	ON BOM.[ComponentItemId] = NCR.[RecordedValue]
WHERE NCR.[PropertyName] LIKE 'Part Affected'

SELECT 
	[TicketId],
	[RecordedValue]
INTO #C
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'NCR Type' AND [RecordedValue] LIKE 'Raw Material' AND [TicketId] IN (SELECT [TicketId] FROM #B)

SELECT *
INTO #D
FROM
(
	SELECT *
	FROM #A
	UNION ALL
	SELECT *
	FROM #C
) D

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[RecordedValue] AS [WhereFound]
INTO #w
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] LIKE 'NCR' AND [Stage] LIKE 'Reporting' AND  [PropertyName] LIKE 'Where Found' AND [TicketId] IN (SELECT [TicketId] FROM #D)

SELECT 
	[TicketId],
	[RecordedValue] AS [ProblemArea]
INTO #p
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] LIKE 'NCR' AND [PropertyName] LIKE 'Problem Area' AND [TicketId] IN (SELECT [TicketId] FROM #D)

SELECT 
	[TicketId],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #fs
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Failure Details' AND [TicketId] IN (SELECT [TicketId] FROM #D)

SELECT 
	[TicketString],
	[CreatedDate],
	[WhereFound],
	[ProblemArea],
	[FailCat],
	[SubFailCat],
	1 AS [Record]
INTO #wpfs
FROM #w W INNER JOIN #p P
	ON W.[TicketId] = P.[TicketId] INNER JOIN 
	(
		SELECT 
			[TicketId],
			[Failure Category] AS [FailCat],
			[Sub-failure Category] AS [SubFailCat]
		FROM 
		(
		SELECT *
		FROM #fs 
		) P 
		PIVOT
		(
			MAX([RecordedValue])
			FOR [PropertyName]
			IN
			(
				[Failure Category],
				[Sub-failure Category]
			)
		) PIV
	) FS
		ON W.[TicketId] = FS.[TicketId]
WHERE [CreatedDate] > CONVERT(datetime, '2014-06-30') AND [FailCat] IS NOT NULL

SELECT 
	[TicketString],
	YEAR([CreatedDate]) AS [Year],
	MONTH([CreatedDate]) AS [Month],
	IIF(MONTH([CreatedDate]) < 4, 1, 
		IIF(MONTH([CreatedDate]) < 7, 2, 
		IIF(MONTH([CreatedDate]) < 10, 3, 4))) AS [Quarter], 
	IIF([CreatedDate] > GETDATE() - 30, 1, 0) AS [last30days],
	IIF([CreatedDate] > GETDATE() - 90, 1, 0) AS [last90days],
	IIF([CreatedDate] > GETDATE() - 365, 1, 0) AS [lastYear],
	[WhereFound],
	[ProblemArea],
	[FailCat],
	[SubFailCat],
	[Record]
FROM #wpfs

DROP TABLE #A, #B, #C, #D, #fs, #p, #w, #wpfs
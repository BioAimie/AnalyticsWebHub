SET NOCOUNT ON

SELECT
	[TicketId],
	IIF([RecordedValue] IN ('HTFA Instrument WIP','Torch Instrument WIP'),'Torch',
		IIF([RecordedValue] = 'FA2.0 Instrument WIP', 'FA2.0', 
		IIF([RecordedValue] = 'FA1.5 Instrument WIP', 'FA1.5', 'General'))) AS [Version]
INTO #ncrType
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'NCR Type' AND [RecordedValue] LIKE '%Instrument% WIP'

SELECT
	[TicketId]
INTO #instRawMat
FROM [PMS1].[dbo].[vInstrumentBillOfMaterials] BOM WITH(NOLOCK) INNER JOIN [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] NCR WITH(NOLOCK)
	ON BOM.[ComponentItemId] = NCR.[RecordedValue]
WHERE NCR.[PropertyName] LIKE 'Part Affected'

SELECT 
	[TicketId],
	'Raw Material' AS [Version]
INTO #ncrRaw
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'NCR Type' AND [RecordedValue] LIKE 'Raw Material' AND [TicketId] IN (SELECT [TicketId] FROM #instRawMat)

SELECT *
INTO #instNCR
FROM
(
	SELECT *
	FROM #ncrType
	UNION ALL
	SELECT *
	FROM #ncrRaw
) D

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[RecordedValue] AS [WhereFound]
INTO #w
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] LIKE 'NCR' AND [Stage] LIKE 'Reporting' AND  [PropertyName] LIKE 'Where Found' AND [TicketId] IN (SELECT [TicketId] FROM #instNCR)

SELECT 
	[TicketId],
	[RecordedValue] AS [ProblemArea]
INTO #p
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] LIKE 'NCR' AND [PropertyName] LIKE 'Problem Area' AND [TicketId] IN (SELECT [TicketId] FROM #instNCR)

SELECT 
	[TicketId],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #fs
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Failure Details' AND [TicketId] IN (SELECT [TicketId] FROM #instNCR)

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
INTO #master
FROM #wpfs

SELECT 
	[Year],
	[Month],
	[Quarter],
	[last30days],
	[last90days],
	[lastYear],
	[WhereFound],
	[ProblemArea],
	[FailCat],
	[SubFailCat],
	SUM([Record]) AS [Record]
FROM #master
GROUP BY
	[Year],
	[Month],
	[Quarter],
	[last30days],
	[last90days],
	[lastYear],
	[WhereFound],
	[ProblemArea],
	[FailCat],
	[SubFailCat]

DROP TABLE #ncrType, #instRawMat, #ncrRaw, #instNCR, #w, #p, #fs, #wpfs, #master
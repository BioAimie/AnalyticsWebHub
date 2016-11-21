SET NOCOUNT ON

SELECT 
	[TicketId],
	[TicketString],
	[Status],
	[CreatedDate],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #root
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Root Causes'

SELECT 
	[TicketId],
	[RecordedValue] AS [FailType]
INTO #fail
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Early Failure Type'

SELECT 
	[TicketId],
	[TicketString],
	YEAR([CreatedDate]) AS [Year],
	MONTH([CreatedDate]) AS [Month],
	IIF(MONTH([CreatedDate]) < 4, 1, 
		IIF(MONTH([CreatedDate]) < 7, 2, 
		IIF(MONTH([CreatedDate]) < 10, 3, 4))) AS [Quarter], 
	IIF([CreatedDate] > GETDATE() - 30, 1, 0) AS [last30days],
	IIF([CreatedDate] > GETDATE() - 90, 1, 0) AS [last90days],
	IIF([CreatedDate] > GETDATE() - 365, 1, 0) AS [lastYear],
	[Where Found] AS [WhereFound],
	[Problem Area] AS [ProblemArea],
	[Failure Category] AS [FailCat],
	[Sub-failure Category] AS [SubFailCat],
	1 AS [Record]
INTO #pvc
FROM
(
	SELECT *
	FROM #root
) P
PIVOT
(
	MAX([RecordedValue])
	FOR [PropertyName]
	IN
	(
		[Where Found],
		[Problem Area],
		[Failure Category],
		[Sub-failure Category]
	)
) PIV
WHERE [Where Found] IS NOT NULL AND [Where Found] NOT LIKE 'N/A' AND [Where Found] NOT LIKE 'No failure complaint'

SELECT 
	[TicketString],
	[Year],
	[Month],
	[Quarter], 
	[last30days],
	[last90days],
	[lastYear],
	[FailType],
	[WhereFound],
	[ProblemArea],
	[FailCat],
	[SubFailCat],
	1 AS [Record]
FROM #pvc P LEFT JOIN #fail F
	ON P.[TicketId] = F.[TicketId]

DROP TABLE #root, #pvc, #fail
SET NOCOUNT ON

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[Part Number] AS [PartNo],
	[Early Failure Type] AS [Fail]
INTO #Fails
FROM
(
	SELECT	
		[TicketId],
		[TicketString],
		[CreatedDate],
		[ObjectId],
		[PropertyName],
		[RecordedValue] 
	FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
	WHERE [ObjectName] LIKE 'Part Information' AND [Tracker] LIKE 'RMA'
) P
PIVOT
(
	MAX([RecordedValue])
	FOR [PropertyName]
	IN 
	(
		[Part Number],
		[Early Failure Type]
	)
) PIV
WHERE [Early Failure Type] IS NOT NULL AND [Early Failure Type] NOT LIKE 'N/A' 
	AND ([Part Number] LIKE 'FLM%-ASY-0001%' OR [Part Number] LIKE 'HTFA-ASY-0001%' OR [Part Number] LIKE 'HTFA-ASY-0003%' OR [Part Number] LIKE 'HTFA-ASY-0104%' OR [Part Number] LIKE 'HTFA-SUB-0103%')

SELECT
	F.[TicketId],
	F.[CreatedDate],
	F.[Fail], 
	F.[PartNo],
	IIF(F.[PartNo] LIKE 'FLM1-%', 'FA1.5',
		IIF(F.[PartNo] LIKE 'FLM2-%', 'FA2.0',
		IIF(F.[PartNo] LIKE 'HTFA-ASY-0001%' OR F.[PartNo] LIKE 'HTFA-ASY-0104%', 'Torch Base', 'Torch Module'))) AS [Version],
	A.[ProblemArea],
	A.[FailCat],
	A.[SubFailCat] 
INTO #Master
FROM #Fails F LEFT JOIN 
(
	SELECT 
		[TicketId],
		[Problem Area] AS [ProblemArea],
		[Failure Category] AS [FailCat],
		[Sub-Failure Category] AS [SubFailCat] 
	FROM
	(
		SELECT 
			[TicketId],
			[ObjectId],
			[PropertyName],
			[RecordedValue] 
		FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
		WHERE [ObjectName] LIKE 'Root Causes' AND [TicketId] IN (SELECT [TicketId] FROM #Fails)
	) P
	PIVOT
	(
		MAX([RecordedValue])
		FOR [PropertyName]
		IN
		(
			[Problem Area],
			[Failure Category],
			[Sub-Failure Category]
		)
	) PIV
	WHERE [Problem Area] IS NOT NULL
) A
	ON F.[TicketId] = A.[TicketId]

SELECT 
	IIF([DistinctRecord] > 1, 0, 1) AS [DistinctRecord],
	YEAR([CreatedDate]) AS [Year],
	MONTH([CreatedDate]) AS [Month],
	DATEPART(ww,[CreatedDate]) AS [Week],
	[Fail],
	IIF([Fail] IN ('DOA','ELF'), 'Production', 'Service') AS [Department],
	[Version],
	[ProblemArea],
	[FailCat],
	[SubFailCat],
	1 AS [Record]
FROM
(
	SELECT 
		ROW_NUMBER() OVER(PARTITION BY [TicketId] ORDER BY [Fail]) AS [DistinctRecord],
		*
	FROM #Master
) A

DROP TABLE #Fails, #Master

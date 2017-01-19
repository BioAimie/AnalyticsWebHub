SET NOCOUNT ON

SELECT
	[TicketId],
	[TicketString],
	[CreatedDate],
	[PropertyName] AS [Key],
	[RecordedValue]
INTO #FinalQC
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] LIKE 'NCR' AND [PropertyName] LIKE 'Where Found' AND [RecordedValue] LIKE '%Final QC'
ORDER BY [TicketId]

SELECT
	[TicketId]
INTO #type
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'NCR Type' AND [RecordedValue] LIKE '%Instrument %WIP' AND [TicketId] IN (SELECT [TicketId] FROM #FinalQC)

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	IIF([RecordedValue] LIKE 'FLM1%','FA1.5',
		IIF([RecordedValue] LIKE 'FLM2%','FA2.0',
		IIF([RecordedValue] LIKE 'HTFA%','Torch','Other'))) AS [Version]
INTO #version
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Component Part Number' AND [TicketId] IN (SELECT [TicketId] FROM #type)

SELECT 
	[TicketId],
	[PropertyName] AS [Key],
	[RecordedValue]
INTO #ProbArea
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Problem Area' AND [TicketId] IN (SELECT [TicketId] FROM #type)

SELECT
	YEAR([CreatedDate]) AS [Year],
	DATEPART(ww,[CreatedDate]) AS [Week],
	[Version],
	[Key],
	REPLACE([RecordedValue], 'Instrument ','') AS [RecordedValue],
	COUNT(V.[TicketId]) AS [Record]
FROM #version V LEFT JOIN #ProbArea P
	ON V.[TicketId] = P.[TicketId]
WHERE [RecordedValue] IS NOT NULL AND [Version] NOT LIKE 'Other' AND [RecordedValue] <> 'Cannot Duplicate - 60 Melt Probe Tm' AND [RecordedValue] <> 'Instrument QC Pouch'
GROUP BY
	YEAR([CreatedDate]),
	DATEPART(ww,[CreatedDate]),
	[Version],
	[Key],
	[RecordedValue]

DROP TABLE #FinalQC, #ProbArea, #type, #version
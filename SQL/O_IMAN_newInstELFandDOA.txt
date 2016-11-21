SET NOCOUNT ON

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #partInfo
FROM [RO_TRACKERS].[Trackers].[dbo].[vAllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Part Information'

SELECT 
	[TicketString],
	YEAR([CreatedDate]) AS [Year],
	MONTH([CreatedDate]) AS [Month],
	DATEPART(ww,[CreatedDate]) AS [Week],
	IIF(LEFT([Part Number], 4) LIKE 'FLM1', 'FA1.5',
		IIF(LEFT([Part Number],4) LIKE 'FLM2', 'FA2.0', 'Torch')) AS [Version],
	[Early Failure Type] AS [Key],
	1 AS [Record]
FROM
(
	SELECT *
	FROM #partInfo
) P
PIVOT
(
	MAX([RecordedValue]) 
	FOR [PropertyName]
	IN
	(
		[Part Number],
		[Lot/Serial Number],
		[Early Failure Type]
	)
) PIV
WHERE [Early Failure Type] IS NOT NULL AND [Early Failure Type] NOT LIKE 'N/A' AND 
	[Part Number] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-ASY-0003') AND [Early Failure Type] IN ('DOA','ELF')
ORDER BY [TicketId]

DROP TABLE #partInfo
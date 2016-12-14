SET NOCOUNT ON

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #partInfo
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Part Information'

SELECT 
	YEAR([CreatedDate]) AS [Year],
	MONTH([CreatedDate]) AS [Month],
	DATEPART(ww,[CreatedDate]) AS [Week],
	IIF(LEFT([Part Number], 4) LIKE 'FLM1', 'FA1.5',
		IIF(LEFT([Part Number],4) LIKE 'FLM2', 'FA2.0', 'Torch')) AS [Version],
	[Early Failure Type] AS [Key],
	COUNT(DISTINCT [TicketId]) AS [Record]
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
WHERE [Early Failure Type] IS NOT NULL AND [Early Failure Type] NOT LIKE 'N/A' AND [Early Failure Type] NOT LIKE '' AND ([Part Number] LIKE 'FLM%-ASY-0001%' OR [Part Number] LIKE 'HTFA-ASY-0003%' OR [Part Number] LIKE 'HTFA-SUB-0103%')
GROUP BY YEAR([CreatedDate]), MONTH([CreatedDate]), DATEPART(ww, [CreatedDate]), [Part Number], [Early Failure Type]

DROP TABLE #partInfo
SET NOCOUNT ON

SELECT 
	[TicketId],
	MAX(CAST([QCDate] AS DATE)) AS [QcDate]
INTO #qcDate
FROM [PMS1].[dbo].[RMAQCCheck]
WHERE [QCDate] IS NOT NULL
GROUP BY [TicketId]

SELECT 
	Q.[QcDate] AS [Date],
	YEAR(Q.[QcDate]) AS [Year],
	MONTH(Q.[QcDate]) AS [Month],
	DATEPART(ww, Q.[QcDate]) AS [Week],
	IIF(LEFT([PartNumber],4) LIKE 'FLM1', 'FA1.5',
		IIF(LEFT([PartNumber],4) LIKE 'FLM2', 'FA2.0', 'Torch')) AS [Version],
	'ShippedRMA' AS [Key],
	COUNT(DISTINCT Q.[TicketId]) AS [Record]
FROM #qcDate Q
INNER JOIN [PMS1].[dbo].[RMAPartInformation] P ON P.[TicketId] = Q.[TicketId]
WHERE ([PartNumber] LIKE 'FLM%-ASY-0001%' OR [PartNumber] LIKE 'HTFA-ASY-0003%' OR [PartNumber] LIKE 'HTFA-SUB-0103%') 
GROUP BY [QcDate], YEAR([QcDate]), MONTH([QcDate]), DATEPART(ww, [QcDate]), [PartNumber]
ORDER BY [QcDate]

DROP TABLE #qcDate

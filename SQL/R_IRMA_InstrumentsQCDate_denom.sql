SET NOCOUNT ON

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	UPPER([RecordedValue]) AS [PartNo]
INTO #PartInfo
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] = 'RMA' AND [ObjectName] = 'Part Information'
	AND [PropertyName] = 'Part Number' AND ([RecordedValue] LIKE 'FLM%-ASY-0001%' OR [RecordedValue] LIKE 'HTFA-ASY-000%' OR [RecordedValue] LIKE 'HTFA-SUB-0103%')

SELECT 
	[TicketId], 
	[ObjectId], 
	[PropertyName],
	[RecordedValue]
INTO #QCcheck
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] o WITH(NOLOCK) 
WHERE [Tracker] = 'RMA' AND [ObjectName] = 'QC Check' AND [TicketId] IN (SELECT [TicketId] FROM #PartInfo)

SELECT 
	[TicketId],
	CAST([QC Date] AS DATE) AS [QCDate],
	[DHR Complete],
	[ObjectId]
INTO #ThruQC
FROM
(
	SELECT *
	FROM #QCcheck
) P
PIVOT
(
	MAX([RecordedValue]) 
	FOR [PropertyName]
	IN
	(
		[QC Tech],
		[QC Date],
		[QC Hours],
		[DHR Complete]
	)
) PIV
WHERE [DHR Complete] LIKE 'Yes' AND [QC Date] IS NOT NULL

SELECT 
	[TicketId],
	MAX([QCDate]) AS [Date]
INTO #QCDate
FROM #ThruQC
GROUP BY [TicketId]

SELECT
	YEAR([Date]) AS [Year],
	MONTH([Date]) AS [Month],
	DATEPART(ww,[Date]) AS [Week],
	[PartNo], 
	CASE
		WHEN [PartNo] LIKE 'FLM1-ASY-0001' THEN 'FA1.5'
		WHEN [PartNo] LIKE 'FLM1-ASY-0001R' THEN 'FA1.5R'
		WHEN [PartNo] LIKE 'FLM2-ASY-0001' THEN 'FA2.0'
		WHEN [PartNo] LIKE 'FLM2-ASY-0001R' THEN 'FA2.0R'
		WHEN [PartNo] LIKE 'HTFA-ASY-0003%' THEN 'Torch Module'
		WHEN [PartNo] LIKE 'HTFA-SUB-0103%' THEN 'Torch Module'
		WHEN [PartNo] LIKE 'HTFA-ASY-0001%' THEN 'Torch Base'
		ELSE 'Other'
	END AS [Version],
	1 AS [Record]
INTO #final
FROM #PartInfo p INNER JOIN #QCDate q
	ON p.[TicketId] = q.[TicketId]

SELECT 
	[Year],
	[Month],
	[Week], 
	[Version],
	SUM([Record]) AS [Record]
FROM #final 
GROUP BY [Year], [Month], [Week], [Version]

DROP TABLE #PartInfo, #QCcheck, #ThruQC, #QCDate, #final 
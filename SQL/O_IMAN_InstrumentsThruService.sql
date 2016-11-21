SET NOCOUNT ON

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #PartInfo
FROM [RO_TRACKERS].[Trackers].[dbo].[vAllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] LIKE 'RMA' AND [ObjectName] LIKE 'Part Information'

SELECT
	[Part Number],
	[TicketString],
	[TicketID],
	IIF (LEFT([Part Number],4) LIKE 'FLM1', 'FA1.5',
		IIF (LEFT([Part Number],4) LIKE 'FLM2', 'FA2.0', 
		IIF (LEFT([Part Number],4) LIKE 'COMP', 'Laptop', 'Torch'))) AS [Version],
	IIF ([Disposition] LIKE '%BFDx%', 'BFDx',
		IIF ([Disposition] LIKE 'Refurbish', 'Refurbish',
		IIF ([Disposition] LIKE '%customer', 'Customer', 'Other'))) AS [Disposition],
	YEAR([CreatedDate]) AS [Year],
	MONTH([CreatedDate]) AS [Month],
	DATEPART(ww, [CreatedDate]) AS [Week]
INTO #Tickets
FROM 
(
	SELECT *
	FROM #PartInfo P
	PIVOT
	(
		MAX([RecordedValue]) 
		FOR [PropertyName]
		IN
		(
			[Part Number],
			[Disposition]
		)
	) PIV
) S
WHERE ([Part Number] LIKE 'FLM%-ASY-0001%' OR [Part Number] LIKE 'HTFA-%' OR [Part Number] LIKE 'COMP-%')

SELECT 
	[Year],
	[Month],
	[Week],
	[Version],
	[Disposition],
	'ToQC' AS [Key],
	COUNT([TicketID]) AS [Record]
INTO #ToQC
FROM 
(
	SELECT 
		YEAR(p.[RecordedValue]) AS [Year],
		MONTH(p.[RecordedValue]) AS [Month],
		DATEPART(ww, p.[RecordedValue]) AS [Week],
		t.[Version],
		t.[Disposition],
		p.[TicketID]
	FROM [RO_TRACKERS].[Trackers].[dbo].[vAllPopertiesByStatus] p WITH(NOLOCK) JOIN #Tickets t
		ON p.[TicketID] = t.[TicketID]
	WHERE [PropertyName] LIKE 'Service Completed' AND [RecordedValue] IS NOT NULL AND [RecordedValue] NOT LIKE ''
) S
GROUP BY [Year], [Month], [Week], [Version], [Disposition]

SELECT 
	[Year],
	[Month],
	[Week],
	[Version],
	[Disposition],
	'ThruQC' AS [Key],
	COUNT([TicketID]) AS [Record]
INTO #ThruQC
FROM 
(
	SELECT 
		[TicketString],
		YEAR(MAX([QC Date])) AS [Year],
		MONTH(MAX([QC Date])) AS [Month],
		DATEPART(ww, MAX([QC Date])) AS [Week],
		[Version],
		[Disposition],
		[TicketID]
	FROM
	(
		SELECT 
			t.[TicketString],
			t.[Part Number],
			o.[TicketId],
			o.[ObjectId],
			o.[PropertyName],
			o.[RecordedValue],
			t.[Version],
			t.[Disposition]
		FROM [RO_TRACKERS].[Trackers].[dbo].[vAllObjectPropertiesByStatus] o WITH(NOLOCK) JOIN #Tickets t
			ON o.[TicketID] = t.[TicketID]
		WHERE [ObjectName] LIKE 'QC Check' 
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
	GROUP BY [TicketString],[TicketID], [Version], [Disposition]
) S
GROUP BY [Year], [Month], [Week], [Version], [Disposition]

SELECT 
	[Year],
	[Month],
	[Week],
	[Version],
	[Disposition],
	'Received' AS [Key],
	COUNT([TicketID]) AS [Record]
INTO #Received
FROM 
(
	SELECT
		YEAR(MAX([RecordedValue])) AS [Year],
		MONTH(MAX([RecordedValue])) AS [Month],
		DATEPART(ww, MAX([RecordedValue])) AS [Week],
		[Version],
		[Disposition],
		p.[TicketID]
	FROM [RO_TRACKERS].[Trackers].[dbo].[vAllPopertiesByStatus] p WITH(NOLOCK) JOIN #Tickets t
		ON p.[TicketID] = t.[TicketID]
	WHERE [PropertyName] LIKE 'Quarantine Release Date' AND [RecordedValue] IS NOT NULL
	GROUP BY p.[TicketID], [Version], [Disposition]
) S
GROUP BY [Year], [Month], [Week], [Version], [Disposition]

SELECT 
	[Year],
	[Month],
	[Week],
	[Version],
	[Disposition],
	'Opened' AS [Key],
	COUNT([TicketID]) AS [Record]
INTO #Opened
FROM #Tickets
GROUP BY [Year], [Month], [Week], [Version], [Disposition]

SELECT 
	[Year],
	[Month],
	[Week],
	[Version],
	[Disposition],
	'Shipped' AS [Key],
	COUNT([TicketID]) AS [Record]
INTO #Shipped
FROM 
(
	SELECT 
		YEAR(CAST(p.[RecordedValue] AS DATE)) AS [Year],
		MONTH(CAST(p.[RecordedValue] AS DATE)) AS [Month],
		DATEPART(ww, CAST(p.[RecordedValue] AS DATE)) AS [Week],
		t.[Version],
		t.[Disposition],
		p.[TicketID]
	FROM [RO_TRACKERS].[Trackers].[dbo].[vAllPopertiesByStatus] p WITH(NOLOCK) JOIN #Tickets t
		ON p.[TicketID] = t.[TicketID]
	WHERE [PropertyName] LIKE 'Shipping Date'
) S
GROUP BY [Year], [Month], [Week], [Version], [Disposition]	

SELECT 
	[Year],
	[Month],
	[Week],
	[Version],
	[Disposition],
	ISNULL([Opened], 0) AS [Opened],
	ISNULL([Received],0) AS [Received],
	ISNULL([ToQC],0) AS [ToQC],
	ISNULL([ThruQC],0) AS [ThruQC],
	ISNULL([Shipped],0) AS [Shipped]
FROM 
(
	SELECT *
	FROM #ToQC
	UNION ALL
	SELECT *
	FROM #ThruQC
	UNION ALL
	SELECT *
	FROM #Received
	UNION ALL
	SELECT *
	FROM #Opened
	UNION ALL 
	SELECT *
	FROM #Shipped
) P
PIVOT
(
	SUM([Record])
	FOR [Key]
	IN 
	(
		[Opened], 
		[Received],
		[ToQC],
		[ThruQC],
		[Shipped]
	)
) PIV
ORDER BY [Year], [Month], [Week], [Version], [Disposition]

DROP TABLE #PartInfo, #Tickets, #ToQC, #ThruQC, #Received, #Opened, #Shipped

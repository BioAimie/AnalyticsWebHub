SET NOCOUNT ON

SELECT 
	[TicketId],
	[CustId],
	[Type]  
INTO #Tickets
FROM 
(
	SELECT 
		[TicketId],
		IIF([CustId] LIKE 'BMX-NC', 'Keep',
			IIF([CustId] IN ('BIODEF','NGDS','IDATEC'),'DoNotKeep',
			IIF([CustId] LIKE 'DIST%','DoNotKeep',
			IIF([CustId] LIKE 'BMX%', 'DoNotKeep', 'Keep')))) AS [CustKeep],
		[CustId],
		[Type],
		[ServiceCenter] 
	FROM 
	(
		SELECT
			[TicketId],
			[Customer Id] AS [CustId],
			[RMA Type] AS [Type],
			[Assigned Service Center]  AS [ServiceCenter]
		FROM
		(
			SELECT 
				[TicketId],
				[PropertyName],
				[RecordedValue] 
			FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
			WHERE [PropertyName] IN ('RMA Type', 'Customer Id', 'Assigned Service Center') AND [Tracker] LIKE 'RMA'
		) A
		PIVOT
		(
			MAX([RecordedValue])
			FOR [PropertyName]
			IN
			(
				[Customer Id],
				[RMA Type],
				[Assigned Service Center] 
			)
		) PIV
	) B
	WHERE [Type] LIKE 'Customer%' AND [ServiceCenter] LIKE 'Salt Lake' 
) C
WHERE [CustKeep] LIKE 'Keep'

SELECT 
	[TicketId],
	[TicketString],
	[RecordedValue] AS [PartNo]
INTO #partNo
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Part Information' AND [PropertyName] LIKE 'Part Number' 
	AND ([RecordedValue] LIKE 'FLM%-ASY-0001%' OR [RecordedValue] LIKE 'HTFA-ASY-000%' OR [RecordedValue] LIKE 'HTFA-SUB-0103%')
	AND [TicketId] IN (SELECT [TicketId] FROM #Tickets)

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate], 
	[RMA Type] AS [Type],
	[Service Tier] AS [ServiceTier]
INTO #tier
FROM
(
	SELECT 
		[TicketId],
		[TicketString],
		[CreatedDate],
		[PropertyName],
		[RecordedValue] 
	FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
	WHERE [PropertyName] IN ('RMA Type', 'Service Tier')
) AS P
PIVOT
(
	MAX([RecordedValue])
	FOR [PropertyName]
	IN
	(
		[RMA Type],
		[Service Tier]
	)
) PIV
WHERE [RMA Type] IN ('Customer - Failure', 'Customer - No Failure') AND [Service Tier] IS NOT NULL
	AND [TicketId] IN (SELECT [TicketId] FROM #Tickets)
ORDER BY [TicketId]

SELECT 
	YEAR([CreatedDate]) AS [Year],
	MONTH([CreatedDate]) AS [Month],
	DATEPART(ww,[CreatedDate]) AS [Week],
	IIF([PartNo] LIKE 'FLM1-ASY-0001%', 'FA1.5',
		IIF([PartNo] LIKE 'FLM2-ASY-0001%', 'FA2.0',
		IIF([PartNo] LIKE 'HTFA-%', 'Torch', 'Other'))) AS [Version],
	[Type],
	[ServiceTier],
	1 AS [Record] 
FROM #partNo P INNER JOIN #tier T
	ON P.[TicketId] = T.[TicketId]

DROP TABLE #Tickets, #partNo, #tier

SET NOCOUNT ON

SELECT 
	[TicketId] 
INTO #Tickets
FROM 
(
	SELECT 
		[TicketId],
		IIF([CustId] LIKE 'BMX-NC', 'Keep',
			IIF([CustId] IN ('BIODEF','NGDS'),'DoNotKeep',
			IIF([CustId] LIKE 'BMX%', 'DoNotKeep', 'Keep'))) AS [CustKeep],
		[CustId],
		[Type]
	FROM 
	(
		SELECT
			[TicketId],
			[Customer Id] AS [CustId],
			[RMA Type] AS [Type]
		FROM
		(
			SELECT 
				[TicketId],
				[PropertyName],
				[RecordedValue] 
			FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
			WHERE [PropertyName] IN ('RMA Type', 'Customer Id') AND [Tracker] LIKE 'RMA'
		) A
		PIVOT
		(
			MAX([RecordedValue])
			FOR [PropertyName]
			IN
			(
				[Customer Id],
				[RMA Type] 
			)
		) PIV
	) B
	WHERE [Type] LIKE 'Customer%' 
) C
WHERE [CustKeep] LIKE 'Keep'

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[Part Number] AS [PartNo],
	[Loaner Needed] AS [Loaner]
INTO #Master
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
	WHERE [ObjectName] LIKE 'Part Information' AND [TicketId] IN (SELECT [TicketId] FROM #Tickets)
) P
PIVOT
(
	MAX([RecordedValue])
	FOR [PropertyName]
	IN
	(
		[Product Type],
		[Part Number],
		[Loaner Needed]
	)
) PIV
ORDER BY [TicketId]

SELECT 
	YEAR([CreatedDate]) AS [Year],
	MONTH([CreatedDate]) AS [Month],
	DATEPART(ww,[CreatedDate]) AS [Week],
	[Loaner],
	'CustRMAs' AS [Key],
	1 AS [Record]
FROM #Master
WHERE [PartNo] LIKE 'FLM%-ASY-0001%' OR [PartNo] LIKE 'HTFA-ASY-000%' OR [PartNo] LIKE 'HTFA-SUB-0103%'

DROP TABLE #Tickets, #Master

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
	[CreatedDate],
	[Part Number] AS [PartNo],
	[Loaner Needed] AS [Loaner],
	[Disposition]
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
		[Loaner Needed], 
		[Disposition] 
	)
) PIV
--WHERE [Disposition] LIKE 'Return to Customer' --do not include for now
ORDER BY [TicketId]

SELECT 
	YEAR([CreatedDate]) AS [Year],
	MONTH([CreatedDate]) AS [Month],
	DATEPART(ww,[CreatedDate]) AS [Week],
	[Loaner],
	'CustRMAs' AS [Key],
	1 AS [Record]
FROM #Master M 
WHERE ([PartNo] LIKE 'FLM1-ASY-0001%' OR [PartNo] LIKE 'FLM2-ASY-0001%') --only include these part numbers per Matt 
	AND [Loaner] NOT LIKE 'N/A'

DROP TABLE #Tickets, #Master

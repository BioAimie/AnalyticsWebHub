SET NOCOUNT ON

SELECT
	[TicketId],
	[RecordedValue] AS [Date]
INTO #aware
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] = 'COMPLAINT' AND [PropertyName] = 'Became Aware Date'

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #fail
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] = 'COMPLAINT' AND [ObjectName] = 'BFDX Part Number'

SELECT
	[LotNo],
	SUBSTRING([RecordedValue], 1, CHARINDEX('-',[RecordedValue], 1)-1) AS [Complaint],
	SUM([Record]) AS [Record]
INTO #field
FROM
(
	SELECT 
		[TicketString],
		[CreatedDate],
		[ObjectId],
		ISNULL([Product Line],'FilmArray') AS [Version],
		[Part Number] AS [PartNo],
		LEFT([Lot/Serial Number], 6) AS [LotNo],
		[Failure Mode] AS [RecordedValue],
		CAST(REPLACE([Quantity Affected],',','') AS INT) AS [Record]
	FROM #fail F
	PIVOT
	(
		MAX([RecordedValue])
		FOR [PropertyName]
		IN
		(
			[Lot/Serial Number],
			[Part Number],
			[Failure Mode] ,
			[Quantity Affected],
			[Product Line]
		)
	) PIV
	WHERE ([Failure Mode] LIKE 'Failure To Hydrate-3-1' OR [Failure Mode] LIKE 'Control Failure-2-0') AND ISNUMERIC([Quantity Affected]) = 1
) T
WHERE ISNUMERIC([LotNo]) = 1 
GROUP BY 
	[LotNo],
	[RecordedValue]

SELECT 
	[LotNo],
	SUM([QtyShipped]) AS [QtyShipped]
INTO #lotsShipped
FROM
(
	SELECT
		[LotNo] AS [LotNo],
		IIF([ItemID] IN ('RFIT-ASY-0001','RFIT-ASY-0018','RFIT-ASY-0105','RFIT-ASY-0114','RFIT-ASY-0116','RFIT-ASY-0118','RFIT-ASY-0120','RFIT-ASY-0124','RFIT-ASY-0126','RFIT-ASY-0002','RFIT-ASY-0007',
							'RFIT-ASY-0008','RFIT-ASY-0015','RFIT-ASY-0092','RFIT-ASY-0097','RFIT-ASY-0098','RFIT-ASY-0100','RFIT-ASY-0108','RFIT-ASY-0111','RFIT-ASY-0112','RFIT-ASY-0129','RFIT-ASY-0136',
							'RFIT-ASY-0118','NI-RFIT-ASY-0001','NI-RFIT-ASY-0002','NI-RFIT-ASY-0105','NI-RFIT-ASY-0114','NI-RFIT-ASY-0116','NI-RFIT-ASY-0118','NI-RFIT-ASY-0124','NI-RFIT-ASY-0126','NI-RFIT-ASY-0127'), 
			[DistQty]*-30, 
			IIF([ItemID] IN ('RFIT-ASY-0090','RFIT-ASY-0091','RFIT-ASY-0098'), [DistQty]*-1, [DistQty]*-6)) AS [QtyShipped]
	FROM [SQL1-RO].[mas500_app].[dbo].[vdvLotTransactions] WITH(NOLOCK)
	WHERE [TranTypeID] LIKE 'SH' AND [ItemID] IN
	(
		'RFIT-ASY-0001',
		'RFIT-ASY-0094',
		'RFIT-ASY-0096',
		'RFIT-ASY-0104',
		'RFIT-ASY-0105',
		'RFIT-ASY-0107',
		'RFIT-ASY-0109',
		'RFIT-ASY-0114',
		'RFIT-ASY-0116',
		'RFIT-ASY-0118',
		'RFIT-ASY-0119',
		'RFIT-ASY-0120',
		'RFIT-ASY-0122',
		'RFIT-ASY-0124',
		'RFIT-ASY-0125',
		'RFIT-ASY-0126',
		'RFIT-ASY-0127',
		'RFIT-ASY-0129','RFIT-ASY-0130','RFIT-ASY-0136','RFIT-ASY-0137',
		'NI-RFIT-ASY-0001',
		'NI-RFIT-ASY-0096',
		'NI-RFIT-ASY-0104',
		'NI-RFIT-ASY-0105',
		'NI-RFIT-ASY-0107',
		'NI-RFIT-ASY-0109',
		'NI-RFIT-ASY-0114',
		'NI-RFIT-ASY-0116',
		'NI-RFIT-ASY-0118',
		'NI-RFIT-ASY-0119',
		'NI-RFIT-ASY-0124',
		'NI-RFIT-ASY-0125',
		'NI-RFIT-ASY-0126',
		'NI-RFIT-ASY-0127'
	)
) T
GROUP BY [LotNo] 

SELECT
	P.[LotNo],
	F.[Complaint],
	SUM(F.[Record]) AS [ComplaintQty],
	SUM(S.[QtyShipped]) AS [QtyShipped]
FROM #field F INNER JOIN
(
	SELECT *
	FROM #lotsShipped
	WHERE [LotNo] IN (SELECT DISTINCT [LotNo] FROM #field)
) S 
	ON F.[LotNo] = S.[LotNo] INNER JOIN 
(
	SELECT
		L.[LotNumber] AS [KitLot],
		LEFT(UL.[LotNumber],6) AS [LotNo]
	FROM [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[UtilizedParts] U WITH(NOLOCK)
			ON L.[LotNumberId] = U.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[Lots] UL WITH(NOLOCK)
				ON U.[LotNumber] = UL.[LotNumber]
	WHERE L.[LotNumber] IN (SELECT DISTINCT [LotNo] FROM #field) AND UL.[BatchRecordId] LIKE 'FA-201C'
	GROUP BY L.[LotNumber], LEFT(UL.[LotNumber],6)
) P
	ON S.[LotNo] = P.[KitLot]
GROUP BY 
	P.[LotNo], 
	F.[Complaint]

DROP TABLE #aware, #fail, #field, #lotsShipped
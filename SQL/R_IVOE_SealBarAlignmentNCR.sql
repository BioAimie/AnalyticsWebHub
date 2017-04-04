SET NOCOUNT ON

SELECT
	[TicketId]
INTO #problemAreaTickets
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus]
WHERE [Tracker]='NCR' AND [PropertyName]='Problem Area' AND [RecordedValue] LIKE '%Seal Bar%'

SELECT DISTINCT
	[TicketId],
	[TicketString],
	[CreatedDate],
	[RecordedValue] AS [SubfailureCategory]
INTO #tickets
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus]
WHERE [Tracker]='NCR' 
	AND [ObjectName]='Failure Details'
	AND [PropertyName]='Sub-failure Category'
	AND [RecordedValue] LIKE '%alignment%'
	AND [TicketId] IN (SELECT [TicketId] FROM #problemAreaTickets)

SELECT
	[TicketId],
	[TicketString],
	REPLACE(LTRIM(RTRIM([Lot or Serial Number])),'KTM','TM') AS [SerialNo],
	REPLACE([Component Part Number],' ','') AS [PartNo]
INTO #partInfo
FROM (
	SELECT 
		[TicketId],
		[TicketString],
		[ObjectId],
		[PropertyName],
		[RecordedValue]
	FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus]
	WHERE [Tracker]='NCR' AND [ObjectName]='Part Numbers'
) Q
PIVOT (
	MAX([RecordedValue])
	FOR [PropertyName] IN (
		[Lot or Serial Number],
		[Component Part Number]
	)
) P
WHERE [Component Part Number] LIKE 'FLM2%' OR [Component Part Number] LIKE 'HTFA%';


WITH [BirthLot] ([TopLotID], [BottomLot], [BottomPart])
AS (
	SELECT
		[LotNumberID] AS [TopLotID],
		[LotNumber] AS [BottomLot],
		[PartNumber] AS [BottomPart]
	FROM [ProductionWeb].[dbo].[UtilizedParts] WITH(NOLOCK)
	WHERE [Quantity]>0
	UNION ALL
	SELECT
		U.[LotNumberId] AS [TopLotID],
		D.[BottomLot] AS [BottomLot],
		D.[BottomPart] AS [BottomPart]
	FROM [BirthLot] D INNER JOIN [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK)
		ON D.[TopLotID] = L.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[UtilizedParts] U WITH(NOLOCK)
			ON L.[LotNumber] = U.[LotNumber]
	WHERE U.[Quantity]>0 AND U.[LotNumber] != 'N/A'
)
SELECT DISTINCT
	REPLACE(REPLACE(REPLACE(TL.[LotNumber],'.',''),'_',''),' ','') AS [SerialNo],
	BL.[DateOfManufacturing]
INTO #manifoldDate
FROM [BirthLot] B INNER JOIN [ProductionWeb].[dbo].[Lots] BL WITH(NOLOCK)
	ON B.[BottomLot] = BL.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[Lots] TL WITH(NOLOCK)
		ON B.[TopLotID] = TL.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[Parts] TP WITH(NOLOCK)
			ON TP.[PartNumberId] = TL.[PartNumberId]
WHERE TP.[PartNumber] IN ('FLM2-ASY-0001','HTFA-SUB-0103','FLM2-SUB-0061')
	AND [BottomPart] IN ('FLM2-SUB-0055','FLM2-SUB-0081','HTFA-SUB-0110')


SELECT
	T.[TicketId],
	T.[TicketString],
	I.[SerialNo],
	M.[DateOfManufacturing],
	T.[CreatedDate],
	T.[SubfailureCategory],
	P.[RecordedValue] AS [PartNumber],
	CASE
		WHEN [RecordedValue] LIKE '%FLM2-%' THEN 'FA2.0'
		WHEN [RecordedValue] LIKE '%HTFA-%' THEN 'Torch'
		ELSE 'Other'
	END AS [Version],
	DATEPART(ww, M.[DateOfManufacturing]) AS [Week],
	MONTH(M.[DateOfManufacturing]) AS [Month],
	YEAR(M.[DateOfManufacturing]) AS [Year],
	1 AS [Record]
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] P
	INNER JOIN #tickets T ON T.[TicketId] = P.[TicketId]
	LEFT JOIN #partInfo I ON I.[TicketId] = P.[TicketId]
	LEFT JOIN #manifoldDate M ON M.[SerialNo] = I.[SerialNo]
WHERE [Tracker]='NCR'
	AND [ObjectName]='Part Numbers'
	AND [PropertyName]='Component Part Number'
	AND ([RecordedValue] LIKE 'FLM2%' OR [RecordedValue] LIKE 'HTFA%')
	
DROP TABLE #problemAreaTickets, #tickets, #partInfo, #manifoldDate

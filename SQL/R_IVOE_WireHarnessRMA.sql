SET NOCOUNT ON

SELECT *
INTO #wireHarFail
FROM (
	SELECT
		P.[TicketId],
		P.[TicketString],
		P.[CreatedDate],
		REPLACE([LotSerialNumber], ' ', '') AS [SerialNo],
		REPLACE(P.[PartNumber], ' ', '') AS [PartNumber],
		IIF(C.[FailureCategory] LIKE '%WIRE-HAR%',
			SUBSTRING(C.[FailureCategory], CHARINDEX('WIRE-HAR',C.[FailureCategory]), 13),
			UPPER(REPLACE(C.[PartNumber], ' ', ''))) AS [WireHarPart],
		IIF(ISNUMERIC(R.[HoursRun])=1, CAST(REPLACE(R.[HoursRun], ',', '') AS FLOAT), NULL) AS [HoursRun],
		R.[CustomerId]
	FROM [PMS1].[dbo].[RMAPartInformation] P
	INNER JOIN [PMS1].[dbo].[RMARootCauses] C ON C.[TicketId] = P.[TicketId]
	INNER JOIN [PMS1].[dbo].[RMA] R ON R.[TicketId] = P.[TicketId]
	WHERE (C.[FailureCategory] LIKE '%WIRE-HAR%' OR C.[PartNumber] LIKE '%WIRE-HAR%')
) Q
WHERE ([PartNumber] LIKE 'FLM_-ASY-0001%' OR [PartNumber] LIKE 'HTFA-SUB-0103%' OR [PartNumber] LIKE 'HTFA-ASY-0003%')
	AND [WireHarPart] NOT LIKE '%554'
	AND [CustomerId] NOT LIKE '%IDATEC%'
	AND YEAR([CreatedDate]) >= 2015
ORDER BY [PartNumber];

WITH [BirthLot] ([TopLotID], [BottomLot], [BottomPart], [Quantity])
AS (
	SELECT
		[LotNumberID] AS [TopLotID],
		[LotNumber] AS [BottomLot],
		[PartNumber] AS [BottomPart],
		[Quantity] AS [Quantity]
	FROM [ProductionWeb].[dbo].[UtilizedParts] U WITH(NOLOCK)
	WHERE [Quantity]>0
	UNION ALL
	SELECT
		U.[LotNumberId] AS [TopLotID],
		D.[BottomLot] AS [BottomLot],
		D.[BottomPart] AS [BottomPart],
		D.[Quantity]*U.[Quantity] AS [Quantity]
	FROM [BirthLot] D INNER JOIN [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK)
		ON D.[TopLotID] = L.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[UtilizedParts] U WITH(NOLOCK)
			ON L.[LotNumber] = U.[LotNumber]
	WHERE U.[Quantity]>0 
		AND D.[BottomPart] NOT LIKE 'FLM_-ASY-0001%'
		AND D.[BottomPart] NOT LIKE 'HTFA-SUB-0103%'
)
SELECT DISTINCT
	REPLACE(REPLACE(REPLACE(TL.[LotNumber],'.',''),'_',''),' ','') AS [SerialNo],
	B.[BottomLot] AS [LotNumber],
	B.[BottomPart] AS [WireHarPart],
	TL.[DateOfManufacturing],
	B.[Quantity]
INTO #wireHarInProd
FROM [BirthLot] B INNER JOIN [ProductionWeb].[dbo].[Lots] BL WITH(NOLOCK)
	ON B.[BottomLot] = BL.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[Lots] TL WITH(NOLOCK)
		ON B.[TopLotID] = TL.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[Parts] TP WITH(NOLOCK)
			ON TP.[PartNumberId] = TL.[PartNumberId]
WHERE TP.[PartNumber] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-SUB-0103')
	AND [BottomPart] LIKE '%WIRE-HAR%'

SELECT
	*
INTO #wireHarPlaced
FROM (
	SELECT
		[SerialNo],
		[LotNumber],
		[WireHarPart],
		[DateOfManufacturing] AS [DatePlaced],
		ISNULL([Quantity],1) AS [Quantity]
	FROM #wireHarInProd
	UNION
	SELECT
	    REPLACE(REPLACE(I.[LotSerialNumber], ' ', ''), '-', '') AS [SerialNo],
		REPLACE(SUBSTRING(U.[LotSerialNumber], 1, CHARINDEX(':', U.[LotSerialNumber]+':')-1), ' ', '') AS [LotNumber],
		REPLACE(U.[PartUsed], ' ', '') AS [WireHarPart],
		U.[CreatedDate] AS [DatePlaced],
		ISNULL(U.[Quantity],1) AS [Quantity]
	FROM [PMS1].[dbo].[RMAPartsUsed] U
	INNER JOIN [PMS1].[dbo].[RMAPartInformation] I ON I.[TicketId] = U.[TicketId]
	WHERE (I.[PartNumber] LIKE 'FLM_-ASY-0001%' OR I.[PartNumber] LIKE 'HTFA-SUB-0103%' OR I.[PartNumber] LIKE 'HTFA-ASY-0003%')
		AND U.[PartUsed] LIKE '%WIRE-HAR%'
		AND YEAR(I.[CreatedDate]) >= '2015'
) Q

SELECT DISTINCT
	[LotNumber],
	[PartNumber],
	CAST([Date] AS DATE) AS [Date]
INTO #wireHarLots
FROM (
	SELECT 
		L.[LotNumber],
		P.[PartNumber],
		'20' + SUBSTRING(RIGHT(L.[LotNumber], 9), 5, 2) + '-' + SUBSTRING(RIGHT(L.[LotNumber], 9), 1, 2) + '-' + SUBSTRING(RIGHT(L.[LotNumber], 9), 3, 2) AS [Date]
	FROM [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK)
	INNER JOIN [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK) ON P.[PartNumberId] = L.[PartNumberId]
	WHERE P.[PartNumber] LIKE '%WIRE-HAR%'
) Q
WHERE ISDATE([Date])=1

SELECT
	REPLACE(REPLACE(REPLACE(SER.[SerialNo],'R',''),'_',''),'.','') AS [SerialNo],
	CAST(SL.[ShipDate] AS DATE) AS [ShipDate]
INTO #instShipped
FROM [RO_MAS].[mas500_app].[dbo].[tsoShipLine] SL
INNER JOIN [RO_MAS].[mas500_app].[dbo].[tsoPackageContent] PC ON PC.[ShipLineKey] = SL.[ShipLineKey]
INNER JOIN [RO_MAS].[mas500_app].[dbo].[timInvtSerial] SER ON SER.[InvtSerialKey] = PC.[InvtSerialKey]
INNER JOIN [RO_MAS].[mas500_app].[dbo].[tsoSOLine] SOL on SOL.[SOLineKey] = SL.[SOLineKey]
INNER JOIN [RO_MAS].[mas500_app].[dbo].[tsoSalesOrder] SO on SO.[SOKey] = SOL.[SOKey]
INNER JOIN [RO_MAS].[mas500_app].[dbo].[tarCustomer] C on C.[CustKey] = SO.[CustKey]
WHERE [CustId] != 'IDATEC'

SELECT
	W.[LotNumber],
	W.[WireHarPart],
	SUM([Quantity]) AS [Count]
INTO #wireHarCountInField
FROM #wireHarPlaced W
INNER JOIN #instShipped I ON I.[SerialNo] = W.[SerialNo]
WHERE W.[LotNumber] IS NOT NULL AND W.[LotNumber] NOT LIKE 'N%A%'
GROUP BY W.[LotNumber], W.[WireHarPart]

ALTER TABLE #wireHarPlaced ALTER COLUMN SerialNo varchar(255)
ALTER TABLE #wireHarPlaced ALTER COLUMN WireHarPart varchar(255)
CREATE INDEX IDX_wireHarPlacedSer ON #wireHarPlaced(SerialNo)
CREATE INDEX IDX_wireHarPlacedPart ON #wireHarPlaced(WireHarPart)

SELECT
	[SerialNo],
	[WireHarPart],
	(SELECT TOP 1
		P.[LotNumber]
	FROM #wireHarPlaced P
	WHERE P.[SerialNo] = W.[SerialNo] AND P.[WireHarPart] = W.[WireHarPart]
	ORDER BY P.[DatePlaced] DESC) AS [LotNumber]
INTO #wireHarFailLot
FROM #wireHarFail W

SELECT
	W.[LotNumber],
	L.[PartNumber],
	L.[Date],
	[Count] AS [LotSizeInField],
	(SELECT COUNT(*)
	FROM #wireHarFailLot F
	WHERE F.[WireHarPart] = W.[WireHarPart] AND F.[LotNumber] = W.[LotNumber]) AS [FailCount],
	YEAR(L.[Date]) AS [Year],
	MONTH(L.[Date]) AS [Month],
	DATEPART(ww, L.[Date]) AS [Week]
FROM #wireHarCountInField W
INNER JOIN #wireHarLots L ON L.[LotNumber] = W.[LotNumber]
WHERE YEAR(L.[Date]) >= 2015 AND L.[PartNumber] != 'WIRE-HAR-0554'
ORDER BY L.[PartNumber], L.[Date]


DROP TABLE #instShipped, #wireHarCountInField, #wireHarFail, #wireHarInProd, #wireHarLots, #wireHarPlaced, #wireHarFailLot

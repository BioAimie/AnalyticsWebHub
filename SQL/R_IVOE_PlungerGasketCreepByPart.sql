SET NOCOUNT ON

SELECT
	[TicketId],
	[TicketString],
	[CreatedDate],
	[PropertyName],
	[RecordedValue]
INTO #lotSerial
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] = 'Part Information' AND [PropertyName] = 'Lot/Serial Number' AND [Tracker] = 'RMA'

SELECT 
	[TicketId],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #partsUsed
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] = 'Parts Used' AND [PropertyName] IN ('Lot/Serial Number','Part Used') AND [Tracker] = 'RMA'

SELECT 
	[TicketId],
	[TicketString],
	[RecordedValue] AS [ServiceCode]
INTO #codes
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] = 'Service Codes' AND [PropertyName] = 'Service Code' AND [Tracker] = 'RMA'

SELECT 
	S.[TicketId],
	S.[TicketString],
	S.[CreatedDate],
	IIF(CHARINDEX('2FA', S.[RecordedValue],1) <> 0, UPPER(SUBSTRING(S.[RecordedValue], CHARINDEX('2FA', S.[RecordedValue], 1), 8)), UPPER(SUBSTRING(S.[RecordedValue], CHARINDEX('FA', S.[RecordedValue], 1), 6))) AS [SerialNo],
	UPPER(P.[PartNo]) AS [PartNo],
	P.[LotNo],
	IIF(C.[ServiceCode] IS NOT NULL, 'GasketCreep', 'NoCreep') AS [Note]
INTO #plungerServiced
FROM #lotSerial S LEFT JOIN
(
	SELECT 
		[TicketId],
		[Part Used] AS [PartNo],
		[Lot/Serial Number] AS [LotNo]
	FROM #partsUsed P 
	PIVOT
	(
		MAX([RecordedValue]) 
		FOR [PropertyName]
		IN
		(
			[Lot/Serial Number],
			[Part Used]	
		)
	) PIV
	WHERE [Part Used] LIKE '%FLM1-GAS-0009%' OR [Part Used] LIKE '%FLM1-GAS-0018%' OR [Part Used] LIKE '%FLM1-SUB-0005%' OR [Part Used] LIKE '%Plunger Gasket%'
) P
	ON S.[TicketId] = P.[TicketId] LEFT JOIN 
(	
	SELECT 
		[TicketId],
		[ServiceCode]	
	FROM #codes 
	WHERE [ServiceCode] LIKE '%204%'
) C
		ON S.[TicketId] = C.[TicketId]
WHERE [PartNo] IS NOT NULL OR [ServiceCode] IS NOT NULL

SELECT 
	[SerialNo],
	[Note],
	[TicketId],
	[TicketString],
	[CreatedDate],
	IIF([LotNo] IS NULL AND [CreatedDate] < CONVERT(DATETIME, '2016-02-01'), 'FLM1-GAS-0009', 
		IIF([PartNo] LIKE 'FLM1-SUB-0005' AND [CreatedDate] < CONVERT(DATETIME, '2016-02-01'), 'FLM1-GAS-0009',
		IIF([PartNo] LIKE 'FLM1-SUB-0005' AND [CreatedDate] >= CONVERT(DATETIME, '2016-02-01'), 'FLM1-GAS-0018', UPPER([PartNo])))) AS [PartPutIn], 
	UPPER([LotNo]) AS [LotPutIn]
INTO #partPutIn
FROM #plungerServiced
WHERE (LEFT([SerialNo],2) LIKE 'FA' AND LEN([SerialNo]) = 6) OR (LEFT([SerialNo],2) LIKE '2F' AND LEN([SerialNo]) >= 8);

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
	WHERE U.[Quantity]>0
)
SELECT DISTINCT
	REPLACE(REPLACE(REPLACE(TL.[LotNumber],'.',''),'_',''),' ','') AS [SerialNo],
	TL.[DateOfManufacturing] AS [InstManfDate],
	BL.[LotNumber] AS [PlungerLot],
	BL.[DateOfManufacturing] AS [PlungerDOM],
	U.[PartNumber] AS [GasketPart]
INTO #plungerBirthed
FROM [BirthLot] B
	INNER JOIN [ProductionWeb].[dbo].[Lots] TL WITH(NOLOCK) ON B.[TopLotID] = TL.[LotNumberId] 
	INNER JOIN [ProductionWeb].[dbo].[Parts] TP WITH(NOLOCK) ON TP.[PartNumberId] = TL.[PartNumberId]
	INNER JOIN [ProductionWeb].[dbo].[Lots] BL WITH(NOLOCK) ON B.[BottomLot] = BL.[LotNumber] 	
	INNER JOIN [ProductionWeb].[dbo].[UtilizedParts] U WITH(NOLOCK) ON U.[LotNumberId] = BL.[LotNumberId]
WHERE [BottomPart] = 'FLM1-SUB-0005' 
	AND TP.[PartNumber] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-SUB-0103') 
	AND U.[PartNumber] IN ('FLM1-GAS-0009','FLM1-GAS-0018')
	AND U.[Quantity]>0

SELECT
	S.[SerialNo],
	S.[TicketId],
	S.[TicketString],
	S.[CreatedDate],
	S.[Note],
	S.[PartPutIn],
	LAG(S.[PartPutIn]) OVER(PARTITION BY S.[SerialNo] ORDER BY S.[VisitNo]) AS [PartTakenOut],
	IIF(S.[VisitNo] = 1, B.[GasketPart], NULL) AS [BirthPart]
INTO #partHistory
FROM
(
	SELECT ROW_NUMBER() OVER(PARTITION BY [SerialNo] ORDER BY [TicketId]) AS [VisitNo],
		 *
	FROM #partPutIn 
	
) S LEFT JOIN 
(
	SELECT *
	FROM #plungerBirthed
)B
	ON S.[SerialNo] = B.[SerialNo]

SELECT 
	[SerialNo],
	[TicketString],
	[CreatedDate],
	[Note],
	IIF([BirthPart] IS NOT NULL AND [PartTakenOut] IS NULL, [BirthPart],
		IIF([BirthPart] IS NULL AND [PartTakenOut] IS NOT NULL, [PartTakenOut], 
		IIF([BirthPart] IS NULL AND [PartTakenOut] IS NULL, 'FLM1-GAS-0009', [PartTakenOut]))) AS [PartTakenOut] 
INTO #partRemoved
FROM #partHistory

SELECT DISTINCT
	[SerialNo],
	[TicketString],
	[CreatedDate],
	[Note],
	[PartTakenOut]
INTO #distinct
FROM #partRemoved
ORDER BY [TicketString]

SELECT 
	YEAR([CreatedDate]) AS [Year],
	MONTH([CreatedDate]) AS [Month],
	DATEPART(ww,[CreatedDate]) AS [Week],
	[PartTakenOut] AS [Key],
	1 AS [Record]
FROM #distinct
WHERE [Note] LIKE 'GasketCreep'

DROP TABLE #codes, #distinct, #lotSerial, #partHistory, #partPutIn, #partRemoved, #partsUsed, #plungerBirthed, #plungerServiced

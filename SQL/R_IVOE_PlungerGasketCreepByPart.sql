SET NOCOUNT ON

SELECT
	[TicketId],
	[TicketString],
	[CreatedDate],
	[PropertyName],
	[RecordedValue]
INTO #lotSerial
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Part Information' AND [PropertyName] LIKE 'Lot/Serial Number'

SELECT 
	[TicketId],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #partsUsed
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Parts Used' AND [PropertyName] IN ('Lot/Serial Number','Part Used')

SELECT 
	[TicketId],
	[TicketString],
	[RecordedValue] AS [ServiceCode]
INTO #codes
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Service Codes' AND [PropertyName] LIKE 'Service Code'

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
	[TicketString],
	[CreatedDate],
	IIF([LotNo] IS NULL AND [CreatedDate] < CONVERT(DATETIME, '2016-02-01'), 'FLM1-GAS-0009', 
		IIF([PartNo] LIKE 'FLM1-SUB-0005' AND [CreatedDate] < CONVERT(DATETIME, '2016-02-01'), 'FLM1-GAS-0009',
		IIF([PartNo] LIKE 'FLM1-SUB-0005' AND [CreatedDate] >= CONVERT(DATETIME, '2016-02-01'), 'FLM1-GAS-0018', UPPER([PartNo])))) AS [PartPutIn], 
	UPPER([LotNo]) AS [LotPutIn]
INTO #partPutIn
FROM #plungerServiced
WHERE (LEFT([SerialNo],2) LIKE 'FA' AND LEN([SerialNo]) = 6) OR (LEFT([SerialNo],2) LIKE '2F' AND LEN([SerialNo]) >= 8)


SELECT
	IIF(L.[LotNumber] LIKE '2FA_00061', '2FA00061', L.[LotNumber]) AS [SerialNo],
	L.[DateOfManufacturing] AS [InstManfDate],
	UPPP.[LotNumber] AS [PlungerLot],
	ULLLL.[DateOfManufacturing] AS [PlungerDOM],
	UPPPP.[PartNumber] AS [GasketPart]
INTO #plungerBirthed
FROM [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) 
	ON P.[PartNumberId] = L.[PartNumberId] INNER JOIN [ProductionWeb].[dbo].[UtilizedParts] U WITH(NOLOCK)
		ON L.[LotNumberId] = U.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[Lots] UL WITH(NOLOCK)
			ON U.[LotNumber] = UL.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[UtilizedParts] UP WITH(NOLOCK)
				ON UL.[LotNumberId] = UP.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[Lots] ULL WITH(NOLOCK)
					ON UP.[LotNumber] = ULL.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[UtilizedParts] UPP WITH(NOLOCK)
						ON ULL.[LotNumberId] = UPP.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[Lots] ULLL WITH(NOLOCK)
							ON UPP.[LotNumber] = ULLL.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[UtilizedParts] UPPP WITH(NOLOCK)
								ON ULLL.[LotNumberId] = UPPP.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[Lots] ULLLL WITH(NOLOCK)
									ON UPPP.[LotNumber] = ULLLL.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[UtilizedParts] UPPPP WITH(NOLOCK)
										ON ULLLL.[LotNumberId] = UPPPP.[LotNumberId]
WHERE P.[PartNumber] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-ASY-0003','HTFA-SUB-0103') AND UPPPP.[PartNumber] IN ('FLM1-GAS-0009','FLM1-GAS-0018')


SELECT 
	S.[SerialNo],
	S.[TicketString],
	S.[CreatedDate],
	S.[Note],
	S.[PartPutIn],
	LAG(S.[PartPutIn]) OVER(PARTITION BY S.[SerialNo] ORDER BY S.[VisitNo]) AS [PartTakenOut],
	IIF(S.[VisitNo] = 1, B.[GasketPart], NULL) AS [BirthPart]
INTO #partHistory
FROM
(
	SELECT ROW_NUMBER() OVER(PARTITION BY [SerialNo] ORDER BY [TicketString]) AS [VisitNo],
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

SELECT 
	YEAR([CreatedDate]) AS [Year],
	MONTH([CreatedDate]) AS [Month],
	DATEPART(ww,[CreatedDate]) AS [Week],
	[PartTakenOut] AS [Key],
	1 AS [Record]
FROM #distinct
WHERE [Note] LIKE 'GasketCreep'

DROP TABLE #codes, #distinct, #lotSerial, #partHistory, #partPutIn, #partRemoved, #partsUsed, #plungerBirthed, #plungerServiced
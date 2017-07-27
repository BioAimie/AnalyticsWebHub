SET NOCOUNT ON;

SELECT DISTINCT 
	[ComponentItemID] AS [PartNumber],
	[ComponentItemShortDesc] AS [PartDesc]
INTO #parts
FROM [PMS1].[dbo].[vInstrumentBillOfMaterials]
WHERE [ComponentItemID] LIKE 'PCBA-SUB-%' AND [ItemID] IN ('FLM2-ASY-0001','HTFA-SUB-0103')

SELECT
	REPLACE(REPLACE(REPLACE([SerialNo],'2FA','FA'),'R',''),'KTM','TM') AS [NormalSerial],
	MAX(TranDate) AS [TranDate]
INTO #shipments
FROM [PMS1].[dbo].[vSerialTransactions]
WHERE [TranType] = 'SH'
GROUP BY [SerialNo]

SELECT 
	[NormalSerial],
	[LotNumber],
	[PartNumber],
	[DatePlaced],
	TRY_CAST('20' + SUBSTRING(RIGHT([LotNumber], 9), 5, 2) + '-' + 
			SUBSTRING(RIGHT([LotNumber], 9), 1, 2) + '-' + 
			SUBSTRING(RIGHT([LotNumber], 9), 3, 2) AS DATE) AS [BoardReceiptDate],
	[HoursRun]
INTO #boardInstrumentParts
FROM [PMS1].[dbo].[bInstrumentParts]
WHERE [PartNumber] IN (SELECT [PartNumber] FROM #parts)

SELECT 
	I.[BoardReceiptDate],
	I.[LotNumber],
	I.[PartNumber],
	P.[PartDesc]
INTO #boardsShipped
FROM #boardInstrumentParts I
INNER JOIN #shipments S ON S.[NormalSerial] = I.[NormalSerial]
INNER JOIN #parts P ON P.[PartNumber] = I.[PartNumber]
WHERE S.[TranDate] >= I.[DatePlaced]

SELECT
	[BoardReceiptDate],
	[PartNumber],
	[PartDesc],
	COUNT(*) [QuantityInField]
FROM #boardsShipped
WHERE [BoardReceiptDate] IS NOT NULL
GROUP BY [BoardReceiptDate], [PartNumber], [PartDesc]
--OUTPUT RESULT: Boards in field

SELECT
	[NormalSerial],
	UPPER(P.[PartNumber]) AS [PartNumber],
	CAST(F.[CreatedDate] AS DATE) AS [CreatedDate],
	F.[TicketString],
	F.[HoursRun],
	F.[EarlyFailureType],
	ROW_NUMBER() OVER(ORDER BY F.[CreatedDate]) AS [FailId]
INTO #boardFailure
FROM [PMS1].[dbo].[bInstrumentFailure] F
INNER JOIN [PMS1].[dbo].[RMAPartsUsed] U ON U.[TicketId] = F.[TicketId]
INNER JOIN #parts P ON P.[PartNumber] = REPLACE(U.[PartUsed], ' ', '')
WHERE [Failure] = 1 AND TRY_CAST(U.[Quantity] AS INT)>0

SELECT
	Q.[CreatedDate],
	Q.[TicketString],
	Q.[PartNumber],
	Q.[LotNumber],
	Q.[BoardReceiptDate],
	Q.[HoursRun],
	Q.[EarlyFailureType],
	P.[PartDesc]
FROM (
	SELECT 
		F.[CreatedDate],
		F.[TicketString],
		IIF(F.[HoursRun] > P.[HoursRun], F.[HoursRun] - P.[HoursRun], F.[HoursRun]) AS [HoursRun],
		F.[EarlyFailureType],
		F.[PartNumber],
		P.[LotNumber],
		P.[BoardReceiptDate],
		ROW_NUMBER() OVER(PARTITION BY [FailId] ORDER BY P.[DatePlaced] DESC) AS [RowNo]
	FROM #boardFailure F
	LEFT JOIN #boardInstrumentParts P ON P.[NormalSerial] = F.[NormalSerial] AND P.[PartNumber] = F.[PartNumber] AND P.[DatePlaced] < F.[CreatedDate]
) Q
INNER JOIN #parts P ON P.[PartNumber] = Q.[PartNumber]
WHERE [RowNo] = 1
ORDER BY [CreatedDate]
--OUTPUT RESULT: Board RMAs

SELECT
	*,
	TRY_CAST('20' + SUBSTRING(RIGHT([LotNumber], 9), 5, 2) + '-' + 
			SUBSTRING(RIGHT([LotNumber], 9), 1, 2) + '-' + 
			SUBSTRING(RIGHT([LotNumber], 9), 3, 2) AS DATE) AS [BoardReceiptDate]
FROM (
	SELECT
		N.[CreatedDate],
		N.[TicketString],
		N.[Disposition],
		UPPER(N.[PartAffected]) AS [PartNumber],
		TRY_CAST(N.[QuantityAffected] AS INT) AS [QuantityAffected],
		REPLACE(SUBSTRING([LotorSerialNumber], 1, PATINDEX('%[:/]%', [LotorSerialNumber] + ':') - 1), ' ', '') AS [LotNumber],
		P.[PartDesc]
	FROM [PMS1].[dbo].[NCRPartsAffected] N
	INNER JOIN #parts P ON P.[PartNumber] = N.[PartAffected]
	WHERE N.[Disposition] NOT LIKE '%Use as is%'
) Q
ORDER BY [BoardReceiptDate]
--OUTPUT RESULT: Board NCRs

SELECT
	L.[LotNumber],
	TRY_CAST('20' + SUBSTRING(RIGHT(L.[LotNumber], 9), 5, 2) + '-' + 
			SUBSTRING(RIGHT(L.[LotNumber], 9), 1, 2) + '-' + 
			SUBSTRING(RIGHT(L.[LotNumber], 9), 3, 2) AS DATE) AS [BoardReceiptDate],
	L.[DateOfManufacturing],
	L.[ActualLotSize],
	L.[DesiredLotSize],
	P.[PartNumber],
	P2.[PartDesc]
FROM [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[Lots] L
INNER JOIN [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[Parts] P ON P.[PartNumberId] = L.[PartNumberId]
INNER JOIN #parts P2 ON P2.[PartNumber] = P.[PartNumber]
ORDER BY [BoardReceiptDate]
-- Board lot size

DROP TABLE #parts, #shipments, #boardInstrumentParts, #boardsShipped, #boardFailure

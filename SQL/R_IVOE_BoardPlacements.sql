SET NOCOUNT ON;

SELECT DISTINCT 
	[ComponentItemID] AS [PartNumber],
	[ComponentItemShortDesc] AS [PartDesc]
INTO #parts
FROM [PMS1].[dbo].[vInstrumentBillOfMaterials]
WHERE [ComponentItemID] LIKE 'PCBA-SUB-%' AND [ItemID] IN ('FLM2-ASY-0001','HTFA-SUB-0103')

SELECT
	LEFT(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([SerialNo],'.',''),'_',''),'2FA','FA'),'R',''),'KTM','TM'),800) AS [NormalSerial],
	MAX(TranDate) AS [TranDate]
INTO #shipments
FROM [PMS1].[dbo].[vSerialTransactions]
WHERE [TranType] = 'SH'
GROUP BY [SerialNo]

SELECT
	[BoardReceiptDate],
	[PartNumber],
	[PartDesc],
	COUNT(*) [QuantityInField]
INTO #boardsInField
FROM (
	SELECT 
		TRY_CAST('20' + SUBSTRING(RIGHT([LotNumber], 9), 5, 2) + '-' + 
				SUBSTRING(RIGHT([LotNumber], 9), 1, 2) + '-' + 
				SUBSTRING(RIGHT([LotNumber], 9), 3, 2) AS DATE) AS [BoardReceiptDate],
		I.[LotNumber],
		I.[PartNumber],
		P.[PartDesc]
	FROM [PMS1].[dbo].[bInstrumentParts] I
	INNER JOIN #shipments S ON S.[NormalSerial] = I.[NormalSerial]
	INNER JOIN #parts P ON P.[PartNumber] = I.[PartNumber]
	WHERE S.[TranDate] >= I.[DatePlaced]
) Q
WHERE [BoardReceiptDate] IS NOT NULL
GROUP BY [BoardReceiptDate], [PartNumber], [PartDesc]

-- OUTPUT: boardsInField

--SELECT * FROM #quantityInField
--SELECT 
--	Q.*,
--	TRY_CAST('20' + SUBSTRING(RIGHT([LotNumber], 9), 5, 2) + '-' + 
--			SUBSTRING(RIGHT([LotNumber], 9), 1, 2) + '-' + 
--			SUBSTRING(RIGHT([LotNumber], 9), 3, 2) AS DATE) AS [BoardManufactureDate]
--INTO #results
--FROM (
--	SELECT
--		LEFT(REPLACE(REPLACE(F.[SerialNo],'R',''), '2FA', 'FA'),800) AS [NormalSerial],
--		F.[SerialNo],
--		F.[PartNumber] AS [InstrumentPartNumber],
--		CAST(U.[CreatedDate] AS DATE) AS [DatePlaced],
--		REPLACE(SUBSTRING(U.[LotSerialNumber],1,PATINDEX('%[:/]%',U.[LotSerialNumber]+':')-1),' ','') AS [LotNumber],
--		UPPER(REPLACE(U.[PartUsed],' ','')) AS [PartNumber],
--		U.[Quantity],
--		U.[TicketString],
--		F.[Failure] AS [FailureRMA]
--	FROM [PMS1].[dbo].[bInstrumentFailure] F
--	INNER JOIN [PMS1].[dbo].[RMAPartsUsed] U ON U.[TicketId] = F.[TicketId]
--	WHERE REPLACE(U.[PartUsed],' ','') IN (SELECT [PartNumber] FROM #parts)
--	UNION
--	SELECT
--		[NormalSerial],
--		[SerialNo],
--		[InstrumentPartNumber],
--		[InstrumentDateOfManufacturing] AS [DatePlaced],
--		[LotNumber],
--		[PartNumber],
--		[Quantity],
--		NULL AS [TicketString],
--		0 AS [FailureRMA]
--	FROM #boardProd
--) Q

--SELECT
--	[NormalSerial],
--	[SerialNo],
--	[InstrumentPartNumber],
--	[DatePlaced],
--	[LotNumber],
--	[PartNumber],
--	[Quantity],
--	[TicketString],
--	[FailureRMA],
--	[BoardFail],
--	[PartDesc],
--	[TranDate]
--FROM (
--	SELECT
--		R.*,
--		ISNULL(LEAD([FailureRMA]) OVER(PARTITION BY R.[NormalSerial], R.[PartNumber] ORDER BY [DatePlaced]), 0) AS [BoardFail],
--		P.[PartDesc],
--		S.[TranDate],
--		ROW_NUMBER() OVER(PARTITION BY R.[SerialNo], R.[PartNumber] ORDER BY S.[TranDate]) AS [RowNo]
--	FROM #results R
--	INNER JOIN #parts P ON P.[PartNumber] = R.[PartNumber]
--	LEFT JOIN #shipments S ON S.[NormalSerial] = R.[NormalSerial] --AND S.[TranDate] >= R.[DatePlaced]
--) Q
--WHERE [RowNo]=1

--DROP TABLE #parts, #shipments, #boardProd, #results

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
GROUP BY [SerialNo]
CREATE CLUSTERED INDEX IDX_Shipments ON #shipments([NormalSerial])

SELECT *
INTO #boardProd
FROM [PMS1].[dbo].[bInstrumentParts] I
WHERE I.[PartNumber] IN (SELECT [PartNumber] FROM #parts)

SELECT 
	Q.*,
	TRY_CAST('20' + SUBSTRING(RIGHT([LotNumber], 9), 5, 2) + '-' + 
			SUBSTRING(RIGHT([LotNumber], 9), 1, 2) + '-' + 
			SUBSTRING(RIGHT([LotNumber], 9), 3, 2) AS DATE) AS [BoardManufactureDate]
INTO #results
FROM (
	SELECT
		LEFT(REPLACE(REPLACE(F.[SerialNo],'R',''), '2FA', 'FA'),800) AS [NormalSerial],
		F.[SerialNo],
		F.[PartNumber] AS [InstrumentPartNumber],
		CAST(U.[CreatedDate] AS DATE) AS [DatePlaced],
		REPLACE(SUBSTRING(U.[LotSerialNumber],1,PATINDEX('%[:/]%',U.[LotSerialNumber]+':')-1),' ','') AS [LotNumber],
		UPPER(REPLACE(U.[PartUsed],' ','')) AS [PartNumber],
		U.[Quantity],
		U.[TicketString],
		F.[Failure] AS [FailureRMA]
	FROM [PMS1].[dbo].[bInstrumentFailure] F
	INNER JOIN [PMS1].[dbo].[RMAPartsUsed] U ON U.[TicketId] = F.[TicketId]
	WHERE REPLACE(U.[PartUsed],' ','') IN (SELECT [PartNumber] FROM #parts)
	UNION
	SELECT
		[NormalSerial],
		[SerialNo],
		[InstrumentPartNumber],
		[InstrumentDateOfManufacturing] AS [DatePlaced],
		[LotNumber],
		[PartNumber],
		[Quantity],
		NULL AS [TicketString],
		0 AS [FailureRMA]
	FROM #boardProd
) Q

SELECT
	R.*,
	ISNULL(LEAD([FailureRMA]) OVER(PARTITION BY R.[NormalSerial], R.[PartNumber] ORDER BY [DatePlaced]), 0) AS [BoardFail],
	P.[PartDesc]
--	S.[TranDate]
INTO #final
FROM #results R
INNER JOIN #parts P ON P.[PartNumber] = R.[PartNumber]
--LEFT JOIN #shipments S ON S.[NormalSerial] = R.[NormalSerial] AND S.[TranDate] >= R.[DatePlaced]

DROP TABLE #final
DROP TABLE #final2

CREATE CLUSTERED INDEX IDX_NormalSerial ON #final([NormalSerial])

SELECT *,
	(SELECT MIN([TranDate]) FROM #shipments S
--	WITH (FORCESEEK(IDX_Shipments(NormalSerial)))
	WHERE S.[NormalSerial] = F.[NormalSerial]) AS [ShipDate]
INTO #final2
FROM #final F



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
--	MIN([TranDate]) AS [ShipDate]
--FROM #final F
--WHERE [TranDate] IS NOT NULL
--GROUP BY [NormalSerial], [SerialNo], [InstrumentPartNumber], [DatePlaced], [LotNumber], [PartNumber], [Quantity], [TicketString], [FailureRMA], [BoardFail], [PartDesc]
--ORDER BY [PartNumber], [SerialNo], [DatePlaced]

--SELECT
--	[PartNumber],
--	[PartDesc],
--	SUM(FailureRMA) AS [Failures],
--	SUM(BoardFail) AS [FailuresKnownLot]
--FROM (
--SELECT
--	R.*,
--	ISNULL(LEAD([FailureRMA]) OVER(PARTITION BY R.[NormalSerial], R.[PartNumber] ORDER BY [DatePlaced]), 0) AS [BoardFail],
--	P.[PartDesc]
--FROM #results R
--INNER JOIN #parts P ON P.[PartNumber] = R.[PartNumber]
----ORDER BY R.[PartNumber], [SerialNo], [DatePlaced]
--) Q
--GROUP BY [PartNumber], [PartDesc]
--ORDER BY SUM(FailureRMA) DESC


DROP TABLE #parts, #shipments, #boardProd, #results, #final

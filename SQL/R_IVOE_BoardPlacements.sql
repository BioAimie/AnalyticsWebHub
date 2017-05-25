SET NOCOUNT ON;

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
	WHERE U.[Quantity]>0 AND D.[BottomPart] NOT IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-SUB-0103','FLM1-ASY-0001R','FLM2-ASY-0001R','HTFA-SUB-0103R')
)
SELECT DISTINCT
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(TL.[LotNumber],'.',''),'_',''),' ',''), 'R', ''), '2FA', 'FA') AS [NormalSerial],
	REPLACE(REPLACE(REPLACE(TL.[LotNumber],'.',''),'_',''),' ','') AS [SerialNo],
	B.[BottomPart] AS [PartNumber],
	CAST(TL.[DateOfManufacturing] AS DATE) AS [DatePlaced],
	B.[BottomLot] AS [LotNumber]
INTO #boardProd
FROM [BirthLot] B INNER JOIN [ProductionWeb].[dbo].[Lots] BL WITH(NOLOCK)
	ON B.[BottomLot] = BL.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[Lots] TL WITH(NOLOCK)
		ON B.[TopLotID] = TL.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[Parts] TP WITH(NOLOCK)
			ON TP.[PartNumberId] = TL.[PartNumberId]
WHERE TP.[PartNumber] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-SUB-0103','FLM1-ASY-0001R','FLM2-ASY-0001R','HTFA-SUB-0103R')
	AND [BottomPart] IN ('PCBA-SUB-0836', 'PCBA-SUB-0838', 'PCBA-SUB-0839', 'PCBA-SUB-0847')

SELECT 
	*,
	TRY_CAST('20' + SUBSTRING(RIGHT([LotNumber], 9), 5, 2) + '-' + 
			SUBSTRING(RIGHT([LotNumber], 9), 1, 2) + '-' + 
			SUBSTRING(RIGHT([LotNumber], 9), 3, 2) AS DATE) AS [BoardManufactureDate]
INTO #results
FROM (
	SELECT
		REPLACE(REPLACE(F.[SerialNo],'R',''), '2FA', 'FA') AS [NormalSerial],
		F.[SerialNo],
		UPPER(REPLACE(U.[PartUsed],' ','')) AS [PartNumber],
		CAST(U.[CreatedDate] AS DATE) AS [DatePlaced],
		REPLACE(SUBSTRING(U.[LotSerialNumber],1,PATINDEX('%[:/]%',U.[LotSerialNumber]+':')-1),' ','') AS [LotNumber],
		U.[TicketString],
		F.[Failure] AS [FailureRMA]
	FROM [PMS1].[dbo].[bInstrumentFailure] F
	INNER JOIN [PMS1].[dbo].[RMAPartsUsed] U ON U.[TicketId] = F.[TicketId]
	WHERE REPLACE(U.[PartUsed],' ','') IN ('PCBA-SUB-0836', 'PCBA-SUB-0838', 'PCBA-SUB-0839', 'PCBA-SUB-0847')
	UNION
	SELECT 
		*,
		NULL AS [TicketString],
		0 AS [FailureRMA]
	FROM #boardProd
) Q

SELECT
	*,
	ISNULL(LEAD([FailureRMA]) OVER(PARTITION BY [NormalSerial], [PartNumber] ORDER BY [DatePlaced]), 0) AS [BoardFail]
FROM #results
ORDER BY [PartNumber], [SerialNo], [DatePlaced]

DROP TABLE #boardProd, #results

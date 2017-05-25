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
	WHERE U.[Quantity]>0
)
SELECT DISTINCT
	REPLACE(REPLACE(REPLACE(TL.[LotNumber],'.',''),'_',''),' ','') AS [SerialNo],
	B.[BottomPart] AS [PartNumber],
	B.[BottomLot] AS [LotNumber],
	TL.[DateOfManufacturing] AS [Date]
INTO #boardProd
FROM [BirthLot] B INNER JOIN [ProductionWeb].[dbo].[Lots] BL WITH(NOLOCK)
	ON B.[BottomLot] = BL.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[Lots] TL WITH(NOLOCK)
		ON B.[TopLotID] = TL.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[Parts] TP WITH(NOLOCK)
			ON TP.[PartNumberId] = TL.[PartNumberId]
WHERE TP.[PartNumber] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-SUB-0103')
	AND [BottomPart] IN ('PCBA-SUB-0836', 'PCBA-SUB-0838', 'PCBA-SUB-0839', 'PCBA-SUB-0847') AND [BottomLot] != 'N/A'

SELECT
	[TicketId],
	IIF([RMATitle] NOT LIKE '%upgrade%' AND
		([RMATitle] LIKE '%error%' OR [RMATitle] LIKE '%fail%' OR [RMATitle] LIKE '%DOA%' OR [RMATitle] LIKE '%ELF%' OR
		[RMAType] LIKE '%- Failure%' OR
		[EarlyFailureType] IN ('SDOA','DOA','ELF','SELF') OR
		([ComplaintFailureMode] IS NOT NULL AND RIGHT([ComplaintFailureMode],3)='1-0') OR
		EXISTS (SELECT 1 FROM [PMS1].[dbo].[RMARootCauses] C WHERE C.[TicketId] = Q.[TicketId] AND
				ISNUMERIC([PartNumber]) = 0 AND [PartNumber] NOT LIKE 'N%A' AND [PartNumber] != '')),
	1, 0) AS [Failure]
INTO #failureRMA
FROM (
	SELECT 	
		P.[TicketId],
		P.[EarlyFailureType],
		R.[RMAType],
		(SELECT TOP 1 
			C.[FailureMode]
		FROM [PMS1].[dbo].[ComplaintBFDXPartNumber] C
		WHERE C.[TicketString] = 'COMPLAINT-'+R.[ComplaintNumber]
			AND REPLACE(C.[LotSerialNumber],' ','') = REPLACE(P.[LotSerialNumber],' ','')) AS [ComplaintFailureMode],
		R.[RMATitle]
	FROM [PMS1].[dbo].[RMAPartInformation] P
	LEFT JOIN [PMS1].[dbo].[RMA] R ON R.[TicketId] = P.[TicketId]
	WHERE LEFT(REPLACE([LotSerialNumber], ' ', ''),3) IN ('2FA','FA4')
) Q

SELECT
	REPLACE(I.[LotSerialNumber],' ','') AS [SerialNo],
	REPLACE(U.[PartUsed],' ','') AS [PartNumber],
	REPLACE(SUBSTRING(U.[LotSerialNumber],1,PATINDEX('%[:/]%',U.[LotSerialNumber]+':')-1),' ','') AS [LotNumber],
	U.[CreatedDate] AS [Date],
	U.[TicketString],
	R.[Failure] AS [FailureRMA]
FROM [PMS1].[dbo].[RMAPartsUsed] U 
INNER JOIN [PMS1].[dbo].[RMAPartInformation] I ON I.[TicketId] = U.[TicketId]
INNER JOIN #failureRMA R ON R.[TicketId] = U.[TicketId]
WHERE (I.[PartNumber] LIKE 'FLM_-ASY-0001%' OR I.[PartNumber] LIKE 'HTFA-SUB-0103%' OR I.[PartNumber] LIKE 'HTFA-ASY-0003%')
AND REPLACE(U.[PartUsed],' ','') IN ('PCBA-SUB-0836', 'PCBA-SUB-0838', 'PCBA-SUB-0839', 'PCBA-SUB-0847')
UNION
SELECT 
	*,
	NULL AS [TicketString],
	0 AS [FailureRMA]
FROM #boardProd
ORDER BY [PartNumber], [SerialNo], [Date]

DROP TABLE #boardProd, #failureRMA

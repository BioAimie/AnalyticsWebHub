SET NOCOUNT ON

SELECT 
	Q.[NormalSerial],
	Q.[WireHarPart],
	(
		SELECT TOP 1
			P.[LotNumber]
		FROM [PMS1].[dbo].[bInstrumentParts] P
		WHERE P.[NormalSerial] = Q.[NormalSerial] AND P.[PartNumber] = Q.[WireHarPart]
			AND P.[DatePlaced] < Q.[CreatedDate]
		ORDER BY P.[DatePlaced] DESC
	) AS [LotNumber]
INTO #wireHarFailLot
FROM (
	SELECT 
		I.[NormalSerial],
		I.[CreatedDate],
		IIF(C.[FailureCategory] LIKE '%WIRE-HAR%',
			SUBSTRING(C.[FailureCategory], CHARINDEX('WIRE-HAR',C.[FailureCategory]), 13),
			UPPER(REPLACE(C.[PartNumber], ' ', ''))) AS [WireHarPart]
	FROM [PMS1].[dbo].[bInstrumentFailure] I
	INNER JOIN [PMS1].[dbo].[RMARootCauses] C ON C.[TicketId] = I.[TicketId]
) Q
WHERE [WireHarPart] LIKE 'WIRE-HAR-%' AND [WireHarPart] != 'WIRE-HAR-0554'

SELECT [NormalSerial] 
INTO #instShipped
FROM [PMS1].[dbo].[bInstrumentShipment]
WHERE [ShipNo] = 1

SELECT
	P.[LotNumber],
	'20' + SUBSTRING(RIGHT(P.[LotNumber], 9), 5, 2) + '-' + 
		SUBSTRING(RIGHT(P.[LotNumber], 9), 1, 2) + '-' + 
		SUBSTRING(RIGHT(P.[LotNumber], 9), 3, 2) AS [ReceiptDate],
	P.[PartNumber] AS [WireHarPart],
	SUM([Quantity]) AS [Count]
INTO #wireHarCountInField
FROM [PMS1].[dbo].[bInstrumentParts] P
WHERE [PartNumber] LIKE 'WIRE-HAR-%' AND [PartNumber] != 'WIRE-HAR-0554'
	AND [LotNumber] IS NOT NULL
	AND P.[NormalSerial] IN (SELECT * FROM #instShipped)
GROUP BY P.[LotNumber], P.[PartNumber]

SELECT
	W.[WireHarPart] AS [PartNumber],
	W.[LotNumber],
	CAST(W.[ReceiptDate] AS DATE) AS [ReceiptDate],
	W.[Count] AS [LotSizeInField],
	(
		SELECT COUNT(*)
		FROM #wireHarFailLot F
		WHERE F.[WireHarPart] = W.[WireHarPart] AND F.[LotNumber] = W.[LotNumber]
	) AS [FailCount],
	YEAR(W.[ReceiptDate]) AS [Year],
	MONTH(W.[ReceiptDate]) AS [Month],
	DATEPART(ww, W.[ReceiptDate]) AS [Week]
FROM #wireHarCountInField W
WHERE ISDATE(W.[ReceiptDate]) = 1
ORDER BY W.[WireHarPart], W.[ReceiptDate]

DROP TABLE #instShipped, #wireHarCountInField, #wireHarFailLot

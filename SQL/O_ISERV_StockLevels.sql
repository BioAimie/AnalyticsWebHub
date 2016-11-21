SET NOCOUNT ON

SELECT 
	S.[SerialNo],
	S.[ItemID],
	S.[WhseID],
	S.[InvtTranDistKey],
	I.[TranDate],
	I.[TranType],
	IIF(I.[TranQty] < 0, -1, 1) AS [Qty]
INTO #SerialTran
FROM 
(
	SELECT
		[TranDate],
		[TranType],
		[TranQty],
		[InvtTranKey]
	FROM [SQL1-RO].[mas500_app].[dbo].[vdvInventoryTran]
	WHERE ([ItemID] LIKE 'HTFA-ASY-0001%' OR [ItemID] LIKE 'HTFA-ASY-0003%'OR [ItemID] LIKE 'FLM1-ASY-0001%' OR [ItemID] LIKE 'FLM2-ASY-0001%')
		AND [TranQty] <> 0
) I INNER JOIN
(
	SELECT 
		REPLACE(REPLACE([SerialNo], '_', ''), '.', '') AS [SerialNo],
		[ItemID],
		[WhseID],
		[InvtTranKey], 
		[InvtTranDistKey]
	FROM [SQL1-RO].[mas500_app].[dbo].[vdvSerialTransactions]
	WHERE ([ItemID] LIKE 'HTFA-ASY-0001%' OR [ItemID] LIKE 'HTFA-ASY-0003%'OR [ItemID] LIKE 'FLM1-ASY-0001%' OR [ItemID] LIKE 'FLM2-ASY-0001%')
) S 
	ON I.[InvtTranKey] = S.[InvtTranKey]
ORDER BY [SerialNo], [InvtTranDistKey]

SELECT 
	ROW_NUMBER() OVER(PARTITION BY [SerialNo] ORDER BY [InvtTranDistKey]) AS [TranNum],
	*
INTO #SerialsOrdered
FROM #SerialTran
WHERE [SerialNo] IN 
(
	SELECT 
		[SerialNo]
	FROM #SerialTran
	GROUP BY [SerialNo]
	HAVING SUM([Qty]) = 1
)

SELECT 
	[ItemID],
	[Qty] AS [Record] 
FROM #SerialsOrdered O INNER JOIN 
(
	SELECT
		[SerialNo],
		MAX([TranNum]) AS [LastTran]
	FROM #SerialsOrdered
	GROUP BY [SerialNo] 
) T
	ON O.[TranNum] = T.[LastTran] AND O.[SerialNo] = T.[SerialNo]
WHERE [ItemID] LIKE '%R' AND [WhseID] LIKE 'STOCK'
ORDER BY [ItemID] 

DROP TABLE #SerialTran, #SerialsOrdered

SET NOCOUNT ON

SELECT
	IIF([SerialNo] LIKE '%R', SUBSTRING([SerialNo],1, PATINDEX('%R',[SerialNo])-1), [SerialNo]) AS [SerialNo],
	[ItemID], 
	[TranID],
	[InvtTranDistKey],
	[TranKey]
INTO #Serials
FROM
(
	SELECT 
		UPPER(REPLACE(REPLACE(REPLACE([SerialNo], '.',''),'_',''),' ','')) AS [SerialNo],
		[ItemID], 
		[TranID],
		[InvtTranDistKey],
		[TranKey]
	FROM [SQL1-RO].[mas500_app].[dbo].[vdvSerialTransactions] WITH(NOLOCK)
	WHERE ([ItemID] LIKE 'HTFA-ASY-0001%' OR [ItemID] LIKE 'HTFA-ASY-0003%' OR [ItemID] LIKE 'FLM%-ASY-0001%')
) A
ORDER BY [SerialNo], [TranKey] 

SELECT 
	[TranID],
	[TranDate],
	[TranKey],
	[TranType],
	IIF([TranQty] < 0, -1, 1) AS [DistQty]  
INTO #Invt
FROM [SQL1-RO].[mas500_app].[dbo].[vdvInventoryTran] WITH(NOLOCK)
WHERE ([ItemID] LIKE 'HTFA-ASY-0001%' OR [ItemID] LIKE 'HTFA-ASY-0003%' OR [ItemID] LIKE 'FLM%-ASY-0001%') 
	AND [TranKey] IS NOT NULL

SELECT
	S.[SerialNo],
	S.[ItemID], 
	S.[TranID],
	S.[TranKey],
	I.[TranDate],
	I.[TranType],
	I.[DistQty],
	H.[CustID],
	H.[SalesTerritoryID]
INTO #Master
FROM #Serials S LEFT JOIN #Invt I ON S.[TranKey] = I.[TranKey] 
	LEFT JOIN 
	(	
		SELECT 
			[TranID],
			[CustID],
			[CustName],
			[SalesTerritoryID]
		FROM [SQL1-RO].[mas500_app].[dbo].[vdvShipmentLine] WITH(NOLOCK)
		WHERE ([ItemID] LIKE 'HTFA-ASY-0001%' OR [ItemID] LIKE 'HTFA-ASY-0003%' OR [ItemID] LIKE 'FLM%-ASY-0001%') 
		GROUP BY [TranID], [CustID], [CustName], [SalesTerritoryID] 
	) H ON S.[TranID] = H.[TranID] 	
ORDER BY S.[SerialNo], S.[TranKey] 

SELECT
	ROW_NUMBER() OVER(PARTITION BY [SerialNo] ORDER BY [TranDate],[TranKey]) AS [Row],
	[SerialNo],
	[ItemID], 
	[TranDate],
	[CustID],
	[SalesTerritoryID],
	[TranType],
	[DistQty] 
INTO #Rows
FROM #Master
ORDER BY [SerialNo]

SELECT 
	R.[SerialNo],
	R.[ItemID], 
	R.[CustID],
	R.[SalesTerritoryID],
	R.[TranType],
	Q.[Qty]
INTO #Final
FROM #Rows R INNER JOIN 
(
	SELECT
		[SerialNo],
		MAX([Row]) AS [LastRow]
	FROM #rows
	GROUP BY [SerialNo]
) S
	ON R.[Row] = S.[LastRow] AND R.[SerialNo] = S.[SerialNo]
INNER JOIN 
(
	SELECT 
		[SerialNo],
		SUM([DistQty]) AS [Qty]
	FROM #Rows
	WHERE [DistQty] IS NOT NULL
	GROUP BY [SerialNo]
) Q 
	ON R.[SerialNo] = Q.[SerialNo] 
WHERE [Qty] = 0

SELECT 
	IIF([ItemID] LIKE 'FLM1-ASY-0001%', 'FA1.5',
		IIF([ItemID] LIKE 'FLM2-ASY-0001%', 'FA2.0',
		IIF([ItemID] LIKE 'HTFA-ASY-0001%', 'Torch Base',
		IIF([ItemID] LIKE 'HTFA-ASY-0003%', 'Torch Module', 'Other')))) AS [Version],
	IIF([SalesTerritoryID] LIKE 'International', 'International',
		IIF([CustID] LIKE 'IDATEC', 'Internal', 'Domestic')) AS [Region],
	1 AS [Record]
FROM #Final
WHERE [CustID] IS NOT NULL

DROP TABLE #Serials, #Invt, #Master, #Rows, #Final

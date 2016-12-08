SET NOCOUNT ON
--grab serials with WM transactions
SELECT DISTINCT 
	[SerialNo]
INTO #Serials
FROM [SQL1-RO].[mas500_app].[dbo].[vdvSerialTransactions] WITH(NOLOCK)
WHERE RIGHT([TranID],2) LIKE 'WM' AND [ItemID] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-ASY-0003')

--grab all transactions for select serials
SELECT 
	[SerialNo],
	[ItemID],
	[TranID],
	[WhseID],
	[TranKey]
INTO #Trans
FROM [SQL1-RO].[mas500_app].[dbo].[vdvSerialTransactions] WITH(NOLOCK)
WHERE [SerialNo] IN (SELECT * FROM #Serials)

--Get final list of serials
SELECT *
INTO #Final
FROM #Serials
WHERE [SerialNo] NOT IN 
(
	--See if serial ever shipped as new instrument, discard these serials
	SELECT DISTINCT
		[SerialNo]
	FROM #Trans 
	WHERE [ItemID] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-ASY-0003') AND RIGHT([TranID],2) LIKE 'SH'
)

--Replace vSerialTransactions view since it is not working 
SELECT        
	S.[SerialNo], 
	S.[DistQty], 
	S.[TranID], 
	S.[TranKey]
INTO #VSerials
FROM [SQL1-RO].[mas500_app].[dbo].[vdvSerialTransactions] S WITH (NOLOCK)
WHERE ([ItemID] LIKE 'FLM1-ASY-0001%' OR [ItemID] LIKE 'FLM2-ASY-0001%' OR [ItemID] LIKE 'HTFA-ASY-0003%')
    
SELECT 
	REPLACE(REPLACE(S.[SerialNo], '_', ''), '.', '') AS [SerialNo], 
	T .[ItemID] AS [ItemID], 
	T .[ItemDesc] AS [ItemDesc], 
	T .[TranType] AS [TranType], 
    T .[WhseID] AS [WhseID], 
	T .[TranDate] AS [TranDate], 
	IIF(T .[TranQty] < 0, - 1, 1) AS [DistQty]
INTO #SerialTrans
FROM [SQL1-RO].[mas500_app].[dbo].[vdvInventoryTran] T WITH (NOLOCK) INNER JOIN #VSerials S 
	ON T .[TranKey] = S.[TranKey]
WHERE T .[TranKey] IS NOT NULL 
	AND (T .[ItemID] LIKE 'FLM1-ASY-0001%' OR T .[ItemID] LIKE 'FLM2-ASY-0001%' OR T .[ItemID] LIKE 'HTFA-ASY-0003%')

--Find tran date from vSerialTransactions view
SELECT
	YEAR([TranDate]) AS [Year],
	MONTH([TranDate]) AS [Month],
	DATEPART(ww,[TranDate]) AS [Week],
	[TranDate],
	[SerialNo],
	[ItemID],
	CASE
		WHEN [ItemID] LIKE 'FLM1-ASY-0001' THEN 'FA1.5'
		WHEN [ItemID] LIKE 'FLM2-ASY-0001' THEN 'FA2.0'
		WHEN [ItemID] IN ('HTFA-ASY-0001','HTFA-ASY-0003') THEN 'Torch'
		ELSE 'Other'
	END AS [Product],
	'Refurb Conversion' AS [Key],
	1 AS [Record]
FROM #SerialTrans
WHERE [SerialNo] IN (SELECT * FROM #Final) AND [TranType] LIKE 'WM' AND [WhseID] LIKE 'STOCK'
	AND [ItemID] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-ASY-0003')
	
DROP TABLE #Serials, #Trans, #Final, #VSerials, #SerialTrans
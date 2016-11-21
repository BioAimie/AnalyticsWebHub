SET NOCOUNT ON

SELECT *
INTO #Serial
FROM [SQL1-RO].[mas500_app].[dbo].[vdvSerialTransactions] WITH(NOLOCK)
WHERE [ItemID] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-ASY-0001','HTFA-ASY-0003')

SELECT *
INTO #Inven
FROM [SQL1-RO].[mas500_app].[dbo].[vdvInventoryTran] WITH(NOLOCK)
WHERE [ItemID] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-ASY-0001','HTFA-ASY-0003')


SELECT 
	ROW_NUMBER() OVER (PARTITION BY [SerialNo] ORDER BY [TranDate]) AS [Row],
	[SerialNo],
	[TranDate],
	s.[WhseID],
	[TranQty]
INTO #Rows
FROM #Serial s LEFT JOIN #Inven i
	ON s.[InvtTranKey] = i.[InvtTranKey]
ORDER BY [SerialNo]

SELECT 
	[SerialNo]
INTO #Serials
FROM #Rows
WHERE [Row] = 1 AND [WhseID] LIKE 'IFSTK'

SELECT 
	[SerialNo],
	MIN([TranDate]) AS [Date],
	IIF(LEFT(s.[ItemID],4) LIKE 'FLM2','FA2.0',
		IIF(LEFT(s.[ItemID],4) LIKE 'FLM1','FA1.5',
		IIF(s.[ItemID] LIKE 'HTFA-ASY-0001','Torch Base',
		IIF(s.[ItemID] LIKE 'HTFA-ASY-0003', 'Torch Module',s.[ItemID])))) AS [Version]
INTO #Stock
FROM #Serial s LEFT JOIN #Inven i
	ON s.[InvtTranKey] = i.[InvtTranKey]
WHERE s.[WhseID] LIKE 'STOCK' AND [TranQty] > 0 
	AND [SerialNo] IN (SELECT * FROM #Serials)
GROUP BY [SerialNo], s.[ItemID]

SELECT
	YEAR([Date]) AS [Year],
	MONTH([Date]) AS [Month],
	[SerialNo], 
	[Version],
	1 AS [Record]
FROM #Stock
ORDER BY [Year],[Month]

DROP TABLE #Serial, #Inven, #Stock, #Rows, #Serials

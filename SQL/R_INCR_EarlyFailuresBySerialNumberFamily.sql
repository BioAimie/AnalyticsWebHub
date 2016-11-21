SET NOCOUNT ON

SELECT ROW_NUMBER() OVER(PARTITION BY [SerialNo] ORDER BY [TranDate], [ItemID] DESC) AS [TranId],
	[SerialNo],
	[ItemID],
	[TranDate]
INTO #trans
FROM [PMS1].[dbo].[vSerialTransactions] WITH(NOLOCK)
WHERE ([TranType] LIKE 'SH' OR ([TranType] IN ('SA','IS') AND [DistQty] = -1)) AND ([ItemID] LIKE '%FLM%-ASY-0001%' OR [ItemID] LIKE '%HTFA-ASY-0003%')

SELECT 
	T1.[SerialNo],
	IIF(LEFT(T1.[ItemID],4) LIKE 'FLM1', 'FA1.5', 
		IIF(LEFT(T1.[ItemID],4) LIKE 'FLM2', 'FA2.0','Torch')) AS [Version], 
	YEAR(T1.[TranDate]) AS [Year],
	DATEPART(ww, T1.[TranDate]) AS [Week],
	1 AS [Record]
INTO #serialShip
FROM #trans T1 INNER JOIN 
(
	SELECT 
		[SerialNo],
		MIN([TranId]) AS [TranId]
	FROM #trans
	GROUP BY [SerialNo]
) T2
	ON T1.[SerialNo] = T2.[SerialNo] AND T1.[TranId] = T2.[TranId]

SELECT 
	[Year],
	[Week],
	[Version],
	SUM([Record]) AS [Shipments]
INTO #periodShip
FROM #serialShip
GROUP BY [Year], [Week], [Version]

SELECT 
	S.[SerialNo], 
	S.[Version],
	S.[Year],
	S.[Week],
	P.[Shipments],
	S.[Record]
FROM #serialShip S LEFT JOIN #periodShip P
	ON S.[Year] = P.[Year] AND S.[Week] = P.[Week] AND S.[Version] = P.[Version]
ORDER BY S.[Year], S.[Week], S.[Version]

DROP TABLE #trans, #serialShip, #periodShip
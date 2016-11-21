SET NOCOUNT ON

SELECT ROW_NUMBER() OVER(PARTITION BY [SerialNo] ORDER BY [TranDate], [ItemID]) AS [uniqueId],
	[ItemID],
	IIF(LEFT([SerialNo],2) LIKE 'FA', SUBSTRING([SerialNo], 1, 6), [SerialNo]) AS [SerialNo],
	[TranDate]
INTO #id
FROM [PMS1].[dbo].[vSerialTransactions] WITH(NOLOCK)
WHERE ([TranType] LIKE 'SH') OR ([TranType] IN ('IS','SA') AND [DistQty]=-1)

SELECT 
	I.[SerialNo],
	V.[ItemID] AS [Version],
	V.[TranDate]
INTO #Transact
FROM
(	
	SELECT 	
		[SerialNo],
		MIN([uniqueId]) AS [id]
	FROM #id 
	GROUP BY [SerialNo]
) I INNER JOIN
(
	SELECT 
		[SerialNo],
		[uniqueId],
		[ItemID],
		[TranDate]
	FROM #id		
) V
	ON I.[id] = V.[uniqueId] AND I.[SerialNo] = V.[SerialNo]

SELECT
	YEAR([TranDate]) AS [Year],
	MONTH([TranDate]) AS [Month],
	DATEPART(ww,[TranDate]) AS [Week],
	IIF(LEFT([Version],4) LIKE 'FLM1', 'FA1.5', 
		IIF(LEFT([Version],4) LIKE 'FLM2', 'FA2.0', 'Torch')) AS [Version],
	'NewInstShip' AS [Key],
	COUNT(DISTINCT [SerialNo]) AS [Record]
FROM #Transact
WHERE ([Version] LIKE 'HTFA-ASY-0003%' OR [Version] LIKE 'FLM%-ASY-0001%') AND [TranDate] > GETDATE() - 400
GROUP BY YEAR([TranDate]), MONTH([TranDate]), DATEPART(ww, [TranDate]), [Version]

DROP TABLE #id, #Transact
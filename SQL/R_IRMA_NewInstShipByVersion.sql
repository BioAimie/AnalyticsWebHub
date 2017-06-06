SET NOCOUNT ON

SELECT ROW_NUMBER() OVER(PARTITION BY [SerialNo] ORDER BY [TranDate], [ItemID]) AS [uniqueId],
	[ItemID],
	[SerialNo],
	[TranDate]
INTO #id
FROM
(
	SELECT
		[ItemID],
		IIF(LEFT([SerialNo],2) = 'FA', SUBSTRING([SerialNo], 1, 6), 
			IIF(LEFT([SerialNo], 3) IN ('KTM','2FA'), SUBSTRING([SerialNo], 1, 8), [SerialNo])) AS [SerialNo],
		[TranDate]
	FROM [PMS1].[dbo].[vSerialTransactions] WITH(NOLOCK)
	WHERE ([TranType] LIKE 'SH') OR ([TranType] IN ('IS','SA') AND [DistQty]=-1)
) T

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
	CAST([TranDate] AS DATE) AS [Date],
	YEAR([TranDate]) AS [Year],
	MONTH([TranDate]) AS [Month],
	DATEPART(ww,[TranDate]) AS [Week],
	IIF(LEFT([Version],4) LIKE 'FLM1', 'FA1.5', 
		IIF(LEFT([Version],4) LIKE 'FLM2', 'FA2.0', 'Torch')) AS [Version],
	'NewInstShip' AS [Key],
	COUNT(*) AS [Record]
FROM #Transact
WHERE ([Version] LIKE 'HTFA-SUB-0103%' OR [Version] LIKE 'HTFA-ASY-0003%' OR [Version] LIKE 'FLM%-ASY-0001%') --AND [TranDate] > GETDATE() - 400
GROUP BY CAST([TranDate] AS DATE), YEAR([TranDate]), MONTH([TranDate]), DATEPART(ww, [TranDate]), [Version]

DROP TABLE #id, #Transact
SET NOCOUNT ON

SELECT 
	ROW_NUMBER() OVER(PARTITION BY [SerialNo] ORDER BY [TranDate], [ItemID]) AS [Row],
	[ItemID],
	IIF([SerialNo] LIKE 'K%R', UPPER(SUBSTRING([SerialNo], 2, PATINDEX('%R', [SerialNo])-2)), 
		IIF([SerialNo] LIKE 'K%', UPPER(SUBSTRING([SerialNo], 2, LEN([SerialNo]))), 
		IIF([SerialNo] LIKE '%R', UPPER(SUBSTRING([SerialNo], 1, PATINDEX('%R', [SerialNo])-1)), UPPER([SerialNo])))) AS [SerialNo],
	[TranDate]
INTO #Serials
FROM [PMS1].[dbo].[vSerialTransactions] WITH(NOLOCK)
WHERE ([ItemID] LIKE 'FLM%-ASY-0001%' OR [ItemID] LIKE 'HTFA-ASY-%')

SELECT 
	S.[SerialNo],
	IIF(S.[ItemID] LIKE 'FLM1%', 'FA 1.5',
		IIF(S.[ItemID] LIKE 'FLM2%', 'FA 2.0', 'Torch')) AS [Version] 
FROM #Serials S INNER JOIN
(
	SELECT 
		[SerialNo],
		MAX([Row]) AS [MaxRow]
	FROM #Serials
	GROUP BY [SerialNo] 
) C
	ON S.[SerialNo] = C.[SerialNo] AND S.[Row] = C.[MaxRow]
ORDER BY S.[SerialNo]

DROP TABLE #Serials

SET NOCOUNT ON

SELECT *,
	YEAR([TranDate]) AS [Year],
	DATEPART(ww,[TranDate]) AS [Week]
INTO #invTrans
FROM [PMS1].[dbo].[vSerialTransactions] WITH(NOLOCK)

SELECT 
	IIF([Week] <= 40, [Year], [Year] + 1) AS [Year],
	IIF([Week] <= 40, [Week] + 13, [Week] - 40) AS [Week], 
	IIF(LEFT([ItemID],4) LIKE 'FLM1','FA1.5',
		IIF(LEFT([ItemID],4) LIKE 'FLM2','FA2.0','Torch')) AS [Version],
	[SerialNo],
	[TranType],
	[DistQty]
INTO #adj
FROM #invTrans

SELECT 
	IIF([Week] < 10, CONCAT([Year],'-0',[Week]), CONCAT([Year],'-',[Week])) AS [DateGroup],
	[SerialNo],
	[TranType],
	[Version],
	[DistQty]	
INTO #concatDate
FROM #adj

SELECT 
	[DateGroup],
	[Version],
	MAX([Record]) AS [Record]
FROM 
(
	SELECT 
		[DateGroup],
		'FA1.5' AS [Version],
		(
			SELECT 
				COUNT([SerialNo])
			FROM
			(
				SELECT
					[SerialNo],
					SUM([DistQty]) AS [Location]
				FROM #concatDate C2
				WHERE [SerialNo] IN
				(
					SELECT 
						[SerialNo]
					FROM #concatDate C1
					WHERE C1.[DateGroup] <= C3.[DateGroup]
					GROUP BY [SerialNo]
					HAVING MAX([Version]) LIKE 'FA1.5'
				)
					AND C2.[DateGroup] <= C3.[DateGroup]
				GROUP BY [SerialNo]
			) A
			WHERE [Location] = 0
		) AS [Record]
	FROM #concatDate C3
	UNION ALL
	SELECT 
		[DateGroup],
		'FA2.0' AS [Version],
		(
			SELECT 
				COUNT([SerialNo])
			FROM
			(
				SELECT
					[SerialNo],
					SUM([DistQty]) AS [Location]
				FROM #concatDate C2
				WHERE [SerialNo] IN
				(
					SELECT 
						[SerialNo]
					FROM #concatDate C1
					WHERE C1.[DateGroup] <= C3.[DateGroup]
					GROUP BY [SerialNo]
					HAVING MAX([Version]) LIKE 'FA2.0'
				)
					AND C2.[DateGroup] <= C3.[DateGroup]
				GROUP BY [SerialNo]
			) A
			WHERE [Location] = 0
		) AS [Record]
	FROM #concatDate C3
	UNION ALL
	SELECT 
		[DateGroup],
		'Torch' AS [Version],
		(
			SELECT 
				COUNT([SerialNo])
			FROM
			(
				SELECT
					[SerialNo],
					SUM([DistQty]) AS [Location]
				FROM #concatDate C2
				WHERE [SerialNo] IN
				(
					SELECT 
						[SerialNo]
					FROM #concatDate C1
					WHERE C1.[DateGroup] <= C3.[DateGroup]
					GROUP BY [SerialNo]
					HAVING MAX([Version]) LIKE 'Torch'
				)
					AND C2.[DateGroup] <= C3.[DateGroup]
				GROUP BY [SerialNo]
			) A
			WHERE [Location] = 0
		) AS [Record]
	FROM #concatDate C3
) A
GROUP BY [DateGroup], [Version] 
ORDER BY [DateGroup], [Version] 

DROP TABLE #invTrans, #adj, #concatDate

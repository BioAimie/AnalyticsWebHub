SET NOCOUNT ON

SELECT 
	S.[SerialNo] AS [OldSerial],
	IIF(S.[SerialNo] LIKE 'K%R', SUBSTRING(S.[SerialNo], 2, PATINDEX('%R', S.[SerialNo])-2),
		IIF(S.[SerialNo] LIKE '%R', SUBSTRING(S.[SerialNo], 1, PATINDEX('%R',S.[SerialNo])-1), 
		IIF(S.[SerialNo] LIKE 'K%', SUBSTRING(S.[SerialNo], 2, LEN(S.[SerialNo])), S.[SerialNo]))) AS [SerialNo],
	S.[ItemID],
	S.[WhseID],
	I.[TranDate],
	IIF(I.[TranQty] > 0, 1,
		IIF(I.[TranQty] < 0, -1, 0)) AS [TranQty],
	I.[InvtTranKey]
INTO #Serials
FROM 
(
	SELECT
		[ItemID],
		[WhseID],
		[InvtTranKey],
		UPPER(REPLACE(REPLACE(REPLACE(REPLACE([SerialNo],' ',''),'_',''),'-',''),'.','')) AS [SerialNo]
	FROM [SQL1-RO].[mas500_app].[dbo].[vdvSerialTransactions] WITH(NOLOCK)
	WHERE [ItemID] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-ASY-0001','HTFA-ASY-0003') OR 
		[ItemID] IN ('FLM1-ASY-0001R','FLM2-ASY-0001R','HTFA-ASY-0001R','HTFA-ASY-0003R')
) S LEFT JOIN 
(
	SELECT
		[TranDate],
		[TranQty],
		[InvtTranKey]
	FROM [SQL1-RO].[mas500_app].[dbo].[vdvInventoryTran] WITH(NOLOCK)
	WHERE [ItemID] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-ASY-0001','HTFA-ASY-0003') OR
		[ItemID] IN ('FLM1-ASY-0001R','FLM2-ASY-0001R','HTFA-ASY-0001R','HTFA-ASY-0003R')
) I
	ON S.[InvtTranKey] = I.[InvtTranKey] 

SELECT
	ROW_NUMBER() OVER(PARTITION BY [SerialNo] ORDER BY [TranDate], [InvtTranKey]) AS [Row],
	[SerialNo],
	[ItemID],
	[TranDate]
INTO #Rows 
FROM #Serials 
WHERE [WhseID] LIKE 'STOCK' AND [TranQty] > 0
	AND [SerialNo] IN 
(
	SELECT 
		[SerialNo] 
	FROM 
	(
		SELECT 
			ROW_NUMBER() OVER (PARTITION BY [SerialNo] ORDER BY [TranDate], [InvtTranKey]) AS [Row],
			[SerialNo],
			[TranDate],
			[WhseID],
			[TranQty]
		FROM #Serials 
	) A
	WHERE [Row] = 1 AND [WhseID] LIKE 'IFSTK'
)

SELECT 
	YEAR([TranDate]) AS [Year],
	MONTH([TranDate]) AS [Month],
	[SerialNo],
	IIF([ItemID] LIKE 'FLM1-%', 'FA1.5',
		IIF([ItemID] LIKE 'FLM2-%', 'FA2.0',
		IIF([ItemID] LIKE 'HTFA-ASY-0001%', 'Torch Base',
		IIF([ItemID] LIKE 'HTFA-ASY-0003%', 'Torch Module', [ItemID])))) AS [Version],
	1 AS [Record]  
FROM #Rows
WHERE [Row] = 1
ORDER BY [TranDate] 

DROP TABLE #Serials, #Rows

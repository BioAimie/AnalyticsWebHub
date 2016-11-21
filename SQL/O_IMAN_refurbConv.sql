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

--See if serial ever shipped as new instrument, discard these serials
SELECT DISTINCT
	[SerialNo]
INTO #Discard
FROM #Trans 
WHERE [ItemID] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-ASY-0003') AND RIGHT([TranID],2) LIKE 'SH'

--Get final list of serials
SELECT *
INTO #Final
FROM #Serials
WHERE [SerialNo] NOT IN (SELECT * FROM #Discard)

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
FROM [PMS1].[dbo].[vSerialTransactions] WITH(NOLOCK)
WHERE [SerialNo] IN (SELECT * FROM #Final) AND [TranType] LIKE 'WM' AND [WhseID] LIKE 'STOCK'
	AND [ItemID] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-ASY-0003')
	
DROP TABLE #Serials, #Trans, #Discard, #Final
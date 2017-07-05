SET NOCOUNT ON

--Additional cleaning of serials and gather all instrument transactions
SELECT 
	IIF([SerialNo] LIKE '2FA%', SUBSTRING([SerialNo], 2, LEN([SerialNo])-1), 
		IIF([SerialNo] LIKE 'K%', SUBSTRING([SerialNo], 2, LEN([SerialNo])-1), [SerialNo])) AS [SerialNo],
	[ItemID], 
	[TranDate], 
	[DistQty], 
	[TranID],
	[TranKey], 
	YEAR([TranDate]) AS [Year],
	DATEPART(ww,[TranDate]) AS [Week]  
INTO #InvtTrans
FROM [PMS1].[dbo].[vSerialTransactions] 

--Add customer ID if any to transactions, all SH should have a customer ID from the shipment line view in MAS
SELECT 
	T.[SerialNo],
	T.[ItemID],
	T.[DistQty],
	T.[TranID],
	T.[TranKey],  
	T.[Year],
	T.[Week],
	IIF(C.[CustomerID] IS NULL, 'None', C.[CustomerID]) AS [CustID] 
INTO #InvtTransCust
FROM #InvtTrans T LEFT JOIN 
(
	SELECT
		MAX([CustID]) AS [CustomerID],
		[TranID]
	FROM [SQL1-RO].[mas500_app].[dbo].[vdvShipmentLine] 
	GROUP BY [TranID] 
) C
	ON T.[TranID] = C.[TranID]
ORDER BY [SerialNo], [TranKey]

--Lag week by 13 weeks (about a quarter) to account for getting instrument set up and running
--13 weeks in an arbitrary estimate of how long it takes for customers to starting running real pouches. I don't think this is based on any real data.
SELECT 
	IIF([Week] <= 40, [Year], [Year] + 1) AS [Year],
	IIF([Week] <= 40, [Week] + 13, [Week] - 40) AS [Week], 
	IIF(LEFT([ItemID],4) LIKE 'FLM1','FA1.5',
		IIF(LEFT([ItemID],4) LIKE 'FLM2','FA2.0','Torch')) AS [Version],
	[SerialNo],
	[DistQty],
	[CustID],
	[TranKey]  
INTO #WeeksLag
FROM #InvtTransCust

--Add dategroup 
SELECT 
	ROW_NUMBER() OVER(PARTITION BY [SerialNo] ORDER BY [TranKey]) AS [Row], 
	IIF([Week] < 10, CONCAT([Year],'-0',[Week]), CONCAT([Year],'-',[Week])) AS [DateGroup],
	[SerialNo],
	[Version],
	[DistQty],
	[CustID],
	[TranKey] 	
INTO #ConcatDate
FROM #WeeksLag
ORDER BY [DateGroup], [SerialNo], [Row]

SELECT
	[Row],
	[DateGroup],
	[SerialNo],
	[Version],
	[DistQty],
	[CustID],
	IIF([CustID] LIKE 'IDATEC', 'Internal',
		IIF([CustID] LIKE '%BMX-NC%', 'Domestic',
		IIF([CustID] LIKE 'BMX%' OR [CustID] LIKE 'DIST%', 'International', 
		IIF([CustID] IN ('BIODEF','NGDS'), 'Defense',
		IIF([CustID] LIKE 'none', 'N/A', 'Domestic'))))) AS [CustType],
	[TranKey]
FROM #ConcatDate

--At each week, filter out instruments whose DistQty is 0 (these should be out), then only choose instruments whose last transaction resulted in a customer shipment (not NULL, not IDATEC)
--Perhaps annotate if customer is defense, international, or domestic

DROP TABLE #InvtTrans, #InvtTransCust, #WeeksLag, #ConcatDate

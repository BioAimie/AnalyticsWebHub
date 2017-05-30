SET NOCOUNT ON

SELECT 
	IIF([CustID] LIKE '%-[0-9]', SUBSTRING([CustID],1,PATINDEX('%-%',[CustID])-1), 
		IIF([CustID] LIKE '%/', SUBSTRING([CustID],1,PATINDEX('%/',[CustID])-1), 
		IIF([CustID] LIKE '%(%)%', SUBSTRING([CustID],1,PATINDEX('%(%)%',[CustID])-1), 
		IIF([CustID] LIKE '99-%', SUBSTRING([CustID], 4, LEN([CustID])), [CustID])))) AS [CustID],
	[Record] 
INTO #CleanCust
FROM
(
	SELECT 
		UPPER(RTRIM(LTRIM([CustID]))) AS [CustID],
		[QtyShipped] AS [Record]
	FROM [PMS1].[dbo].[vPouchShipmentsWithAnnotations_IOID]
	WHERE [CustID] IS NOT NULL AND CAST([ShipDate] AS DATE) >= GETDATE() - 365
) A
ORDER BY [CustID]

SELECT 
	A.[CustID],
	B.[CustName],
	A.[CustID] + ' - ' + B.[CustName] AS [Customer], 
	A.[Record]
FROM
(
	SELECT	
		[CustID],
		SUM([Record]) AS [Record]
	FROM #CleanCust
	GROUP BY [CustID]
) A LEFT JOIN 
(
	SELECT DISTINCT 
		[CustID],
		[CustName]
	FROM [SQL1-RO].[mas500_app].[dbo].[vdvCustomer]
) B
	ON A.[CustID] = B.[CustID]

DROP TABLE #CleanCust

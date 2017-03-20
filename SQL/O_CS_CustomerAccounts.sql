--This query finds the total number of customer accounts.
SET NOCOUNT ON

SELECT DISTINCT 
	CAST([CreateDate] AS DATE) AS [Date],
	[CustID], 
	[CustName],
	1 AS [Record]
INTO #Cust
FROM [SQL1-RO].[mas500_app].[dbo].[vdvCustomer] WITH(NOLOCK)

SELECT 
	[Year],
	[Month],
	[Week],
	'CustAccount' AS [Key],
	SUM([Record]) AS [Record]
FROM 
(
	SELECT 
		YEAR([Date]) AS [Year],
		MONTH([Date]) AS [Month],
		DATEPART(ww, [Date]) AS [Week],
		[Record] 
	FROM #Cust
) A
GROUP BY [Year], [Month], [Week]

DROP TABLE #Cust

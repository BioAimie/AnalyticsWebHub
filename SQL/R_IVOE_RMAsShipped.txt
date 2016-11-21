SET NOCOUNT ON

SELECT
	[TicketString],
	[TicketId],
	CAST([RecordedValue] AS DATE) AS [ShippingDate]
INTO #tickets
FROM [RO_TRACKERS].[Trackers].[dbo].[vAllPopertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Shipping Date'

SELECT
	YEAR([ShippingDate]) AS [Year],
	MONTH([ShippingDate]) AS [Month],
	DATEPART(ww,[ShippingDate]) AS [Week],
	'Shipped' AS [Key],
	1 AS [Record]
INTO #shipped
FROM #tickets

SELECT 
	[Year],
	[Month],
	[Week],
	[Key],
	SUM([Record]) AS [Record]
FROM #shipped
GROUP BY
	[Year],
	[Month],
	[Week],
	[Key]

DROP TABLE #tickets, #shipped	 
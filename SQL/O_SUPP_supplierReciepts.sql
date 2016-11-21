SELECT
	CAST([RcvDate] AS DATE) AS [Date],
	YEAR([RcvDate]) AS [Year],
	MONTH([RcvDate]) AS [Month],
	DATEPART(ww,[RcvDate]) AS [Week],
	UPPER([ItemID]) AS [PartNumber],
	[VendName],
	IIF([RcvQty] < 0, 0, [RcvQty]) AS [RcvQty]
FROM [PMS1].[dbo].[vSupplierReceipts] WITH(NOLOCK)
--WHERE [RcvDate] > CONVERT(DATETIME, '2014-03-01')
ORDER BY [ItemID], [VendName], [RcvDate]
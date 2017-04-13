SELECT
	YEAR([ShipDate]) AS [Year],
	MONTH([ShipDate]) AS [Month],
	DATEPART(ww,[ShipDate]) AS [Week],
	'PouchesShipped' AS [Key],
	[Panel],
	SUM(IIF([TranType] NOT LIKE 'SH',-1*[QtyShipped],[QtyShipped])) AS [Record]
FROM [PMS1].[dbo].[vPouchShipmentsWithAnnotations_IOID] WITH(NOLOCK)
WHERE [ShipDate] >= (GETDATE() - 600) AND [ProductClass] LIKE 'IVD' AND [CustID] NOT LIKE 'IDATEC'
GROUP BY 
	YEAR([ShipDate]),
	MONTH([ShipDate]),
	DATEPART(ww,[ShipDate]),
	[Panel]
ORDER BY 
	YEAR([ShipDate]),
	MONTH([ShipDate]),
	DATEPART(ww,[ShipDate])

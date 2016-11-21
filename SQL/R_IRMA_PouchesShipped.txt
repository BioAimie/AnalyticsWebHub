SELECT
	YEAR([ShipDate]) AS [Year],
	DATEPART(ww,[ShipDate]) AS [Week],
	'PouchesShipped' AS [Key],
	SUM(IIF([TranType] NOT LIKE 'SH',-1*[QtyShipped],[QtyShipped])) AS [Record]
FROM [PMS1].[dbo].[vPouchShipmentsWithAnnotations_IOID] WITH(NOLOCK)
WHERE [ShipDate] >= (GETDATE() - 600) AND [ProductClass] LIKE 'IVD' AND [CustID] NOT LIKE 'IDATEC'
GROUP BY 
	YEAR([ShipDate]),
	DATEPART(ww,[ShipDate])
ORDER BY 
	YEAR([ShipDate]),
	DATEPART(ww,[ShipDate])
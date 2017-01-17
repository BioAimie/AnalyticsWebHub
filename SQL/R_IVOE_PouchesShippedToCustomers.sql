SELECT
	YEAR([ShipDate]) AS [Year],
	MONTH([ShipDate]) AS [Month],
	DATEPART(ww,[ShipDate]) AS [Week],
	'CustPouchShip' AS [Key],
	IIF([TranType] NOT LIKE 'SH', -1*[QtyShipped], [QtyShipped]) AS [Record]
FROM [PMS1].[dbo].[vPouchShipmentsWithAnnotations_IOID] WITH(NOLOCK)
WHERE [ShipDate] >= CONVERT(datetime, '2013-01-01') AND [ProductClass] = 'IVD' AND [CustID] <> 'IDATEC'
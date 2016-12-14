SELECT
	YEAR([ShipDate]) AS [Year],
	DATEPART(ww,[ShipDate]) AS [Week],
	[Panel] AS [Version],
	'CustPouchShip' AS [Key],
	IIF([SalesTerritoryID] LIKE 'International', [SalesTerritoryID], 'Domestic') AS [RecordedValue],
	IIF([TranType] NOT LIKE 'SH',-1*[QtyShipped],[QtyShipped]) AS [Record]
FROM [PMS1].[dbo].[vPouchShipmentsWithAnnotations_IOID] WITH(NOLOCK)
WHERE [ProductClass] LIKE 'IVD' AND [CustID] NOT LIKE 'IDATEC'
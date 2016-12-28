SET NOCOUNT ON

SELECT
	CAST([ShipDate] AS DATE) AS [ShipDate],
	[Panel] AS [Version],
	'CustPouchShip' AS [Key],
	IIF([SalesTerritoryID] LIKE 'International', [SalesTerritoryID], 'Domestic') AS [RecordedValue],
	IIF([TranType] NOT LIKE 'SH',-1*[QtyShipped],[QtyShipped]) AS [Record]
INTO #AllPouches
FROM [PMS1].[dbo].[vPouchShipmentsWithAnnotations_IOID] WITH(NOLOCK)
WHERE [ProductClass] LIKE 'IVD' AND [CustID] NOT LIKE 'IDATEC'

SELECT 
	[Version],
	'Last 365 Days' AS [Key],
	IIF([ShipDate] >= CAST(GETDATE()-30 AS DATE), 1, 0) AS [Last30Days],
	[Record] 
FROM #AllPouches
WHERE [ShipDate] >= CAST(GETDATE()-365 AS DATE) 
ORDER BY [ShipDate]

DROP TABLE #AllPouches

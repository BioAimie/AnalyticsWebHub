SET NOCOUNT ON

SELECT 
       [ShipDate],
	   RIGHT([ItemID],13) AS [ItemID],
	   [Panel],
	   [CurrentCustClassID],
	   [CustID],
	   [CustName],
	   [WhseID],
       IIF([QtyShipped] < 0, -1*[QtyShipped], [QtyShipped]) AS [QtyShipped],
	   [TranType],
	   [SalesSource],
       [SalesTerritoryID],
	   [ProductClass],
	   [IncludeInSales],
	   [NonInventory]
INTO #PouchSumm
FROM [PMS1].[dbo].[vPouchShipmentsWithAnnotations_IOID]

SELECT
	YEAR([ShipDate]) AS [Year],
	MONTH([ShipDate]) AS [Month],
	IIF(MONTH([ShipDate]) BETWEEN 1 AND 3, 1,
		IIF(MONTH([ShipDate]) BETWEEN 4 AND 6, 2,
		IIF(MONTH([ShipDate]) BETWEEN 7 AND 9, 3, 4))) AS [Quarter],
	[Panel],
	[CurrentCustClassID],
	[CustID],
	[CustName],
	[QtyShipped]
FROM #PouchSumm
WHERE [CustID] NOT LIKE 'IDATEC' AND [Panel] NOT LIKE 'Other' AND [IncludeInSales] = 1

DROP TABLE #PouchSumm



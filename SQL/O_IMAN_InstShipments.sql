SET NOCOUNT ON

SELECT 
	s.[TranID],
	UPPER(REPLACE(REPLACE(REPLACE(REPLACE(s.[SerialNo], ' ',''),'.',''),'_',''),'-','')) AS [SerialNo],
	s.[ItemID],
	s.[WhseID],
	t.[CustID],
	t.[CustName],
	t.[ShipToCountryId],
	i.[TranType],
	t.[ShipDate], 
	i.[TranDate],
	t.[SalesSource],
    t.[CurrentCustClassID],
	IIF(t.[SalesTerritoryID] IS NULL, 'Other', [SalesTerritoryID]) AS [SalesTerritoryID],
	1 AS [Record]
INTO #Shipments
FROM 
(
	SELECT *
	FROM [SQL1-RO].[mas500_app].[dbo].[vdvSerialTransactions]
	WHERE [ItemID] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-ASY-0001','HTFA-ASY-0003','FLM1-ASY-0001R','FLM2-ASY-0001R','HTFA-ASY-0003R','HTFA-ASY-0001R') 
) s
LEFT JOIN [SQL1-RO].[mas500_app].[dbo].[vdvInventoryTran] i ON s.[TranKey] = i.[TranKey]
LEFT JOIN 
(
	SELECT *
	FROM [SQL1-RO].[mas500_app].[dbo].[vdvShipmentLine]
	WHERE [ItemID] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-ASY-0001','HTFA-ASY-0003','FLM1-ASY-0001R','FLM2-ASY-0001R','HTFA-ASY-0003R','HTFA-ASY-0001R') 
) t ON s.[TranID] = t.[TranID]
WHERE ((i.[TranType] LIKE 'SH') OR (i.[TranType] IN ('IS','SA') AND i.[TranQty] < 0))
GROUP BY 
	t.[ShipDate], 
	i.[TranDate],
	i.[TranType], 
	s.[WhseID], 
	s.[ItemID],
	t.[SalesTerritoryID],
	t.[CustID],
	t.[CustName],
	t.[CurrentCustClassID], 
	s.[SerialNo], 
	s.[TranID], 
	t.[ShipToCountryId], 
	t.[SalesSource]

SELECT 
	IIF([SerialNo] LIKE '%R', SUBSTRING([SerialNo],1, PATINDEX('%R',[SerialNo])-1), [SerialNo]) AS [SerialNo],
	YEAR([TranDate]) AS [Year],
	MONTH([TranDate]) AS [Month],
	DATEPART(ww, [TranDate]) AS [Week],
	[TranDate] AS [ShipDate],
	[ItemID],
	CASE
		WHEN [ItemID] LIKE 'FLM1-ASY-0001' THEN 'FA1.5'
		WHEN [ItemID] LIKE 'FLM1-ASY-0001R' THEN 'FA1.5R'
		WHEN [ItemID] LIKE 'FLM2-ASY-0001' THEN 'FA2.0'
		WHEN [ItemID] LIKE 'FLM2-ASY-0001R' THEN 'FA2.0R'
		WHEN [ItemID] LIKE 'HTFA-ASY-0001' THEN 'Torch Base'
		WHEN [ItemID] LIKE 'HTFA-ASY-0001R' THEN 'Torch Base R'
		WHEN [ItemID] LIKE 'HTFA-ASY-0003' THEN 'Torch Module'
		WHEN [ItemID] LIKE 'HTFA-ASY-0003R' THEN 'Torch Module R'
		ELSE 'Other'
	END AS [Product],
	[CustID],
	[CustName],
	[CurrentCustClassID] AS [CustClass],
	[ShipToCountryID] AS [Country],
	[SalesTerritoryID],
	IIF ([SalesTerritoryID] LIKE 'W%', 'West',
		IIF ([SalesTerritoryID] LIKE 'NE%', 'North East',
		IIF ([SalesTerritoryID] LIKE 'SE%', 'South East',
		IIF ([SalesTerritoryID] LIKE 'GL%', 'Great Lakes',
		IIF ([SalesTerritoryID] LIKE 'C%', 'Central',
		IIF ([SalesTerritoryID] LIKE 'MA%', 'Mid Atlantic',
		IIF ([SalesTerritoryID] IS NULL, 'Other',
			[SalesTerritoryID]))))))) AS [SalesTerritory],
	[SalesSource],
	CASE
		WHEN [SalesSource] IN ('REG Trade ADDON', 'RRA Cap Lease', 'FP OpLease', 'FP CapLeas', 'OPLease/Flex', 'Inst OpLease', 'RRA Op Lease', 
			'Sale', 'Inst CapLease', 'RRA') AND [ShipToCountryID] LIKE 'USA' THEN 'Domestic Sale'
		WHEN [SalesSource] IN ('REG Trade ADDON', 'RRA Cap Lease', 'FP OpLease', 'FP CapLeas', 'OPLease/Flex', 'Inst OpLease', 'RRA Op Lease', 
			'Sale', 'Inst CapLease', 'RRA') AND [SalesTerritoryID] LIKE 'International' THEN 'International Sale'
		WHEN [SalesSource] IN ('FOC Trade WAR', 'REG Trade WAR', 'FP CapLeas Trad', 'RRA Op TradeUp', 'RRA Cap TradeUp', 'FP OpLeas Trade', 'FOC Trade NOWAR',
			'REG Trade NOWAR', 'InstOpLease TU', 'Inst CapLease Trade', 'Inst OpLease Trade') THEN 'Trade-Up'
		WHEN [SalesSource] IN ('Loaner - EAP') THEN 'EAP'
		WHEN [SalesSource] IN ('Loaner RMA PR','Loan CSA/RSA PR','Loaner Beta PR', 'FP CapLeas PR', 'OPLease/Flex PR', 'RRA CapLeas PR', 'RRA OpLease PR', 
			'InstOpLease PR', 'FP OpLease PR','PermRepl', 'EAP PermRepl', 'NONW Perm Rep', 'STRental PR', 'RRA PR', 'MFGW Perm Rep', 'EXTW Perm Rep', 
			'DEMO FSE PR', 'BFDXInst PR', 'Sale Perm Rep','Inst CapLeas PR','Loaner MTA PR') THEN 'Replacement'
		WHEN [SalesSource] IN ('DEMO - FSE','DEMO - DIST') THEN 'Demo'
		WHEN [SalesSource] IN ('Loaner - MTA', 'Loaner CSA/RSA', 'Loaner - RMA','Loaner - Beta') THEN 'Loaner'
		WHEN [SalesSource] IN ('BFDXInst','MFGW', 'EXTW', 'NONW') THEN 'Internal'
		WHEN [SalesSource] IN ('STRental') THEN 'Short Term Rental'
		ELSE 'Other'
	END AS [SalesType],
	[Record]
INTO #Master
FROM #Shipments

SELECT
	ROW_NUMBER() OVER(PARTITION BY [SerialNo] ORDER BY [ShipDate]) AS [ShipOrder],
	[SerialNo],
	[Year],
	[Month],
	[Week],
	[ShipDate],
	[ItemID],
	[Product],
	[CustID],
	[CustName],
	[CustClass],
	[Country],
	[SalesTerritoryID],
	[SalesTerritory],
	[SalesSource],
	[SalesType],
	[Record]
FROM #Master
ORDER BY [SerialNo] 

DROP TABLE #Shipments, #Master

SET NOCOUNT ON

SELECT 
	[SerialNo],
	s.[ItemID],
	s.[WhseID],
	[CustID],
	[CustName],
	[ShipToCountryId],
	[TranType],
	[ShipDate], 
	[SalesSource],
    [CurrentCustClassID],
	IIF([SalesTerritoryID] IS NULL, 'Other', [SalesTerritoryID]) AS [SalesTerritoryID],
	1 AS [Record]
INTO #Shipments
FROM [SQL1-RO].[mas500_app].[dbo].[vdvSerialTransactions] s LEFT JOIN [SQL1-RO].[mas500_app].[dbo].[vdvShipmentLine] t
       ON s.[TranID] = t.[TranID]
WHERE (([TranType] LIKE 'SH') OR ([TranType] IN ('IS','SA') AND [DistQty]=-1))
       AND t.[ItemID] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-ASY-0001','HTFA-ASY-0003','FLM1-ASY-0001R','FLM2-ASY-0001R','HTFA-ASY-0003R','HTFA-ASY-0001R')
       AND s.[ItemID] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-ASY-0001','HTFA-ASY-0003','FLM1-ASY-0001R','FLM2-ASY-0001R','HTFA-ASY-0003R','HTFA-ASY-0001R') 
GROUP BY 
	[ShipDate], 
	[TranType], 
	s.[WhseID], 
	s.[ItemID],
	[SalesTerritoryID],
	[CustID],
	[CustName],
	[CurrentCustClassID], 
	[SerialNo], 
	s.[TranID], 
	[ShipToCountryId], 
	[SalesSource]

SELECT 
	YEAR([ShipDate]) AS [Year],
	MONTH([ShipDate]) AS [Month],
	DATEPART(ww, [ShipDate]) AS [Week],
	[ShipDate],
	[ItemID],
	CASE
		WHEN [ItemID] LIKE 'FLM1-ASY-0001' THEN 'FA1.5'
		WHEN [ItemID] LIKE 'FLM1-ASY-0001R' THEN 'FA1.5R'
		WHEN [ItemID] LIKE 'FLM2-ASY-0001' THEN 'FA2.0'
		WHEN [ItemID] LIKE 'FLM2-ASY-0001R' THEN 'FA2.0R'
		WHEN [ItemID] IN ('HTFA-ASY-0001','HTFA-ASY-0003') THEN 'HTFA'
		WHEN [ItemID] IN ('HTFA-ASY-0001R','HTFA-ASY-0003R') THEN 'HTFAR'
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
		IIF ([SalesTerritoryID] IS NULL, 'Other',
			[SalesTerritoryID])))))) AS [SalesTerritory],
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
FROM #Shipments

DROP TABLE #Shipments


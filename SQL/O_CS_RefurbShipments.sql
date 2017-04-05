SET NOCOUNT ON

SELECT 
	[SerialNo],
	s.[ItemID],
	[CustID],
	[CustName],
	[ShipToCountryId],
	[ShipDate], 
	[SalesSource],
	IIF([SalesTerritoryID] IS NULL, 'Other', [SalesTerritoryID]) AS [SalesTerritoryID],
	1 AS [Record]
INTO #Shipments
FROM [SQL1-RO].[mas500_app].[dbo].[vdvSerialTransactions] s LEFT JOIN [SQL1-RO].[mas500_app].[dbo].[vdvShipmentLine] t
	 ON s.[TranID] = t.[TranID]
WHERE (([TranType] LIKE 'SH') OR ([TranType] IN ('IS','SA') AND [DistQty]=-1))
	AND t.[ItemID] IN ('FLM1-ASY-0001R','FLM2-ASY-0001R','HTFA-ASY-0003R','HTFA-ASY-0001R', 'COMP-SUB-0016R')
	AND s.[ItemID] IN ('FLM1-ASY-0001R','FLM2-ASY-0001R','HTFA-ASY-0003R','HTFA-ASY-0001R', 'COMP-SUB-0016R') 
	AND [CustID] NOT LIKE 'IDATEC'
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
		WHEN [ItemID] LIKE 'FLM1-ASY-0001R' THEN 'FA1.5R'
		WHEN [ItemID] LIKE 'FLM2-ASY-0001R' THEN 'FA2.0R'
		WHEN [ItemID] LIKE 'HTFA-ASY-0001R' THEN 'Torch Base R'
		WHEN [ItemID] LIKE 'HTFA-ASY-0003R' THEN 'Torch Module R'
		WHEN [ItemID] LIKE 'COMP-SUB-0016R' THEN 'Computer'
		ELSE 'Other'
	END AS [Product],
	[CustID],
	[CustName],
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
		WHEN [SalesSource] IN ('BFDXInst') THEN 'BFDx'
		WHEN [SalesSource] IN ('Sale') THEN 'Sale'
		WHEN [SalesSource] IN ('EXTW', 'MFGW', 'NONW', 'Loaner CSA/RSA', 'Loaner - RMA','Loaner - MTA','Loaner - Beta P') THEN 'Loaner'
		WHEN [SalesSource] IN ('EAP PermRepl', 'EXTW Perm Rep' , 'FP CapLeas PR', 'FP OpLease PR', 'Inst OpLease PR', 'Loan CSA/RSA PR', 'MFGW Perm Rep', 'NONW Perm Rep', 'OPLease/Flex Pr', 'RRA CapLeas PR', 'RRA OpLease PR', 'Sale Perm Rep', 'STRental PR', 'PermRepl', 'InstOpLease PR','Loaner RMA PR','RRA PR') THEN 'Replacements'
		WHEN [SalesSource] IN ('Loaner - EAP') THEN 'EAP'
		WHEN [SalesSource] IN ('FP OpLeas Trade', 'InstOpLease TU', 'REG Trade ADDON', 'REG Trade NOWAR', 'REG Trade WAR', 'RRA CAP TradeUp' , 'FOC Trade WAR', 'RRA Op TradeUp','FP CapLeas Trad') THEN 'Trade-Up'
		WHEN [SalesSource] IN ('FP CapLeas',  'FP OpLease', 'Inst OpLease', 'RRA Op Lease', 'STRental', 'OPLease/Flex') THEN 'Rental/Flex/Lease'
		WHEN [SalesSource] IN ('Loan CSA/RSA', 'Loaner-MTA') THEN 'Study Instruments'
		WHEN [SalesSource] IN ('Donation') THEN 'Donation'
		ELSE 'Other'
	END AS [SalesType],
	[Record]
FROM #Shipments
ORDER BY [ShipDate]

DROP TABLE #Shipments

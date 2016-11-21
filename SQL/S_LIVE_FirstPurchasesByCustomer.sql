SET NOCOUNT ON

--Instruments
SELECT
	ROW_NUMBER() OVER(PARTITION BY [CustID] ORDER BY [SalesOrderDate]) AS [OrderNumber],
	[SalesOrder], 
	[ItemID],
	UPPER([CustID]) AS [CustID],
	[CustName],
	[SalesOrderDate],
	[ShipDate],
	[SalesTerritoryID],
	[SperName], 
	[CurrentCustClassID] 
INTO #InstShip
FROM [SQL1-RO].[mas500_app].[dbo].[vdvShipmentLine] WITH(NOLOCK)
WHERE ([ItemID] LIKE 'FLM%-ASY-0001%' OR [ItemID] LIKE 'HTFA-ASY-0003')
ORDER BY [CustName], [SalesOrderDate] 

SELECT
	[CustID],
	[CustName],
	[SalesOrderDate] AS [InstrumentSale],
	[ShipDate] AS [InstrumentShip],
	[SalesTerritoryID],
	[SperName], 
	[CurrentCustClassID]
INTO #FirstInstShip
FROM #InstShip
WHERE [OrderNumber] = 1

SELECT
	[TranID], 
	[ItemID],
	UPPER([CustID]) AS [CustID],
	[CustName],
	[TranDate]
INTO #InstSale
FROM [SQL1-RO].[mas500_app].[dbo].[vdvSalesOrderLine] WITH(NOLOCK)
WHERE ([ItemID] LIKE 'FLM%-ASY-0001%' OR [ItemID] LIKE 'HTFA-ASY-0003')
ORDER BY [CustName] 

SELECT
	[TranID],
	MAX([CustClassID]) AS [CustClassID],
	MAX([PrimarySperName]) AS [SalesPerson]
INTO #SO
FROM [SQL1-RO].[mas500_app].[dbo].[vdvSalesOrder] WITH(NOLOCK)
GROUP BY [TranID] 

SELECT 
	ROW_NUMBER() OVER(PARTITION BY I.[CustID] ORDER BY [TranDate]) AS [SaleNumber],
	I.[TranID],
	I.[CustID],
	I.[CustName],
	[TranDate], 
	[SalesTerritoryID],
	[SalesPerson], 
	C.[CustClassID]
INTO #InstSaleA
FROM #InstSale I LEFT JOIN #SO S
	ON I.[TranID] = S.[TranID]
	LEFT JOIN 
	(
		SELECT 
			UPPER([CustID]) AS [CustID], 
			[CustName],
			[CustClassID],
			[SalesTerritoryID]
		FROM [SQL1-RO].[mas500_app].[dbo].[vdvCustomer] WITH(NOLOCK)
	) C
		ON I.[CustID] = C.[CustID]

SELECT
	[CustID],
	[CustName],
	[TranDate] AS [InstrumentSale],
	[SalesTerritoryID],
	[SalesPerson], 
	[CustClassID]
INTO #FirstInstSale
FROM #InstSaleA
WHERE [SaleNumber] = 1

SELECT
	ISNULL(SA.[CustID], SH.[CustID]) AS [CustID],
	ISNULL(SA.[CustName], SH.[CustName]) AS [CustName],
	ISNULL(SH.[InstrumentSale], SA.[InstrumentSale]) AS [InstrumentSale],
	[InstrumentShip],
	ISNULL(SH.[SalesTerritoryID], SA.[SalesTerritoryID]) AS [SalesTerritoryID],
	ISNULL([SperName], [SalesPerson]) AS [SalesPerson],
	ISNULL([CurrentCustClassID], [CustClassID]) AS [CustomerType]
INTO #FirstInst
FROM #FirstInstSale SA FULL OUTER JOIN #FirstInstShip SH
	ON SA.[CustID] = SH.[CustID]
ORDER BY [InstrumentSale]

--Verification kits 
SELECT
	[TranID], 
	[ItemID],
	UPPER([CustID]) AS [CustID],
	[CustName],
	[TranDate]
INTO #verKits
FROM [SQL1-RO].[mas500_app].[dbo].[vdvSalesOrderLine] WITH(NOLOCK)
WHERE [ItemID] IN 
	(
		'FLM1-ASY-0122',
		'FLM1-ASY-0124',
		'FLM1-ASY-0130',
		'FLM1-ASY-0145',
		'FLM1-ASY-0121',
		'FLM1-ASY-0123',
		'FLM1-ASY-0129',
		'FLM1-ASY-0144'
	)
ORDER BY [CustName] 

SELECT 
	[CustID],
	[CustName],
	MIN([TranDate]) AS [Verification]
INTO #FirstVer
FROM #verKits
GROUP BY [CustID], [CustName] 

--Regular pouches
SELECT
	[TranID], 
	[ItemID],
	UPPER([CustID]) AS [CustID],
	[CustName],
	[TranDate],
	[QtyOrd] 
INTO #pouch
FROM [SQL1-RO].[mas500_app].[dbo].[vdvSalesOrderLine] WITH(NOLOCK)
WHERE [ItemID] IN 
	(
		'RFIT-ASY-0001',	--30 pack
		'RFIT-ASY-0002',	--BT
		'RFIT-ASY-0104',	--6 pack
		'RFIT-ASY-0105',	--30 pack	
		'RFIT-ASY-0107',	--6 pack
		'RFIT-ASY-0109',	--6 pack
		'RFIT-ASY-0114',	--30 pack
		'RFIT-ASY-0116',	--30 pack
		'RFIT-ASY-0118',	--30 pack
		'RFIT-ASY-0119',	--6 pack
		'RFIT-ASY-0122',	--BT
		'RFIT-ASY-0124',	--30 pack
		'RFIT-ASY-0125',	--6 pack
		'RFIT-ASY-0126',	--30 pack
		'RFIT-ASY-0127'		--6 pack
	)
ORDER BY [CustName] 

SELECT 
	[CustID],
	[CustName],
	MIN([TranDate]) AS [Pouch]
INTO #FirstPouch
FROM #pouch
GROUP BY [CustID], [CustName] 

--Third pouch purchase
SELECT 
	IIF([CustID] LIKE 'AMC-%' OR [CustID] LIKE 'LAB-%', SUBSTRING([CustID],5,LEN([CustID])),
		IIF([CustID] LIKE '%-[0-9]', SUBSTRING([CustID],1,PATINDEX('%-[0-9]',[CustID])-1),[CustID])) AS [CustID],
	[TranDate],
	[QtyOrd]
INTO #pouchQty
FROM #pouch

SELECT *,
	SUM([QtyOrd]) OVER(PARTITION BY [CustID] ORDER BY [TranDate]) AS [TotalOrd]
INTO #pouchSum
FROM #pouchQty

SELECT *
INTO #pouchSum3
FROM #pouchSum
WHERE [TotalOrd] >= 3
ORDER BY [CustID], [TranDate]

SELECT 
	[CustID],
	MIN([TranDate]) AS [ThirdPouch]
INTO #ThirdPouch
FROM #pouchSum3
GROUP BY [CustID]

--Join Instrument and Verification and pouch
SELECT
	ISNULL(I.[CustID],V.[CustID]) AS [CustID],
	ISNULL(I.[CustName],V.[CustName]) AS [CustName],
	I.[SalesTerritoryID],
	I.[SalesPerson],
	I.[CustomerType],
	I.[InstrumentSale],
	I.[InstrumentShip],
	V.[Verification]
INTO #InstVer
FROM #FirstInst I FULL OUTER JOIN #FirstVer V
	ON I.[CustID] = V.[CustID] 
ORDER BY [CustName]

--Join Instrument/Verification to Pouch
SELECT
	ISNULL(I.[CustID],P.[CustID]) AS [CustID],
	ISNULL(I.[CustName], P.[CustName]) AS [CustName], 
	I.[SalesTerritoryID],
	IIF(I.[SalesTerritoryID] LIKE 'C%', 'Central',
		IIF(I.[SalesTerritoryID] LIKE 'GL%', 'Great Lakes', 
		IIF(I.[SalesTerritoryID] LIKE 'NE%', 'North East', 
		IIF(I.[SalesTerritoryID] LIKE 'SE%', 'South East', 
		IIF(I.[SalesTerritoryID] LIKE 'W%', 'West', 'Unknown'))))) AS [SalesRegion],
	ISNULL(I.[SalesPerson],'Unknown') AS [SalesPerson],
	I.[CustomerType],
	I.[InstrumentSale],
	I.[InstrumentShip],
	I.[Verification],
	P.[Pouch]
INTO #Master
FROM #InstVer I FULL OUTER JOIN #FirstPouch P
			ON I.[CustID] = P.[CustID]
ORDER BY [InstrumentSale]

--Clean up data per Carolyn's instructions
SELECT 
	A.[CustID],
	A.[CustName],
	A.[SalesTerritoryID],
	A.[SalesRegion],
	A.[SalesPerson],
	A.[CustomerType],
	A.[InstrumentSale],
	A.[InstrumentShip],
	A.[Verification],
	A.[Pouch],
	T.[ThirdPouch]
INTO #Final
FROM 
(
	SELECT 
		IIF([CustID] LIKE 'AMC-%' OR [CustID] LIKE 'LAB-%', SUBSTRING([CustID],5,LEN([CustID])),
			IIF([CustID] LIKE '%-[0-9]', SUBSTRING([CustID],1,PATINDEX('%-[0-9]',[CustID])-1),[CustID])) AS [CustID],
		[CustName],
		[SalesTerritoryID],
		[SalesRegion],
		[SalesPerson],
		[CustomerType],
		[InstrumentSale],
		[InstrumentShip],
		[Verification],
		[Pouch]
	FROM #Master
	WHERE [CustID] NOT LIKE '99-%' AND [SalesRegion] NOT LIKE 'Unknown' AND [SalesPerson] NOT LIKE 'House Account'
) A
LEFT JOIN #ThirdPouch T
	ON A.[CustID] = T.CustID
ORDER BY [CustID]

SELECT 
	ROW_NUMBER() OVER(PARTITION BY [CustID] ORDER BY [InstrumentSale]) AS [Ordered],
	[CustID],
	[CustName],
	[SalesTerritoryID],
	[SalesRegion],
	[SalesPerson],
	[CustomerType]
INTO #CustInfo
FROM #Final

SELECT
	C.[CustID],
	C.[CustName],
	C.[SalesTerritoryID],
	C.[SalesRegion],
	C.[CustomerType],
	F.[InstrumentSale],
	F.[InstrumentShip],
	F.[Verification],
	F.[Pouch],
	F.[ThirdPouch] 
FROM
(
	SELECT *
	FROM #CustInfo
	WHERE [Ordered] = 1
) C LEFT JOIN
(
	SELECT
		[CustID],
		MIN([InstrumentSale]) AS [InstrumentSale],
		MIN([InstrumentShip]) AS [InstrumentShip],
		MIN([Verification]) AS [Verification],
		MIN([Pouch]) AS [Pouch],
		MIN([ThirdPouch]) AS [ThirdPouch]
	FROM #Final
	GROUP BY [CustID]
) F
	ON C.[CustID] = F.[CustID]

DROP TABLE #InstShip, #FirstInst, #verKits, #FirstVer, #FirstPouch, #pouch, #InstVer, #InstSale, #FirstInstSale, #FirstInstShip, 
	#InstSaleA, #SO, #Master, #Final, #CustInfo, #pouchQty, #pouchSum, #pouchSum3, #ThirdPouch

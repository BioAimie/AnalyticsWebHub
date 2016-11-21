SELECT 
	ISNULL([SalesOrder], 'NoSO') AS [SalesOrder],
	[ItemID],
	[WhseID],
	[ProductType],
	ISNULL([CustID], 'IDATEC') AS [CustID],
	[CustClass], 
	ISNULL([State],'BFDx') AS [State],
	ISNULL([Country],'BFDx') AS [Country],
	[SalesSource],
	[SalesTerritoryID],
	[SOUnitPrice],
	[OrderStatus],
	[ShipDate],
	IIF([TranType] LIKE 'SH', [ItemsShipped], -1*[ItemsShipped]) AS [ItemsShipped],
	IIF([TranType] LIKE 'SH', [QtyShipped], -1*[QtyShipped]) AS [QtyShipped] 
FROM
(
	SELECT 
		ISNULL(S.[SalesOrder], I.[SalesOrder]) AS [SalesOrder],
		ISNULL(S.[ItemID], I.[ItemID]) AS [ItemID],
		ISNULL(S.[WhseID], I.[WhseID]) AS [WhseID],
		--ISNULL(S.[ItemShortDesc], I.[ItemShortDesc]) AS [ItemShortDesc],
		ISNULL(S.[ProductType], I.[ProductType]) AS [ProductType],
		ISNULL(S.[CustID], I.[CustID]) AS [CustID],
		ISNULL(S.[CurrentCustClassID], I.[CurrentCustClassID]) AS [CustClass],
		--ISNULL(S.[CustName], I.[CustName]) AS [CustName],
		ISNULL(S.[ShipToAddrStateID], I.[ShipToAddrStateID]) AS [State],
		ISNULL(S.[ShipToCountryID], I.[ShipToCountryID]) AS [Country],
		--ISNULL(S.[WhseDesc], I.[WhseDesc]) AS [WhseDesc],
		ISNULL(S.[SalesSource], I.[SalesSource]) AS [SalesSource],
		ISNULL(S.[SalesTerritoryID], I.[SalesTerritoryID]) AS [SalesTerritoryID],
		ISNULL(S.[SalesOrderUnitPrice], I.[SalesOrderUnitPrice]) AS [SOUnitPrice],
		ISNULL(S.[OrderStatus], I.[OrderStatus]) AS [OrderStatus],
		ISNULL(S.[ShipDate], I.[ShipDate]) AS [ShipDate],
		ISNULL(S.[QtyShipped], I.[QtyShipped]) AS [ItemsShipped],
		ISNULL(S.[ItemQty], I.[ItemQty]) AS [QtyShipped],
		ISNULL(S.[TranID], I.[TranID]) AS [TranID],
		ISNULL(S.[TranType], I.[TranType]) AS [TranType]
	FROM 
	(
		SELECT 
			--[ItemID],
			--[ItemShortDesc],
			[SalesOrder],
			[ItemID],
			[WhseID],
			--[Description] AS [WhseDesc],
			IIF([ItemID] IN ('RFIT-ASY-0001','RFIT-ASY-0096','RFIT-ASY-0105','RFIT-ASY-0107','RFIT-ASY-0120','RFIT-ASY-0124','RFIT-ASY-0125','NI-RFIT-ASY-0001','NI-RFIT-ASY-0096','NI-RFIT-ASY-0105','NI-RFIT-ASY-0107',
							 'NI-RFIT-ASY-0124','NI-RFIT-ASY-0125','NI-RFIT-ASY-0093','RFIT-ASY-0115'), 'RP',
				IIF([ItemID] IN ('RFIT-ASY-0118','RFIT-ASY-0119','NI-RFIT-ASY-0118','NI-RFIT-ASY-0119'), 'ME', 
				IIF([ItemID] IN ('RFIT-ASY-0094','RFIT-ASY-0122','RFIT-ASY-0002','NI-RFIT-ASY-0002','NI-RFIT-ASY-0094'), 'BT',
				IIF([ItemID] IN ('RFIT-ASY-0104','RFIT-ASY-0116','RFIT-ASY-0008','NI-RFIT-ASY-0104','NI-RFIT-ASY-0116','NI-RFIT-ASY-0008'), 'GI',
				IIF([ItemID] IN ('RFIT-ASY-0109','RFIT-ASY-0114','RFIT-ASY-0126','RFIT-ASY-0127','RFIT-ASY-0007','NI-RFIT-ASY-0109','NI-RFIT-ASY-0114','NI-RFIT-ASY-0126','NI-RFIT-ASY-0127','NI-RFIT-ASY-0007'), 'BCID',
				IIF([ItemID] LIKE 'FLM1-ASY-0001%', 'FA1.5',
				IIF([ItemID] LIKE 'FLM2-ASY-0001%', 'FA2.0',
				IIF([ItemID] LIKE 'HTFA-%', 'Torch','Other')))))))) AS [ProductType],
			[CustID],
			[CurrentCustClassID],
			--[CustName],
			[ShipToAddrStateID],
			[ShipToCountryID],
			[SalesSource],
			--[SalesSourceDesc],
			[SalesTerritoryID],
			--[FreightAmt],
			[SalesOrderUnitPrice],
			--[InvoiceUnitPrice],
			--[SalesOrderExtAmt],
			--[InvoiceExtAmt],
			--[InvoiceTradeDiscAmt],
			[OrderStatus],
			--[SalesOrderDate],
		--[RequestDate],
		--[PromiseDate],
			[ShipDate],
			--[SalesOrderQty],
			[QtyShipped],
			IIF([ItemID] IN ('RFIT-ASY-0001','RFIT-ASY-0018','RFIT-ASY-0105','RFIT-ASY-0114','RFIT-ASY-0116','RFIT-ASY-0118','RFIT-ASY-0120','RFIT-ASY-0124','RFIT-ASY-0126','RFIT-ASY-0002','RFIT-ASY-0007',
							 'RFIT-ASY-0008','RFIT-ASY-0015','RFIT-ASY-0092','RFIT-ASY-0097','RFIT-ASY-0098','RFIT-ASY-0100','RFIT-ASY-0108','RFIT-ASY-0111','RFIT-ASY-0112',
							 'RFIT-ASY-0118','NI-RFIT-ASY-0001','NI-RFIT-ASY-0002',	'NI-RFIT-ASY-0105',	'NI-RFIT-ASY-0114','NI-RFIT-ASY-0116','NI-RFIT-ASY-0118','NI-RFIT-ASY-0124','NI-RFIT-ASY-0126','NI-RFIT-ASY-0127'), 
				[QtyShipped]*30, 
				IIF([ItemID] IN ('RFIT-ASY-0090','RFIT-ASY-0091','RFIT-ASY-0098','FLM1-ASY-0001','FLM1-ASY-0001R','FLM2-ASY-0001','FLM2-ASY-0001R'), [QtyShipped], [QtyShipped]*6)) AS [ItemQty],
			[TranID],
			[TranType]
			/*,
		[OrderSalesPerson],
		[OrderSperID],
		[OrderCustClassID],
		[OrderCustClassName],
		[CurrentCustClassID],
		[SperID],
		IIF([ItemID] IN ('RFIT-ASY-0001','RFIT-ASY-0094','RFIT-ASY-0096','RFIT-ASY-0104','RFIT-ASY-0105','RFIT-ASY-0107','RFIT-ASY-0109','RFIT-ASY-0114','RFIT-ASY-0116','RFIT-ASY-0118','RFIT-ASY-0119',
						 'RFIT-ASY-0120','RFIT-ASY-0122','RFIT-ASY-0124','RFIT-ASY-0125','RFIT-ASY-0126','RFIT-ASY-0127', 
						 'NI-RFIT-ASY-0001','NI-RFIT-ASY-0096','NI-RFIT-ASY-0096','NI-RFIT-ASY-0104','NI-RFIT-ASY-0105','NI-RFIT-ASY-0107','NI-RFIT-ASY-0109','NI-RFIT-ASY-0114','NI-RFIT-ASY-0116',
						 'NI-RFIT-ASY-0118','NI-RFIT-ASY-0119','NI-RFIT-ASY-0124','NI-RFIT-ASY-0125','NI-RFIT-ASY-0126','NI-RFIT-ASY-0127'), 'IVD',
			IIF([ItemID] IN ('RFIT-ASY-0002','RFIT-ASY-0007','RFIT-ASY-0008','RFIT-ASY-0015','NI-RFIT-ASY-0002',
							 'NI-RFIT-ASY-0007','NI-RFIT-ASY-0008','NI-RFIT-ASY-0093','NI-RFIT-ASY-0094' ), 'RUO', 'Internal')) AS [ProductClass],
		IIF([ItemID] IN ('RFIT-ASY-0018','RFIT-ASY-0019','RFIT-ASY-0094','RFIT-ASY-0104','RFIT-ASY-0105','RFIT-ASY-0107','RFIT-ASY-0109','RFIT-ASY-0114','RFIT-ASY-0116','RFIT-ASY-0118','RFIT-ASY-0119',
						 'RFIT-ASY-0122','RFIT-ASY-0124','RFIT-ASY-0125','RFIT-ASY-0126','RFIT-ASY-0127') AND [SalesTerritoryID] NOT IN ('House','International','Defense'), 1, 0) AS [IncludeInSales],
		IIF([ItemID] LIKE 'NI-RFIT-ASY-%', 1, 0) AS [NonInventory]
		*/
		FROM [SQL1-RO].[mas500_app].[dbo].[vdvShipmentLine] WITH(NOLOCK)
		WHERE [ItemID] IN
		(
			'RFIT-ASY-0001',	--IVD Respitory Panel v1.6, FinishedGood (30)	MOST RECENT MANF DATE = 2013-12-18	** expired part
			'RFIT-ASY-0094',	--BioThreat Panel Alpha, FinishedGood (6)		MOST RECENT MANF DATE = 2015-09-18	** not included in sales
			'RFIT-ASY-0096',	--CE IVD Respiratory Panel, FinishedGood (6)    MOST RECENT MANF DATE = 2013-04-30	** not included in sales
			'RFIT-ASY-0104',	--IVD GI Panel, FinishedGood (6)				MOST RECENT MANF DATE = 2015-10-12	** included in sales
			'RFIT-ASY-0105',	--IVD Respiratory Panel, FinishedGood (30)		MOST RECENT MANF DATE = 2015-10-16	** included in sales
			'RFIT-ASY-0107',	--IVD Respiratory Panel, FinishedGood (6)		MOST RECENT MANF DATE = 2015-08-24	** included in sales
			'RFIT-ASY-0109',	--IVD BCID Panel, FinishedGood (6)				MOST RECENT MANF DATE = 2015-10-19	** included in sales
			'RFIT-ASY-0114',	--IVD BCID Panel, FinishedGood (30)				MOST RECENT MANF DATE = 2015-10-15	** included in sales
			'RFIT-ASY-0116',	--IVD GI Panel, FinishedGood (30)				MOST RECENT MANF DATE = 2015-10-14	** included in sales
			'RFIT-ASY-0118',	--MEP, FinishedGood (30)						MOST RECENT MANF DATE = 2015-10-09	** included in sales
			'RFIT-ASY-0119',	--MEP, FinishedGood (6)							MOST RECENT SHIP DATE = 2015-11-16	** included in sales
			'RFIT-ASY-0120',	--EZ Respiratory Panel v1.7, FinishedGood (30)	Looks like a mistake, only four from 2014-10-31 to 2015-05-22 **no sales
			'RFIT-ASY-0122',	--BioThreat Panel E, FinishedGood (6)			MOST RECENT MANF DATE = 2015-10-14	** included in sales
			'RFIT-ASY-0124',	--IVD Respiratory Panel FAIV, FinishedGood (30)	MOST RECENT MANF DATE = 2015-10-19	** included in sales
			'RFIT-ASY-0125',	--IVD Respiratory Panel FAIV, FinishedGood (6)	MOST RECENT MANF DATE = 2015-09-22	** included in sales
			'RFIT-ASY-0126',	--IVD BCID Panel FAIV, FinishedGood (30)		MOST RECENT MANF DATE = 2015-10-06	** included in sales
			'RFIT-ASY-0127',	--IVD BCID Panel FAIV, FinishedGood (6)			MOST RECENT MANF DATE = 2015-09-30	** included in sales
			--'RFIT-ASY-0002',	--RUO BioThreat Panel, SubAssembly (30)			MOST RECENT MANF DATE = 2014-11-22	
			--'RFIT-ASY-0007',	--RUO BCID Panel, FinishedGood (30)				MOST RECENT MANF DATE = 2013-05-13
			--'RFIT-ASY-0008',	--RUO GI Panel, FinishedGood (30)				MOST RECENT MANF DATE = 2014-04-30
			--'RFIT-ASY-0115',	--RP v1.7 RUO (30)                              NO DATA
			--'RFIT-ASY-0090',	--Basic Calc, SubAssembly ******** (1)
			--'RFIT-ASY-0091',	--IQC, FinishedGood ************** (1)
			--'RFIT-ASY-0092',	--Basic Calc R&D, FinishedGood *** (?)
			--'RFIT-ASY-0097',	--R&D Chemisty, SubAssembly ****** (?)
			--'RFIT-ASY-0098',	--Sample Prep, SubAssembly ******* (1)
			'RFIT-ASY-0100',	--Respiratory R&D, FinishedGood ** (?)
			--'RFIT-ASY-0108',	--Molded Parts, FinishedGood ***** (?)
			--'RFIT-ASY-0111',	--IQC, FinishedGood ************** (30)
			--'RFIT-ASY-0112',	--Basic Calc, FinishedGood ******* (30) Looks like a mistake, only one from 2014-01-21
			'NI-RFIT-ASY-0001',	--FA IVD Respiratory Panel Pouch Kit (30)		NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0096',	--FilmArray RP CE IVD 6 Pouch Kit (6)			NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0104',	--KIT, GI PANEL, IVD 6 TESTS (6)				NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0105',	--FA Respiratory Panel v1.7 30 Pouch Kit (30)	NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0107',	--FilmArray Respiratory Panel,  6 pouches (6)	NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0109',	--FA BCID Panel IVD, 6 Pouch Kit (6)			NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0114',	--CE IVD FA BCID 30 Pack Kit (30)				NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0116',	--KIT, GI PANEL, IVD, 30 TESTS (30)				NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0118',	--MEP 30 pack configuration (30)				NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0119',	--MEP 6 pack configuration (6)					NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0124',	--FAIV Kit, Respiratory Panel, IVD 30 Test (3)	NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0125',	--FAIV Kit, Respiratory Panel, IVD 6 Tests (6)	NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0126',	--FAIV Kit, BCID Panel, IVD, 30 Tests (30)		NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0127', --FAIV Kit, BCID Panel, IVD, 6 Tests (6)		NON-INVENTORY						** not included in sales
			'FLM1-ASY-0001',
			'FLM2-ASY-0001',
			'FLM1-ASY-0001R',
			'FLM2-ASY-0001R',
			'HTFA-ASY-0003'		--Torch (HTFA) Instrument
			--'NI-RFIT-ASY-0002',	--BT RUO Panel 30 Pouch Kit (30)				NON-INVENTORY						** not included in sales
			--'NI-RFIT-ASY-0007',	--FA RUO BCID Pouch Kit (30)					NON-INVENTORY						** not included in sales
			--'NI-RFIT-ASY-0008',	--RUO Gastrointestinal Panel v2.0 Kit (30)		NON-INVENTORY						** not included in sales
			--'NI-RFIT-ASY-0093',	--FA RUO Respiratory Panel Pouch Kit (30)		NON-INVENTORY						** not included in sales
			--'NI-RFIT-ASY-0094'	--BT RUO 6 Pouch Kit (6)						NON-INVENTORY						** not included in sales 
		) 
	) S FULL OUTER JOIN
	(
		SELECT 
			NULL AS [SalesOrder],
			[ItemID],
			[WhseID],
			--[ItemDesc] AS [ItemShortDesc],
			IIF([ItemID] IN ('RFIT-ASY-0001','RFIT-ASY-0096','RFIT-ASY-0105','RFIT-ASY-0107','RFIT-ASY-0120','RFIT-ASY-0124','RFIT-ASY-0125','NI-RFIT-ASY-0001','NI-RFIT-ASY-0096','NI-RFIT-ASY-0105','NI-RFIT-ASY-0107',
							 'NI-RFIT-ASY-0124','NI-RFIT-ASY-0125','NI-RFIT-ASY-0093','RFIT-ASY-0115'), 'RP',
				IIF([ItemID] IN ('RFIT-ASY-0118','RFIT-ASY-0119','NI-RFIT-ASY-0118','NI-RFIT-ASY-0119'), 'ME', 
				IIF([ItemID] IN ('RFIT-ASY-0094','RFIT-ASY-0122','RFIT-ASY-0002','NI-RFIT-ASY-0002','NI-RFIT-ASY-0094'), 'BT',
				IIF([ItemID] IN ('RFIT-ASY-0104','RFIT-ASY-0116','RFIT-ASY-0008','NI-RFIT-ASY-0104','NI-RFIT-ASY-0116','NI-RFIT-ASY-0008'), 'GI',
				IIF([ItemID] IN ('RFIT-ASY-0109','RFIT-ASY-0114','RFIT-ASY-0126','RFIT-ASY-0127','RFIT-ASY-0007','NI-RFIT-ASY-0109','NI-RFIT-ASY-0114','NI-RFIT-ASY-0126','NI-RFIT-ASY-0127','NI-RFIT-ASY-0007'), 'BCID',
				IIF([ItemID] LIKE 'FLM1-ASY-0001%', 'FA1.5',
				IIF([ItemID] LIKE 'FLM2-ASY-0001%', 'FA2.0',
				IIF([ItemID] LIKE 'HTFA-%', 'Torch','Other')))))))) AS [ProductType],
			NULL AS [CustID],
			NULL AS [CurrentCustClassID],
			NULL AS [ShipToAddrStateID],
			NULL AS [ShipToCountryID],
			NULL AS [SalesSource],
			NULL AS [SalesTerritoryID],
			NULL AS [SalesOrderUnitPrice],
			NULL AS [OrderStatus],
			--NULL AS [CustName],
		--[WhseDesc],
			[TranDate] AS [ShipDate],
			[TranQty] AS [QtyShipped],
			IIF([ItemID] IN ('RFIT-ASY-0001','RFIT-ASY-0018','RFIT-ASY-0105','RFIT-ASY-0114','RFIT-ASY-0116','RFIT-ASY-0118','RFIT-ASY-0120','RFIT-ASY-0124','RFIT-ASY-0126','RFIT-ASY-0002','RFIT-ASY-0007',
							 'RFIT-ASY-0008','RFIT-ASY-0015','RFIT-ASY-0092','RFIT-ASY-0097','RFIT-ASY-0098','RFIT-ASY-0100','RFIT-ASY-0108','RFIT-ASY-0111','RFIT-ASY-0112',
							 'RFIT-ASY-0118','NI-RFIT-ASY-0001','NI-RFIT-ASY-0002',	'NI-RFIT-ASY-0105',	'NI-RFIT-ASY-0114','NI-RFIT-ASY-0116','NI-RFIT-ASY-0118','NI-RFIT-ASY-0124','NI-RFIT-ASY-0126','NI-RFIT-ASY-0127'), 
				[TranQty]*30, 
				IIF([ItemID] IN ('RFIT-ASY-0090','RFIT-ASY-0091','RFIT-ASY-0098','FLM1-ASY-0001','FLM1-ASY-0001R','FLM2-ASY-0001','FLM2-ASY-0001R'), [TranQty], [TranQty]*6)) AS [ItemQty],
			[TranID],
			[TranType]
												/*
		IIF([ItemID] IN ('RFIT-ASY-0001','RFIT-ASY-0094','RFIT-ASY-0096','RFIT-ASY-0104','RFIT-ASY-0105','RFIT-ASY-0107','RFIT-ASY-0109','RFIT-ASY-0114','RFIT-ASY-0116','RFIT-ASY-0118','RFIT-ASY-0119',
						 'RFIT-ASY-0120','RFIT-ASY-0122','RFIT-ASY-0124','RFIT-ASY-0125','RFIT-ASY-0126','RFIT-ASY-0127', 
						 'NI-RFIT-ASY-0001','NI-RFIT-ASY-0096','NI-RFIT-ASY-0096','NI-RFIT-ASY-0104','NI-RFIT-ASY-0105','NI-RFIT-ASY-0107','NI-RFIT-ASY-0109','NI-RFIT-ASY-0114','NI-RFIT-ASY-0116',
						 'NI-RFIT-ASY-0118','NI-RFIT-ASY-0119','NI-RFIT-ASY-0124','NI-RFIT-ASY-0125','NI-RFIT-ASY-0126','NI-RFIT-ASY-0127'), 'IVD',
			IIF([ItemID] IN ('RFIT-ASY-0002','RFIT-ASY-0007','RFIT-ASY-0008','RFIT-ASY-0015','NI-RFIT-ASY-0002',
							 'NI-RFIT-ASY-0007','NI-RFIT-ASY-0008','NI-RFIT-ASY-0093','NI-RFIT-ASY-0094' ), 'RUO', 'Internal')) AS [ProductClass],
		0 AS [IncludeInSales],
		0 AS [NonInventory]
		*/ 
		FROM [SQL1-RO].[mas500_app].[dbo].[vdvInventoryTran] WITH(NOLOCK)
		WHERE [ItemID] IN
		(
			'RFIT-ASY-0001',	--IVD Respitory Panel v1.6, FinishedGood (30)	MOST RECENT MANF DATE = 2013-12-18	** expired part
			'RFIT-ASY-0094',	--BioThreat Panel Alpha, FinishedGood (6)		MOST RECENT MANF DATE = 2015-09-18	** not included in sales
			'RFIT-ASY-0096',	--CE IVD Respiratory Panel, FinishedGood (6)    MOST RECENT MANF DATE = 2013-04-30	** not included in sales
			'RFIT-ASY-0104',	--IVD GI Panel, FinishedGood (6)				MOST RECENT MANF DATE = 2015-10-12	** included in sales
			'RFIT-ASY-0105',	--IVD Respiratory Panel, FinishedGood (30)		MOST RECENT MANF DATE = 2015-10-16	** included in sales
			'RFIT-ASY-0107',	--IVD Respiratory Panel, FinishedGood (6)		MOST RECENT MANF DATE = 2015-08-24	** included in sales
			'RFIT-ASY-0109',	--IVD BCID Panel, FinishedGood (6)				MOST RECENT MANF DATE = 2015-10-19	** included in sales
			'RFIT-ASY-0114',	--IVD BCID Panel, FinishedGood (30)				MOST RECENT MANF DATE = 2015-10-15	** included in sales
			'RFIT-ASY-0116',	--IVD GI Panel, FinishedGood (30)				MOST RECENT MANF DATE = 2015-10-14	** included in sales
			'RFIT-ASY-0118',	--MEP, FinishedGood (30)						MOST RECENT MANF DATE = 2015-10-09	** included in sales
			'RFIT-ASY-0119',	--MEP, FinishedGood (6)							MOST RECENT SHIP DATE = 2015-11-16	** included in sales
			'RFIT-ASY-0120',	--EZ Respiratory Panel v1.7, FinishedGood (30)	Looks like a mistake, only four from 2014-10-31 to 2015-05-22 **no sales
			'RFIT-ASY-0122',	--BioThreat Panel E, FinishedGood (6)			MOST RECENT MANF DATE = 2015-10-14	** included in sales
			'RFIT-ASY-0124',	--IVD Respiratory Panel FAIV, FinishedGood (30)	MOST RECENT MANF DATE = 2015-10-19	** included in sales
			'RFIT-ASY-0125',	--IVD Respiratory Panel FAIV, FinishedGood (6)	MOST RECENT MANF DATE = 2015-09-22	** included in sales
			'RFIT-ASY-0126',	--IVD BCID Panel FAIV, FinishedGood (30)		MOST RECENT MANF DATE = 2015-10-06	** included in sales
			'RFIT-ASY-0127',	--IVD BCID Panel FAIV, FinishedGood (6)			MOST RECENT MANF DATE = 2015-09-30	** included in sales
			--'RFIT-ASY-0002',	--RUO BioThreat Panel, SubAssembly (30)			MOST RECENT MANF DATE = 2014-11-22	
			--'RFIT-ASY-0007',	--RUO BCID Panel, FinishedGood (30)				MOST RECENT MANF DATE = 2013-05-13
			--'RFIT-ASY-0008',	--RUO GI Panel, FinishedGood (30)				MOST RECENT MANF DATE = 2014-04-30
			--'RFIT-ASY-0115',	--RP v1.7 RUO (30)                              NO DATA
			--'RFIT-ASY-0090',	--Basic Calc, SubAssembly ******** (1)
			--'RFIT-ASY-0091',	--IQC, FinishedGood ************** (1)
			--'RFIT-ASY-0092',	--Basic Calc R&D, FinishedGood *** (?)
			--'RFIT-ASY-0097',	--R&D Chemisty, SubAssembly ****** (?)
			--'RFIT-ASY-0098',	--Sample Prep, SubAssembly ******* (1)
			'RFIT-ASY-0100',	--Respiratory R&D, FinishedGood ** (?)
			--'RFIT-ASY-0108',	--Molded Parts, FinishedGood ***** (?)
			--'RFIT-ASY-0111',	--IQC, FinishedGood ************** (30)
			--'RFIT-ASY-0112',	--Basic Calc, FinishedGood ******* (30) Looks like a mistake, only one from 2014-01-21
			'NI-RFIT-ASY-0001',	--FA IVD Respiratory Panel Pouch Kit (30)		NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0096',	--FilmArray RP CE IVD 6 Pouch Kit (6)			NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0104',	--KIT, GI PANEL, IVD 6 TESTS (6)				NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0105',	--FA Respiratory Panel v1.7 30 Pouch Kit (30)	NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0107',	--FilmArray Respiratory Panel,  6 pouches (6)	NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0109',	--FA BCID Panel IVD, 6 Pouch Kit (6)			NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0114',	--CE IVD FA BCID 30 Pack Kit (30)				NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0116',	--KIT, GI PANEL, IVD, 30 TESTS (30)				NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0118',	--MEP 30 pack configuration (30)				NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0119',	--MEP 6 pack configuration (6)					NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0124',	--FAIV Kit, Respiratory Panel, IVD 30 Test (3)	NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0125',	--FAIV Kit, Respiratory Panel, IVD 6 Tests (6)	NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0126',	--FAIV Kit, BCID Panel, IVD, 30 Tests (30)		NON-INVENTORY						** not included in sales
			'NI-RFIT-ASY-0127', --FAIV Kit, BCID Panel, IVD, 6 Tests (6)		NON-INVENTORY						** not included in sales
			'FLM1-ASY-0001',
			'FLM2-ASY-0001',
			'FLM1-ASY-0001R',
			'FLM2-ASY-0001R',
			'HTFA-ASY-0003'		--Torch (HTFA) Instrument
			--'NI-RFIT-ASY-0002',	--BT RUO Panel 30 Pouch Kit (30)				NON-INVENTORY						** not included in sales
			--'NI-RFIT-ASY-0007',	--FA RUO BCID Pouch Kit (30)					NON-INVENTORY						** not included in sales
			--'NI-RFIT-ASY-0008',	--RUO Gastrointestinal Panel v2.0 Kit (30)		NON-INVENTORY						** not included in sales
			--'NI-RFIT-ASY-0093',	--FA RUO Respiratory Panel Pouch Kit (30)		NON-INVENTORY						** not included in sales
			--'NI-RFIT-ASY-0094'	--BT RUO 6 Pouch Kit (6)						NON-INVENTORY						** not included in sales 
		) AND [WhseID] IN ('STOCK','RFSTK','STOCK2','FFSTK') AND [TranType] IN ('IS','SA')
	) I
		ON S.[TranID] = I.[TranID]
	WHERE S.[ShipDate] > GETDATE() - 90 OR I.[ShipDate] > GETDATE() - 90
	--WHERE (S.[ShipDate] >= '2015-01-01' OR I.[ShipDate] >= '2015-01-01') AND
		--(S.[ShipDate] <= '2015-01-31' OR I.[ShipDate] <= '2015-01-31')
) D

ORDER BY [ShipDate], [SalesOrder]
USE [PMS1]
GO
IF OBJECT_ID('dbo.vPouchShipments','V') IS NOT NULL
DROP VIEW [dbo].[vPouchShipments]
USE [PMS1]
GO
CREATE VIEW [dbo].[vPouchShipments]
AS
SELECT
	[ItemID],
	[ItemShortDesc],
	IIF([ItemID] IN ('RFIT-ASY-0001','RFIT-ASY-0096','RFIT-ASY-0105','RFIT-ASY-0107','RFIT-ASY-0120','RFIT-ASY-0124','RFIT-ASY-0125','NI-RFIT-ASY-0001','NI-RFIT-ASY-0096','NI-RFIT-ASY-0105','NI-RFIT-ASY-0107',
					 'NI-RFIT-ASY-0124','NI-RFIT-ASY-0125','NI-RFIT-ASY-0093','RFIT-ASY-0115','RFIT-ASY-0129','RFIT-ASY-0130','RFIT-ASY-0136','RFIT-ASY-0137'), 'RP',
		IIF([ItemID] IN ('RFIT-ASY-0118','RFIT-ASY-0119','NI-RFIT-ASY-0018','NI-RFIT-ASY-0019'), 'ME', 
		IIF([ItemID] IN ('RFIT-ASY-0094','RFIT-ASY-0122','RFIT-ASY-0002','NI-RFIT-ASY-0002','NI-RFIT-ASY-0094'), 'BT',
		IIF([ItemID] IN ('RFIT-ASY-0104','RFIT-ASY-0116','RFIT-ASY-0008','NI-RFIT-ASY-0104','NI-RFIT-ASY-0116','NI-RFIT-ASY-0008'), 'GI',
		IIF([ItemID] IN ('RFIT-ASY-0109','RFIT-ASY-0114','RFIT-ASY-0126','RFIT-ASY-0127','RFIT-ASY-0007','NI-RFIT-ASY-0109','NI-RFIT-ASY-0114','NI-RFIT-ASY-0126','NI-RFIT-ASY-0127','NI-RFIT-ASY-0007'), 
			'BCID','Other'))))) AS [Panel],
	[SchdShipDate],
	[ShipLineNo],
	[CustID],
	[CustName],
	[WhseID],
	[Description] AS [WhseDesc],
	[ShipDate],
	[QtyShipped] AS [Qty],
	IIF([ItemID] IN ('RFIT-ASY-0001','RFIT-ASY-0018','RFIT-ASY-0105','RFIT-ASY-0114','RFIT-ASY-0116','RFIT-ASY-0118','RFIT-ASY-0120','RFIT-ASY-0124','RFIT-ASY-0126','RFIT-ASY-0002','RFIT-ASY-0007',
						 'RFIT-ASY-0008','RFIT-ASY-0015','RFIT-ASY-0092','RFIT-ASY-0097','RFIT-ASY-0098','RFIT-ASY-0100','RFIT-ASY-0108','RFIT-ASY-0111','RFIT-ASY-0112','RFIT-ASY-0129','RFIT-ASY-0136',
						 'RFIT-ASY-0118','NI-RFIT-ASY-0001','NI-RFIT-ASY-0002',	'NI-RFIT-ASY-0105',	'NI-RFIT-ASY-0114','NI-RFIT-ASY-0116','NI-RFIT-ASY-0118','NI-RFIT-ASY-0124','NI-RFIT-ASY-0126','NI-RFIT-ASY-0127'), 
			[QtyShipped]*30, 
			IIF([ItemID] IN ('RFIT-ASY-0090','RFIT-ASY-0091','RFIT-ASY-0098'), [QtyShipped], [QtyShipped]*6)) AS [QtyShipped],
	[SalesSource],
	[SalesTerritoryID],
	[TranID],
	[SalesOrder]
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
	'RFIT-ASY-0118',	--MEP, FinishedGood (30)						MOST RECENT MANF DATE = 2015-10-09	** no sales (not sure what this part number is)
	'RFIT-ASY-0119',	--MEP, FinishedGood (6)							MOST RECENT MANF DATE = 2015-10-09	** no sales (not sure what this part number is)
	'RFIT-ASY-0120',	--EZ Respiratory Panel v1.7, FinishedGood (30)	Looks like a mistake, only four from 2014-10-31 to 2015-05-22 **no sales
	'RFIT-ASY-0122',	--BioThreat Panel E, FinishedGood (6)			MOST RECENT MANF DATE = 2015-10-14	** included in sales
	'RFIT-ASY-0124',	--IVD Respiratory Panel FAIV, FinishedGood (30)	MOST RECENT MANF DATE = 2015-10-19	** included in sales
	'RFIT-ASY-0125',	--IVD Respiratory Panel FAIV, FinishedGood (6)	MOST RECENT MANF DATE = 2015-09-22	** included in sales
	'RFIT-ASY-0126',	--IVD BCID Panel FAIV, FinishedGood (30)		MOST RECENT MANF DATE = 2015-10-06	** included in sales
	'RFIT-ASY-0127',	--IVD BCID Panel FAIV, FinishedGood (6)			MOST RECENT MANF DATE = 2015-09-30	** included in sales
	'RFIT-ASY-0129',	--IVD RP2, FinishedGood (30)
	'RFIT-ASY-0130',	--IVD RP2, FinishedGood (6)
	'RFIT-ASY-0136',	--IVD RP2plus, FinishedGood (30)	
	'RFIT-ASY-0137',	--IVD RP2plus, FinishedGood (6)	
	/*
	'RFIT-ASY-0002',	--RUO BioThreat Panel, SubAssembly (30)			MOST RECENT MANF DATE = 2014-11-22	
	'RFIT-ASY-0007',	--RUO BCID Panel, FinishedGood (30)				MOST RECENT MANF DATE = 2013-05-13
	'RFIT-ASY-0008',	--RUO GI Panel, FinishedGood (30)				MOST RECENT MANF DATE = 2014-04-30
	'RFIT-ASY-0115',	--RP v1.7 RUO (30)                              NO DATA
	'RFIT-ASY-0090',	--IQC, FinishedGood ************** (?)
	'RFIT-ASY-0091',	--Basic Calc, SubAssembly ******** (?)	
	'RFIT-ASY-0092',	--Basic Calc R&D, FinishedGood *** (?)
	'RFIT-ASY-0097',	--R&D Chemisty, SubAssembly ****** (?)
	'RFIT-ASY-0098',	--Sample Prep, SubAssembly ******* (?)
	'RFIT-ASY-0100',	--Respiratory R&D, FinishedGood ** (?)
	'RFIT-ASY-0108',	--Molded Parts, FinishedGood ***** (?)
	'RFIT-ASY-0111',	--IQC, FinishedGood ************** (30)
	'RFIT-ASY-0112'		--Basic Calc, FinishedGood ******* (30) Looks like a mistake, only one from 2014-01-21
	*/
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
	'NI-RFIT-ASY-0127'/*,--FAIV Kit, BCID Panel, IVD, 6 Tests (6)		NON-INVENTORY						** not included in sales
	'NI-RFIT-ASY-0002',	--BT RUO Panel 30 Pouch Kit (30)				NON-INVENTORY						** not included in sales
	'NI-RFIT-ASY-0007',	--FA RUO BCID Pouch Kit (30)					NON-INVENTORY						** not included in sales
	'NI-RFIT-ASY-0008',	--RUO Gastrointestinal Panel v2.0 Kit (30)		NON-INVENTORY						** not included in sales
	'NI-RFIT-ASY-0093',	--FA RUO Respiratory Panel Pouch Kit (30)		NON-INVENTORY						** not included in sales
	'NI-RFIT-ASY-0094',	--BT RUO 6 Pouch Kit (6)						NON-INVENTORY						** not included in sales */
)
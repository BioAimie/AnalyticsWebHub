USE PMS1
GO

IF OBJECT_ID('[dbo].[bInstrumentShipment]') IS NOT NULL
DROP VIEW [dbo].[bInstrumentShipment]
GO

CREATE VIEW [dbo].[bInstrumentShipment] AS
SELECT 
	*,
	ROW_NUMBER() OVER(PARTITION BY [NormalSerial] ORDER BY [ShipDate]) AS [ShipNo]
FROM (
	SELECT
		UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(SER.[SerialNo], ' ', ''), '_', ''), '.', ''), 'KTM', 'TM'), 'R', ''), '2FA', 'FA')) AS [NormalSerial],
		UPPER(REPLACE(REPLACE(REPLACE(REPLACE(SER.[SerialNo], ' ', ''), '_', ''), '.', ''), 'KTM', 'TM')) AS [SerialNo],
		I.[ItemID],
		CAST(SL.[ShipDate] AS DATE) AS [ShipDate],
		C.[CustId],
		CL.[CustClassName],
		IIF(SS.[SalesSourceID] LIKE '%loan%' OR SOL.[ExtCmnt] LIKE '%loan%' OR SO.[TranCmnt] LIKE '%loan%', 1, 0) AS [Loaner],
		V.[Refurb],
		V.[Version]
	FROM [RO_MAS].[mas500_app].[dbo].[tsoShipLine] SL
	INNER JOIN [RO_MAS].[mas500_app].[dbo].[tsoPackageContent] PC ON PC.[ShipLineKey] = SL.[ShipLineKey]
	INNER JOIN [RO_MAS].[mas500_app].[dbo].[timInvtSerial] SER ON SER.[InvtSerialKey] = PC.[InvtSerialKey]
	INNER JOIN [RO_MAS].[mas500_app].[dbo].[timItem] I ON I.[ItemKey] = SER.[ItemKey]
	INNER JOIN [RO_MAS].[mas500_app].[dbo].[tsoSOLine] SOL on SOL.[SOLineKey] = SL.[SOLineKey]
	INNER JOIN [RO_MAS].[mas500_app].[dbo].[tsoSalesOrder] SO on SO.[SOKey] = SOL.[SOKey]
	INNER JOIN [RO_MAS].[mas500_app].[dbo].[tarCustomer] C on C.[CustKey] = SO.[CustKey]
	INNER JOIN [RO_MAS].[mas500_app].[dbo].[tarCustClass] CL on CL.[CustClassKey] = C.[CustClassKey]
	LEFT JOIN [RO_MAS].[mas500_app].[dbo].[tsoSalesSource] SS on SS.[SalesSourceKey] = SO.[SalesSourceKey]
	INNER JOIN [PMS1].[dbo].[bInstrumentVersion] V ON V.[PartNumber] = I.[ItemID]
) Q
GO


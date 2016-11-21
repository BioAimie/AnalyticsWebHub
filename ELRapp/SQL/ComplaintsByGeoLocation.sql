SET NOCOUNT ON

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[PropertyName],
	[RecordedValue]
INTO #cmplt
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] LIKE 'COMPLAINT' AND [PropertyName] IN ('Customer Id','Customer Name','Customer Contact','Contact Telephone Number','Contact Fax Number','Contact Email','Customer Address')

SELECT 
	[TicketId],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #bfdxProd
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] LIKE 'COMPLAINT' AND [ObjectName] LIKE 'BFDX Part Number'

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[Customer Id] AS [CustID],
	[Customer Name] AS [CustName],
	[Customer Address] AS [CustAddr],
	[Customer Contact] AS [CustContact],
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([Contact Telephone Number],'-',''),'(',''),')',''),'.',''),' ','')  AS [ContactPhone],
	[Contact Fax Number] AS [ContactFax],
	[Contact Email] AS [ContactEmail]
INTO #custCmplt
FROM #cmplt P
PIVOT
(
	MAX([RecordedValue])
	FOR [PropertyName]
	IN
	(
		[Customer Id],
		[Customer Name],
		[Customer Address],
		[Customer Contact],
		[Contact Telephone Number],
		[Contact Fax Number],
		[Contact Email]
	)
) PIV
WHERE [CreatedDate] > GETDATE() - 90

SELECT
	[TicketId],
	[Product Line] AS [ProdLine],
	[Lot/Serial Number] AS [LotNo],
	[Part Number] AS [PartNo],
	[Failure Mode] AS [FailMode],
	[Quantity Affected] AS [Qty]
INTO #cmltProd
FROM #bfdxProd P
PIVOT
(
	MAX([RecordedValue])
	FOR [PropertyName]
	IN
	(
		[Product Line],
		[Lot/Serial Number],
		[Part Number],
		[Failure Mode],
		[Quantity Affected]
	)
) PIV
WHERE [TicketId] IN (SELECT [TicketId] FROM #custCmplt)

SELECT DISTINCT
	[CustID] AS [CustID],
	[CustName] AS [CustName],
	[ContactName] AS [ContactName],
	[ContactPhone] AS [ContactPhone],
	[ContactEMailAddr] AS [ContactEmail],
	[CustClassID] AS [CustClass],
	[SalesTerritoryID] AS [Territory],
	[ShipAddrName] AS [ShipAddrName],
	[ShipAddrLine1] AS [ShipAddrLine1],
	[ShipAddrCity] AS [ShipAddrCity],
	[ShipAddrState] AS [ShipAddrState],
	[ShipAddrPostalCode] AS [ShipAddrZip],
	[ShipAddrCountry] AS [ShipAddrCountry]
INTO #masCust
FROM [SQL1-RO].[mas500_app].[dbo].[vdvCustomer] WITH(NOLOCK)

SELECT
	C.[TicketId],
	C.[TicketString],
	C.[CreatedDate],
	M.[Territory],
	M.[CustClass],
	M.[CustID],
	M.[ShipAddrState],
	M.[ShipAddrZip],
	M.[ShipAddrCountry]
INTO #bestMatch
FROM #custCmplt C LEFT JOIN #masCust M
	ON C.[CustID] = M.[CustID]	
WHERE M.[CustID] IS NOT NULL

SELECT
	C.[TicketId],
	C.[TicketString],
	C.[CreatedDate],
	M.[Territory],
	M.[CustClass],
	M.[CustID],
	M.[ShipAddrState],
	M.[ShipAddrZip],
	M.[ShipAddrCountry]
INTO #goodMatch
FROM #custCmplt C LEFT JOIN #masCust M
	ON C.[CustName] = M.[CustName]
WHERE M.[CustName] IS NOT NULL AND C.[TicketId] NOT IN (SELECT [TicketId] FROM #bestMatch)

SELECT 
	C.[TicketId],
	C.[TicketString],
	C.[CreatedDate],
	M.[Territory],
	M.[CustClass],
	M.[CustID],
	M.[ShipAddrState],
	M.[ShipAddrZip],
	M.[ShipAddrCountry]
INTO #okayMatch
FROM #custCmplt C LEFT JOIN #masCust M
	ON C.[CustContact] = M.[ContactName]
WHERE M.[CustName] IS NOT NULL AND C.[TicketId] NOT IN (SELECT [TicketId] FROM #bestMatch) AND C.[TicketId] NOT IN (SELECT [TicketId] FROM #goodMatch)

SELECT
	C.[TicketId],
	C.[TicketString],
	C.[CreatedDate],
	M.[Territory],
	M.[CustClass],
	M.[CustID],
	M.[ShipAddrState],
	M.[ShipAddrZip],
	M.[ShipAddrCountry]
INTO #fairMatch
FROM #custCmplt C LEFT JOIN #masCust M
	ON LEFT(C.[ContactPhone],10) = LEFT(M.[ContactPhone],10)
WHERE M.[CustName] IS NOT NULL AND C.[TicketId] NOT IN (SELECT [TicketId] FROM #bestMatch) AND C.[TicketId] NOT IN (SELECT [TicketId] FROM #goodMatch) AND 
		C.[TicketId] NOT IN (SELECT [TicketId] FROM #okayMatch)

SELECT
	C.[TicketId],
	C.[TicketString],
	C.[CreatedDate],
	M.[Territory],
	M.[CustClass],
	M.[CustID],
	M.[ShipAddrState],
	M.[ShipAddrZip],
	M.[ShipAddrCountry]
INTO #lastMatch
FROM #custCmplt C LEFT JOIN #masCust M
	ON LEFT(C.[CustAddr],25) = LEFT(M.[ShipAddrName],25)
WHERE M.[CustName] IS NOT NULL AND C.[TicketId] NOT IN (SELECT [TicketId] FROM #bestMatch) AND C.[TicketId] NOT IN (SELECT [TicketId] FROM #goodMatch) AND 
		C.[TicketId] NOT IN (SELECT [TicketId] FROM #okayMatch) AND C.[TicketId] NOT IN (SELECT [TicketId] FROM #fairMatch)

SELECT
	[TicketId],
	[TicketString],
	[CreatedDate],
	[CustClass],
	[Territory],
	[ShipAddrCountry] AS [Country],
	[Region]
INTO #masMatched
FROM 
(
	SELECT 
		[TicketId],
		[TicketString],
		[CreatedDate],
		[CustClass],
		ISNULL([Territory], [CustClass]) AS [Territory],
		ISNULL([ShipAddrState],'International') AS [Region],
		[ShipAddrCountry]
	FROM #bestMatch
	UNION 
	SELECT 
		[TicketId],
		[TicketString],
		[CreatedDate],
		[CustClass],
		ISNULL([Territory], [CustClass]) AS [Territory],
		ISNULL([ShipAddrState],'International') AS [Region],
		[ShipAddrCountry]
	FROM #goodMatch
	UNION 
	SELECT 
		[TicketId],
		[TicketString],
		[CreatedDate],
		[CustClass],
		ISNULL([Territory], [CustClass]) AS [Territory],
		ISNULL([ShipAddrState],'International') AS [Region],
		[ShipAddrCountry]
	FROM #okayMatch
	UNION
	SELECT 
		[TicketId],
		[TicketString],
		[CreatedDate],
		[CustClass],
		ISNULL([Territory], [CustClass]) AS [Territory],
		ISNULL([ShipAddrState],'International') AS [Region],
		[ShipAddrCountry]
	FROM #fairMatch
	UNION
	SELECT 
		[TicketId],
		[TicketString],
		[CreatedDate],
		[CustClass],
		ISNULL([Territory], [CustClass]) AS [Territory],
		ISNULL([ShipAddrState],'International') AS [Region],
		[ShipAddrCountry]
	FROM #lastMatch
) D
WHERE [ShipAddrCountry] IS NOT NULL
GROUP BY 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[CustClass],
	[Territory],
	[Region],
	[ShipAddrCountry]

SELECT
	[TicketId],
	[TicketString],
	[CreatedDate],
	[Country],
	MAX([Region]) AS [Region],
	MAX([CustClass]) AS [CustClass],
	MAX([Territory]) AS [Territory]
INTO #complaintBase
FROM #masMatched
GROUP BY 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[Country]

SELECT DISTINCT
	[PartNumber],
	[Name]
INTO #prodWebRfit
FROM [ProductionWeb].[dbo].[Parts] WITH(NOLOCK)
WHERE [PartNumber] LIKE 'RFIT-%-%'

SELECT 
	M.[TicketId],
	M.[TicketString],
	M.[CreatedDate],
	M.[CustClass],
	M.[Territory],
	M.[Region],
	M.[Country],
	IIF(C.[PartNo] LIKE 'FLM1-ASY-0001','FA1.5',
		IIF(C.[PartNo] LIKE 'FLM1-ASY-0001R','FA1.5R',
		IIF(C.[PartNo] LIKE 'FLM2-ASY-0001','FA2.0',
		IIF(C.[PartNo] LIKE 'FLM2-ASY-0001R','FA2.0R',
		IIF(C.[PartNo] LIKE 'COMP%' AND C.[ProdLine] LIKE 'FilmArray', 'FA1.5',
		IIF(C.[PartNo] LIKE 'COMP%' AND C.[ProdLine] LIKE 'FilmArray 2.0', 'FA2.0', 
		IIF(P.[Name] IS NOT NULL AND P.[Name] LIKE '%RESP%','RP',
		IIF(P.[Name] IS NOT NULL AND P.[Name] LIKE '%GI%','GI',
		IIF(P.[Name] IS NOT NULL AND P.[Name] LIKE '%BCID%','BCID',
		IIF(P.[Name] IS NOT NULL AND P.[Name] LIKE '%ME%','ME','Other')))))))))) AS [Version],
	IIF(CHARINDEX('-1-', C.[FailMode], 1) > 0, 'Instrument',
		IIF(CHARINDEX('-2-', C.[FailMode], 1) > 0, 'Chemistry',
		IIF(CHARINDEX('-3-', C.[FailMode], 1) > 0, 'Pouch',
		IIF(CHARINDEX('-4-', C.[FailMode], 1) > 0, 'Software',
		IIF(CHARINDEX('-5-', C.[FailMode], 1) > 0, 'Accessory/Kitting', C.[FailMode]))))) AS [Class],
	C.[PartNo],
	P.[Name],
	CAST(REPLACE(REPLACE(C.[Qty],',',''),'.','') AS INT) AS [Qty]
INTO #annotated
FROM #complaintBase M LEFT JOIN #cmltProd C
	ON M.[TicketId] = C.[TicketId] LEFT JOIN #prodWebRfit P
		ON C.[PartNo] = P.[PartNumber]
WHERE ISNUMERIC([Qty]) = 1

SELECT 
	[CustClass],
	[Territory],
	[Region],
	SUBSTRING([Name],1,LEN([Name])) AS [Country],
	[Class] AS [ComplaintType],
	[Version] AS [Product],
	[Qty]
FROM
(
	SELECT 
		[CustClass],
		[Territory],
		[Region],
		[Country],
		[Class],
		[Version],
		SUM([Qty]) AS [Qty]
	FROM #annotated
	GROUP BY 
		[CustClass],
		[Territory],
		[Region],
		[Country],
		[Class],
		[Version]
) D LEFT JOIN 
(
	SELECT DISTINCT
		[CountryID] AS [CountryID],
		[Name] AS [Name]
	FROM [SQL1-RO].[mas500_app].[dbo].[tsmCountry] WITH(NOLOCK)
) M
	ON D.[Country] = M.[CountryID]

DROP TABLE #cmplt, #bfdxProd, #custCmplt, #cmltProd, #masCust, #bestMatch, #goodMatch, #okayMatch, #fairMatch, #lastMatch,
			#masMatched, #complaintBase, #prodWebRfit, #annotated
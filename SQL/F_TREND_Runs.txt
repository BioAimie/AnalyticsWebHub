SET NOCOUNT ON

DECLARE @runs TABLE
(
	[RunDataId] INT,
	[Panel] VARCHAR(20),
	[Date] DATE,
	[Instrument] VARCHAR(20),
	[Name] VARCHAR(200),
	[StateAbv] VARCHAR(8),
	[CustomerSiteId] INT,
	[Record] INT
)

INSERT INTO @runs
SELECT
	R.[RunDataId],
	IIF(R.[PouchTitle] LIKE 'Resp%', 'RP',
		IIF(R.[PouchTitle] LIKE 'GI %', 'GI',
		IIF(R.[PouchTitle] LIKE 'BCID %', 'BCID',
		IIF(R.[PouchTitle] LIKE 'ME %', 'ME', 'Other')))) AS [Panel],
	CAST(R.[StartTime] AS DATE) AS [Date],
	R.[InstrumentSerialNumber],
	C.[Name],
	C.[Province],
	S.[CustomerSiteId],
	1 AS [Record]
FROM [FADataWarehouse].[dbo].[RunData] R WITH(NOLOCK) INNER JOIN [FADataWarehouse].[dbo].[ConnectorLaptops] L WITH(NOLOCK)
	ON R.[ConnectorLaptopId] = L.[ConnectorLaptopId] INNER JOIN [FADataWarehouse].[dbo].[CustomerSites] S WITH(NOLOCK)
		ON L.[CustomerSiteId] = S.[CustomerSiteId] INNER JOIN [FADataWarehouse].[dbo].[Customers] C WITH(NOLOCK)
			ON S.[CustomerId] = C.[CustomerId]
WHERE R.[RunStatus] LIKE 'Completed' AND R.[SuppressState] LIKE 'Trendable' AND S.[CustomerSiteId] <> 37

SELECT *
FROM @runs
SET NOCOUNT ON

DECLARE @runs TABLE
(
	[RunDataId] INT,
	[Panel] VARCHAR(60),
	[Date] DATE,
	[Name] VARCHAR(200),
	[CustomerSiteId] INT
)

DECLARE @bugs TABLE
(
	[RunDataId] INT,
	[ResultType] VARCHAR(40),
	[Interpretation] VARCHAR(100)
)

INSERT INTO @runs
SELECT
	R.[RunDataId],
	R.[PouchTitle],
	CAST(R.[StartTime] AS DATE) AS [Date],
	C.[Name],
	S.[CustomerSiteId]
FROM [FADataWarehouse].[dbo].[RunData] R WITH(NOLOCK) INNER JOIN [FADataWarehouse].[dbo].[ConnectorLaptops] L WITH(NOLOCK)
	ON R.[ConnectorLaptopId] = L.[ConnectorLaptopId] INNER JOIN [FADataWarehouse].[dbo].[CustomerSites] S WITH(NOLOCK)
		ON L.[CustomerSiteId] = S.[CustomerSiteId] INNER JOIN [FADataWarehouse].[dbo].[Customers] C WITH(NOLOCK)
			ON S.[CustomerId] = C.[CustomerId]
WHERE R.[RunStatus] LIKE 'Completed' AND R.[SuppressState] LIKE 'Trendable' AND S.[CustomerSiteId] <> 37 AND R.[StartTime] > CONVERT(DATE, '2013-12-25')

INSERT INTO @bugs
SELECT 
	[RunDataId],
	[ResultType],
	[Interpretation]
FROM [FADataWarehouse].[dbo].[SummarizedPositiveAssayResults] WITH(NOLOCK)
WHERE [RunDataId] IN (SELECT [RunDataId] FROM @runs) AND [ResultType] NOT LIKE 'Control'

SELECT *
FROM @bugs
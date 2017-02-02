SET NOCOUNT ON

SELECT
	YEAR([creation_ts]) AS [Year],
	MONTH([creation_ts]) AS [Month],
	IIF([cf_vpapproval] LIKE '---', 'No', [cf_vpapproval]) AS [Key],
	1 AS [Record]
FROM [BFDXDatamart].[BugsContam].[bugs]
WHERE CAST([creation_ts] AS DATE) > '2016-01-01' AND [product_id] = 11

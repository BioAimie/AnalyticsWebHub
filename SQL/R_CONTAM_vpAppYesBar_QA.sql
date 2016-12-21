SET NOCOUNT ON

SELECT 
	CONVERT(CHAR(7), [creation_ts], 120) AS [CreatedDate],
	IIF([cf_vpapproval]='---','No',[cf_vpapproval]) AS [Key],
	1 AS [Record]
INTO #vpApp
FROM [BFDXDatamart].[BugsContam].[bugs]
WHERE [creation_ts] > '2016-01-01' AND [product_id] = 11

SELECT 
	[CreatedDate], 
	[Key], 
	SUM([Record]) AS Record
FROM #vpApp
GROUP BY [CreatedDate], [Key]
ORDER BY [CreatedDate], [Key]

DROP TABLE #vpApp
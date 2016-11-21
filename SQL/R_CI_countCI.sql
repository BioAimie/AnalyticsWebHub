SET NOCOUNT ON

SELECT
	YEAR([creation_ts]) AS [Year],
	DATEPART(mm,[creation_ts]) AS [Month],
	'CI' AS [Key],
	COUNT(bug_id) AS [Record]
FROM CI...bugs
WHERE [creation_ts] > '2015-01-01' AND [Resolution] NOT IN ('DUPLICATE', 'Voided')
GROUP BY YEAR([creation_ts]), DATEPART(mm,[creation_ts])
ORDER BY [Year], [Month]
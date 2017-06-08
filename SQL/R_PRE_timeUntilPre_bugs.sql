--Time until PRE
SET NOCOUNT ON

SELECT 
	A.[bug_id],
	CAST(B.[creation_ts] AS DATE) AS [DateOpened], 
	CAST(MIN(A.[bug_when]) AS DATE) AS [PREDate]
INTO #bugs
FROM [CI]...[bugs_activity] A WITH(NOLOCK) INNER JOIN [CI]...[bugs] B WITH(NOLOCK)	
	ON A.[bug_id] = B.[bug_id]
WHERE A.[fieldid] = 70 AND A.[removed] = '' AND B.[cf_regulatory_review] LIKE 'Yes' AND B.[resolution] NOT IN ('Voided', 'DUPLICATE')
GROUP BY A.[bug_id], B.[creation_ts]

SELECT
	[bug_id] AS [Bug],
	YEAR([DateOpened]) AS [Year],
	MONTH([DateOpened]) AS [Month], 
	[DateOpened], 
	DATEDIFF(day, [DateOpened], [PREDate]) AS [DaysToPRE],
	1 AS [Record] 
FROM #bugs 
ORDER BY [bug_id] 

DROP TABLE #bugs

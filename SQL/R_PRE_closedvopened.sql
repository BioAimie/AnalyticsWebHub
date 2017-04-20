SET NOCOUNT ON

--Opened
SELECT 
	YEAR([creation_ts]) AS [Year],
	DATEPART(ww, [creation_ts]) AS [Week],
	'Opened' AS [Key],
	1 AS [Record] 
INTO #all
FROM [CI]...[bugs] WITH(NOLOCK)
WHERE [resolution] NOT IN ('Voided', 'DUPLICATE')
UNION ALL
--Closed
SELECT 
	YEAR([DateClosed]) AS [Year],
	DATEPART(ww, [DateClosed]) AS [Week],
	'Closed' AS [Key],
	1 AS [Record] 
FROM 
(
	SELECT
		A.[bug_id],
		CAST(MAX(A.[bug_when]) AS DATE) AS [DateClosed] 
	FROM [CI]...[bugs_activity] A WITH(NOLOCK) INNER JOIN [CI]...[bugs] B WITH(NOLOCK)	
		ON A.[bug_id] = B.[bug_id]
	WHERE A.[fieldid] = 9 AND A.[added] LIKE 'CLOSED' AND B.[resolution] NOT IN ('Voided', 'DUPLICATE')
	GROUP BY B.[creation_ts], A.[bug_id]
) A

SELECT 
	[Year],
	[Week],
	[Key],
	SUM([Record]) AS [Record]
FROM #all
GROUP BY [Year], [Week], [Key]
ORDER BY [Year], [Week], [Key] 

DROP TABLE #all

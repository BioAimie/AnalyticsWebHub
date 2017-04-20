SET NOCOUNT ON

--CI team members (from past year)
SELECT 
	[userid],
	[realname] 
INTO #CITeam
FROM [CI]...[profiles] WITH(NOLOCK)
WHERE [realname] IN ('Dana Saif','Kimon Clarke','Ivan Arano','Mark Druss','Yarema Nagadzhyna')
--Raul Herrera ?
--Lindsay Meyers ?

SELECT
	A.[bug_id],
	CAST(B.[creation_ts] AS DATE) AS [DateOpened],
	CAST(MAX(A.[bug_when]) AS DATE) AS [DateClosed] 
INTO #dates
FROM [CI]...[bugs_activity] A WITH(NOLOCK) INNER JOIN [CI]...[bugs] B WITH(NOLOCK)	
	ON A.[bug_id] = B.[bug_id]
WHERE A.[fieldid] = 9 AND A.[added] LIKE 'CLOSED' AND A.[who] IN (SELECT [userid] FROM #CITeam) AND B.[cf_reporttype] NOT LIKE 'Trend' AND B.[resolution] NOT IN ('Voided', 'DUPLICATE')
GROUP BY B.[creation_ts], A.[bug_id]
ORDER BY B.[creation_ts], A.[bug_id]

SELECT 
	YEAR([DateOpened]) AS [Year],
	MONTH([DateOpened]) AS [Month],
	DATEDIFF(day, [DateOpened], [DateClosed]) AS [DaysToClose],
	1 AS [Record] 
FROM #dates

DROP TABLE #CITeam, #dates

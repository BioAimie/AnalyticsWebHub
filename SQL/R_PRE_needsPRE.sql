--open CI that need PRE and time since opened
SET NOCOUNT ON

--CI team members (from past year)
SELECT 
	[userid],
	[realname] 
INTO #CITeam
FROM [CI]...[profiles] WITH(NOLOCK)
WHERE [realname] IN ('Dana Saif','Kimon Clarke','Ivan Arano','Mark Druss','Yarema Nagadzhyna')

SELECT
	CAST([creation_ts] AS DATE) AS [DateOpened],
	[bug_id],
	[assigned_to]
INTO #bugs
FROM [CI]...[bugs] WITH(NOLOCK)
WHERE [bug_status] LIKE 'Open' AND [cf_regulatory_review] LIKE 'Yes' AND [cf_corrective] LIKE ''

SELECT 
	YEAR([DateOpened]) AS [Year],
	MONTH([DateOpened]) AS [Month], 
	[bug_id] AS [Bug], 
	DATEDIFF(day, [DateOpened], GETDATE()) AS [DaysSinceOpen],
	IIF(C.[realname] IS NULL, 'Other', 'CI Team') AS [AssignedTo],
	1 AS [Record] 
FROM #bugs B LEFT JOIN #CITeam C
	ON B.[assigned_to] = C.[userid]

DROP TABLE #CITeam, #bugs

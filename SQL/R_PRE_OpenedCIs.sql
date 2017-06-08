SET NOCOUNT ON

--CI team members (from past year)
SELECT 
	[userid],
	[realname] 
INTO #CITeam
FROM [CI]...[profiles] WITH(NOLOCK)
WHERE [realname] IN ('Dana Saif','Kimon Clarke','Ivan Arano','Mark Druss','Yarema Nagadzhyna')

SELECT 
	YEAR([creation_ts]) AS [Year],
	DATEPART(ww, [creation_ts]) AS [Week],
	'Opened' AS [Key],
	IIF(C.[realname] IS NULL, 'Other', 'CI Team') AS [AssignedTo],
	1 AS [Record]
FROM [CI]...[bugs] B WITH(NOLOCK) LEFT JOIN #CITeam C
	ON B.[assigned_to] = C.[userid] 
WHERE [resolution] NOT IN ('Voided', 'DUPLICATE') AND [bug_status] NOT LIKE 'CLOSED'

DROP TABLE #CITeam

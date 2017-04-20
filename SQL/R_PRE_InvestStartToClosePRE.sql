SET NOCOUNT ON

SELECT
	A.[bug_id],
	CAST(MAX(A.[bug_when]) AS DATE) AS [DateClosed] 
INTO #closed
FROM [CI]...[bugs_activity] A WITH(NOLOCK) INNER JOIN [CI]...[bugs] B WITH(NOLOCK)	
	ON A.[bug_id] = B.[bug_id]
WHERE A.[fieldid] = 9 AND A.[added] LIKE 'CLOSED' AND B.[resolution] NOT IN ('Voided', 'DUPLICATE')
GROUP BY B.[creation_ts], A.[bug_id]

SELECT 
	A.[bug_id],
	CAST(B.[creation_ts] AS DATE) AS [DateOpened], 
	CAST(B.[cf_invesigation_start_date] AS DATE) AS [InvestigationStart], 
	CAST(MIN(A.[bug_when]) AS DATE) AS [PREDate]
INTO #StartPRE
FROM [CI]...[bugs_activity] A WITH(NOLOCK) INNER JOIN [CI]...[bugs] B WITH(NOLOCK)	
	ON A.[bug_id] = B.[bug_id]
WHERE A.[fieldid] = 70 AND A.[removed] = '' AND B.[cf_regulatory_review] LIKE 'Yes' AND B.[resolution] NOT IN ('Voided', 'DUPLICATE')
GROUP BY A.[bug_id], B.[creation_ts], B.[cf_invesigation_start_date]

SELECT 
	S.[bug_id] AS [Bug], 
	S.[DateOpened],
	'InvestStartToClose' AS [Key], 
	IIF(DATEDIFF(day, S.[InvestigationStart], C.[DateClosed]) < 0, 0, DATEDIFF(day, S.[InvestigationStart], C.[DateClosed])) AS [Record]
INTO #Master
FROM #StartPRE S LEFT JOIN #closed C
	ON S.[bug_id] = C.[bug_id] 
UNION ALL
SELECT 
	[bug_id] AS [Bug], 
	[DateOpened],
	'InvestStartToPRE' AS [Key], 
	IIF(DATEDIFF(day, [InvestigationStart], [PREDate]) < 0, 0, DATEDIFF(day, [InvestigationStart], [PREDate])) AS [Record]
FROM #StartPRE

SELECT
	YEAR([DateOpened]) AS [Year],
	MONTH([DateOpened]) AS [Month],
	[Key],
	[Record]
FROM #Master 

DROP TABLE #closed, #StartPRE, #Master

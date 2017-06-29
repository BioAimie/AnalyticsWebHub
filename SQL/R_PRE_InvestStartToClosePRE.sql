SET NOCOUNT ON

SELECT
	A.[bug_id],
	CAST(B.[creation_ts] AS DATE) AS [DateOpened], 
	CAST(B.[cf_invesigation_start_date] AS DATE) AS [InvestigationStart], 
	CAST(B.[cf_investigation_completed_date] AS DATE) AS [InvestigationComplete], 
	CAST(MIN(A.[bug_when]) AS DATE) AS [PREDate]
INTO #StartPRE
FROM [CI]...[bugs_activity] A WITH(NOLOCK) INNER JOIN [CI]...[bugs] B WITH(NOLOCK)	
	ON A.[bug_id] = B.[bug_id]
WHERE A.[fieldid] = 70 AND A.[removed] = '' AND B.[cf_regulatory_review] LIKE 'Yes' AND B.[resolution] NOT IN ('Voided', 'DUPLICATE')
GROUP BY A.[bug_id], B.[creation_ts], B.[cf_invesigation_start_date], B.[cf_investigation_completed_date]

SELECT 
	[bug_id] AS [Bug], 
	[DateOpened],
	'InvestStartToInvestComplete' AS [Key], 
	IIF(DATEDIFF(day, [InvestigationStart], [InvestigationComplete]) < 0, 0, DATEDIFF(day, [InvestigationStart], [InvestigationComplete])) AS [Record]
INTO #Master
FROM #StartPRE
UNION ALL
SELECT 
	[bug_id] AS [Bug], 
	[DateOpened],
	'InvestStartToPRE' AS [Key], 
	IIF(DATEDIFF(day, [InvestigationStart], [PREDate]) < 0, 0, DATEDIFF(day, [InvestigationStart], [PREDate])) AS [Record]
FROM #StartPRE
UNION ALL
SELECT 
	[bug_id] AS [Bug], 
	[DateOpened],
	'CICreationToInvestStart' AS [Key], 
	IIF(DATEDIFF(day, [DateOpened], [InvestigationStart]) < 0, 0, DATEDIFF(day, [DateOpened], [InvestigationStart])) AS [Record]
FROM #StartPRE

SELECT
	YEAR([DateOpened]) AS [Year],
	MONTH([DateOpened]) AS [Month],
	[Key],
	[Record]
FROM #Master 
WHERE [DateOpened] >= CAST(GETDATE() - 500 AS DATE)

DROP TABLE #StartPRE, #Master

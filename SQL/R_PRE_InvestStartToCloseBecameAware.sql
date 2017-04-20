SET NOCOUNT ON

SELECT
	[bug_id],
	CAST([creation_ts] AS DATE) AS [DateOpened], 
	CAST([cf_invesigation_start_date] AS DATE) AS [InvestigationStart] 
INTO #start
FROM [CI]...[bugs] WITH(NOLOCK)
WHERE [resolution] NOT IN ('Voided', 'DUPLICATE') AND [cf_invesigation_start_date] IS NOT NULL

SELECT
	B.[bug_id],
	CAST(T.[RecordedValue] AS DATE) AS [BecameAware]
INTO #aware
FROM [CI]...[bugs] B WITH(NOLOCK) INNER JOIN [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] T WITH(NOLOCK) 
	ON B.[cf_complaint] = T.[TicketString]
WHERE T.[Tracker] LIKE 'COMPLAINT' AND T.[PropertyName] LIKE 'Became Aware Date' AND B.[resolution] NOT IN ('Voided', 'DUPLICATE')

SELECT
	A.[bug_id],
	CAST(MAX(A.[bug_when]) AS DATE) AS [DateClosed] 
INTO #closed
FROM [CI]...[bugs_activity] A WITH(NOLOCK) INNER JOIN [CI]...[bugs] B WITH(NOLOCK)	
	ON A.[bug_id] = B.[bug_id]
WHERE A.[fieldid] = 9 AND A.[added] LIKE 'CLOSED' AND B.[resolution] NOT IN ('Voided', 'DUPLICATE')
GROUP BY B.[creation_ts], A.[bug_id]

SELECT 
	S.[bug_id],
	[DateOpened],
	DATEDIFF(day, [DateOpened], [InvestigationStart]) AS [CItoInvestStart],
	DATEDIFF(day, [BecameAware], [InvestigationStart]) AS [BecameAwaretoInvestStart],
	DATEDIFF(day, [InvestigationStart], [DateClosed]) AS [InvestStarttoClose]
INTO #master
FROM #start S LEFT JOIN #aware A
	ON S.[bug_id] = A.[bug_id]
	LEFT JOIN #closed C
		ON S.[bug_id] = C.[bug_id] 
WHERE [DateOpened] >= GETDATE()-120

SELECT 
	[bug_id] AS [Bug],
	[DateOpened],
	'Days Between CI Created to Investigation Start' AS [Key],
	[CItoInvestStart] AS [Record]
FROM #master
WHERE [CItoInvestStart] IS NOT NULL
UNION ALL
SELECT 
	[bug_id] AS [Bug],
	[DateOpened],
	'Days Between Became Aware Date to Investigation Start' AS [Key],
	[BecameAwaretoInvestStart] AS [Record]
FROM #master
WHERE [BecameAwaretoInvestStart] IS NOT NULL
UNION ALL
SELECT 
	[bug_id] AS [Bug],
	[DateOpened],
	'Days Between Investigation Start to Close Date' AS [Key],
	[InvestStarttoClose] AS [Record]
FROM #master
WHERE [InvestStarttoClose] IS NOT NULL

DROP TABLE #start, #aware, #closed, #master

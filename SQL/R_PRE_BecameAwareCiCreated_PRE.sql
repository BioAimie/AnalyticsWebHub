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
	B.[bug_id],
	CAST(T.[RecordedValue] AS DATE) AS [BecameAware]
INTO #aware
FROM [CI]...[bugs] B WITH(NOLOCK) INNER JOIN [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] T WITH(NOLOCK) 
	ON B.[cf_complaint] = T.[TicketString]
WHERE T.[Tracker] LIKE 'COMPLAINT' AND T.[PropertyName] LIKE 'Became Aware Date' AND B.[cf_regulatory_review] LIKE 'Yes' AND B.[resolution] NOT IN ('Voided', 'DUPLICATE')

SELECT
	B.[bug_id] AS [Bug],
	[DateOpened],
	'Days Between CI Created and PRE Review' AS [Key],
	DATEDIFF(day, [DateOpened], [PREDate]) AS [Record]
FROM #bugs B LEFT JOIN #aware A
	ON B.[bug_id] = A.[bug_id]
WHERE B.[DateOpened] >= GETDATE()-120
UNION ALL
SELECT
	B.[bug_id] AS [Bug],
	[DateOpened],
	'Days Between Became Aware Date and PRE Review' AS [Key],
	DATEDIFF(day, [BecameAware], [PREDate]) AS [Record]
FROM #bugs B LEFT JOIN #aware A
	ON B.[bug_id] = A.[bug_id]
WHERE B.[DateOpened] >= GETDATE()-120
ORDER BY [Bug] 

DROP TABLE #bugs, #aware

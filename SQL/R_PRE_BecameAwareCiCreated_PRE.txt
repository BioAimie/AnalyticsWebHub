SET NOCOUNT ON

SELECT
	[bug_id],
	min([bug_when]) AS [preDateAdded]
INTO #PRE
FROM CI...bugs_activity
WHERE [bug_id] > '13000' AND [fieldid] = '70' AND [removed] = ''
GROUP BY [bug_id]

SELECT
	CAST([creation_ts] AS DATE) [ciCreatedDate],
	[bug_id],
	[cf_complaint],
	[cf_regulatory_review]
INTO #created
FROM CI...bugs
WHERE [cf_complaint] <> 'N/A' AND [creation_ts] > GETDATE()-120

SELECT
	CAST([RecordedValue] AS DATE) AS [BecameAwareDate],
	[ciCreatedDate],
	[bug_id],
	[cf_complaint],
	[cf_regulatory_review]
INTO #master
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] C INNER JOIN #created CI
ON C.[TicketString] = CI.[cf_complaint]
WHERE [Tracker] = 'Complaint' AND [PropertyName] LIKE 'Became Aware Date'

SELECT
	gM.[bug_id] AS [BugId], 
	DATEDIFF(dd, [BecameAwareDate], [preDateAdded]) AS [Days],
	'BecameAwareUntilPre' AS [Note],
	1 AS [Record]
FROM #master gM INNER JOIN #PRE mP
	ON gM.[bug_id] = mP.[bug_id]
WHERE [BecameAwareDate] <> [ciCreatedDate] AND [cf_regulatory_review] = 'Yes'
UNION
SELECT
	gM.[bug_id] AS [BugId],
	DATEDIFF(dd, [ciCreatedDate], [preDateAdded]) AS [Days],
	'ciCreatedUntilPRE' AS [Note],
	1 AS Record
FROM #master gM INNER JOIN #PRE mP
	ON gM.[bug_id] = mP.[bug_id]
WHERE [BecameAwareDate] <> [ciCreatedDate] AND [cf_regulatory_review] = 'Yes'
ORDER BY [BugId]

DROP TABLE #created, #PRE, #master
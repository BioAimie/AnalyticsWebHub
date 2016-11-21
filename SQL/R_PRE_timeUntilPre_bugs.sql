--TimeUntilPre based on bugs
SET NOCOUNT ON
SELECT
bug_id,
min(bug_when) AS DateAdded
INTO #minPRE
FROM CI...bugs_activity
WHERE bug_id > '13000'
AND fieldid = '70'
AND removed = ''
GROUP BY bug_id
ORDER BY bug_id;

SELECT CONVERT(CHAR(7),b.creation_ts, 120) AS CreatedDate,
A.bug_id,
DATEDIFF(dd,B.creation_ts, A.DateAdded) AS DaysUntilPRE
FROM CI...bugs AS B
INNER JOIN #minPRE AS A
ON A.bug_id = B.bug_id
WHERE cf_regulatory_review = 'Yes' 
AND B.creation_ts > GETDATE()-120
ORDER BY CreatedDate

DROP TABLE #minPRE
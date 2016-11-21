SET NOCOUNT ON
SELECT CONVERT(CHAR(7),[creation_ts], 120) AS CreatedDate, DATEDIFF(dd,creation_ts,MAX(bug_when)) AS DaysProcess
INTO #ciCloseYear
FROM CI...bugs_activity A
INNER JOIN CI...bugs B
ON A.bug_id = B.bug_id
WHERE (who='1730'
OR who='1739'
OR who='1682'
OR who='1149')
AND fieldid='9'
AND added='CLOSED'
AND creation_ts > GETDATE()-365
GROUP BY creation_ts, B.bug_id, added, removed
ORDER BY DaysProcess desc

SELECT CreatedDate, AVG(DaysProcess) AS AvgDaysProcess
FROM #ciCloseYear
GROUP BY CreatedDate

DROP TABLE #ciCloseYear
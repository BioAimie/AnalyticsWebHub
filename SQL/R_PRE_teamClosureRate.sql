--Overall Closures by PostMarket
SELECT DATEPART(yy,creation_ts) AS [Year]
, DATEPART(mm,creation_ts) AS [Month]
, DATEPART(wk,creation_ts) AS [Week]
, IIF(who='1730' OR who='1739' OR who='1682' OR who='1149','PMS','Other') AS [Key]
,1 AS Record
FROM CI...bugs_activity A
INNER JOIN CI...bugs B
ON A.bug_id = B.bug_id
WHERE fieldid='9'
AND added='CLOSED'
AND creation_ts > GETDATE()-365
GROUP BY creation_ts, who
ORDER BY [Year] desc, [Month]
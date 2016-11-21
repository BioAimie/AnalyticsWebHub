SET NOCOUNT ON
SELECT CONVERT(CHAR(7),b.creation_ts, 120) AS CreatedDate,
IIF(comments LIKE '%z101%', 'z101'
,IIF(comments LIKE '%z102%', 'z102',
IIF(comments LIKE '%z103%', 'z103',
IIF(comments LIKE '%z201%', 'z201',
IIF(comments LIKE '%z202%', 'z202',
IIF(comments LIKE '%z203%', 'z203',
IIF(comments LIKE '%z301%', 'z301',
IIF(comments LIKE '%z302%', 'z302',
IIF(comments LIKE '%z303%', 'z303',NULL))))))))) AS Code
,1 AS Record
INTO #codes
FROM CI...bugs_fulltext f INNER JOIN CI...bugs b
ON f.bug_id = b.bug_id
WHERE (comments LIKE '%z1%'
OR comments LIKE '%z2%'
OR comments LIKE '%z3%')
AND comments IS NOT NULL
AND creation_ts > '2016-01-01'

SELECT [CreatedDate], 
CASE WHEN [Code] = 'z101' THEN 'Sufficient info: Investigation started.'
WHEN [Code] = 'z102' THEN 'Waiting for customer info.' 
WHEN [Code] = 'z201' THEN 'Additional info requested.' 
WHEN [Code] = 'z202' THEN 'Additional info received.' 
WHEN [Code] = 'z203' THEN 'Supplemental info requested.' 
WHEN [Code] = 'z204' THEN 'Supplemental info received.'
WHEN [Code] = 'z301' THEN 'Customer follow-up requested.' 
WHEN [Code] = 'z302' THEN 'Customer follow-up received.' 
END AS [Code]
,SUM(Record) AS Record
FROM #codes
GROUP BY CreatedDate,Code

DROP TABLE #codes
SET NOCOUNT ON
SELECT DISTINCT
		YEAR(StartTime) AS [Year]
		,DATEPART(mm,StartTime) AS [Month]
		,DATEPART(wk,StartTime) AS [Week]
		,SUBSTRING(SampleId,4,CHARINDEX('_',SampleId,4)-4) AS [Group]
		,CASE WHEN [Name] LIKE 'HRV%' THEN 'HRV'
			ELSE [Name] END AS [Name]
		,PouchSN AS [PouchSerialNumber]
		,[Panel] AS [PouchTitle]
		,1 AS Record
FROM [PMS1].[dbo].[InfoStore_pouchRuns_FA]
WHERE lower(SampleId) LIKE '%br_pool%'
		AND Name NOT LIKE 'yeast%'
		AND Name NOT LIKE 'PCR%'
		AND Result = 'Positive'
ORDER BY [Year], [Month], [Week], [PouchSerialNumber], [Name]
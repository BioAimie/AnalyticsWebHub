SET NOCOUNT ON
SELECT DISTINCT
	YEAR(StartTime) AS [Year]
	,DATEPART(mm,StartTime) AS [Month]
	,DATEPART(wk,StartTime) AS [Week]
	,SUBSTRING(SampleId,6,2) AS [Group]
	,CASE WHEN [Name] LIKE 'HRV%' THEN 'HRV'
		ELSE [Name] END AS [Name]
	,PouchSN AS [PouchSerialNumber]
	,[Panel] AS [PouchTitle]
	,1 AS Record
FROM [PMS1].[dbo].[InfoStore_pouchRuns_FA]
WHERE LOWER(SampleId) LIKE '%kd%'
	AND Name NOT LIKE 'yeast%'
	AND Name NOT LIKE 'PCR%'
	AND Result = 'Positive'
	AND Panel = 'RP'
ORDER BY [Year], [Month], [Week], [PouchSerialNumber], [Name]
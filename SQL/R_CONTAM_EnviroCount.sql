SET NOCOUNT ON
SELECT DISTINCT
		YEAR(StartTime) AS [Year]
		,DATEPART(mm,StartTime) AS [Month]
		,DATEPART(wk,StartTime) AS [Week]
		,SUBSTRING(SampleId,CHARINDEX('_',SampleId,8)+1,3) AS [Group]
		,CASE WHEN [Name] LIKE 'HRV%' THEN 'HRV'
			ELSE [Name] END AS [Name]
		,[PouchSN] AS [PouchSerialNumber]
		,[Panel]  AS [PouchTitle]
		,1 AS Record
  FROM [PMS1].[dbo].[InfoStore_pouchRuns_FA]
  WHERE LOWER(SampleId) LIKE '%5w4b%'
		AND (SampleId LIKE '%420%'
			OR SampleId LIKE '%390%'
			OR SampleId LIKE '%400%'
			OR SampleId LIKE '%410%'
			OR SampleId LIKE '%421%')
		AND Name NOT LIKE 'yeast%'
		AND Name NOT LIKE 'PCR%'
		AND Result = 'Positive'
ORDER BY [Year], [Month], [Week], [PouchSerialNumber], [Name]
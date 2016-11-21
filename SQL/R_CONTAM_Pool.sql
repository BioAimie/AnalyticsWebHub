SET NOCOUNT ON
SELECT DISTINCT
		YEAR(StartTime) AS [Year]
		,DATEPART(mm,StartTime) AS [Month]
		,DATEPART(wk,StartTime) AS [Week]
		,SUBSTRING(SampleId,4,CHARINDEX('_',SampleId,4)-4) AS [Group]
		,CAST([Cp] AS numeric(2,0)) AS [Cp]
		,CASE WHEN [Name] LIKE 'HRV%' THEN 'HRV'
			ELSE [Name] END AS [Name]
		,[WellName]
		,[PouchSN] AS [PouchSerialNumber]
		,[Panel] AS [PouchTitle]
		,IIF(Name LIKE 'PCR%' OR Name Like 'yeast%','No Contamination'
			,IIF(Result='Positive','Contamination','No Contamination')) AS Contamination
		,1 AS Record
FROM [PMS1].[dbo].[InfoStore_pouchRuns_FA]
WHERE lower(SampleId) LIKE '%br_pool%'
ORDER BY [Year], [Month], [Week], [PouchSerialNumber], [Name]
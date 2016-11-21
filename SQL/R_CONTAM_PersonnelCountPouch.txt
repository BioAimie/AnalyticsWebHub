SET NOCOUNT ON
SELECT DISTINCT
		YEAR(StartTime) AS [Year]
		,DATEPART(mm,StartTime) AS [Month]
		,DATEPART(wk,StartTime) AS [Week]
		,SUBSTRING(SampleId,6,2) AS [Group]
		,PouchSN AS [PouchSerialNumber]
		,Panel AS [PouchTitle]
		,IIF(Name LIKE 'PCR%' OR Name Like 'yeast%','No Contamination'
			,IIF(Result='Positive','Contamination','No Contamination')) AS Contamination
		,1 AS Record
FROM [PMS1].[dbo].[InfoStore_pouchRuns_FA]
WHERE lower(SampleId) LIKE '%kd%'
ORDER BY [Year], [Month], [PouchSerialNumber]
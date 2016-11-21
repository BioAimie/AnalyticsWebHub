SELECT DISTINCT
CASE WHEN [Name] LIKE 'HRV%' THEN 'HRV'
	ELSE [Name] END AS [Name]
FROM InfoStore_pouchRuns_FA
WHERE [PouchTitle] = 'Respiratory Panel v1.7'
ORDER BY [Name]
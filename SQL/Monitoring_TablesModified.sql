SELECT 
	[name],
	[create_date],
	[modify_date]
FROM [PMS1].[sys].[tables]
WHERE [name] IN ('bInstrumentParts', 'bInstrumentProduced') OR
	[name] LIKE 'RMA%' OR [name] LIKE 'Complaint%' OR [name] LIKE 'NCR%'
ORDER BY [name]

SELECT 
	[SerialNumber], 
	'PouchLeak' AS [Key],
	ISNULL([PouchLeak],0) AS [Record]
FROM [PouchTracker].[dbo].[PostRunPouchObservations] WITH(NOLOCK)

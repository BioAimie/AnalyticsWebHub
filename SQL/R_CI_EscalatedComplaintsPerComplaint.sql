SELECT 
	YEAR([CreatedDate]) AS [Year],
	DATEPART(ww,[CreatedDate]) AS [Week],
	[RecordedValue] AS [Key],
	COUNT([TicketId]) AS [Record]
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Issue CI' AND [CreatedDate] > GETDATE() - 400
GROUP BY YEAR([CreatedDate]), DATEPART(ww,[CreatedDate]), [RecordedValue]
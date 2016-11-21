SET NOCOUNT ON
SELECT
	YEAR([CreatedDate]) AS [Year],
	DATEPART(mm,[CreatedDate]) AS [Month],
	'Complaints' AS [Key],
	COUNT([TicketId]) AS [Record]
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Issue CI' AND [CreatedDate] > '2015-01-01'
GROUP BY YEAR([CreatedDate]), DATEPART(mm,[CreatedDate])
ORDER BY [Year], [Month]
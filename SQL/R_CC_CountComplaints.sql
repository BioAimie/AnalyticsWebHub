SET NOCOUNT ON

SELECT 
	[Year],
	[Month],
	'Complaints' AS [Key],
	COUNT([TicketId]) AS [Record]
FROM
(
	SELECT
		[TicketString],
		[TicketId],
		CAST([CreatedDate] AS DATE) AS [Date],
		YEAR([CreatedDate]) AS [Year],
		MONTH([CreatedDate]) AS [Month]
	FROM [dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
	WHERE [Tracker] LIKE 'Complaint'
	GROUP BY [TicketString], [TicketId], [CreatedDate]
) A 
GROUP BY [Year], [Month]
ORDER BY [Year], [Month] 

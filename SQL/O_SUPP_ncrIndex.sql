SELECT 
	[TicketId],
	[TicketString]
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] = 'NCR' AND [PropertyName] = 'NCR Title'
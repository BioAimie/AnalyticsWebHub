SET NOCOUNT ON

SELECT
	[TicketID], 
	[TicketString], 
	[CreatedDate]
INTO #customerRMAs
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] LIKE 'RMA' AND [PropertyName] LIKE 'RMA Type' AND [RecordedValue] LIKE 'Customer%'

SELECT 
	[TicketID],
	[TicketString],
	[RecordedValue] AS [ReceivedDate]
INTO #receivedDate
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [TicketID] IN (SELECT [TicketID] FROM #customerRMAs) AND [PropertyName] LIKE 'Received Date' 

SELECT 
	[TicketID], 
	[TicketString], 
	[RecordedValue] AS [ServiceCenter]
INTO #serviceCenter
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [TicketID] IN (SELECT [TicketID] FROM #customerRMAs) AND [PropertyName] LIKE 'Assigned Service Center' and [RecordedValue] NOT LIKE 'Field Service'

SELECT 
	[TicketID], 
	[TicketString],
	[RecordedValue] AS [CustomerType]
INTO #customerType
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [TicketID] IN (SELECT [TicketID] FROM #customerRMAs) AND [PropertyName] LIKE 'Customer Id'

SELECT 
	DATEPART(MONTH, [CreatedDate]) AS [Month], 
	DATEPART(YEAR, [CreatedDate]) AS [Year], 
	[ServiceCenter], 
	IIF([CustomerType] LIKE 'BMX%', 'BMX', 'US') AS [CustomerType],
	IIF(DATEDIFF(DAY, [CreatedDate] , [ReceivedDate]) > 0, DATEDIFF(DAY, [CreatedDate] , [ReceivedDate]), 0) AS [DaysToReceived]
FROM #customerRMAs c LEFT JOIN #receivedDate r 
	ON c.[TicketID] = r.[TicketID] LEFT JOIN #serviceCenter s
		ON c.[TicketID] = s.[TicketID] LEFT JOIN #customerType ct 
			ON c.[TicketID] = ct.[TicketID]
ORDER BY [Year], [Month]

DROP TABLE #customerRMAs, #receivedDate, #serviceCenter, #customerType






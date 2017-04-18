SET NOCOUNT ON

SELECT 
	[TicketID]
INTO #customerRMAs
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] LIKE 'RMA' AND [PropertyName] LIKE 'RMA Type' AND [RecordedValue] LIKE 'Customer%' 

SELECT 
	[TicketId],
	[CreatedDate],
	[Received Date] AS [ReceivedDate],
	[Assigned Service Center] AS [ServiceCenter],
	[Customer Id] AS [CustID]
INTO #Master
FROM 
(
	SELECT 
		[TicketId],
		[CreatedDate], 
		[PropertyName],
		[RecordedValue] 
	FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
	WHERE [TicketID] IN (SELECT [TicketID] FROM #customerRMAs) AND [PropertyName] IN ('Received Date', 'Assigned Service Center', 'Customer Id')
) P
PIVOT
(
	MAX([RecordedValue])
	FOR [PropertyName]
	IN
	(
		[Received Date], 
		[Assigned Service Center], 
		[Customer Id]
	)
) PIV

SELECT 
	YEAR([CreatedDate]) AS [Year],
	MONTH([CreatedDate]) AS [Month],
	[ServiceCenter],
	IIF([CustID] LIKE 'BMX-NC', 'US Other',
		IIF([CustID] LIKE 'BMX%', 'BMX',
		IIF([CustID] IN ('BIODEF','NGDS') , 'Defense', 'US Other'))) AS [CustomerType],
	[CustID],
	IIF(DATEDIFF(day, [CreatedDate], [ReceivedDate]) < 0, 0, DATEDIFF(day, [CreatedDate], [ReceivedDate])) AS [DaysUntilReceipt] 
FROM #Master
WHERE [ServiceCenter] NOT LIKE 'Field Service'

DROP TABLE #customerRMAs, #Master

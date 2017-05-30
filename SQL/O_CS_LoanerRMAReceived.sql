SET NOCOUNT ON

SELECT 
	[TicketId],
	[CreatedDate],
	[RMA Type] AS [Type],
	[Received Date] AS [ReceivedDate],
	[Assigned Service Center] AS [ServiceCenter],
	[Customer Id] AS [CustID]
INTO #Master
FROM
(
	SELECT 
		[TicketId],
		[TicketString],
		[CreatedDate],
		[PropertyName],
		[RecordedValue] 
	FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] 
	WHERE [Tracker] LIKE 'RMA' AND [PropertyName] IN ('RMA Type', 'Received Date', 'Assigned Service Center', 'Customer Id') 
) P
PIVOT
(
	MAX([RecordedValue])
	FOR [PropertyName]
	IN
	(
		[RMA Type],
		[Received Date], 
		[Assigned Service Center], 
		[Customer Id]
	)
) PIV
WHERE [RMA Type] LIKE 'Loaner%' AND [Assigned Service Center] LIKE 'Salt Lake'

SELECT *
FROM
(
	SELECT 
		YEAR([CreatedDate]) AS [Year],
		MONTH([CreatedDate]) AS [Month],
		[ServiceCenter],
		IIF([CustID] LIKE 'BMX-NC%', 'US Other',
			IIF([CustID] LIKE 'BMX%', 'BMX',
			IIF([CustID] LIKE 'DIST%', 'BMX',
			IIF([CustID] IN ('BIODEF','NGDS') , 'Defense', 'US Other')))) AS [CustomerType],
		[CustID],
		IIF(DATEDIFF(day, [CreatedDate], [ReceivedDate]) < 0, 0, DATEDIFF(day, [CreatedDate], [ReceivedDate])) AS [DaysUntilReceipt] 
	FROM #Master
	WHERE [CustID] NOT LIKE 'IDATEC'
) A
WHERE [CustomerType] LIKE 'US Other'

DROP TABLE #Master

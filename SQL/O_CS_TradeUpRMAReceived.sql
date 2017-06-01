SET NOCOUNT ON

SELECT DISTINCT
	[TicketId]
INTO #Tickets
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus]
WHERE [Tracker] LIKE 'RMA' AND [ObjectName] LIKE 'Part Information' AND [PropertyName] LIKE 'Part Number'
	AND [RecordedValue] LIKE 'FLM1-ASY-0001%'

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
WHERE [RMA Type] IN ('FP OpLeas Trade','REG Trade ADD ON','REG Trade NONWAR','REG Trade WAR','RRA CAP TradeUP','FOC Trade WAR','RRA OP TradeUP','FP CapLeas Trad','FOC Trade NONWAR')
	AND [Assigned Service Center] NOT LIKE 'Field Service' AND [TicketId] IN (SELECT * FROM #Tickets)

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
ORDER BY [ServiceCenter], [CustomerType]

DROP TABLE #Tickets, #Master

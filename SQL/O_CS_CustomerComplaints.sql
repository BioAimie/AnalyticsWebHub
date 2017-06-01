SET NOCOUNT ON

SELECT
	[TicketId],
	[TicketString],
	CAST([CreatedDate] AS DATE) AS [Date],
	UPPER(RTRIM(LTRIM([RecordedValue]))) AS [CustID],
	1 AS [Record] 
INTO #Customers
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus]
WHERE [Tracker] LIKE 'COMPLAINT' AND [PropertyName] LIKE 'Customer Id'

SELECT 
	[TicketId],
	[TicketString],
	[Date],
	IIF([CustID] LIKE '%-[0-9]', SUBSTRING([CustID],1,PATINDEX('%-%',[CustID])-1), 
		IIF([CustID] LIKE '%/', SUBSTRING([CustID],1,PATINDEX('%/',[CustID])-1), 
		IIF([CustID] LIKE '%(%)%', SUBSTRING([CustID],1,PATINDEX('%(%)%',[CustID])-1), 
		IIF([CustID] LIKE '99-%', SUBSTRING([CustID], 4, LEN([CustID])), [CustID])))) AS [CustID],
	[Record] 
INTO #CleanCust
FROM #Customers 
WHERE [CustID] NOT LIKE 'N/A'

SELECT 
	[CustID],
	IIF([CustID] LIKE 'BMX-NC%', 'US',
		IIF([CustID] LIKE 'BMX%', 'International',
		IIF([CustID] LIKE 'DIST%', 'International', 'US'))) AS [Region], 
	[Record]
FROM
(
	SELECT
		[CustID],
		SUM([Record]) AS [Record]
	FROM #CleanCust
	WHERE [CustID] NOT LIKE 'N/A' AND [Date] >= GETDATE()-365
	GROUP BY [CustID]
) A
WHERE [CustID] NOT IN ('BIODEF','NGDS','IDATEC') AND [CustID] NOT LIKE ''
ORDER BY [CustID] 

DROP TABLE #Customers, #CleanCust

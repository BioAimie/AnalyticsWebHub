SET NOCOUNT ON

SELECT
	[TicketId],
	[CreatedDate],
	DATEPART(yy,[CreatedDate]) AS [Year],
	DATEPART(mm,[CreatedDate]) AS [Month],
	DATEPART(wk,[CreatedDate]) AS [Week],
	IIF(UPPER([RecordedValue]) LIKE '%HARD-SHL-0016%', 'old', 'new') AS [Key],
	[RecordedValue],
	1 AS Record,
	[TicketString]
INTO #lidlatch
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus]
WHERE Tracker = 'RMA' AND (RecordedValue LIKE '%HARD-SHL-0016%' OR RecordedValue LIKE '%FLM1-MAC-0367%') AND ObjectName = 'Root Causes'

SELECT 
	[TicketId],
	UPPER(REPLACE(REPLACE(REPLACE(REPLACE([RecordedValue],' ',''),'.',''),'-',''),'_','')) AS [SerialNo]
INTO #rmaSerial
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Part Information' AND [PropertyName] LIKE 'Lot/Serial Number' AND [TicketId] IN (SELECT [TicketId] FROM #lidlatch)

SELECT 
	S.[SerialNo],
	L.[CreatedDate],
	L.[Year],
	L.[Month],
	L.[Week],
	L.[Key],
	L.[Record]
INTO #failures
FROM #lidlatch L INNER JOIN #rmaSerial S
	ON L.[TicketId] = S.[TicketId]
WHERE LEFT(S.[SerialNo], 2) IN ('FA','2F','HT','TM')

SELECT
	[SerialNo],
	[TranDate]
INTO #shipments
FROM [PMS1].[dbo].[vSerialTransactions] WITH(NOLOCK)
WHERE [TranType] LIKE 'SH' OR ([TranType] IN ('SA','IS') AND [DistQty] = -1)

SELECT 
	[SerialNo],
	[Key],
	[Record],
	(
		SELECT
			MAX([TranDate]) AS [LastShipDate]
		FROM #shipments S
		WHERE S.[SerialNo] = F.[SerialNo] AND S.[TranDate] < F.[CreatedDate]
	) AS [Date] 
INTO #master
FROM #failures F

SELECT 
	[SerialNo],
	ISNULL(YEAR([Date]), 2015) AS [Year],
	ISNULL(MONTH([Date]), 3) AS [Month],
	ISNULL(DATEPART(ww, [Date]), DATEPART(ww, CONVERT(DATETIME, '2015-03-31'))) AS [Week],
	[Key],
	[Record]
INTO #binned
FROM #master

SELECT 
	[Year],
	[Month],
	[Week],
	[Key],
	SUM([Record]) AS [Record]
FROM #binned
GROUP BY [Year], [Month], [Week], [Key]

DROP TABLE #lidlatch, #rmaSerial, #failures, #shipments, #binned, #master
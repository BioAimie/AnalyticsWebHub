SET NOCOUNT ON

SELECT
	[TicketId],
	[TicketString],
	[CreatedDate],
	[InitialCloseDate],
	[Status]
INTO #AllComplaints
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] LIKE 'COMPLAINT' AND CAST([CreatedDate] AS DATE) >= '2014-01-01'
GROUP BY 
	[TicketId],
	[TicketString],
	[CreatedDate], 
	[InitialCloseDate], 
	[Status]

SELECT	
	[DateOpened],
	[DateClosed], 
	[YearOpen],
	[MonthOpen],
	[WeekOpen],
	[YearClosed],
	[MonthClosed],
	[WeekClosed],
	[DaysOpen],
	IIF([DaysOpen] BETWEEN 0 AND 30, '0 - 30',
		IIF([DaysOpen] BETWEEN 31 AND 60, '31 - 60',
		IIF([DaysOpen] BETWEEN 61 AND 90, '61 - 90',
		IIF([DaysOpen] BETWEEN 91 AND 120, '91 - 120', '121+')))) AS [Key],
	[Status],
	1 AS [Record] 
FROM
(
	SELECT
		CAST([CreatedDate] AS DATE) AS [DateOpened],
		CAST([InitialCloseDate] AS DATE) AS [DateClosed], 
		YEAR([CreatedDate]) AS [YearOpen],
		MONTH([CreatedDate]) AS [MonthOpen],
		DATEPART(ww,[CreatedDate]) AS [WeekOpen],
		YEAR([InitialCloseDate]) AS [YearClosed],
		MONTH([InitialCloseDate]) AS [MonthClosed],
		DATEPART(ww,[InitialCloseDate]) AS [WeekClosed],
		IIF([InitialCloseDate] IS NULL, DATEDIFF(day, CAST([CreatedDate] AS DATE), CAST(GETDATE() AS DATE)),
			DATEDIFF(day, CAST([CreatedDate] AS DATE), CAST([InitialCloseDate] AS DATE))) AS [DaysOpen],
		IIF([Status] LIKE 'Closed%', 'Closed', 'Open') AS [Status]
	FROM #AllComplaints
) A

DROP TABLE #AllComplaints

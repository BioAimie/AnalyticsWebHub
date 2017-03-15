SET NOCOUNT ON

SELECT 
	A1.[TicketId],
	[TicketString],
	[Status],
	[OpenDate],
	[CloseDate],
	[Type],
	[ServiceCenter],
	[ReceivedDate],
	[QuarantineDate],
	[ServiceDate],
	[SODate],
	[ShippingDate],
	[QCDate]
INTO #Props
FROM
(
	SELECT 
		[TicketId],
		[TicketString],
		[Status],
		CAST([CreatedDate] AS DATE) AS [OpenDate],
		CAST([InitialCloseDate] AS DATE) AS [CloseDate],
		[RMA Type] AS [Type], 
		[Assigned Service Center] AS [ServiceCenter],
		CAST([Received Date] AS DATE) AS [ReceivedDate], 
		CAST([Quarantine Release Date] AS DATE) AS [QuarantineDate], 
		CAST([Service Completed] AS DATE) AS [ServiceDate],
		CAST([SO Date] AS DATE) AS [SODate],
		CAST([Shipping Date] AS DATE) AS [ShippingDate]
	FROM
	(
		SELECT
			[TicketId],
			[TicketString],
			[Status],
			[CreatedDate],
			[InitialCloseDate],
			[PropertyName],
			[RecordedValue] 
		FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
		WHERE [PropertyName] IN ('RMA Type', 'Received Date', 'Quarantine Release Date', 'Service Completed','SO Date','Shipping Date', 'Assigned Service Center')
	) A
	PIVOT
	(
		MAX([RecordedValue])
		FOR [PropertyName]
		IN
		(
			[RMA Type], 
			[Assigned Service Center],
			[Received Date], 
			[Quarantine Release Date], 
			[Service Completed],
			[SO Date],
			[Shipping Date]
		)
	) PIV
) A1 LEFT JOIN 
(
	SELECT 
		[TicketId],
		MAX([QCDate]) AS [QCDate]
	FROM
	(
		SELECT
			[TicketId],
			CAST([QC Date] AS DATE) AS [QCDate],
			[DHR Complete] AS [DHR]
		FROM
		(
			SELECT 
				[TicketId],
				[ObjectId],
				[PropertyName],
				[RecordedValue] 
			FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
			WHERE [ObjectName] LIKE 'QC Check'
		) B
		PIVOT
		(
			MAX([RecordedValue])
			FOR [PropertyName]
			IN
			(
				[QC Date],
				[DHR Complete]		
			)
		) PIV2
		WHERE [QC Date] IS NOT NULL
	) C
	GROUP BY [TicketId] 
) B1
	ON A1.[TicketId] = B1.[TicketId]

SELECT 
	[TicketId],
	[TicketString],
	[Status],
	[CreatedDate],
	[InitialCloseDate], 
	[Part Number] AS [PartNo],
	IIF([Disposition] LIKE 'Return to Customer', 'Return to Customer', 'Other') AS [Disposition]
INTO #PartInfo
FROM 
(
	SELECT 
		[TicketId],
		[TicketString],
		[Status],
		[CreatedDate],
		[InitialCloseDate],
		[ObjectId],
		[PropertyName],
		[RecordedValue] 
	FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
	WHERE [ObjectName] LIKE 'Part Information'
) D
PIVOT
(
	MAX([RecordedValue]) 
	FOR [PropertyName]
	IN
	(
		[Part Number],
		[Disposition] 
	)
) PIV3

SELECT
	A2.[TicketId],
	ISNULL(A2.[TicketString], B2.[TicketString]) AS [TicketString],
	A2.[Part],
	A2.[Disposition],
	ISNULL(A2.[Status], B2.[Status]) AS [Status],
	ISNULL(B2.[OpenDate], A2.[CreatedDate]) AS [OpenDate],
	ISNULL(B2.[CloseDate], A2.[InitialCloseDate]) AS [CloseDate],
	B2.[Type],
	B2.[ServiceCenter],
	B2.[ReceivedDate],
	B2.[QuarantineDate],
	B2.[ServiceDate],
	B2.[SODate],
	B2.[ShippingDate],
	B2.[QCDate],
	C2.[LoanerRMADate],
	IIF(C2.[LoanerRMADate] IS NULL OR C2.[LoanerRMADate] < B2.[QCDate] OR C2.[LoanerRMADate] > B2.[SODate] OR C2.[LoanerRMADate] > B2.[ShippingDate], B2.[QCDate], C2.[LoanerRMADate]) AS [CorrectedLoanerDate]
INTO #Master
FROM 
(
	SELECT
		[TicketId],
		[TicketString],
		[Status],
		[CreatedDate],
		[InitialCloseDate], 
		MIN([Part]) AS [Part],
		MAX([Disposition]) AS [Disposition]
	FROM 
	(
		SELECT
			[TicketId],
			[TicketString],
			[Status],
			[CreatedDate],
			[InitialCloseDate], 
			IIF([PartNo] LIKE 'FLM%-ASY-0001%', 'Instrument',
				IIF([PartNo] LIKE 'HTFA-ASY-000%', 'Instrument',
				IIF([PartNo] LIKE 'HTFA-SUB-0103', 'Instrument', 
				IIF([PartNo] LIKE 'COMP-%', 'Computer', 
				IIF([PartNo] LIKE 'RFIT-%', 'Pouch', 'Accessory'))))) AS [Part],
			[Disposition]
		FROM #PartInfo
	) E
	GROUP BY 
		[TicketId],
		[TicketString],
		[Status],
		[CreatedDate],
		[InitialCloseDate]
) A2 LEFT JOIN #Props B2
	ON A2.[TicketId] = B2.[TicketId]
LEFT JOIN 
(
	SELECT 
		[TicketId],
		CAST([RecordedValue] AS DATE) AS [LoanerRMADate]
	FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
	WHERE [PropertyName] LIKE 'Loaner RMA Completed'
) C2
	ON A2.[TicketId] = C2.[TicketId] 

SELECT
	[Part],
	[Disposition],
	IIF([Status] LIKE 'Closed%', 'Closed', 'Open') AS [Status],
	[Type],
	[ServiceCenter],
	[OpenDate],
	DATEDIFF(day,[OpenDate],[ReceivedDate]) AS [DaysInReceiving], 
	[ReceivedDate],
	DATEDIFF(day,[ReceivedDate],[QuarantineDate]) AS [DaysInQuarantine/Decon],	
	[QuarantineDate],
	DATEDIFF(day, [QuarantineDate],[ServiceDate]) AS [DaysInService],
	[ServiceDate],
	DATEDIFF(day, [ServiceDate], [QCDate]) AS [DaysInQC], 
	[QCDate],
	DATEDIFF(day, [QCDate], [CorrectedLoanerDate]) AS [DaysInLoanerRMA],
	[CorrectedLoanerDate], 
	DATEDIFF(day, [CorrectedLoanerDate], [SODate]) AS [DaysToSalesOrder],
	[SODate],
	DATEDIFF(day, [SODate], [ShippingDate]) AS [DaysToShip],
	[ShippingDate],
	[CloseDate]
INTO #Final
FROM #Master

SELECT  
	YEAR([OpenDate]) AS [YearOpen],
	MONTH([OpenDate]) AS [MonthOpen],
	DATEPART(ww, [OpenDate]) AS [WeekOpen],
	YEAR([CloseDate]) AS [YearClose],
	MONTH([CloseDate]) AS [MonthClose],
	DATEPART(ww, [CloseDate]) AS [WeekClose],
	YEAR([ShippingDate]) AS [YearShip],
	MONTH([ShippingDate]) AS [MonthShip],
	DATEPART(ww, [ShippingDate]) AS [WeekShip],	
	[Part],
	[Disposition],
	[Status],
	[Type],
	[ServiceCenter],
	IIF([DaysInReceiving] < 0, 0, [DaysInReceiving]) AS [DaysInReceiving],
	IIF([DaysInQuarantine/Decon] < 0, 0, [DaysInQuarantine/Decon]) AS [DaysInQuarantine/Decon],
	IIF([DaysInService] < 0, 0, [DaysInService]) AS [DaysInService],
	IIF([DaysInQC] < 0, 0, [DaysInQC]) AS [DaysInQC],
	IIF([DaysInLoanerRMA] < 0, 0, [DaysInLoanerRMA]) AS [DaysInLoanerRMA],
	IIF([DaysToSalesOrder] < 0, 0, [DaysToSalesOrder]) AS [DaysToSalesOrder],
	IIF([DaysToShip] < 0, 0, [DaysToShip]) AS [DaysToShip],
	1 AS [Record] 
FROM #Final

DROP TABLE #Props, #PartInfo, #Master, #Final

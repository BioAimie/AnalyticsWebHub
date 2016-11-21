SET NOCOUNT ON 

SELECT 
	[TicketId]
INTO #consider
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] LIKE 'RMA' AND [Status] IN ('Closed','Accounting','Shipping','SalesOrderGeneration','Closure','InstrumentQCandDHR')

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #partinfo
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Part Information' AND [TicketId] IN (SELECT [TicketId] FROM #consider)

SELECT 
	[TicketId],
	[PropertyName],
	[RecordedValue]
INTO #workflow
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'RMA Workflow' AND [TicketId] IN (SELECT [TicketId] FROM #consider)

SELECT 
	[TicketId],
	[PropertyName],
	[RecordedValue]
INTO #properties
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] IN ('RMA Title','RMA Type','Complaint Number','Hours Run','Service Completed') AND [TicketId] IN (SELECT [TicketId] FROM #consider)

SELECT
	[TicketId],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #rootCause
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK) 
WHERE [ObjectName] LIKE 'Root Causes' AND [TicketId] IN (SELECT [TicketId] FROM #consider)

SELECT 
	I.[TicketId],
	I.[TicketString],
	I.[CreatedDate],
	I.[Part Number] AS [PartNo],
	IIF(LEFT(I.[SerialNo],2) LIKE 'FA', SUBSTRING(I.[SerialNo],1,6),
		IIF(LEFT(I.[SerialNo],2) LIKE '2F', SUBSTRING(I.[SerialNo],1,8), [SerialNo])) AS [SerialNo],
	P.[ServiceDate],
	P.[HoursRun],
	P.[Title],
	I.[CustFail],
	P.[Complaint],
	P.[Type],
	R.[RCFail],
	W.[ServiceReq],
	IIF(P.[Title] LIKE '%error%' OR P.[Title] LIKE '%fail%' OR P.[Title] LIKE ' DOA%' OR P.[Title] LIKE ' ELF%' OR P.[Title] LIKE ' SDOA%' OR P.[Title] LIKE ' SELF%', 1, 0) AS [TitleFlag],
	IIF(ISNUMERIC(P.[Complaint]) = 1, 1, 0) AS [ComplaintFlag],
	IIF(ISNUMERIC(P.[Complaint]) = 1 AND P.[Title] LIKE '%loaner%', 1, 
		IIF(ISNUMERIC(P.[Complaint]) = 1 AND P.[Title] LIKE '%demo%', 1, 
		IIF(ISNUMERIC(P.[Complaint]) = 1 AND P.[Type] LIKE '%No Failure', 1, 0))) AS [StripComplaintFlag], 
	IIF(P.[Type] LIKE '%- Failure%', 1, 0) AS [TypeFlag],
	IIF(I.[CustFail] IN ('SDOA','DOA','ELF','SELF'), 1, 0) AS [CustFlag]
INTO #flagged
FROM
(
	SELECT 
		[TicketId],
		[TicketString],
		[CreatedDate],
		[Part Number],
		[Lot/Serial Number] AS [SerialNo],
		[Early Failure Type] AS [CustFail]
	FROM #partinfo P
	PIVOT
	(
		MAX([RecordedValue])
		FOR [PropertyName]
		IN
		(
			[Part Number],
			[Lot/Serial Number],
			[Early Failure Type]
		)
	) PIV
	WHERE [Part Number] LIKE '%FLM%-ASY-0001%' OR [Part Number] LIKE 'HTFA-ASY-0003%'
) I LEFT JOIN
(
	SELECT 
		[TicketId],
		[RMA Title] AS [Title],
		[RMA Type] AS [Type],
		[Complaint Number] AS [Complaint],
		[Hours Run] AS [HoursRun],
		[Service Completed] AS [ServiceDate]
	FROM #properties P
	PIVOT
	(
		MAX([RecordedValue])
		FOR [PropertyName]
		IN
		(
			[RMA Title],
			[RMA Type],
			[Complaint Number],
			[Hours Run],
			[Service Completed]
		)
	) PIV
) P
	ON I.[TicketId] = P.[TicketId] LEFT JOIN
(
	SELECT DISTINCT
		[TicketId],
		1 AS [RCFail]
	FROM #rootCause
	WHERE [PropertyName] LIKE 'Part Number' AND [RecordedValue] IS NOT NULL AND ISNUMERIC([RecordedValue]) = 0 AND [RecordedValue] NOT LIKE 'N%A' AND [RecordedValue] NOT LIKE ''
) R
	ON I.[TicketId] = R.[TicketId] LEFT JOIN
(
	SELECT 
		[TicketId],
		[RecordedValue] AS [ServiceReq]
	FROM #workflow
	WHERE [PropertyName] LIKE 'Service'
) W
	ON I.[TicketId] = W.[TicketId]
WHERE (LEFT([SerialNo],2) IN ('FA','2F','HT') OR [Part Number] LIKE 'HTFA-%') AND [ServiceReq] LIKE 'true' 

SELECT 
	[TicketId]
INTO #complaintsReal
FROM #flagged 
WHERE [ComplaintFlag] = 1 AND [TitleFlag] = 0 AND ([CustFlag] = 0 OR [CustFlag] IS NULL) AND ([TypeFlag] = 0 OR [TypeFlag] IS NULL) AND ([RCFail] = 0 OR [RCFail] IS NULL) AND [StripComplaintFlag] = 0

SELECT
	F.[TicketId],
	F.[TicketString],
	F.[CreatedDate],
	CAST(F.[ServiceDate] AS DATETIME) AS [ServiceDate],
	F.[PartNo],
	IIF(LEFT(F.[SerialNo],2) LIKE 'FA', SUBSTRING(F.[SerialNo], 1, 6), [SerialNo]) AS [SerialNo],
	F.[HoursRun],
	IIF(C.[TicketId] IS NOT NULL, 1, 
		IIF([TitleFlag] = 1, 1, 
		IIF([TypeFlag] = 1, 1,
		IIF([CustFlag] = 1, 1,
		IIF([RCFail] = 1, 1, 0))))) AS [Failure]
INTO #bestSet
FROM #flagged F LEFT JOIN #complaintsReal C
	ON F.[TicketId] = C.[TicketId]

SELECT ROW_NUMBER() OVER(PARTITION BY [SerialNo] ORDER BY [TicketId]) AS [VisitNo],
	UPPER([PartNo]) AS [PartNo],
	UPPER([SerialNo]) AS [SerialNo],
	[TicketId],
	[TicketString],
	[CreatedDate],
	[ServiceDate],
	CAST(REPLACE([HoursRun],',','') AS FLOAT) AS [HoursRun],	
	[Failure]
INTO #visitOrdered
FROM #bestSet
WHERE [Failure] = 1 AND (ISNUMERIC([HoursRun]) = 1 OR [HoursRun] IS NULL)

SELECT 
	[VisitNo],
	[PartNo],
	[SerialNo],
	[TicketString],
	CAST([CreatedDate] AS DATE) AS [CreatedDate],
	CAST([ServiceDate] AS DATE) AS [ServiceDate],
	[HoursRun],
	LAG([HoursRun]) OVER(PARTITION BY [SerialNo] ORDER BY [VisitNo]) AS [PriorHours]
INTO #lagged
FROM #visitOrdered 

SELECT *,
	IIF([PriorHours] IS NULL, [HoursRun], ([HoursRun] - [PriorHours])) AS [MTBF]
INTO #mtbf
FROM #lagged

SELECT 
	YEAR([ServiceDate]) AS [Year],
	MONTH([ServiceDate]) AS [Month],
	[MTBF]
FROM #mtbf
WHERE [MTBF] IS NOT NULL AND [MTBF] > 0.0000001 AND [ServiceDate] IS NOT NULL

DROP TABLE #consider, #partinfo, #workflow, #properties, #rootCause, #flagged, #complaintsReal, #bestSet, #visitOrdered, #lagged, #mtbf
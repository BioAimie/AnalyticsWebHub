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
WHERE [ObjectName] LIKE 'Part Information'

SELECT 
	[TicketId],
	[PropertyName],
	[RecordedValue]
INTO #workflow
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'RMA Workflow'

SELECT 
	[TicketId],
	[PropertyName],
	[RecordedValue]
INTO #properties
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] IN ('RMA Title','RMA Type','Complaint Number','Hours Run','Service Completed')

SELECT
	[TicketId],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #rootCause
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK) 
WHERE [ObjectName] LIKE 'Root Causes'

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
	IIF(P.[Title] LIKE '%error%' OR P.[Title] LIKE '%fail%' OR P.[Title] LIKE '% DOA%' OR P.[Title] LIKE '% ELF%' OR P.[Title] LIKE '% SDOA%' OR P.[Title] LIKE '% SELF%', 1, 0) AS [TitleFlag],
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
	WHERE ([Part Number] LIKE '%FLM%-ASY-0001%' OR [Part Number] LIKE 'HTFA-ASY-0003%' OR [Part Number] LIKE 'HTFA-SUB-0103%') AND [TicketId] IN (SELECT [TicketId] FROM #consider)
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
WHERE (LEFT([SerialNo],2) IN ('FA','2F','HT','TM','KT') OR [Part Number] LIKE 'HTFA-%') AND [ServiceReq] LIKE 'true' 

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

SELECT 
	[CreatedDate],
	[SerialNo]
INTO #serialReturns
FROM
(
	SELECT ROW_NUMBER() OVER(PARTITION BY [SerialNo] ORDER BY [TicketId]) AS [VisitNo],
		UPPER([PartNo]) AS [PartNo],
		UPPER([SerialNo]) AS [SerialNo],
		[TicketId],
		[TicketString],
		[CreatedDate],
		[ServiceDate]
	FROM #bestSet
	WHERE [Failure] = 1
) T
WHERE [VisitNo] = 1

SELECT *
INTO #instShip
FROM [PMS1].[dbo].[vSerialTransactions] WITH(NOLOCK)

SELECT ROW_NUMBER() OVER(PARTITION BY [SerialNo] ORDER BY [TranDate]) AS [uniqueId],
	[ItemID],
	IIF(LEFT([SerialNo],2) LIKE 'FA', SUBSTRING([SerialNo], 1, 6), [SerialNo]) AS [SerialNo],
	[TranDate]
INTO #serialShipId
FROM
(
	SELECT
		REPLACE(REPLACE(REPLACE(REPLACE([SerialNo],'R',''),'_',''),'.',''),' ','') AS [SerialNo],
		[ItemID],
		[TranType],
		[TranDate],
		[DistQty]
	FROM #instShip
) T
WHERE ([TranType] LIKE 'SH') OR ([TranType] IN ('IS','SA') AND [DistQty]=-1)
ORDER BY [SerialNo]

SELECT 
	I.[SerialNo],
	V.[ItemID] AS [Version],
	I.[TranDate]
INTO #serialShipments
FROM
(	
	SELECT 	
		[SerialNo],
		MIN([uniqueId]) AS [id],
		MIN([TranDate]) AS [TranDate]
	FROM #serialShipId
	GROUP BY [SerialNo]
) I INNER JOIN
(
	SELECT 
		[uniqueId],
		[ItemID],
		[SerialNo]
	FROM #serialShipId		
) V
	ON I.[SerialNo] = V.[SerialNo] AND I.[id] = V.[uniqueId]

SELECT 
	YEAR(S.[TranDate]) AS [Year],
	MONTH(S.[TranDate]) AS [Month],
	S.[SerialNo],
	IIF(R.[CreatedDate] IS NULL, 0, 1) AS [ReturnedDueToFailure],
	ISNULL(F.[FailCount], 0) AS [TimesReturnedDueToFailure]
INTO #shipFailTracker
FROM #serialShipments S LEFT JOIN #serialReturns R
	ON S.[SerialNo] = R.[SerialNo] LEFT JOIN
	(
		SELECT 
			[SerialNo],
			SUM([Failure]) AS [FailCount]
		FROM #bestSet
		GROUP BY [SerialNo]
	) F
		ON S.[SerialNo] = F.[SerialNo]

SELECT 
	S.[Year],
	S.[Month],
	S.[Shipments],
	ISNULL(R.[Returned],0) AS [Returned],
	F.[FailCount]
FROM
(
	SELECT 
		[Year],
		[Month],
		COUNT([SerialNo]) AS [Shipments]
	FROM #shipFailTracker
	GROUP BY 
		[Year],
		[Month]
) S LEFT JOIN 
(
	SELECT 
		[Year],
		[Month],
		SUM([ReturnedDueToFailure]) AS [Returned]
	FROM #shipFailTracker
	WHERE [ReturnedDueToFailure] = 1
	GROUP BY 
		[Year],
		[Month]
) R 
	ON (S.[Year] = R.[Year] AND S.[Month] = R.[Month]) LEFT JOIN
(
	SELECT
		[Year],
		[Month],
		SUM([TimesReturnedDueToFailure]) AS [FailCount]
	FROM #shipFailTracker
	GROUP BY 
		[Year],
		[Month]
) F
	ON (S.[Year] = F.[Year] AND S.[Month] = F.[Month])
WHERE S.[Year] > 2012
ORDER BY S.[Year], S.[Month]

DROP TABLE #bestSet, #complaintsReal, #consider, #flagged, #partinfo, #properties, #rootCause, #serialReturns, #serialShipId, #serialShipments, 
			#shipFailTracker, #workflow, #instShip
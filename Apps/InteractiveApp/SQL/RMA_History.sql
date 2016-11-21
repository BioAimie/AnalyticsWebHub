SET NOCOUNT ON

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[Status],
	[ObjectName],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #ObjectsRMA
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] LIKE 'RMA' AND [ObjectName] IN ('Root Causes','Part Information')

SELECT 
	[TicketId],
	[PropertyName],
	[RecordedValue]
INTO #PropertiesRMA
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] LIKE 'RMA' AND [PropertyName] IN ('RMA Type','Customer Id','Complaint Number','Hours Run','RMA Title')

SELECT 
	[TicketId],
	SUBSTRING([TicketString], CHARINDEX('-',[TicketString],1)+1, 10) AS [Complaint],
	[ObjectId],
	[ObjectName],
	[PropertyName],
	[RecordedValue]
INTO #ObjectsComplaint
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] LIKE 'COMPLAINT' AND [ObjectName] IN ('Related RMAs', 'BFDX Part Number')

SELECT 
	[TicketId],
	[PropertyName],
	[RecordedValue] 
INTO #PropertiesComplaint
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] LIKE 'COMPLAINT' AND [PropertyName] IN ('Customer Id','Customer Name')

SELECT 
	SUBSTRING(T1.[TicketString],5,10) AS [TicketString],
	T1.[CreatedDate],
	T1.[Status],
	UPPER(T1.[Serial Number]) AS [Serial Number],
	T1.[Disposition],
	T1.[Early Failure Type],
	UPPER(T2.[Customer Id]) AS [Customer Id],
	T2.[Complaint Number],
	T2.[RMA Title],
	T2.[RMA Type],
	T2.[Hours Run],
	T3.[Root Cause Part Number]
INTO #rma
FROM
(
	SELECT 
		[TicketId],
		[TicketString],
		[CreatedDate],
		[Status],
		REPLACE([Lot/Serial Number],' ','') AS [Serial Number],
		[Disposition],
		[Early Failure Type]
	FROM
	(
		SELECT
			[TicketId],
			[TicketString],
			[CreatedDate],
			[Status],
			[ObjectId],
			[PropertyName],
			[RecordedValue]
		FROM #ObjectsRMA 
		WHERE [ObjectName] LIKE 'Part Information'
	) P PIVOT
	(
		MAX([RecordedValue])
		FOR [PropertyName]
		IN
		(
			[Part Number],
			[Lot/Serial Number],
			[Disposition],
			[Early Failure Type]
		)
	) PIV
	WHERE LEFT([Part Number],13) IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-ASY-0003')
) T1 LEFT JOIN
(
	SELECT 
		[TicketId],
		[RMA Title],
		[RMA Type],
		[Customer Id],
		[Complaint Number],
		[Hours Run]
	FROM #PropertiesRMA P
	PIVOT
	(
		MAX([RecordedValue])
		FOR [PropertyName] 
		IN
		(
			[RMA Title],
			[RMA Type],
			[Customer Id],
			[Complaint Number],
			[Hours Run]
		)
	) PIV
) T2
	ON T1.[TicketId] = T2.[TicketId] LEFT JOIN
(
	SELECT 
		[TicketId],
		SUBSTRING(
		(
			SELECT
				','+[RecordedValue]  AS [text()]
			FROM #ObjectsRMA OR2
			WHERE OR2.[ObjectName] LIKE 'Root Causes' AND OR2.[PropertyName] LIKE 'Part Number' AND OR2.[TicketId] = OR1.[TicketId]
			ORDER BY OR2.[TicketId]
			FOR XML PATH ('')
		), 2, 1000) AS [Root Cause Part Number]
	FROM #ObjectsRMA OR1
	WHERE [ObjectName] LIKE 'Root Causes' AND [PropertyName] LIKE 'Part Number'
) T3
	ON T1.[TicketId] = T3.[TicketId]

SELECT 
	F.[Complaint],
	UPPER(C.[Customer Id]) AS [Customer Id],
	C.[Customer Name],
	F.[Product Line],
	F.[Part Number],
	UPPER(F.[Lot/Serial Number]) AS [Lot/Serial Number],
	UPPER(R.[SerialNoEst]) AS [SerialNoEst],
	F.[Failure Mode],
	R.[RMA],
	R.[Description],
	IIF(F.[Lot/Serial Number] <> R.[SerialNoEst], 0, 1) AS [SerialNoMatch]
INTO #complaintRMAs
FROM
(
	SELECT 
		[TicketId],
		[Customer Id],
		[Customer Name]
	FROM #PropertiesComplaint P
	PIVOT
	(
		MAX([RecordedValue])
		FOR [PropertyName]
		IN
		(
			[Customer Id],
			[Customer Name]
		)
	) PIV
) C LEFT JOIN
(
	SELECT 
		[TicketId],
		[Complaint],
		[Product Line],
		[Part Number],
		REPLACE(REPLACE(REPLACE(REPLACE([Lot/Serial Number],' ',''),'.',''),'-',''),'_','') AS [Lot/Serial Number],
		[Failure Mode]
	FROM
	(
		SELECT 
			[TicketId],
			[Complaint],
			[ObjectId],
			[PropertyName],
			[RecordedValue]
		FROM #ObjectsComplaint
		WHERE [ObjectName] LIKE 'BFDX Part Number'
	) P
	PIVOT 
	(
		MAX([RecordedValue])
		FOR [PropertyName]
		IN
		(
			[Product Line],
			[Part Number],
			[Lot/Serial Number],
			[Failure Mode]
		)
	) PIV
) F 
	ON C.[TicketId] = F.[TicketId] LEFT JOIN
(
	SELECT 
		[TicketId],
		REPLACE(REPLACE([RMA], 'RMA',''),' ','') AS [RMA],
		[Description],
		IIF(CHARINDEX('2FA', [Description], 1) <> 0, SUBSTRING([Description], CHARINDEX('2FA', [Description], 1), 8),
			IIF(CHARINDEX('FA', [Description], 1) <> 0, SUBSTRING([Description], CHARINDEX('FA', [Description], 1), 6),
			IIF(CHARINDEX('TM', [Description], 1) <> 0, SUBSTRING([Description], CHARINDEX('TM', [Description], 1), 8), ''))) AS [SerialNoEst]
	FROM
	(
		SELECT 
			[TicketId],
			[ObjectId],
			[PropertyName],
			[RecordedValue]
		FROM #ObjectsComplaint
		WHERE [ObjectName] LIKE 'Related RMAs'
	) P
	PIVOT
	(
		MAX([RecordedValue])
		FOR [PropertyName]
		IN
		(
			[RMA],
			[Description]
		)
	) PIV
) R
	ON C.[TicketId] = R.[TicketId]
WHERE ISNUMERIC([RMA]) = 1

SELECT 
	[TicketString],
	[Serial Number],
	REPLACE([Hours Run],',','') AS [Hours Run],
	IIF([Early Failure Type] IN ('DOA','SDOA','SELF','ELF'), 1,
		IIF([RMA Title] LIKE '%error%' OR [RMA Title] LIKE '%fail%', 1,
		IIF([RMA Type] LIKE '%- Failure', 1,
		IIF(ISNUMERIC([Complaint Number]) = 1 AND [RMA Title] NOT LIKE '%loaner%', 1,
		IIF([Root Cause Part Number] NOT LIKE 'N%A' AND [Root Cause Part Number] IS NOT NULL, 1, 0))))) AS [Failure]
INTO #failures
FROM #rma

SELECT 
	[Serial Number],
	[TicketString],
	[Hours Run],
	LAG([Hours Run]) OVER(PARTITION BY [Serial Number] ORDER BY CAST([TicketString] AS INT)) AS [Prior Hours],
	[Failure] 
INTO #failureHours
FROM #failures
WHERE LEFT([Serial Number], 2) IN ('FA','2F','HT','TM','AF','FL') AND [Failure] = 1

SELECT 
	[Serial Number],
	[TicketString],
	CAST([Hours Run] AS FLOAT) AS [Hours Run],
	CAST([Prior Hours] AS FLOAT) AS [Prior Hours],
	[Failure]
INTO #numericHours
FROM
(
	SELECT 
		[Serial Number],
		[TicketString],
		[Failure],
		IIF([Hours Run] IS NULL, '0', 
			IIF([Hours Run] LIKE '%N%A%' OR [Hours Run] LIKE '%n%a%','0', [Hours Run])) AS [Hours Run],
		IIF([Prior Hours] IS NULL, '0', 
			IIF([Hours Run] LIKE '%N%A%' OR [Prior Hours] LIKE '%n%a%','0', [Prior Hours])) AS [Prior Hours]
	FROM #failureHours
) T

SELECT 
	[TicketString],
	[Serial Number],
	[Hours Run],
	[Prior Hours],
	[Failure],
	IIF([Hours Run] - [Prior Hours] < 0, [Hours Run], [Hours Run] - [Prior Hours]) AS [Hours Inc]
INTO #lookUpHours
FROM #numericHours

SELECT 
	C.[Customer Id],
	C.[Customer Name],
	C.[RMA],
	R.[CreatedDate],
	R.[Status],
	C.[Complaint],
	SUBSTRING(
		(
			SELECT
				','+[Failure Mode]  AS [text()]
			FROM #complaintRMAs C2
			WHERE C2.[Complaint] = C.[Complaint] AND C2.[SerialNoEst] = C.[SerialNoEst]
			ORDER BY C2.[Complaint]
			FOR XML PATH ('')
		), 2, 1000) AS [Complaint Failure Mode],
	R.[Serial Number],
	R.[RMA Type],
	R.[Disposition],
	R.[Early Failure Type],
	R.[Hours Run],
	R.[Root Cause Part Number]
INTO #bestMatch
FROM #rma R INNER JOIN #complaintRMAs C
	ON R.[Complaint Number] = C.[Complaint] AND R.[TicketString] = C.[RMA] AND R.[Serial Number] = C.[SerialNoEst]
GROUP BY
	C.[Customer Id],
	C.[Customer Name],
	C.[RMA],
	R.[CreatedDate],
	R.[Status],
	C.[Complaint],
	C.[SerialNoEst],
	C.[Failure Mode],
	R.[Serial Number],
	R.[RMA Type],
	R.[Disposition],
	R.[Early Failure Type],
	R.[Hours Run],
	R.[Root Cause Part Number]

SELECT 
	R.[Customer Id],
	C.[Customer Name],
	R.[TicketString] AS [RMA],
	R.[CreatedDate],
	R.[Status],
	R.[Complaint Number] AS [Complaint],
	SUBSTRING(
		(
			SELECT
				','+[Failure Mode]  AS [text()]
			FROM #complaintRMAs C2
			WHERE C2.[Complaint] = C.[Complaint] AND C2.[SerialNoEst] = C.[SerialNoEst]
			ORDER BY C2.[Complaint]
			FOR XML PATH ('')
		), 2, 1000) AS [Complaint Failure Mode],
	R.[Serial Number],
	R.[RMA Type],
	R.[Disposition],
	R.[Early Failure Type],
	R.[Hours Run],
	R.[Root Cause Part Number]
INTO #secondMatch
FROM #rma R INNER JOIN #complaintRMAs C
	ON R.[Complaint Number] = C.[Complaint]
WHERE R.[TicketString] NOT IN (SELECT [RMA] FROM #bestMatch) AND ISNUMERIC(C.[Complaint]) = 1
GROUP BY
	R.[Customer Id],
	C.[Customer Name],
	R.[TicketString],
	R.[CreatedDate],
	R.[Status],
	R.[Complaint Number],
	C.[Complaint],
	C.[SerialNoEst],
	C.[Failure Mode],
	R.[Serial Number],
	R.[RMA Type],
	R.[Disposition],
	R.[Early Failure Type],
	R.[Hours Run],
	R.[Root Cause Part Number]

SELECT 
	R.[Customer Id],
	ISNULL(MAX(C.[CustName]),'No Complaint Data') AS [Customer Name],
	R.[TicketString] AS [RMA],
	R.[CreatedDate],
	R.[Status],
	R.[Complaint Number] AS [Complaint],
	'No Complaint Data' AS [Complaint Failure Mode],
	R.[Serial Number],
	R.[RMA Type],
	R.[Disposition],
	R.[Early Failure Type],
	R.[Hours Run],
	R.[Root Cause Part Number]
INTO #leftOver
FROM #rma R LEFT JOIN 
(
	SELECT DISTINCT 
		[CustID],
		[CustName]
	FROM [SQL1-RO].[mas500_app].[dbo].[vdvCustomer]
) C 
	ON R.[Customer Id] = C.[CustID]
WHERE R.[TicketString] NOT IN (SELECT [RMA] FROM #bestMatch) AND R.[TicketString] NOT IN (SELECT [RMA] FROM #secondMatch)
GROUP BY
	R.[Customer Id],
	R.[TicketString],
	R.[CreatedDate],
	R.[Status],
	R.[Complaint Number],
	R.[Serial Number],
	R.[RMA Type],
	R.[Disposition],
	R.[Early Failure Type],
	R.[Hours Run],
	R.[Root Cause Part Number]

SELECT 
	REPLACE(T.[Customer Id],' ','') AS [Customer Id],
	T.[Customer Name],
	CAST(T.[CreatedDate] AS DATE) AS [Date Created],
	T.[Complaint] AS [Related Complaint],
	T.[RMA],
	T.[Status],
	T.[Serial Number],
	T.[Complaint Failure Mode],
	T.[RMA Type],
	T.[Disposition],
	T.[Early Failure Type],
	T.[Root Cause Part Number],
	MAX(L.[Hours Inc]) AS [Runs Since Last Failure]
FROM
(
	SELECT 
		[Customer Id],
		[Customer Name],
		[RMA],
		[CreatedDate],
		[Status],
		[Complaint],
		[Complaint Failure Mode],
		[Serial Number],
		[RMA Type],
		[Disposition],
		[Early Failure Type],
		[Hours Run],
		[Root Cause Part Number]
	FROM
	(
		SELECT *
		FROM #bestMatch
		UNION
		SELECT *
		FROM #secondMatch
		UNION
		SELECT *
		FROM #leftOver
	) T
	GROUP BY
		[Customer Id],
		[Customer Name],
		[RMA],
		[CreatedDate],
		[Status],
		[Complaint],
		[Complaint Failure Mode],
		[Serial Number],
		[RMA Type],
		[Disposition],
		[Early Failure Type],
		[Hours Run],
		[Root Cause Part Number]
) T INNER JOIN #lookUpHours L
	ON T.[RMA] = L.[TicketString]
WHERE T.[CreatedDate] > CONVERT(DATETIME, '2014-11-01') --AND [Customer Name] LIKE 'No Complaint Data'
GROUP BY
	T.[Customer Id],
	T.[Customer Name],
	T.[CreatedDate],
	T.[Complaint],
	T.[RMA],
	T.[Status],
	T.[Serial Number],
	T.[Complaint Failure Mode],
	T.[RMA Type],
	T.[Disposition],
	T.[Early Failure Type],
	T.[Root Cause Part Number]
ORDER BY CAST([RMA] AS INT)

DROP TABLE #ObjectsComplaint, #ObjectsRMA, #PropertiesComplaint, #PropertiesRMA, #complaintRMAs, #rma, #bestMatch, #failureHours, #failures, #lookUpHours, #numericHours, #secondMatch, #leftOver
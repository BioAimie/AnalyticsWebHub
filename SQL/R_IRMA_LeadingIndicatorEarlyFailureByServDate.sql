SET NOCOUNT ON

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[RecordedValue] AS [Title]
INTO #complaint
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] = 'COMPLAINT' AND [PropertyName] = 'Complaint Title'

SELECT 
	[TicketId],
	[RecordedValue] AS [FailureMode]
INTO #failure
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] = 'COMPLAINT' AND [ObjectName] = 'BFDX Part Number' AND [PropertyName] = 'Failure Mode'

SELECT 
	[TicketId],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #relatedRMA
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] = 'COMPLAINT' AND [ObjectName] = 'Related RMAs'

SELECT 
	SUBSTRING(C.[TicketString],CHARINDEX('-',C.[TicketString],1)+1,6) AS [Complaint],
	C.[CreatedDate],
	C.[Title],
	IIF(C.[Title] LIKE '%SDOA%', 'SDOA',
		IIF(C.[Title] LIKE '%DOA%', 'DOA',
		IIF(C.[Title] LIKE '%SELF%', 'SELF',
		IIF(C.[Title] LIKE '% ELF%', 'ELF', NULL)))) AS [FailType],
	IIF(CHARINDEX('V0',C.[Title])<>0, SUBSTRING(C.[Title], CHARINDEX('V0',C.[Title],1), 4),
		IIF(CHARINDEX('T0',C.[Title])<>0, SUBSTRING(C.[Title], CHARINDEX('T0',C.[Title],1), 4),
		IIF(CHARINDEX('M0',C.[Title])<>0, SUBSTRING(C.[Title], CHARINDEX('M0',C.[Title],1), 4), NULL))) AS [ErrorInTitle],
	IIF(CHARINDEX('V0',C.[Title], CHARINDEX('V0',C.[Title],1)+4)<>0, SUBSTRING(C.[Title], CHARINDEX('V0',C.[Title], CHARINDEX('V0',C.[Title],1)+4), 4), NULL) AS [PressureError2],
	IIF(CHARINDEX('2FA', C.[Title], 1)<>0, SUBSTRING(C.[Title], CHARINDEX('2FA', C.[Title], 1), 8),
		IIF(CHARINDEX('FA', C.[Title], 1)<>0, SUBSTRING(C.[Title], CHARINDEX('FA', C.[Title], 1), 6), NULL)) AS [TitleSerialNo],
	IIF(CHARINDEX('-1-',F.[FailureMode],1)<>0, SUBSTRING(F.[FailureMode],1,CHARINDEX('-1-',F.[FailureMode],1)-1), NULL) AS [FailureMode],
	R.[RMA],
	IIF(CHARINDEX('2FA', R.[Description], 1)<>0, SUBSTRING(R.[Description], CHARINDEX('2FA', R.[Description], 1), 8),
		IIF(CHARINDEX('FA', R.[Description], 1)<>0, SUBSTRING(R.[Description], CHARINDEX('FA', R.[Description], 1), 6),
		IIF(CHARINDEX('HTP', R.[Description], 1)<>0, SUBSTRING(R.[Description], CHARINDEX('HTP', R.[Description], 1), 6), 
		IIF(CHARINDEX('KTM', R.[Description], 1)<>0, SUBSTRING(R.[Description], CHARINDEX('KTM', R.[Description], 1), 8), 
		IIF(CHARINDEX('TM', R.[Description], 1)<>0, CONCAT('K', SUBSTRING(R.[Description], CHARINDEX('TM', R.[Description], 1), 7)), NULL))))) AS [SerialNo]  
INTO #complexComplaint
FROM #complaint C LEFT JOIN #failure F
	ON C.[TicketId] = F.[TicketId] LEFT JOIN 
	(
		SELECT 
			[TicketId],
			[RMA],
			[Description]
		FROM #relatedRMA R
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
--WHERE LEFT(R.[Description] , 2) IN ('FA','2F','KT','TM','HT')
WHERE [FailureMode] LIKE '%-1-%' OR [Title] LIKE '% V0% Err%' OR [Title] LIKE '% M0% Err%' OR [Title] LIKE '% T0% Err%'

SELECT *
INTO #rmaAll
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] O WITH(NOLOCK)
WHERE [Tracker] = 'RMA' AND [ObjectName] = 'Part Information'

SELECT 
	SUBSTRING(S.[TicketString], CHARINDEX('-',S.[TicketString],1)+1,6) AS [RMA],
	P.[PartNo],
	S.[SerialNo],
	S.[Complaint],
	F.[FailureType],
	D.[ServiceDate]
INTO #rmaInfo
FROM
(
	SELECT 
		P.[TicketId],
		P.[TicketString],
		P.[RecordedValue] AS [Complaint],
		O.[ObjectId],
		REPLACE(REPLACE(REPLACE(O.[RecordedValue],' ',''),'_',''),'-','') AS [SerialNo]
	FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] P WITH(NOLOCK) INNER JOIN #rmaAll O WITH(NOLOCK)
		ON P.[TicketId] = O.[TicketId]
	WHERE O.[Tracker] = 'RMA' AND O.[ObjectName] = 'Part Information' AND O.[PropertyName] = 'Lot/Serial Number' AND P.[PropertyName] = 'Complaint Number'
) S LEFT JOIN 
(
	SELECT 
		[TicketId],
		[ObjectId],
		[RecordedValue] AS [PartNo]
	FROM #rmaAll WITH(NOLOCK)
	WHERE [Tracker] = 'RMA' AND [ObjectName] = 'Part Information' AND [PropertyName] = 'Part Number'
) P 
	ON S.[TicketId] = P.[TicketId] AND S.[ObjectId] = P.[ObjectId] LEFT JOIN
(
	SELECT 
		[TicketId],
		[ObjectId],
		[RecordedValue] AS [FailureType]
	FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
	WHERE [Tracker] = 'RMA' AND [ObjectName] = 'Part Information' AND [PropertyName] = 'Early Failure Type'
) F
	ON P.[TicketId] = F.[TicketId] AND P.[ObjectId] = F.[ObjectId] LEFT JOIN
(
	SELECT
		[TicketId],
		CAST([RecordedValue] AS DATE) AS [ServiceDate]
	FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK) 
	WHERE [Tracker] = 'RMA' AND [PropertyName] = 'Service Completed' AND [RecordedValue] IS NOT NULL
) D
	ON P.[TicketId] = D.[TicketId]

SELECT 
	C.[Complaint],
	R.[ServiceDate],
	C.[SerialNo],
	C.[RMA],
	ISNULL([EarlyFailType], [FailureType]) AS [EarlyFailureType],
	C.[Failure]	
INTO #greatMatch
FROM
(
	SELECT 
		[Complaint],
		[CreatedDate],
		[FailType] AS [EarlyFailType],
		IIF([ErrorInTitle] IS NOT NULL AND [PressureError2] IS NOT NULL, CONCAT([ErrorInTitle],', ',[PressureError2]),
			IIF([ErrorInTitle] IS NOT NULL, [ErrorInTitle], [FailureMode])) AS [Failure],
		[RMA],
		[SerialNo]
	FROM #complexComplaint
	GROUP BY 
		[Complaint],
		[CreatedDate],
		[FailType],
		[ErrorInTitle],
		[PressureError2],
		[FailureMode],
		[RMA],
		[SerialNo]
) C INNER JOIN 
(
	SELECT 
		[ServiceDate],
		[RMA],
		IIF(LEFT([SerialNo],2) LIKE 'FA', SUBSTRING([SerialNo],1,6),
			IIF(LEFT([SerialNo],2) LIKE '2F', SUBSTRING([SerialNo],1,8), 
			IIF(LEFT([SerialNo],2) LIKE 'HT', SUBSTRING([SerialNo],1,6), 
			IIF(LEFT([SerialNo],2) LIKE 'TM', CONCAT('K', SUBSTRING([SerialNo],1,7)), 
			IIF(LEFT([SerialNo],2) LIKE 'KT', SUBSTRING([SerialNo],1,8), [SerialNo]))))) AS [SerialNo],
		[Complaint],
		[FailureType]
	FROM #rmaInfo
	WHERE LEFT([SerialNo],2) IN ('FA','2F','KT','TM','HT') AND ISNUMERIC([Complaint]) = 1
) R
	ON C.[Complaint] = R.[Complaint] AND C.[RMA] = R.[RMA] AND C.[SerialNo] = R.[SerialNo]

SELECT
	C.[Complaint],
	R.[ServiceDate],
	ISNULL(C.[SerialNo], R.[SerialNo]) AS [SerialNo],
	C.[RMA],
	ISNULL([EarlyFailType], [FailureType]) AS [EarlyFailureType],
	C.[Failure]
INTO #secondBestMatch
FROM
(
	SELECT 
		[Complaint],
		[CreatedDate],
		[FailType] AS [EarlyFailType],
		IIF([ErrorInTitle] IS NOT NULL AND [PressureError2] IS NOT NULL, CONCAT([ErrorInTitle],', ',[PressureError2]),
			IIF([ErrorInTitle] IS NOT NULL, [ErrorInTitle], [FailureMode])) AS [Failure],
		[RMA],
		[SerialNo]
	FROM #complexComplaint
	GROUP BY 
		[Complaint],
		[CreatedDate],
		[FailType],
		[ErrorInTitle],
		[PressureError2],
		[FailureMode],
		[RMA],
		[SerialNo]
) C INNER JOIN 
(
		SELECT 
		[ServiceDate],
		[RMA],
		IIF(LEFT([SerialNo],2) LIKE 'FA', SUBSTRING([SerialNo],1,6),
			IIF(LEFT([SerialNo],2) LIKE '2F', SUBSTRING([SerialNo],1,8), 
			IIF(LEFT([SerialNo],2) LIKE 'HT', SUBSTRING([SerialNo],1,6), 
			IIF(LEFT([SerialNo],2) LIKE 'TM', CONCAT('K', SUBSTRING([SerialNo],1,7)), 
			IIF(LEFT([SerialNo],2) LIKE 'KT', SUBSTRING([SerialNo],1,8), [SerialNo]))))) AS [SerialNo],
		[Complaint],
		[FailureType]
	FROM #rmaInfo
	WHERE LEFT([SerialNo],2) IN ('FA','2F','KT','TM','HT') AND ISNUMERIC([Complaint]) = 1
) R
	ON C.[Complaint] = R.[Complaint] AND C.[RMA] = R.[RMA]
WHERE C.[Complaint] NOT IN (SELECT [Complaint] FROM #greatMatch) 

SELECT
	C.[Complaint],
	R.[ServiceDate],
	C.[SerialNo],
	ISNULL(C.[RMA],R.[RMA]) AS [RMA],
	ISNULL(C.[EarlyFailType], R.[FailureType]) AS [EarlyFailureType],
	C.[Failure]
INTO #thirdBestMatch
FROM
(
	SELECT 
		[Complaint],
		[CreatedDate],
		[FailType] AS [EarlyFailType],
		IIF([ErrorInTitle] IS NOT NULL AND [PressureError2] IS NOT NULL, CONCAT([ErrorInTitle],', ',[PressureError2]),
			IIF([ErrorInTitle] IS NOT NULL, [ErrorInTitle], [FailureMode])) AS [Failure],
		[RMA],
		[SerialNo]
	FROM #complexComplaint
	GROUP BY 
		[Complaint],
		[CreatedDate],
		[FailType],
		[ErrorInTitle],
		[PressureError2],
		[FailureMode],
		[RMA],
		[SerialNo]
) C INNER JOIN 
(
		SELECT 
		[ServiceDate],
		[RMA],
		IIF(LEFT([SerialNo],2) LIKE 'FA', SUBSTRING([SerialNo],1,6),
			IIF(LEFT([SerialNo],2) LIKE '2F', SUBSTRING([SerialNo],1,8), 
			IIF(LEFT([SerialNo],2) LIKE 'HT', SUBSTRING([SerialNo],1,6), 
			IIF(LEFT([SerialNo],2) LIKE 'TM', CONCAT('K', SUBSTRING([SerialNo],1,7)), 
			IIF(LEFT([SerialNo],2) LIKE 'KT', SUBSTRING([SerialNo],1,8), [SerialNo]))))) AS [SerialNo],
		[Complaint],
		[FailureType]
	FROM #rmaInfo
	WHERE LEFT([SerialNo],2) IN ('FA','2F','KT','TM','HT') AND ISNUMERIC([Complaint]) = 1
) R
	ON C.[Complaint] = R.[Complaint] AND C.[SerialNo] = R.[SerialNo]
WHERE C.[Complaint] NOT IN (SELECT [Complaint] FROM #greatMatch)
		AND C.[Complaint] NOT IN (SELECT [Complaint] FROM #secondBestMatch)

SELECT
	C.[Complaint],
	R.[ServiceDate],
	ISNULL(C.[SerialNo], R.[SerialNo]) AS [SerialNo],
	ISNULL(C.[RMA],R.[RMA]) AS [RMA],
	ISNULL([EarlyFailType], [FailureType]) AS [EarlyFailureType],
	C.[Failure]
INTO #fourthBestMatch
FROM
(
	SELECT 
		[Complaint],
		[CreatedDate],
		[FailType] AS [EarlyFailType],
		IIF([ErrorInTitle] IS NOT NULL AND [PressureError2] IS NOT NULL, CONCAT([ErrorInTitle],', ',[PressureError2]),
			IIF([ErrorInTitle] IS NOT NULL, [ErrorInTitle], [FailureMode])) AS [Failure],
		[RMA],
		[SerialNo]
	FROM #complexComplaint
	GROUP BY 
		[Complaint],
		[CreatedDate],
		[FailType],
		[ErrorInTitle],
		[PressureError2],
		[FailureMode],
		[RMA],
		[SerialNo]
) C INNER JOIN 
(
		SELECT 
		[ServiceDate],
		[RMA],
		IIF(LEFT([SerialNo],2) LIKE 'FA', SUBSTRING([SerialNo],1,6),
			IIF(LEFT([SerialNo],2) LIKE '2F', SUBSTRING([SerialNo],1,8), 
			IIF(LEFT([SerialNo],2) LIKE 'HT', SUBSTRING([SerialNo],1,6), 
			IIF(LEFT([SerialNo],2) LIKE 'TM', CONCAT('K', SUBSTRING([SerialNo],1,7)), 
			IIF(LEFT([SerialNo],2) LIKE 'KT', SUBSTRING([SerialNo],1,8), [SerialNo]))))) AS [SerialNo],
		[Complaint],
		[FailureType]
	FROM #rmaInfo
	WHERE LEFT([SerialNo],2) IN ('FA','2F','KT','TM','HT') AND ISNUMERIC([Complaint]) = 1
) R
	ON C.[Complaint] = R.[Complaint]
WHERE C.[Complaint] NOT IN (SELECT [Complaint] FROM #greatMatch)
		AND C.[Complaint] NOT IN (SELECT [Complaint] FROM #secondBestMatch) AND C.[Complaint] NOT IN (SELECT [Complaint] FROM #thirdBestMatch)

SELECT 
	ROW_NUMBER() OVER(PARTITION BY [SerialNo] ORDER BY [ServiceDate]) AS [VisitNo], 
	[SerialNo],
	[ServiceDate],
	[EarlyFailureType] AS [Key],
	CASE [Failure]
		WHEN 'V040' THEN 'Bead Beater Error'
		WHEN 'V040 Bead Motor Stall' THEN 'Bead Beater Error'
		WHEN 'Failure To Plunge' THEN 'Failure To Plunge'
		WHEN 'T031' THEN 'Fluorimeter Failure'
		WHEN 'Loose/Missing Fastener' THEN 'Loose/Missing Fastener'
		WHEN 'M012 Valve Controller Error' THEN 'Other Board Failure'
		WHEN 'M035' THEN 'Other Board Failure'
		WHEN 'V046' THEN 'Other Board Failure'
		WHEN 'Other Instrument Error' THEN 'Other Instrument Error'
		WHEN 'M022 Lid Lock' THEN 'Pouch Loading Area'
		WHEN 'Pouch Chamber Obstruction' THEN 'Pouch Loading Area'
		WHEN 'Pouch Holder' THEN 'Pouch Loading Area'
		WHEN 'Pouch Sensor' THEN 'Pouch Loading Area'
		WHEN 'V019' THEN 'Pressure Error'
		WHEN 'V019, V030' THEN 'Pressure Error'
		WHEN 'V019, V030, V039, V041 Pressure Error' THEN 'Pressure Error'
		WHEN 'V030' THEN 'Pressure Error'
		WHEN 'V030, V039' THEN 'Pressure Error'
		WHEN 'V039' THEN 'Pressure Error'
		WHEN 'V039, V019' THEN 'Pressure Error'
		WHEN 'V039, V030' THEN 'Pressure Error'
		WHEN 'V039, V041' THEN 'Pressure Error'
		WHEN 'V041' THEN 'Pressure Error'
		WHEN 'V041, V039' THEN 'Pressure Error'
		WHEN 'V045' THEN 'Pressure Error'
		WHEN 'V033' THEN 'Seal Bar Error'
		WHEN 'V033, V042, V043 Seal Bar Errors' THEN 'Seal Bar Error'
		WHEN 'V043' THEN 'Seal Bar Error'
		WHEN 'T032' THEN 'Temperature Control Error'
		WHEN 'T032 Temp Timeout Error' THEN 'Temperature Control Error'
		WHEN '7003 Failed Excitation Check' THEN 'Optics'
		ELSE 'Other'
	END AS [RecordedValue],
	1 AS [Record]
INTO #visitNo
FROM
(
	SELECT *
	FROM #greatMatch 
	UNION
	SELECT *
	FROM #secondBestMatch
	UNION
	SELECT *
	FROM #thirdBestMatch
	UNION
	SELECT *
	FROM #fourthBestMatch
) D
ORDER BY [SerialNo], [ServiceDate]

SELECT *,
	LAG([ServiceDate]) OVER(PARTITION BY [SerialNo] ORDER BY [VisitNo]) AS [PriorServiceDate]
INTO #lagged
FROM #visitNo

SELECT 
	[VisitNo],
	UPPER([SerialNo]) AS [SerialNo], 
	[ServiceDate], 
	[PriorServiceDate],
	[Key],
	[RecordedValue],
	[Record]
INTO #key
FROM #lagged
WHERE [Key] IN ('SELF', 'SDOA') 
	AND [PriorServiceDate] IS NOT NULL
ORDER BY [SerialNo], [ServiceDate] 

SELECT
	MAX([VisitNo]) AS [LastVisit], 
	[SerialNo]
INTO #lastvisit
FROM #key 
GROUP BY [SerialNo] 

SELECT 
	YEAR([PriorServiceDate]) AS [Year],
	MONTH([PriorServiceDate]) AS [Month],
	DATEPART(ww,[PriorServiceDate]) AS [Week],
	[Key],
	[RecordedValue],
	[Record] 
FROM #lastvisit l INNER JOIN #key k
	ON l.[LastVisit] = k.[VisitNo] AND l.[SerialNo] = k.[SerialNo]

DROP TABLE #complaint, #failure, #relatedRMA, #complexComplaint, #rmaAll, #rmaInfo, #greatMatch, #secondBestMatch, #thirdBestMatch, #fourthBestMatch,
	#visitNo, #lagged, #key, #lastvisit

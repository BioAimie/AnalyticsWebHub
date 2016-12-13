SET NOCOUNT ON

SELECT 
	REPLACE(REPLACE(REPLACE(UPPER([LotNumber]),' ',''),'_',''),'-','') AS [LotNumber],
	[PartNumber],
	[DateOfManufacturing]
INTO #birthDate
FROM [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK)
	ON P.[PartNumberId] = L.[PartNumberId]
WHERE [PartNumber] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-ASY-0003','HTFA-SUB-0103') AND [DateOfManufacturing] > CONVERT(datetime,'2014-06-01')

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #partInfo
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Part Information'

SELECT
	[TicketId],
	[TicketString],
	[CreatedDate],
	[PropertyName],
	[RecordedValue]
INTO #freePropPivrops
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] IN ('Hours Run','Complaint Number','RMA Type','RMA Title','System Failure') 

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[Part Number], 
	REPLACE(REPLACE(REPLACE(UPPER([Lot/Serial Number]),' ',''),'_',''),'-','') AS [SerialNo],
	[Early Failure Type] AS [CustFailType]
INTO #partInfoPiv
FROM
(
	SELECT *
	FROM #partInfo
) P
PIVOT(
	MAX([RecordedValue])
	FOR [PropertyName] 
	IN
	(
		[Part Number],
		[Lot/Serial Number],
		[Early Failure Type]
	)
) PIV
WHERE LEFT([Part Number],3) IN ('FLM','HTF')

SELECT 
	[TicketId],
	[RMA Type] AS [Type],
	[RMA Title] AS [Title],
	[Complaint Number] AS [Complaint],
	[System Failure] AS [SystemFailure],
	REPLACE([Hours Run],',','') AS [HoursRun]
INTO #freePropPiv
FROM 
(
	SELECT *
	FROM #freePropPivrops
) P
PIVOT
(
	MAX([RecordedValue])
	FOR [PropertyName]
	IN
	(
		[RMA Type],
		[RMA Title],
		[Complaint Number],
		[System Failure],
		[Hours Run]
	)
) PIV

SELECT
	[LotNumber] AS [SerialNo],
	[PartNumber] AS [PartNo],
	[DateOfManufacturing] AS [BirthDate],
	[TicketString],
	P.[TicketId],
	[CreatedDate],
	[Part Number],
	[Title],
	[CustFailType],
	[Type],
	CAST([HoursRun] AS FLOAT) AS [HoursRun],
	IIF([Type] LIKE '% - Failure', 1, 0) AS [FailureType],
	IIF([SystemFailure] = 'True', 1, 0) AS [FailCheck],
	IIF([CustFailType] IN ('DOA','ELF'), 1, 0) AS [CustFailTypeProd],
	IIF(CAST([HoursRun] AS FLOAT) < 100.0001, 1, 0) AS [HoursRunLow],
	IIF([Title] LIKE '% error%' OR [Title] LIKE '% fail%' OR [Title] LIKE '% DOA%' OR [Title] LIKE '% ELF%',1, 0) AS [TitleFail],
	IIF(ISNUMERIC([Complaint])=1, 1, 0) AS [Complaint]
INTO #flaggedForFailures
FROM #birthDate B LEFT JOIN #partInfoPiv P
	ON B.[LotNumber] = P.[SerialNo] LEFT JOIN #freePropPiv F
		ON P.[TicketId] = F.[TicketId]
WHERE [HoursRun] NOT LIKE 'N%A' AND [HoursRun] IS NOT NULL

SELECT 
	[SerialNo],
	IIF(LEFT([PartNo],4) LIKE 'FLM2','FA2.0',
		IIF(LEFT([PartNo],4) LIKE 'FLM1','FA1.5','Torch')) AS [Version],
	YEAR([BirthDate]) AS [Year],
	DATEPART(ww,[BirthDate]) AS [Week],
	[TicketId],
	[TicketString],
	[CreatedDate],
	[HoursRun],
	IIF([FailureType] = 1 AND [HoursRunLow] = 1, 1,
		IIF([FailCheck] = 1 AND [HoursRunLow] = 1, 1,
		IIF([CustFailTypeProd] = 1 AND [HoursRunLow] = 1, 1,
		IIF([CustFailTypeProd] = 1 AND [HoursRun] IS NULL, 1,
		IIF([TitleFail] = 1 AND [HoursRunLow] = 1, 1, 
		IIF([Complaint] = 1 AND [Title] NOT LIKE '%loaner%' AND [HoursRunLow] = 1, 1, 0)))))) AS [Failure]
INTO #master
FROM #flaggedForFailures

SELECT 
	[SerialNo],
	[Version],
	[Year],
	[Week],
	[TicketId],
	[TicketString],
	[Failure]
INTO #firstFailure
FROM #master WHERE [TicketId] IN 
(
	SELECT
		MIN([TicketId]) AS [TicketId]
	FROM #master
	WHERE [TicketString] IS NOT NULL
	GROUP BY [SerialNo]
) OR [TicketString] IS NULL

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #bfdxParts
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'BFDX Part Number'

SELECT 
	[TicketId],
	[TicketString],
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(UPPER([Lot/Serial Number]),',',''),' ',''),'.',''),'_',''),'-','') AS [SerialNo],
	SUBSTRING([Failure Mode], 1, CHARINDEX('-',[Failure Mode],1)-1) AS [Complaint]
INTO #complaints
FROM
(
	SELECT 
		[TicketId],
		[TicketString],
		[CreatedDate],
		[ObjectId],
		[PropertyName],
		[RecordedValue]
	FROM #bfdxParts
) P
PIVOT
(
	MAX([RecordedValue])
	FOR [PropertyName]
	IN
	(
		[Lot/Serial Number],
		[Failure Mode]
	)
) PIV
WHERE [Failure Mode] LIKE '%-1-%'

SELECT 
	F.[SerialNo],
	F.[Version],
	F.[Year],
	F.[Week],
	C.[TicketString],
	ISNULL(C.[Complaint], 'No Complaint') AS [Complaint]
INTO #combined
FROM
(
	SELECT
		[SerialNo],
		[Version],
		[Year],
		[Week],
		1 AS [Record]
	FROM #firstFailure
	WHERE [Failure] = 1
	GROUP BY 
		[SerialNo],
		[Version],
		[Year],
		[Week]
) F LEFT JOIN 
(
	SELECT 
		C1.[SerialNo],
		C1.[TicketString],
		IIF(C1.[Complaint] LIKE '%Pressure Error%', 'Pressure Errors',
			IIF(C1.[Complaint] LIKE '%Seal Bar%', 'Seal Bar Errors',
			IIF(C1.[Complaint] LIKE '%Lid Lock%', 'Lid Lock Errors',
			IIF(C1.[Complaint] LIKE '%Bead Motor Stall%', 'Bead Beater Stall',
			IIF(C1.[Complaint] LIKE '%7003%', 'LED Excitation Error',
			IIF(C1.[Complaint] LIKE '%Temp %', 'Temp Timeout Errors', C1.[Complaint])))))) AS [Complaint]
	FROM #complaints C1 INNER JOIN
	(
		SELECT 
			[SerialNo],
			MIN([TicketId]) AS [TicketId]
		FROM #complaints 
		GROUP BY [SerialNo]
	) C2
		ON C1.[TicketId] = C2.[TicketId]
) C
	ON F.[SerialNo] = C.[SerialNo]
ORDER BY [Year], [Week]

SELECT 
	C.[Year],
	C.[Week],
	CONCAT(C.[Complaint], ' ', CONCAT(ROUND(100*CAST(C.[Record] AS FLOAT)/CAST(A.[Record] AS FLOAT), 0),'%')) AS [Label]
INTO #labels
FROM
(
	SELECT 
		[Year],
		[Week],
		[Complaint],
		COUNT([SerialNo]) AS [Record]
	FROM #combined
	GROUP BY [Year], [Week], [Complaint]
) C LEFT JOIN 
(
	SELECT
		[Year],
		[Week],
		COUNT([SerialNo]) AS [Record]
	FROM #combined
	GROUP BY [Year], [Week]
) A
	ON C.[Year] = A.[Year] AND C.[Week] = A.[Week]

SELECT DISTINCT
	IIF(L2.[Week] < 10, CONCAT(L2.[Year], '-0', L2.[Week]), CONCAT(L2.[Year], '-', L2.[Week])) AS [DateGroup],
	SUBSTRING(
		(
			SELECT
				',' + L1.[Label] AS [text()]
			FROM #labels L1
			WHERE L1.[Year] = L2.[Year] AND L1.[Week] = L2.[Week]
			ORDER BY L1.[Label]
			FOR XML PATH('')
		), 2, 1000) AS [Annotation]
FROM #labels L2

DROP TABLE #birthDate, #partInfo, #freePropPivrops, #partInfoPiv, #freePropPiv, #flaggedForFailures, #master, #firstFailure, #complaints, #combined, #labels, #bfdxParts
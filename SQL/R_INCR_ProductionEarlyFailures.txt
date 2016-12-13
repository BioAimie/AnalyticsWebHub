SET NOCOUNT ON

SELECT 
	REPLACE(REPLACE(REPLACE(REPLACE([LotNumber],'_',''),'-',''),'.',''),' ','') AS [LotNumber],
	[PartNumber],
	[DateOfManufacturing]
INTO #birthDate
FROM [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK)
	ON P.[PartNumberId] = L.[PartNumberId]
WHERE [PartNumber] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-SUB-0103','HTFA-ASY-0003','HTFA-SUB-0103') AND [DateOfManufacturing] > CONVERT(datetime,'2014-06-01')

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
	UPPER(REPLACE([Lot/Serial Number],' ','')) AS [SerialNo],
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
	[System Failure] AS [FailCheck],
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
	IIF([Title] LIKE '% error%' OR [Title] LIKE '% fail%' OR [Title] LIKE '%DOA%' OR [Title] LIKE '%ELF%',1, 0) AS [TitleFail],
	IIF(ISNUMERIC([Complaint])=1, 1, 0) AS [Complaint]
INTO #flaggedForFailures
FROM #birthDate B LEFT JOIN #partInfoPiv P
	ON B.[LotNumber] = P.[SerialNo] LEFT JOIN #freePropPiv F
		ON P.[TicketId] = F.[TicketId]
WHERE [HoursRun] NOT LIKE 'N%A' AND [HoursRun] IS NOT NULL

SELECT 
	IIF(LEFT([SerialNo],2) LIKE 'TM', CONCAT('K',[SerialNo]), [SerialNo]) AS [SerialNo], 
	IIF(LEFT([PartNo],4) LIKE 'FLM2','FA2.0',
		IIF(LEFT([PartNo],4) LIKE 'FLM1','FA1.5','Torch')) AS [Version],
	[BirthDate],
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
	[CreatedDate],
	[BirthDate],
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
	[SerialNo],
	[Version],
	[Year],
	[Week],
	DATEDIFF(ww, [BirthDate], [CreatedDate]) AS [DeltaWeeks],
	'InternallyFlaggedFailure' AS [Key],
	1 AS [Record]
FROM #firstFailure
WHERE [Failure] = 1

DROP TABLE #birthDate, #partInfo, #freePropPivrops, #partInfoPiv, #freePropPiv, #flaggedForFailures, #master, #firstFailure
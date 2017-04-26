SET NOCOUNT ON

SELECT 
	REPLACE(REPLACE(REPLACE(REPLACE(L.[LotNumber],' ',''),'_',''),'-',''),'.','') AS [LotNo],
	IIF(LEFT(P.[PartNumber],4) IN ('FLM2','HTFA'), SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(L.[LotNumber],' ',''),'_',''),'-',''),'.',''), 1, 8),
		SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(L.[LotNumber],' ',''),'_',''),'-',''),'.',''), 1, 6)) AS [SerialNo],
	P.[PartNumber],
	L.[DateOfManufacturing],
	L.[VersionId],
	IIF(L.[VersionId] IN ('IP','01','02','03','05','FrNew'), 1, 0) AS [New]
INTO #cleanSerials
FROM [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK)
	ON L.[PartNumberId] = P.[PartNumberId]
WHERE (P.[PartNumber] LIKE 'FLM%-ASY-0001%' OR P.[PartNumber] LIKE 'HTFA-ASY-0003%' OR P.[PartNumber] = 'HTFA-SUB-0103') 

SELECT 
	[SerialNo],
	MIN([DateOfManufacturing]) AS [DateOfManufacturing]
INTO #birthDate
FROM
(
	SELECT 
		[LotNo],
		IIF([SerialNo] LIKE '%R', SUBSTRING([SerialNo],1, PATINDEX('%R',[SerialNo])-1), [SerialNo]) AS [SerialNo],
		[PartNumber],
		[DateOfManufacturing],
		[VersionId],
		[New] 
	FROM #cleanSerials
) T
WHERE [New] = 1
GROUP BY [SerialNo]

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #partInfo
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Part Information' AND [Tracker] LIKE 'RMA' 

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[PropertyName],
	[RecordedValue]
INTO #freePropPivrops
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] IN ('Hours Run','Complaint Number','RMA Type','RMA Title','System Failure') AND [Tracker] LIKE 'RMA' 

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
	B.[SerialNo],
	[DateOfManufacturing] AS [BirthDate],
	[TicketString],
	P.[TicketId],
	[CreatedDate],
	[Part Number] AS [PartNo],
	[Title],
	[CustFailType],
	[Type],
	CAST([HoursRun] AS FLOAT) AS [HoursRun],
	IIF([Type] LIKE '% - Failure', 1, 0) AS [FailureType],
	IIF([FailCheck] = 'True', 1, 0) AS [FailCheck],
	IIF([CustFailType] IN ('DOA','ELF'), 1, 0) AS [CustFailTypeProd],
	IIF(CAST([HoursRun] AS FLOAT) < 100.0001, 1, 0) AS [HoursRunLow],
	IIF([Title] LIKE '% error%' OR [Title] LIKE '% fail%' OR [Title] LIKE '%DOA%' OR [Title] LIKE '%ELF%',1, 0) AS [TitleFail],
	IIF(ISNUMERIC([Complaint])=1, 1, 0) AS [Complaint],
	IIF(ISNUMERIC(F.[Complaint]) = 1 AND F.[Title] LIKE '%loaner%', 1,
		IIF(ISNUMERIC(F.[Complaint]) = 1 AND F.[Title] LIKE '%demo%', 1, 
		IIF(ISNUMERIC(F.[Complaint]) = 1 AND F.[Type] LIKE '%No Failure', 1, 0))) AS [StripComplaintFlag]
INTO #flaggedForFailures
FROM #birthDate B INNER JOIN #partInfoPiv P
	ON B.[SerialNo] = P.[SerialNo] LEFT JOIN #freePropPiv F
		ON P.[TicketId] = F.[TicketId]
WHERE [HoursRun] NOT LIKE 'N%A' AND [HoursRun] IS NOT NULL

SELECT
	[TicketId]
INTO #complaintsReal
FROM #flaggedForFailures
WHERE [Complaint] = 1 AND [TitleFail] = 0 AND ([CustFailTypeProd] = 0 OR [CustFailTypeProd] IS NULL) AND ([FailureType] = 0 OR [FailureType] IS NULL) AND ([FailCheck] = 0 OR [FailCheck] IS NULL) AND [StripComplaintFlag] = 0

SELECT 
	IIF(LEFT([SerialNo],2) LIKE 'TM', CONCAT('K',[SerialNo]), [SerialNo]) AS [SerialNo], 
	IIF(LEFT([PartNo],4) LIKE 'FLM2','FA2.0',
		IIF(LEFT([PartNo],4) LIKE 'FLM1','FA1.5','Torch')) AS [Version],
	[BirthDate],
	YEAR([BirthDate]) AS [Year],
	DATEPART(ww,[BirthDate]) AS [Week],
	F.[TicketId],
	[TicketString],
	[CreatedDate],
	[HoursRun],
	[CustFailTypeProd],
	IIF([FailureType] = 1 AND [HoursRunLow] = 1, 1,
		IIF([FailCheck] = 1 AND [HoursRunLow] = 1, 1,
		IIF([CustFailTypeProd] = 1 AND [HoursRunLow] = 1, 1,
		IIF([CustFailTypeProd] = 1 AND [HoursRun] IS NULL, 1,
		IIF([TitleFail] = 1 AND [HoursRunLow] = 1, 1, 
		IIF(C.[TicketId] IS NOT NULL AND [HoursRunLow] = 1, 1, 0)))))) AS [Failure]
INTO #master
FROM #flaggedForFailures F LEFT JOIN #complaintsReal C
	ON F.[TicketId] = C.[TicketId]

SELECT 
	[SerialNo],
	[Version],
	[Year],
	[Week],
	[TicketId],
	[TicketString],
	[CreatedDate],
	[BirthDate],
	[Failure],
	[CustFailTypeProd] AS [CustReportFailure]
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
UNION ALL
SELECT 
	[SerialNo],
	[Version],
	[Year],
	[Week],
	DATEDIFF(ww, [BirthDate], [CreatedDate]) AS [DeltaWeeks],
	'CustReportedFailure' AS [Key],
	1 AS [Record]
FROM #firstFailure
WHERE [CustReportFailure] = 1

DROP TABLE #cleanSerials, #birthDate, #partInfo, #freePropPivrops, #partInfoPiv, #freePropPiv, #flaggedForFailures, #master, #firstFailure

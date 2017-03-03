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
	B.[SerialNo],
	[DateOfManufacturing] AS [BirthDate],
	[TicketString],
	P.[TicketId],
	[CreatedDate],
	[Part Number] AS [PartNo],
	[Title],
	[CustFailType],
	[Type],
	[Complaint] AS [ComplaintNo],
	CAST([HoursRun] AS FLOAT) AS [HoursRun],
	IIF([Type] LIKE '% - Failure', 1, 0) AS [FailureType],
	IIF([FailCheck] = 'True', 1, 0) AS [FailCheck],
	IIF([CustFailType] IN ('DOA','ELF'), 1, 0) AS [CustFailTypeProd],
	IIF(CAST([HoursRun] AS FLOAT) < 100.0001, 1, 0) AS [HoursRunLow],
	IIF([Title] LIKE '% error%' OR [Title] LIKE '% fail%' OR [Title] LIKE '%DOA%' OR [Title] LIKE '%ELF%',1, 0) AS [TitleFail],
	IIF(ISNUMERIC([Complaint])=1, 1, 0) AS [Complaint]
INTO #flaggedForFailures
FROM #birthDate B INNER JOIN #partInfoPiv P
	ON B.[SerialNo] = P.[SerialNo] LEFT JOIN #freePropPiv F
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
	[CustFailTypeProd],
	[ComplaintNo],
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
	REPLACE([ComplaintNo],' ','') AS [ComplaintNo],
	[BirthDate],
	[Failure],
	[CustFailTypeProd] AS [CustReportFailure]
INTO #firstFailure
FROM #master 
WHERE [CustFailTypeProd] = 1
		
SELECT 
	[TicketId],
	[TicketString],
	SUBSTRING([TicketString], 11, 100) AS [ComplaintNo],
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
	   [ComplaintNo],
       REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(UPPER([Lot/Serial Number]),',',''),' ',''),'.',''),'_',''),'-','') AS [SerialNo],
       IIF(CHARINDEX('-',[Failure Mode],8)<>0, SUBSTRING([Failure Mode], 1, CHARINDEX('-',[Failure Mode],8)-1), [Failure Mode]) AS [Complaint],
	   IIF([Failure Mode] LIKE '%-1-%', 'InstrumentError','OtherError') AS [InstError]
INTO #complaints
FROM
(
       SELECT 
             [TicketId],
             [TicketString],
			 [ComplaintNo],
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

SELECT 
    F.[SerialNo],
    F.[Version],
	F.[RMA],
    F.[Year],
    F.[Week],
	[Failure],
	[CustReportFailure],
    C.[TicketString],
    ISNULL(C.[Complaint], 'No Complaint') AS [Complaint]
INTO #combined
FROM
(
       SELECT 
             [SerialNo],
             [Version],
			 [TicketString] AS [RMA],
			 [ComplaintNo],
             [Year],
             [Week],
			 [Failure],
			 [CustReportFailure],
             1 AS [Record]
       FROM #firstFailure
       WHERE [CustReportFailure] = 1
       GROUP BY 
             [SerialNo],
             [Version],
			 [TicketString],
			 [ComplaintNo],
             [Year],
             [Week],
			 [Failure],
			 [CustReportFailure]
) F LEFT JOIN 
(
       SELECT 
             C1.[SerialNo],
             C1.[TicketString],
			 C1.[ComplaintNo],
             IIF(C1.[Complaint] LIKE '%Pressure Error%', 'Pressure Errors',
                    IIF(C1.[Complaint] LIKE '%Seal Bar%', 'Seal Bar Errors',
                    IIF(C1.[Complaint] LIKE '%Lid Lock%', 'Lid Lock Errors',
                    IIF(C1.[Complaint] LIKE '%Bead Motor Stall%', 'Bead Beater Stall',
                    IIF(C1.[Complaint] LIKE '%7003%', 'LED Excitation Error',
					IIF(C1.[Complaint] LIKE 'Lua 1005%', 'LUA Execution Error: Set Clock',
                    IIF(C1.[Complaint] LIKE '%Temp %', 'Temp Timeout Errors', C1.[Complaint]))))))) AS [Complaint]
       FROM #complaints C1 
) C
	ON F.[ComplaintNo] = C.[ComplaintNo]

SELECT 
	[Year],
	[Week],
	MIN(ISNULL([Complaint 1],'xNA')) AS [Complaint 1],
	MAX(ISNULL([Record 1],0)) AS [Record 1],
	MIN(ISNULL([Complaint 2],'xNA')) AS [Complaint 2],
	MAX(ISNULL([Record 2],0)) AS [Record 2],
	MIN(ISNULL([Complaint 3],'xNA')) AS [Complaint 3],
	MAX(ISNULL([Record 3],0)) AS [Record 3],
	MIN(ISNULL([Complaint 4],'xNA')) AS [Complaint 4],
	MAX(ISNULL([Record 4],0)) AS [Record 4],
	MIN(ISNULL([Complaint 5],'xNA')) AS [Complaint 5],
	MAX(ISNULL([Record 5],0)) AS [Record 5],
	MIN(ISNULL([Complaint 6],'xNA')) AS [Complaint 6],
	MAX(ISNULL([Record 6],0)) AS [Record 6],
	MIN(ISNULL([Complaint 7],'xNA')) AS [Complaint 7],
	MAX(ISNULL([Record 7],0)) AS [Record 7],
	MIN(ISNULL([Complaint 8],'xNA')) AS [Complaint 8],
	MAX(ISNULL([Record 8],0)) AS [Record 8],
	MIN(ISNULL([Complaint 9],'xNA')) AS [Complaint 9],
	MAX(ISNULL([Record 9],0)) AS [Record 9],
	MIN(ISNULL([Complaint 10],'xNA')) AS [Complaint 10],
	MAX(ISNULL([Record 10],0)) AS [Record 10]
INTO #WeeksGrouped
FROM 
(
	SELECT 
		[Year],
		[Week],
		[Complaint],
		[Record], 
		CONCAT('Complaint ', [ComplaintNum]) AS [LabelNum],
		CONCAT('Record ', [ComplaintNum]) AS [RecordNum]

	FROM
	(
		SELECT *,
				ROW_NUMBER() OVER(PARTITION BY [Year], [Week] ORDER BY [Record]) AS [ComplaintNum]
		FROM 
		(
			SELECT 
				[Year],
				[Week],
				[Complaint],
				COUNT([SerialNo]) AS [Record]
			FROM #combined
			GROUP BY [Year], [Week], [Complaint]
		) A
	) B
) P
PIVOT
(
	MAX([Complaint])
	FOR [LabelNum] IN
	(
		[Complaint 1],
		[Complaint 2],
		[Complaint 3],
		[Complaint 4],
		[Complaint 5],
		[Complaint 6],
		[Complaint 7],
		[Complaint 8],
		[Complaint 9],
		[Complaint 10]
	)	
) PIV1 
PIVOT
(
	MAX([Record])
	FOR [RecordNum] IN
	(
		[Record 1],
		[Record 2],
		[Record 3],
		[Record 4],
		[Record 5],
		[Record 6],
		[Record 7],
		[Record 8],
		[Record 9],
		[Record 10]
	)	
) PIV2 
GROUP BY [Year], [Week]

DECLARE @DateFrom DATETIME, @DateTo DATETIME;
SET @DateFrom = CONVERT(DATETIME, '2014-06-01');
SET @DateTo = GETDATE();
WITH T(date)
AS
(
	SELECT @DateFrom
	UNION ALL
	SELECT DATEADD(day, 1, T.date) FROM T WHERE T.date < @DateTo
)
SELECT 
	YEAR(date) AS [Year],
	MONTH(date) AS [Month],
	DATEPART(ww,date) AS [Week]	
INTO #Calendar
FROM T
GROUP BY YEAR(date), MONTH(date), DATEPART(ww,date)
OPTION(MAXRECURSION 32767)

SELECT
	C.[Year],
	C.[Week],
	ISNULL([Complaint 1], 'xNA') AS [Complaint 1], 
	ISNULL([Record 1], 0) AS [Record 1],
	ISNULL([Complaint 2], 'xNA') AS [Complaint 2], 
	ISNULL([Record 2], 0) AS [Record 2],
	ISNULL([Complaint 3], 'xNA') AS [Complaint 3], 
	ISNULL([Record 3], 0) AS [Record 3],
	ISNULL([Complaint 4], 'xNA') AS [Complaint 4], 
	ISNULL([Record 4], 0) AS [Record 4],
	ISNULL([Complaint 5], 'xNA') AS [Complaint 5], 
	ISNULL([Record 5], 0) AS [Record 5],
	ISNULL([Complaint 6], 'xNA') AS [Complaint 6], 
	ISNULL([Record 6], 0) AS [Record 6],
	ISNULL([Complaint 7], 'xNA') AS [Complaint 7], 
	ISNULL([Record 7], 0) AS [Record 7],
	ISNULL([Complaint 8], 'xNA') AS [Complaint 8], 
	ISNULL([Record 8], 0) AS [Record 8],
	ISNULL([Complaint 9], 'xNA') AS [Complaint 9], 
	ISNULL([Record 9], 0) AS [Record 9],
	ISNULL([Complaint 10], 'xNA') AS [Complaint 10], 
	ISNULL([Record 10], 0) AS [Record 10]
INTO #AllWeeks
FROM 
(
	SELECT 
		[Year],
		[Week] 
	FROM #Calendar 
	GROUP BY [Year], [Week] 
)C LEFT JOIN #WeeksGrouped W
	ON C.[Year] = W.[Year] AND C.[Week] = W.[Week] 

SELECT	
	A.[Year],
	A.[Week],
	A.[Complaint 1],
	A.[Record 1], 
	A.[Complaint 2],
	A.[Record 2], 
	A.[Complaint 3],
	A.[Record 3], 
	A.[Complaint 4],
	A.[Record 4], 
	A.[Complaint 5],
	A.[Record 5], 
	A.[Complaint 6],
	A.[Record 6], 
	A.[Complaint 7],
	A.[Record 7], 
	A.[Complaint 8],
	A.[Record 8], 
	A.[Complaint 9],
	A.[Record 9], 
	A.[Complaint 10],
	A.[Record 10],
	B1.[Complaint 1] AS [Complaint 11],
	B1.[Record 1] AS [Record 11], 
	B1.[Complaint 2] AS [Complaint 12],
	B1.[Record 2] AS [Record 12], 
	B1.[Complaint 3] AS [Complaint 13],
	B1.[Record 3] AS [Record 13], 
	B1.[Complaint 4] AS [Complaint 14],
	B1.[Record 4] AS [Record 14], 
	B1.[Complaint 5] AS [Complaint 15],
	B1.[Record 5] AS [Record 15], 
	B1.[Complaint 6] AS [Complaint 16],
	B1.[Record 6] AS [Record 16], 
	B1.[Complaint 7] AS [Complaint 17],
	B1.[Record 7] AS [Record 17], 
	B1.[Complaint 8] AS [Complaint 18],
	B1.[Record 8] AS [Record 18], 
	B1.[Complaint 9] AS [Complaint 19],
	B1.[Record 9] AS [Record 19], 
	B1.[Complaint 10] AS [Complaint 20],
	B1.[Record 10] AS [Record 20],
	B2.[Complaint 1] AS [Complaint 21],
	B2.[Record 1] AS [Record 21], 
	B2.[Complaint 2] AS [Complaint 22],
	B2.[Record 2] AS [Record 22], 
	B2.[Complaint 3] AS [Complaint 23],
	B2.[Record 3] AS [Record 23], 
	B2.[Complaint 4] AS [Complaint 24],
	B2.[Record 4] AS [Record 24], 
	B2.[Complaint 5] AS [Complaint 25],
	B2.[Record 5] AS [Record 25], 
	B2.[Complaint 6] AS [Complaint 26],
	B2.[Record 6] AS [Record 26], 
	B2.[Complaint 7] AS [Complaint 27],
	B2.[Record 7] AS [Record 27], 
	B2.[Complaint 8] AS [Complaint 28],
	B2.[Record 8] AS [Record 28], 
	B2.[Complaint 9] AS [Complaint 29],
	B2.[Record 9] AS [Record 29], 
	B2.[Complaint 10] AS [Complaint 30],
	B2.[Record 10] AS [Record 30],
	B3.[Complaint 1] AS [Complaint 31],
	B3.[Record 1] AS [Record 31],  
	B3.[Complaint 2] AS [Complaint 32],
	B3.[Record 2] AS [Record 32], 
	B3.[Complaint 3] AS [Complaint 33],
	B3.[Record 3] AS [Record 33], 
	B3.[Complaint 4] AS [Complaint 34],
	B3.[Record 4] AS [Record 34], 
	B3.[Complaint 5] AS [Complaint 35],
	B3.[Record 5] AS [Record 35], 
	B3.[Complaint 6] AS [Complaint 36],
	B3.[Record 6] AS [Record 36], 
	B3.[Complaint 7] AS [Complaint 37],
	B3.[Record 7] AS [Record 37], 
	B3.[Complaint 8] AS [Complaint 38],
	B3.[Record 8] AS [Record 38], 
	B3.[Complaint 9] AS [Complaint 39],
	B3.[Record 9] AS [Record 39], 
	B3.[Complaint 10] AS [Complaint 40],
	B3.[Record 10] AS [Record 40]
INTO #WeeksLagged
FROM 
(
	SELECT 
		*, 
		LAG([Week], 3) OVER(ORDER BY [Year], [Week]) AS [LagWeek1],
		LAG([Week], 2) OVER(ORDER BY [Year], [Week]) AS [LagWeek2],
		LAG([Week], 1) OVER(ORDER BY [Year], [Week]) AS [LagWeek3],
		LAG([Year], 3) OVER(ORDER BY [Year], [Week]) AS [LagYear1],
		LAG([Year], 2) OVER(ORDER BY [Year], [Week]) AS [LagYear2],
		LAG([Year], 1) OVER(ORDER BY [Year], [Week]) AS [LagYear3]
	FROM #AllWeeks
) A INNER JOIN #AllWeeks B1 ON A.[LagWeek1] = B1.[Week] AND A.[LagYear1] = B1.[Year] 
	INNER JOIN #AllWeeks B2 ON A.[LagWeek2] = B2.[Week] AND A.[LagYear2] = B2.[Year] 
	INNER JOIN #AllWeeks B3 ON A.[LagWeek3] = B3.[Week] AND A.[LagYear3] = B3.[Year] 

SELECT 
	[Year],
	[Week],
	[Label],
	SUM([Record]) AS [Record]
INTO #WeeksAgg
FROM
(
	SELECT 
		[Year],
		[Week],
		[Label],
		[Record]  
	FROM 
	(
		SELECT *
		FROM #WeeksLagged
	) P 
	UNPIVOT
	(
		[Label]
		FOR [Complaint]
		IN 
		(
			[Complaint 1],
			[Complaint 2],
			[Complaint 3],
			[Complaint 4],
			[Complaint 5],
			[Complaint 6],
			[Complaint 7],
			[Complaint 8],
			[Complaint 9],
			[Complaint 10],
			[Complaint 11],
			[Complaint 12],
			[Complaint 13],
			[Complaint 14],
			[Complaint 15],
			[Complaint 16],
			[Complaint 17],
			[Complaint 18],
			[Complaint 19],
			[Complaint 20],
			[Complaint 21],
			[Complaint 22],
			[Complaint 23],
			[Complaint 24],
			[Complaint 25],
			[Complaint 26],
			[Complaint 27],
			[Complaint 28],
			[Complaint 29],
			[Complaint 30],
			[Complaint 31],
			[Complaint 32],
			[Complaint 33],
			[Complaint 34],
			[Complaint 35],
			[Complaint 36],
			[Complaint 37],
			[Complaint 38],
			[Complaint 39],
			[Complaint 40]
		)	
	)PIV1
	UNPIVOT
	(
		[Record]
		FOR [RecordNum]
		IN 
		(
			[Record 1],
			[Record 2],
			[Record 3],
			[Record 4],
			[Record 5],
			[Record 6],
			[Record 7],
			[Record 8],
			[Record 9],
			[Record 10],
			[Record 11],
			[Record 12],
			[Record 13],
			[Record 14],
			[Record 15],
			[Record 16],
			[Record 17],
			[Record 18],
			[Record 19],
			[Record 20],
			[Record 21],
			[Record 22],
			[Record 23],
			[Record 24],
			[Record 25],
			[Record 26],
			[Record 27],
			[Record 28],
			[Record 29],
			[Record 30],
			[Record 31],
			[Record 32],
			[Record 33],
			[Record 34],
			[Record 35],
			[Record 36],
			[Record 37],
			[Record 38],
			[Record 39],
			[Record 40]
		)	
	)PIV2
	WHERE ([RecordNum] = 'Record 1' AND [Complaint] = 'Complaint 1') OR
	([RecordNum] = 'Record 2' AND [Complaint] = 'Complaint 2') OR
	([RecordNum] = 'Record 3' AND [Complaint] = 'Complaint 3') OR
	([RecordNum] = 'Record 4' AND [Complaint] = 'Complaint 4') OR
	([RecordNum] = 'Record 5' AND [Complaint] = 'Complaint 5') OR
	([RecordNum] = 'Record 6' AND [Complaint] = 'Complaint 6') OR
	([RecordNum] = 'Record 7' AND [Complaint] = 'Complaint 7') OR
	([RecordNum] = 'Record 8' AND [Complaint] = 'Complaint 8') OR
	([RecordNum] = 'Record 9' AND [Complaint] = 'Complaint 9') OR
	([RecordNum] = 'Record 10' AND [Complaint] = 'Complaint 10') OR
	([RecordNum] = 'Record 11' AND [Complaint] = 'Complaint 11') OR
	([RecordNum] = 'Record 12' AND [Complaint] = 'Complaint 12') OR
	([RecordNum] = 'Record 13' AND [Complaint] = 'Complaint 13') OR
	([RecordNum] = 'Record 14' AND [Complaint] = 'Complaint 14') OR
	([RecordNum] = 'Record 15' AND [Complaint] = 'Complaint 15') OR
	([RecordNum] = 'Record 16' AND [Complaint] = 'Complaint 16') OR
	([RecordNum] = 'Record 17' AND [Complaint] = 'Complaint 17') OR
	([RecordNum] = 'Record 18' AND [Complaint] = 'Complaint 18') OR
	([RecordNum] = 'Record 19' AND [Complaint] = 'Complaint 19') OR
	([RecordNum] = 'Record 20' AND [Complaint] = 'Complaint 20') OR
	([RecordNum] = 'Record 21' AND [Complaint] = 'Complaint 21') OR
	([RecordNum] = 'Record 22' AND [Complaint] = 'Complaint 22') OR
	([RecordNum] = 'Record 23' AND [Complaint] = 'Complaint 23') OR
	([RecordNum] = 'Record 24' AND [Complaint] = 'Complaint 24') OR
	([RecordNum] = 'Record 25' AND [Complaint] = 'Complaint 25') OR
	([RecordNum] = 'Record 26' AND [Complaint] = 'Complaint 26') OR
	([RecordNum] = 'Record 27' AND [Complaint] = 'Complaint 27') OR
	([RecordNum] = 'Record 28' AND [Complaint] = 'Complaint 28') OR
	([RecordNum] = 'Record 29' AND [Complaint] = 'Complaint 29') OR
	([RecordNum] = 'Record 30' AND [Complaint] = 'Complaint 30') OR
	([RecordNum] = 'Record 31' AND [Complaint] = 'Complaint 31') OR
	([RecordNum] = 'Record 32' AND [Complaint] = 'Complaint 32') OR
	([RecordNum] = 'Record 33' AND [Complaint] = 'Complaint 33') OR
	([RecordNum] = 'Record 34' AND [Complaint] = 'Complaint 34') OR
	([RecordNum] = 'Record 35' AND [Complaint] = 'Complaint 35') OR
	([RecordNum] = 'Record 36' AND [Complaint] = 'Complaint 36') OR
	([RecordNum] = 'Record 37' AND [Complaint] = 'Complaint 37') OR
	([RecordNum] = 'Record 38' AND [Complaint] = 'Complaint 38') OR
	([RecordNum] = 'Record 39' AND [Complaint] = 'Complaint 39') OR
	([RecordNum] = 'Record 40' AND [Complaint] = 'Complaint 40')
) A
WHERE [Label] NOT LIKE 'xNA'
GROUP BY [Year], [Week], [Label] 

SELECT 
       A.[Year],
       A.[Week],
       CONCAT(A.[Label], ' ', CONCAT(ROUND(100*CAST(A.[Record] AS FLOAT)/CAST(B.[Total] AS FLOAT), 0),'%')) AS [Label],
	   A.[Record]
INTO #labels
FROM #WeeksAgg A LEFT JOIN 
(
	SELECT 
		[Year],
		[Week],
		SUM([Record]) AS [Total]
	FROM #WeeksAgg
	GROUP BY [Year], [Week] 
) B ON A.[Year] = B.[Year] AND A.[Week] = B.[Week] 
ORDER BY A.[Year], A.[Week] 

SELECT DISTINCT
       IIF(L2.[Week] < 10, CONCAT(L2.[Year], '-0', L2.[Week]), CONCAT(L2.[Year], '-', L2.[Week])) AS [DateGroup],
       SUBSTRING(
             (
                    SELECT
                           ',' + L1.[Label] AS [text()]
                    FROM #labels L1
                    WHERE L1.[Year] = L2.[Year] AND L1.[Week] = L2.[Week]
                    ORDER BY L1.[Record] DESC
                    FOR XML PATH('')
             ), 2, 1000) AS [Annotation]
FROM #labels L2

DROP TABLE #cleanSerials, #birthDate, #partInfo, #freePropPivrops, #partInfoPiv, #freePropPiv, #flaggedForFailures, #master, #firstFailure, #complaints, #combined, #labels, #bfdxParts,
	#AllWeeks, #Calendar, #WeeksAgg, #WeeksGrouped, #WeeksLagged

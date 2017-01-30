
SET NOCOUNT ON 

SELECT
       R.[StartTime] AS [Date],
       R.[PouchSerialNumber] AS [PouchSerialNumber],
       R.[SampleType] AS [Protocol],
       T.[Name] AS [ControlName],
       IIF(TR.[Result] LIKE 'Pass', 0 , 1) AS [Result]
INTO #allcontrols
FROM [FILMARRAYDB].[FilmArray2].[dbo].[Target_Assay] TA WITH(NOLOCK) INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[Target] T WITH(NOLOCK)
       ON TA.[target_id] = T.[Id] INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[TargetResult] TR WITH(NOLOCK)
             ON T.[Id] = TR.[target_id] INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[MetaAnalysis] A WITH(NOLOCK)
                    ON TR.[analysis_id] = A.[Id] INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[ExperimentRun] R WITH(NOLOCK)
                           ON A.[experiment_id] = R.[Id]
WHERE TR.[TypeCode] = 'control' AND  R.[StartTime] >= GETDATE() - 370 AND 
(

		R.[SampleId] NOT LIKE '%NewBuild%' AND
		R.[SampleId] NOT LIKE '%PostRepair%' AND
		R.[SampleId] NOT LIKE '%service%'
) AND R.[InstrumentSerialNumber] IN serialnumbervector

SELECT 
	[Date], 
	[PouchSerialNumber],
	[Protocol], 
	[PCR2 Control] AS [PCR2], 
	[PCR1 Control] AS [PCR1],
	[RNA Process Control] AS [yeastRNA]
INTO #controls
FROM
(
	SELECT *
	FROM #allcontrols
) P
PIVOT(
	MAX([Result])
	FOR [ControlName] 
	IN
	(
		[PCR1 Control],
		[PCR2 Control],
		[RNA Process Control]
	)
) PIV


SELECT 
	R.[StartTime] AS [Date],
    R.[InstrumentSerialNumber] AS [SerialNo],
	R.[PouchSerialNumber] AS [PouchSerialNumber],
	R.[SampleType] AS [Protocol],
	R.[ExperimentStatus] 
INTO #experimentStatus
FROM [FILMARRAYDB].[FilmArray2].[dbo].[ExperimentRun] R WITH(NOLOCK)
WHERE 
	(
		R.[ExperimentStatus] NOT LIKE 'Aborted' AND 
		R.[ExperimentStatus] NOT LIKE 'Incomplete' AND 
		R.[ExperimentStatus] NOT LIKE 'In Progress'

	)  AND 
	(
		R.[SampleId] NOT LIKE '%NewBuild%' AND
		R.[SampleId] NOT LIKE '%PostRepair%' AND
		R.[SampleId] NOT LIKE '%service%'
	)	AND R.[StartTime] >= GETDATE() - 400 AND  R.[InstrumentSerialNumber] IN serialnumbervector

SELECT 
	[Date], 
	[SerialNo], 
	[PouchSerialNumber],
	[Protocol],
	IIF([ExperimentStatus] LIKE 'Instrument% Error', 1, 0) AS [Value]
INTO #instrumentErrors
FROM #experimentStatus


SELECT 
	[Date], 
	[SerialNo], 
	[PouchSerialNumber],
	[Protocol],
	IIF([ExperimentStatus] LIKE 'Software Error', 1, 0) AS [Value]
INTO #softwareErrors
FROM #experimentStatus


SELECT
       R.[StartTime] AS [Date],
       R.[InstrumentSerialNumber] AS [SerialNo],
	   R.[PouchSerialNumber] AS [PouchSerialNumber],
	   R.[SampleType] AS [Protocol],
	   ISNULL(P.[PouchLeak], 0 ) AS [Value]
INTO #pouchLeaks
FROM [FILMARRAYDB].[FilmArray2].[dbo].[ExperimentRun] R WITH(NOLOCK) INNER JOIN [PouchTracker].[dbo].[PostRunPouchObservations] P WITH(NOLOCK) 
		ON P.[SerialNumber] = R.[PouchSerialNumber] 
WHERE
	 (
		 R.[SampleId] NOT LIKE '%NewBuild%' AND
		 R.[SampleId] NOT LIKE '%PostRepair%' AND
		 R.[SampleId] NOT LIKE '%service%'
	 )	 AND  R.[StartTime] >= GETDATE() - 400  AND  R.[InstrumentSerialNumber] IN serialnumbervector

SELECT
       ER.[PouchSerialNumber] AS [PouchSerialNumber],
       CAST(ER.[StartTime]  AS DATE) AS [Date],
       AA.[Name],
       ISNULL(RR.[Cp], 30) AS [Cp],
       [Tm1]
INTO #cpValues
FROM [FILMARRAYDB].[FilmArray2].[dbo].[AssayResult] AR WITH(NOLOCK) INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[Assay] AA WITH(NOLOCK) 
       ON AR.[assay_id] = AA.[Id] INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[Assay_Reaction] ARX WITH(NOLOCK) 
             ON AA.[Id] = ARX.[assay_id] INNER JOIN  [FILMARRAYDB].[FilmArray2].[dbo].[Reaction] RX WITH(NOLOCK) 
                    ON ARX.[reaction_id] = RX.[Id] INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[ReactionResult] RR WITH(NOLOCK) 
                           ON RX.[Id] = RR.[reaction_id] INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[MetaAnalysis] MA WITH(NOLOCK) 
                                 ON AR.[analysis_id] = MA.[Id] INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[ExperimentRun] ER WITH(NOLOCK) 
                                        ON MA.[experiment_id] = ER.[Id]
WHERE ER.[StartTime] >= GETDATE() - 370  AND  AA.[Name] LIKE 'yeastRNA'



SELECT 
	ie.[Date], 
	ie.[SerialNo],
	ie.[Protocol],  
	ISNULL(ie.[Value], 0) AS [InstrumentError],
	ISNULL(se.[Value], 0) AS [SoftwareError], 
	ISNULL(pl.[Value], 0 ) AS [PouchLeak], 
	ISNULL(c.[PCR2], 0) AS [PCR2],
	ISNULL(c.[PCR1], 0) AS [PCR1],
	ISNULL(c.[yeastRNA], 0) AS [yeastRNA],
	FORMAT(AVG(ISNULL(cpv.[Cp], 40)), 'N2') AS [Cp]
INTO #fa2
FROM #instrumentErrors ie LEFT JOIN #softwareErrors se 
	ON ie.[PouchSerialNumber] = se.[PouchSerialNumber] LEFT JOIN #pouchLeaks pl 
		ON ie.[PouchSerialNumber] = pl.[PouchSerialNumber] LEFT JOIN #controls c
			ON ie.[PouchSerialNumber] = c.[PouchSerialNumber] LEFT JOIN #cpValues cpv
				ON ie.[PouchSerialNumber] = cpv.[PouchSerialNumber]
GROUP BY ie.[Date], ie.[SerialNo], ie.[Protocol], ie.[Value], se.[Value], pl.[Value], c.[PCR1], c.[PCR2], c.[yeastRNA]


SELECT
       R1.[StartTime] AS [Date],
       R1.[PouchSerialNumber] AS [PouchSerialNumber],
       R1.[SampleType] AS [Protocol],
       T1.[Name] AS [ControlName],
       IIF(TR1.[Result] LIKE 'Pass', 0 , 1) AS [Result]
INTO #allcontrols1
FROM [FILMARRAYDB].[FilmArray2].[dbo].[Target_Assay] TA1 WITH(NOLOCK) INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[Target] T1 WITH(NOLOCK)
       ON TA1.[target_id] = T1.[Id] INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[TargetResult] TR1 WITH(NOLOCK)
             ON T1.[Id] = TR1.[target_id] INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[MetaAnalysis] A1 WITH(NOLOCK)
                    ON TR1.[analysis_id] = A1.[Id] INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[ExperimentRun] R1 WITH(NOLOCK)
                           ON A1.[experiment_id] = R1.[Id]
WHERE TR1.[TypeCode] = 'control' AND  R1.[StartTime] >= GETDATE() - 370 AND 
(

		R1.[SampleId] NOT LIKE '%NewBuild%' AND
		R1.[SampleId] NOT LIKE '%PostRepair%' AND
		R1.[SampleId] NOT LIKE '%service%'
) AND R1.[InstrumentSerialNumber] IN serialnumbervector

SELECT 
	[Date], 
	[PouchSerialNumber],
	[Protocol], 
	[PCR2 Control] AS [PCR2], 
	[PCR1 Control] AS [PCR1],
	[RNA Process Control] AS [yeastRNA]
INTO #controls1
FROM
(
	SELECT *
	FROM #allcontrols1
) P
PIVOT(
	MAX([Result])
	FOR [ControlName] 
	IN
	(
		[PCR1 Control],
		[PCR2 Control],
		[RNA Process Control]
	)
) PIV


SELECT 
	R1.[StartTime] AS [Date],
    R1.[InstrumentSerialNumber] AS [SerialNo],
	R1.[PouchSerialNumber],
	R1.[SampleType] AS [Protocol],
	R1.[ExperimentStatus] 
INTO #experimentStatus1
FROM [FILMARRAYDB].[FilmArray1].[FilmArray].[ExperimentRun] R1 WITH(NOLOCK)
WHERE 
	(
		R1.[ExperimentStatus] NOT LIKE 'Aborted' AND 
		R1.[ExperimentStatus] NOT LIKE 'Incomplete' AND 
		R1.[ExperimentStatus] NOT LIKE 'In Progress'

	)  AND 

	(
		R1.[SampleId] NOT LIKE '%NewBuild%' AND
		R1.[SampleId] NOT LIKE '%PostRepair%' AND
		R1.[SampleId] NOT LIKE '%service%'
	)   AND  R1.[StartTime] >= GETDATE() - 400 AND  R1.[InstrumentSerialNumber] IN serialnumbervector

SELECT 
	[Date], 
	[SerialNo], 
	[PouchSerialNumber],
	[Protocol],
	IIF([ExperimentStatus] LIKE 'Instrument% Error', 1, 0) AS [Value]
INTO #instrumentErrors1
FROM #experimentStatus1


SELECT 
	[Date], 
	[SerialNo], 
	[PouchSerialNumber],
	[Protocol],
	IIF([ExperimentStatus] LIKE 'Software Error', 1, 0) AS [Value]
INTO #softwareErrors1
FROM #experimentStatus1


SELECT
       R1.[StartTime] AS [Date],
       R1.[InstrumentSerialNumber] AS [SerialNo],
	   R1.[PouchSerialNumber],
	   R1.[SampleType] AS [Protocol],
	   ISNULL(P1.[PouchLeak], 0 ) AS [Value]
INTO #pouchLeaks1
FROM [FILMARRAYDB].[FilmArray1].[FilmArray].[ExperimentRun] R1 WITH(NOLOCK) INNER JOIN [PouchTracker].[dbo].[PostRunPouchObservations] P1 WITH(NOLOCK) 
		ON P1.[SerialNumber] = R1.[PouchSerialNumber] 
WHERE 
	(
		R1.[SampleId] NOT LIKE '%NewBuild%' AND
		R1.[SampleId] NOT LIKE '%PostRepair%' AND
		R1.[SampleId] NOT LIKE '%service%'
	)	AND  R1.[StartTime] >= GETDATE() - 400 AND  R1.[InstrumentSerialNumber] IN serialnumbervector

SELECT
       ER1.[PouchSerialNumber] AS [PouchSerialNumber],
       CAST(ER1.[StartTime]  AS DATE) AS [Date],
       AA1.[Name],
       ISNULL(RR1.[Cp], 30) AS [Cp],
	   [Tm1]
INTO #cpValues1
FROM [FILMARRAYDB].[FilmArray1].[FilmArray].[AssayResult] AR1 WITH(NOLOCK) INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[Assay] AA1 WITH(NOLOCK) 
       ON AR1.[assay_id] = AA1.[Id] INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[Assay_Reaction] ARX1 WITH(NOLOCK) 
             ON AA1.[Id] = ARX1.[assay_id] INNER JOIN  [FILMARRAYDB].[FilmArray1].[FilmArray].[Reaction] RX1 WITH(NOLOCK) 
                    ON ARX1.[reaction_id] = RX1.[Id] INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[ReactionResult] RR1 WITH(NOLOCK) 
                           ON RX1.[Id] = RR1.[reaction_id] INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[MetaAnalysis] MA1 WITH(NOLOCK) 
                                 ON AR1.[analysis_id] = MA1.[Id] INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[ExperimentRun] ER1 WITH(NOLOCK) 
                                        ON MA1.[experiment_id] = ER1.[Id]
WHERE ER1.[StartTime] >= GETDATE() - 370  AND AA1.[Name] LIKE 'yeastRNA'


SELECT 
	ie1.[Date],
	ie1.[SerialNo],
	ie1.[Protocol],
	ISNULL(ie1.[Value], 0 ) AS [InstrumentError],
	ISNULL(se1.[Value], 0)  AS [SoftwareError], 
	ISNULL(pl1.[Value], 0)  AS [PouchLeak], 
	ISNULL(c1.[PCR2], 0) AS [PCR2],
	ISNULL(c1.[PCR1], 0) AS [PCR1],
	ISNULL(c1.[yeastRNA], 0) AS [yeastRNA],
	FORMAT(AVG(ISNULL(cpv1.[Cp], 40)), 'N2') AS [Cp]
INTO #fa1
FROM #instrumentErrors1 ie1 LEFT JOIN #softwareErrors1 se1 
	ON ie1.[PouchSerialNumber] = se1.[PouchSerialNumber] LEFT JOIN #pouchLeaks1 pl1 
		ON ie1.[PouchSerialNumber] = pl1.[PouchSerialNumber] LEFT JOIN #controls1 c1
			ON ie1.[PouchSerialNumber] = c1.[PouchSerialNumber] LEFT JOIN #cpValues1 cpv1
				ON ie1.[PouchSerialNumber] = cpv1.[PouchSerialNumber]
GROUP BY ie1.[Date], ie1.[SerialNo], ie1.[Protocol], ie1.[Value], se1.[Value], pl1.[Value], c1.[PCR1], c1.[PCR2], c1.[yeastRNA]



SELECT *
FROM 
	( 
		SELECT * 
		FROM #fa1
		UNION
	    SELECT * 
	    FROM #fa2
	)aft

DROP TABLE #controls, #allcontrols, #experimentStatus, #instrumentErrors, #softwareErrors, #pouchLeaks, #fa2, #controls1, #allcontrols1, #experimentStatus1, #instrumentErrors1, #softwareErrors1, #pouchLeaks1, #fa1, #cpValues, #cpValues1


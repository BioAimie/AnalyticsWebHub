SET NOCOUNT ON


SELECT 
	R.[StartTime] AS [Date],
    R.[InstrumentSerialNumber] AS [SerialNo],
	R.[PouchSerialNumber] AS [PouchSerialNumber],
	R.[SoftwareVersion]
INTO #version2
FROM [FILMARRAYDB].[FilmArray2].[dbo].[ExperimentRun] R WITH(NOLOCK)


SELECT 
	R.[StartTime] AS [Date],
    R.[InstrumentSerialNumber] AS [SerialNo],
	R.[PouchSerialNumber] AS [PouchSerialNumber],
	R.[SoftwareVersion]
INTO #version1
FROM [FILMARRAYDB].[FilmArray1].[FilmArray].[ExperimentRun] R WITH(NOLOCK)


SELECT 
	ROW_NUMBER() OVER(PARTITION BY [SerialNo] ORDER BY [Date]) AS [RowNumber],
	[Date], 
	[SerialNo], 
	[PouchSerialNumber], 
	[SoftwareVersion]
INTO #allVersions
FROM 
	(	
		SELECT * 
		FROM #version1
		UNION 
		SELECT * 
		FROM #version2
	)vs


SELECT 
	av.[SerialNo], 
	av.[SoftwareVersion] AS [FirstVersion], 
	av2.[SoftwareVersion] AS [LastVersion],
	IIF(SUBSTRING(av.[SoftwareVersion], 1,1) != SUBSTRING(av2.[SoftwareVersion], 1, 1), CONCAT( 'Converted to ', SUBSTRING(av2.[SoftwareVersion], 1,1)),
	 SUBSTRING(av2.[SoftwareVersion], 1, 1)) AS [Version]
INTO #versions
FROM 
	(
		SELECT 
		[SerialNo],
		MIN(RowNumber) AS [firstRow], 
		MAX(RowNumber) AS [lastRow]
		FROM #allVersions
		GROUP BY [SerialNo]
	 )tmp INNER JOIN #allVersions av
		ON av.[SerialNo] = tmp.[SerialNo] AND av.[RowNumber] = tmp.[firstRow] INNER JOIN #allVersions av2
			ON av2.[SerialNo] = tmp.[SerialNo] AND av2.[RowNumber] = tmp.[lastRow]
ORDER BY av.[SerialNo] 



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
WHERE TR.[TypeCode] = 'control' AND 
(
       R.[SampleId] LIKE 'QC_RP%' OR 
       R.[SampleId] LIKE 'QC_BCID%' OR 
       R.[SampleId] LIKE 'QC_GI%' OR
       R.[SampleId] LIKE 'QC_ME%' OR 
	   R.[SampleId] LIKE '%PouchQc%'
) AND R.[StartTime] >= GETDATE() - 370 AND 
(

		R.[SampleId] NOT LIKE '%NewBuild%' AND
		R.[SampleId] NOT LIKE '%PostRepair%' AND
		R.[SampleId] NOT LIKE '%service%'
)
GROUP BY
	 R.[StartTime],
     R.[PouchSerialNumber],
     R.[SampleType],
     T.[Name],
     TR.[Result]


SELECT 
	[Date], 
	[PouchSerialNumber],
	[Protocol], 
	[PCR2 Control] AS [PCR2], 
	[PCR1 Control] AS [PCR1],
	IIF((ISNULL([RNA Process Control], 0) + ISNULL([DNA Process Control], 0)) > 0, 1 ,0)  AS [yeast]
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
		[RNA Process Control],
		[DNA Process Control]
		
	)
) PIV


SELECT 
	R.[StartTime] AS [Date],
	R.[PouchSerialNumber] AS [PouchSerialNumber],
	R.[SampleType] AS [Protocol],
    R.[InstrumentSerialNumber] AS [SerialNo],
	R.[ExperimentStatus],
	R.[SoftwareVersion]
INTO #experimentStatus
FROM [FILMARRAYDB].[FilmArray2].[dbo].[ExperimentRun] R WITH(NOLOCK)
WHERE 
    (
		 R.[ExperimentStatus] NOT LIKE 'Aborted' AND 
		 R.[ExperimentStatus] NOT LIKE 'Incomplete' AND 
		 R.[ExperimentStatus] NOT LIKE 'In Progress'

	)   AND 
	(
		 R.[SampleId] LIKE 'QC_RP%' OR 
		 R.[SampleId] LIKE 'QC_BCID%' OR 
		 R.[SampleId] LIKE 'QC_GI%' OR
		 R.[SampleId] LIKE 'QC_ME%' OR
		 R.[SampleId] LIKE '%PouchQC%'
	)    AND R.[StartTime] >= GETDATE() - 400 AND 
	(

	     R.[SampleId] NOT LIKE '%NewBuild%' AND
         R.[SampleId] NOT LIKE '%PostRepair%' AND
         R.[SampleId] NOT LIKE '%service%'

	)



SELECT 
	[Date], 
	[SerialNo], 
	[PouchSerialNumber],
	[Protocol],
	IIF([ExperimentStatus] LIKE 'Instrument% Error', 1, 0) AS [Value],
	[SoftwareVersion]
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
		R.[SampleId] LIKE 'QC_RP%' OR 
		R.[SampleId] LIKE 'QC_BCID%' OR 
		R.[SampleId] LIKE 'QC_GI%' OR
		R.[SampleId] LIKE 'QC_ME%' OR
		R.[SampleId] LIKE '%PouchQC%'
	)   AND R.[StartTime] >= GETDATE() - 400 AND 
	(

		R.[SampleId] NOT LIKE '%NewBuild%' AND
		R.[SampleId] NOT LIKE '%PostRepair%' AND
		R.[SampleId] NOT LIKE '%service%'

	)



SELECT
       ER.[PouchSerialNumber] AS [PouchSerialNumber],
       CAST(ER.[StartTime]  AS DATE) AS [Date],
       AA.[Name],
       ISNULL(RR.[Cp], 30) AS [Cp],
       [Tm1]
INTO #cptm
FROM [FILMARRAYDB].[FilmArray2].[dbo].[AssayResult] AR WITH(NOLOCK) INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[Assay] AA WITH(NOLOCK) 
       ON AR.[assay_id] = AA.[Id] INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[Assay_Reaction] ARX WITH(NOLOCK) 
             ON AA.[Id] = ARX.[assay_id] INNER JOIN  [FILMARRAYDB].[FilmArray2].[dbo].[Reaction] RX WITH(NOLOCK) 
                    ON ARX.[reaction_id] = RX.[Id] INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[ReactionResult] RR WITH(NOLOCK) 
                           ON RX.[Id] = RR.[reaction_id] INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[MetaAnalysis] MA WITH(NOLOCK) 
                                 ON AR.[analysis_id] = MA.[Id] INNER JOIN [FILMARRAYDB].[FilmArray2].[dbo].[ExperimentRun] ER WITH(NOLOCK) 
                                        ON MA.[experiment_id] = ER.[Id]
WHERE ER.[StartTime] >= GETDATE() - 370  AND (AA.[Name] LIKE 'yeast%' OR AA.[Name] LIKE '%RNA%') AND (AA.[Name] NOT LIKE 'hRNA')


SELECT 
	[PouchSerialNumber], 
	MAX([Date]) AS [Date], 
	AVG([Cp]) AS [Cp]
INTO #cpAvg 
FROM #cptm
WHERE [Cp] != 30 AND [Cp] IS NOT NULL
GROUP BY [PouchSerialNumber]


SELECT 
	[PouchSerialNumber], 
	MAX([Date]) AS [Date], 
	AVG([Tm1]) AS [Tm]
INTO #tmAvg
FROM #cptm
WHERE [Tm1] IS NOT NULL 
GROUP BY [PouchSerialNumber]


SELECT 
	ie.[Date], 
	ie.[SerialNo],
	ie.[Protocol],
	v.[Version], 
	ISNULL(ie.[Value], 0) AS [InstrumentError],
	ISNULL(se.[Value], 0) AS [SoftwareError], 
	ISNULL(pl.[Value],0 ) AS [PouchLeak], 
	ISNULL(c.[PCR2], 0) AS [PCR2],
	ISNULL(c.[PCR1], 0) AS [PCR1],
	ISNULL(c.[yeast], 0) AS [yeast],
	FORMAT(cp.[Cp], 'N2') AS [Cp],
	FORMAT(tm.[Tm], 'N2') AS [Tm]
INTO #fa2
FROM #instrumentErrors ie LEFT JOIN #softwareErrors se 
	ON ie.[PouchSerialNumber] = se.[PouchSerialNumber] LEFT JOIN #pouchLeaks pl 
		ON ie.[PouchSerialNumber] = pl.[PouchSerialNumber] LEFT JOIN #controls c
			ON ie.[PouchSerialNumber] = c.[PouchSerialNumber] LEFT JOIN #cpAvg cp
				ON ie.[PouchSerialNumber] = cp.[PouchSerialNumber] LEFT JOIN #tmAvg tm
					ON ie.[PouchSerialNumber] = tm.[PouchSerialNumber] LEFT JOIN #versions v
						ON ie.[SerialNo] = v.[SerialNo]


SELECT
       R1.[StartTime] AS [Date],
       R1.[PouchSerialNumber] AS [PouchSerialNumber],
       R1.[SampleType] AS [Protocol],
       T1.[Name] AS [ControlName],
       IIF(TR1.[Result] LIKE 'Pass', 0 , 1) AS [Result]
INTO #allcontrols1
FROM [FILMARRAYDB].[FilmArray1].[FilmArray].[Target_Assay] TA1 WITH(NOLOCK) INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[Target] T1 WITH(NOLOCK)
       ON TA1.[target_id] = T1.[Id] INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[TargetResult] TR1 WITH(NOLOCK)
             ON T1.[Id] = TR1.[target_id] INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[MetaAnalysis] A1 WITH(NOLOCK)
                    ON TR1.[analysis_id] = A1.[Id] INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[ExperimentRun] R1 WITH(NOLOCK)
                           ON A1.[experiment_id] = R1.[Id]
WHERE TR1.[TypeCode] = 'control' AND 
(
       R1.[SampleId] LIKE 'QC_RP%' OR 
       R1.[SampleId] LIKE 'QC_BCID%' OR 
       R1.[SampleId] LIKE 'QC_GI%' OR
       R1.[SampleId] LIKE 'QC_ME%' OR 
	   R1.[SampleId] LIKE '%PouchQc%'
) AND R1.[StartTime] >= GETDATE() - 370 AND 

(

		R1.[SampleId] NOT LIKE '%NewBuild%' AND
		R1.[SampleId] NOT LIKE '%PostRepair%' AND
		R1.[SampleId] NOT LIKE '%service%'
)
GROUP BY
	 R1.[StartTime],
     R1.[PouchSerialNumber],
     R1.[SampleType],
     T1.[Name],
     TR1.[Result]


SELECT 
	[Date], 
	[PouchSerialNumber],
	[Protocol], 
	[PCR2 Control] AS [PCR2], 
	[PCR1 Control] AS [PCR1],
	IIF((ISNULL([RNA Process Control], 0) + ISNULL([DNA Process Control], 0)) > 0, 1 ,0)  AS [yeast]
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
		[RNA Process Control],
		[DNA Process Control]
	)
) PIV


SELECT 
	R1.[StartTime] AS [Date],
    R1.[InstrumentSerialNumber] AS [SerialNo],
	R1.[PouchSerialNumber] AS [PouchSerialNumber],
	R1.[SampleType] AS [Protocol],
	R1.[ExperimentStatus],
	R1.[SoftwareVersion] 
INTO #experimentStatus1
FROM [FILMARRAYDB].[FilmArray1].[FilmArray].[ExperimentRun] R1 WITH(NOLOCK)
WHERE 
	(
		 R1.[ExperimentStatus] NOT LIKE 'Aborted' AND 
		 R1.[ExperimentStatus] NOT LIKE 'Incomplete' AND 
		 R1.[ExperimentStatus] NOT LIKE 'In Progress'

	)   AND 
	(
		 R1.[SampleId] LIKE 'QC_RP%' OR 
		 R1.[SampleId] LIKE 'QC_BCID%' OR 
		 R1.[SampleId] LIKE 'QC_GI%' OR
		 R1.[SampleId] LIKE 'QC_ME%' OR
		 R1.[SampleId] LIKE '%PouchQC%'
	)    AND R1.[StartTime] >= GETDATE() - 400 AND 
	(

		R1.[SampleId] NOT LIKE '%NewBuild%' AND
		R1.[SampleId] NOT LIKE '%PostRepair%' AND
		R1.[SampleId] NOT LIKE '%service%'

	)



SELECT 
	[Date], 
	[SerialNo], 
	[PouchSerialNumber],
	[Protocol],
	IIF([ExperimentStatus] LIKE 'Instrument% Error', 1, 0) AS [Value],
	[SoftwareVersion]
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
	   R1.[PouchSerialNumber] AS [PouchSerialNumber],
	   R1.[SampleType] AS [Protocol],
	   ISNULL(P1.[PouchLeak], 0 ) AS [Value]
INTO #pouchLeaks1
FROM [FILMARRAYDB].[FilmArray1].[FilmArray].[ExperimentRun] R1 WITH(NOLOCK) INNER JOIN [PouchTracker].[dbo].[PostRunPouchObservations] P1 WITH(NOLOCK) 
		ON P1.[SerialNumber] = R1.[PouchSerialNumber] 
WHERE
	(
		R1.[SampleId] LIKE 'QC_RP%' OR 
		R1.[SampleId] LIKE 'QC_BCID%' OR 
		R1.[SampleId] LIKE 'QC_GI%' OR
		R1.[SampleId] LIKE 'QC_ME%' OR
		R1.[SampleId] LIKE '%PouchQC%'
	)  AND R1.[StartTime] >= GETDATE() - 400 AND 
	(

		R1.[SampleId] NOT LIKE '%NewBuild%' AND
		R1.[SampleId] NOT LIKE '%PostRepair%' AND
		R1.[SampleId] NOT LIKE '%service%'

	)


SELECT
       ER1.[PouchSerialNumber] AS [PouchSerialNumber],
       CAST(ER1.[StartTime]  AS DATE) AS [Date],
       AA1.[Name],
       ISNULL(RR1.[Cp], 30) AS [Cp],
	   [Tm1]
INTO #cptm1
FROM [FILMARRAYDB].[FilmArray1].[FilmArray].[AssayResult] AR1 WITH(NOLOCK) INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[Assay] AA1 WITH(NOLOCK) 
       ON AR1.[assay_id] = AA1.[Id] INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[Assay_Reaction] ARX1 WITH(NOLOCK) 
             ON AA1.[Id] = ARX1.[assay_id] INNER JOIN  [FILMARRAYDB].[FilmArray1].[FilmArray].[Reaction] RX1 WITH(NOLOCK) 
                    ON ARX1.[reaction_id] = RX1.[Id] INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[ReactionResult] RR1 WITH(NOLOCK) 
                           ON RX1.[Id] = RR1.[reaction_id] INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[MetaAnalysis] MA1 WITH(NOLOCK) 
                                 ON AR1.[analysis_id] = MA1.[Id] INNER JOIN [FILMARRAYDB].[FilmArray1].[FilmArray].[ExperimentRun] ER1 WITH(NOLOCK) 
                                        ON MA1.[experiment_id] = ER1.[Id]
WHERE ER1.[StartTime] >= GETDATE() - 370  AND (AA1.[Name] LIKE 'yeast%' OR AA1.[Name] LIKE '%RNA%') AND (AA1.[Name] NOT LIKE 'hRNA')


SELECT 
	[PouchSerialNumber], 
	MAX([Date]) AS [Date], 
	AVG([Cp]) AS [Cp]
INTO #cpAvg1
FROM #cptm1
WHERE [Cp] != 30 AND [Cp] IS NOT NULL
GROUP BY [PouchSerialNumber]


SELECT 
	[PouchSerialNumber], 
	MAX([Date]) AS [Date], 
	AVG([Tm1]) AS [Tm]
INTO #tmAvg1
FROM #cptm1
WHERE [Tm1] IS NOT NULL 
GROUP BY [PouchSerialNumber]


SELECT 
	ie1.[Date],
	ie1.[SerialNo],
	ie1.[Protocol],
	v1.[Version],
	ISNULL(ie1.[Value], 0 ) AS [InstrumentError],
	ISNULL(se1.[Value], 0)  AS [SoftwareError], 
	ISNULL(pl1.[Value], 0)  AS [PouchLeak], 
	ISNULL(c1.[PCR2], 0) AS [PCR2],
	ISNULL(c1.[PCR1], 0) AS [PCR1],
	ISNULL(c1.[yeast], 0) AS [yeast],
	FORMAT(cp1.[Cp], 'N2') AS [Cp],
	FORMAT(tm1.[Tm], 'N2') AS [Tm]
INTO #fa1
FROM #instrumentErrors1 ie1 LEFT JOIN #softwareErrors1 se1 
	ON ie1.[PouchSerialNumber] = se1.[PouchSerialNumber] LEFT JOIN #pouchLeaks1 pl1 
		ON ie1.[PouchSerialNumber] = pl1.[PouchSerialNumber] LEFT JOIN #controls1 c1
			ON ie1.[PouchSerialNumber] = c1.[PouchSerialNumber] LEFT JOIN #cpAvg1 cp1
				ON ie1.[PouchSerialNumber] = cp1.[PouchSerialNumber] LEFT JOIN #tmAvg1 tm1
					ON ie1.[PouchSerialNumber] = tm1.[PouchSerialNumber] LEFT JOIN #versions v1
						ON ie1.[SerialNo] = v1.[SerialNo]

SELECT * 
FROM 
	( 
		SELECT * 
		FROM #fa1
		UNION 
	    SELECT * 
	    FROM #fa2
	)aft


DROP TABLE #controls, #allcontrols, #experimentStatus, #instrumentErrors, #softwareErrors, #pouchLeaks, #fa2, #controls1, #allcontrols1, #experimentStatus1, #instrumentErrors1, #softwareErrors1, #pouchLeaks1, #fa1, #cptm, #cpAvg,  #tmAvg, #cptm1, #cpAvg1, #tmAvg1, #version1, #version2, #allVersions, #versions 

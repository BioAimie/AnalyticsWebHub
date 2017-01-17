SET NOCOUNT ON

SELECT DISTINCT
	REPLACE(REPLACE(REPLACE(L.[LotNumber],' ',''),'_',''),'.','') AS [SerialNo],
	L.[DateOfManufacturing],
	UPPPP.[LotNumber] AS [WindowBladderLot]
INTO #windowBladderAtBirth
FROM [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) 
	ON P.[PartNumberId] = L.[PartNumberId] INNER JOIN [ProductionWeb].[dbo].[UtilizedParts] U WITH(NOLOCK)
		ON L.[LotNumberId] = U.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[Lots] UL WITH(NOLOCK)
			ON U.[LotNumber] = UL.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[UtilizedParts] UP WITH(NOLOCK)
				ON UL.[LotNumberId] = UP.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[Lots] ULL WITH(NOLOCK)
					ON UP.[LotNumber] = ULL.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[UtilizedParts] UPP WITH(NOLOCK)
						ON ULL.[LotNumberId] = UPP.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[Lots] ULLL WITH(NOLOCK)
							ON UPP.[LotNumber] = ULLL.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[UtilizedParts] UPPP WITH(NOLOCK)
								ON ULLL.[LotNumberId] = UPPP.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[Lots] ULLLL WITH(NOLOCK)
									ON UPPP.[LotNumber] = ULLLL.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[UtilizedParts] UPPPP WITH(NOLOCK)
										ON ULLLL.[LotNumberId] = UPPPP.[LotNumberId]
WHERE P.[PartNumber] IN ('FLM1-ASY-0001' ,'FLM2-ASY-0001','HTFA-ASY-0003','FLM2-ASY-0001R','HTFA-ASY-0003R') AND UPPPP.[PartNumber] LIKE 'FLM1-SUB-0044' AND UPPPP.[Quantity] > 0

SELECT
	[TicketId],
	[TicketString],
	[CreatedDate],
	[Status],
	[PropertyName],
	[RecordedValue]
INTO #freePropPrePiv
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] IN ('RMA Title', 'RMA Type', 'Complaint Number', 'Hours Run') AND [Tracker] = 'RMA'

SELECT
	[TicketId],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #partInfoPrePiv
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] = 'Part Information' AND [Tracker] = 'RMA'

SELECT 
	[TicketId],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #partsUsedPrePiv
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] = 'Parts Used' AND [Tracker] = 'RMA'

SELECT DISTINCT
	[TicketId]
INTO #servCodeIndicatesFailure
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] = 'Service Codes' AND [RecordedValue] IN ('53','55','50','54','56','51','52') AND [Tracker] = 'RMA'

SELECT 
	[TicketId]
INTO #rootCauseIndicatesFailure
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] = 'Root Causes' AND [PropertyName] = 'Part Number' AND [RecordedValue] = 'FLM1-SUB-0044' AND [Tracker] = 'RMA'
 
SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[Status],
	[RMA Title] AS [Title],
	[RMA Type] AS [Type],
	[Complaint Number] AS [Complaint],
	[Hours Run] AS [HoursRun]
INTO #freePropPiv
FROM #freePropPrePiv P 
PIVOT
(
	MAX([RecordedValue])
	FOR [PropertyName]
	IN
	(
		[RMA Title],
		[RMA Type],
		[Complaint Number],
		[Hours Run]
	)
) PIV

SELECT
	[TicketId],
	[Part Number],
	REPLACE(REPLACE(REPLACE([Lot/Serial Number], ' ',''),'.',''),'_','') AS [SerialNo],
	[Early Failure Type] AS [CustFailType]
INTO #partInfoPiv
FROM #partInfoPrePiv P
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
WHERE [Part Number] LIKE '%FLM%-ASY-0001%' OR [Part Number] LIKE '%HTFA%'

SELECT
	[TicketId],
	IIF(CHARINDEX(':', [Lot/Serial Number], 1) = 0, UPPER(REPLACE(REPLACE([Lot/Serial Number],' ',''), ')','')), UPPER(REPLACE(REPLACE(SUBSTRING([Lot/Serial Number], 1, CHARINDEX(':', [Lot/Serial Number], 1)-1),' ',''), ')',''))) AS [WindowBladderReplacementLot]
INTO #windowBladderLotUsed
FROM #partsUsedPrePiv P
PIVOT
(
	MAX([RecordedValue])
	FOR [PropertyName]
	IN
	(
		[Part Used],
		[Lot/Serial Number]
	)
) PIV
WHERE REPLACE([Part Used],' ','') = 'FLM1-SUB-0044'

SELECT 
	[SerialNo],
	[WhseID],
	[TranType],
	[DistQty]
INTO #serialTrans
FROM [PMS1].[dbo].[vSerialTransactions] WITH(NOLOCK)

SELECT DISTINCT 
	[SerialNo]
INTO #hasShipped
FROM #serialTrans
WHERE [TranType] IN ('IS','SA','SH') AND [WhseID] IN ('STOCK','IFSTK') AND [DistQty] = -1

SELECT
	[WindowBladderLot],
	[LotSizeInField],
	IIF([DateOfManufacturing] IS NOT NULL, CAST([DateOfManufacturing] AS DATE),
		IIF(CHARINDEX('.',[WindowBladderLot],1) <> 0, 
			CAST(CONCAT(SUBSTRING(RIGHT([WindowBladderLot],9),1,2),'-', SUBSTRING(RIGHT([WindowBladderLot],9),3,2),'-20', SUBSTRING(RIGHT([WindowBladderLot],9),5,2)) AS DATE), 
		NULL
		)
	) AS [DateOfManufacturing]
INTO #lotsBySize
FROM
(
	SELECT 
		[WindowBladderLot],
		SUM([Record]) AS [LotSizeInField]
	FROM
	(
		SELECT
			W.[SerialNo],
			W.[WindowBladderLot],
			1 AS [Record]
		FROM #windowBladderAtBirth W INNER JOIN #hasShipped S
			ON W.[SerialNo] = S.[SerialNo]
		UNION ALL
		SELECT
			P.[SerialNo],
			REPLACE(W.[WindowBladderReplacementLot],' ','') AS [WindowBladderLot],
			1 AS [Record]	
		FROM #windowBladderLotUsed W INNER JOIN #partInfoPiv P
			ON W.[TicketId] = P.[TicketId]
		WHERE [WindowBladderReplacementLot] IS NOT NULL
	) D
	GROUP BY [WindowBladderLot]
) W LEFT JOIN [ProductionWeb].[dbo].[Lots] L
	ON W.[WindowBladderLot] = L.[LotNumber]
WHERE [WindowBladderLot] NOT LIKE 'N%A'

SELECT
	[TicketId],
	[TicketString],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #complaints
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] = 'BFDX Part Number' AND [PropertyName] IN ('Lot/Serial Number','Failure Mode') AND [Tracker] = 'COMPLAINT'

SELECT 
	[TicketId],
	[TicketString],
	REPLACE(REPLACE(REPLACE([Lot/Serial Number], ' ',''),'.',''),'_','') AS [SerialNo]
INTO #relatedComplaints
FROM #complaints C
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
WHERE [Failure Mode] LIKE '%Pressure Error%'

SELECT
	[TicketId],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #relatedRMA
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] = 'Related RMAs' AND [TicketId] IN (SELECT [TicketId] FROM #relatedComplaints) AND [Tracker] = 'COMPLAINT'

SELECT
	[TicketId],
	CONCAT('RMA-',[RMA]) AS [RelatedRMA],
	REPLACE(IIF(CHARINDEX('KTM', [Description], 1) <> 0, SUBSTRING([Description], CHARINDEX('KTM', [Description], 1), 9),
				IIF(CHARINDEX('TM', [Description], 1) <> 0, SUBSTRING([Description], CHARINDEX('TM', [Description], 1), 7),
				IIF(CHARINDEX('2FA', [Description], 1) <> 0, SUBSTRING([Description], CHARINDEX('2FA', [Description], 1), 8),
				IIF(CHARINDEX('FA', [Description], 1) <> 0, SUBSTRING([Description], CHARINDEX('FA', [Description], 1), 6), NULL)))),' ','') AS [SerialNo]
INTO #relateToSerial
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
WHERE [Description] IS NOT NULL AND ISNUMERIC([RMA]) = 1

SELECT DISTINCT
	C.[TicketId],
	C.[TicketString],
	S.[RelatedRMA],
	S.[SerialNo]
INTO #pressureFail
FROM #relatedComplaints C INNER JOIN #relateToSerial S
	ON C.[TicketId] = S.[TicketId] AND C.[SerialNo] = S.[SerialNo]
ORDER BY [SerialNo]

SELECT 
	F.[TicketId],
	F.[TicketString],
	F.[CreatedDate],
	F.[Status],
	IIF(ISNUMERIC(F.[HoursRun]) = 1, CAST(REPLACE(F.[HoursRun],',','') AS FLOAT), NULL) AS [HoursRun],
	REPLACE(IIF(LEFT(S.[SerialNo],2) LIKE 'FA', UPPER(SUBSTRING(S.[SerialNo],1,6)), 
				IIF(LEFT(S.[SerialNo],3) LIKE '2FA', UPPER(SUBSTRING(S.[SerialNo],1,8)),
				IIF(LEFT(S.[SerialNo],3) LIKE 'KTM', UPPER(SUBSTRING(S.[SerialNo],1,9)), CONCAT('K', UPPER(SUBSTRING(S.[SerialNo],1,7)))))),' ','') AS [SerialNo],
	W.[WindowBladderReplacementLot],
	IIF(W.[WindowBladderReplacementLot] IS NOT NULL AND C.[TicketId] IS NOT NULL, 1,
		IIF(R.[TicketId] IS NOT NULL, 1, 0)) AS [WindowBladderFailure],
	IIF(P.[SerialNo] IS NOT NULL AND F.[Status] IN ('Reporting','Receiving','Quarantine'), 1, 0) AS [FieldV041Error]
INTO #windowBladderReplacements
FROM #freePropPiv F LEFT JOIN #partInfoPiv S
	ON F.[TicketId] = S.[TicketId] LEFT JOIN #windowBladderLotUsed W
		ON F.[TicketId] = W.[TicketId] LEFT JOIN #servCodeIndicatesFailure C
			ON F.[TicketId] = C.[TicketId] LEFT JOIN #rootCauseIndicatesFailure R
				ON F.[TicketId] = R.[TicketId] LEFT JOIN #pressureFail P
					ON S.[SerialNo] = P.[SerialNo] AND F.[TicketString] = P.[RelatedRMA]
WHERE (W.[WindowBladderReplacementLot] IS NOT NULL OR (F.[Status] IN ('Reporting','Receiving','Quarantine') AND P.[SerialNo] IS NOT NULL)) AND LEFT(S.[SerialNo],2) IN ('FA','2F','KT','TM')

SELECT 
	R.[SerialNo],
	R.[WindowBladderFailure],
	R.[FieldV041Error],
	R.[TicketString],
	R.[CreatedDate],
	R.[HoursRun],
	LAG(R.[HoursRun]) OVER(PARTITION BY R.[SerialNo] ORDER BY R.[TicketId]) AS [PriorHours],
	IIF(R.[VisitNo] = 1, B.[WindowBladderLot], NULL) AS [WindowBladderBirthLot],
	R.[WindowBladderReplacementLot],
	LAG(R.[WindowBladderReplacementLot]) OVER(PARTITION BY R.[SerialNo] ORDER BY R.[TicketId]) AS [WindowBladderLotRemoved]
INTO #preppedForAnalysis
FROM
(
	SELECT ROW_NUMBER() OVER(PARTITION BY [SerialNo] ORDER BY [TicketId]) AS [VisitNo],
		*
	FROM #windowBladderReplacements 
) R LEFT JOIN 
(
	SELECT *
	FROM #windowBladderAtBirth
) B
	ON R.[SerialNo] = B.[SerialNo]

SELECT
	[SerialNo],
	[TicketString],
	[CreatedDate],
	[FailType],
	IIF([FailType] LIKE 'ConfirmedFailure' AND [HoursBetweenReplacement] > 0.0000, [HoursBetweenReplacement], 
		IIF([FailType] LIKE 'ConfirmedFailure', [HoursRun], 0)) AS [HoursBetweenReplacement],
	[WindowBladderLotRemovedFromInst]
INTO #failedBladderStats
FROM
(
	SELECT 
		[SerialNo],
		[TicketString],
		[CreatedDate],
		IIF([WindowBladderFailure] = 1, 'ConfirmedFailure',
			IIF([FieldV041Error] = 1 AND [WindowBladderFailure] <> 1 AND [CreatedDate] > GETDATE() - 120, 'PotentialFailure', 'Other')) AS [FailType],
	[PriorHours],
	[HoursRun],
		IIF([PriorHours] IS NULL, [HoursRun], [HoursRun] - [PriorHours]) AS [HoursBetweenReplacement],
		IIF([WindowBladderBirthLot] IS NOT NULL AND [WindowBladderLotRemoved] IS NULL, [WindowBladderBirthLot], [WindowBladderLotRemoved]) AS [WindowBladderLotRemovedFromInst]
	FROM #preppedForAnalysis
	WHERE [WindowBladderFailure] = 1 OR [FieldV041Error] = 1
	GROUP BY 
		[SerialNo],
		[TicketString],
		[CreatedDate],
		[WindowBladderFailure],
		[FieldV041Error],
		[PriorHours],
		[HoursRun],
		[WindowBladderBirthLot],
		[WindowBladderLotRemoved]
) D
WHERE [FailType] LIKE 'ConfirmedFailure' OR [FailType] LIKE 'PotentialFailure' 

SELECT 
	[WindowBladderLotRemovedFromInst],
	[FailType],
	[HoursBetweenBin],
	SUM([EarlyFailureInLot]) AS [EarlyFailuresInLot],
	COUNT([TicketString]) AS [AllFailuresInLot]
INTO #failByLot
FROM
(
	SELECT 
		[WindowBladderLotRemovedFromInst],
		[FailType],
		[TicketString],
		IIF([HoursBetweenReplacement] < 100.0000, 1, 0) AS [EarlyFailureInLot],
		CASE
			WHEN [HoursBetweenReplacement] BETWEEN 0 AND 100 THEN '0-100'
			WHEN [HoursBetweenReplacement] BETWEEN 100 AND 500 THEN '100-500'
			WHEN [HoursBetweenReplacement] BETWEEN 500 AND 1000 THEN '500-1000'
			WHEN [HoursBetweenReplacement] > 1000 THEN '1000+'
			ELSE 'Other'
		END AS [HoursBetweenBin]
	FROM #failedBladderStats
	WHERE [WindowBladderLotRemovedFromInst] IS NOT NULL AND [HoursBetweenReplacement] IS NOT NULL
) T
GROUP BY [WindowBladderLotRemovedFromInst], [FailType], [HoursBetweenBin]

SELECT
	YEAR([DateOfManufacturing]) AS [Year],
	MONTH([DateOfManufacturing]) AS [Month],
	DATEPART(ww,[DateOfManufacturing]) AS [Week],
	[WindowBladderLot],
	[EarlyFailuresInLot],
	[AllFailuresInLot],
	[LotSizeInField],
	[HoursBetweenBin],
	[FailType]
INTO #badLots
FROM #failByLot E LEFT JOIN #lotsBySize L
	ON E.[WindowBladderLotRemovedFromInst] = L.[WindowBladderLot]
WHERE [WindowBladderLot] IS NOT NULL

SELECT 
	[WindowBladderLot],
	[Year],
	[Month],
	[Week],
	[Key],
	ISNULL([RecordedValue],'NoFailure') AS [RecordedValue],
	IIF([RecordedValue] LIKE 'PotentialFailure', 'Unknown', [HoursBetweenBin]) AS [HoursBetweenBin],
	[Record],
	[AdjRecord]
FROM
(
	SELECT
		[WindowBladderLot],
		[Year],
		[Month],
		[Week],
		'EarlyFailuresInLot' AS [Key],
		[FailType] AS [RecordedValue],
		[HoursBetweenBin],
		[EarlyFailuresInLot] AS [Record],
		[AllFailuresInLot] AS [AdjRecord]
	FROM
	(
		SELECT 
			YEAR([DateOfManufacturing]) AS [Year],
			MONTH([DateOfManufacturing]) AS [Month],
			DATEPART(ww,[DateOfManufacturing]) AS [Week],
			[WindowBladderLot],
			0 AS [EarlyFailuresInLot],
			0 AS [AllFailuresInLot],
			[LotSizeInField],
			NULL AS [HoursBetweenBin],
			NULL AS [FailType] 
		FROM #lotsBySize 
		WHERE [WindowBladderLot] NOT IN (SELECT [WindowBladderLot] FROM #badLots) AND [DateOfManufacturing] IS NOT NULL
		UNION
		SELECT *
		FROM #badLots
	) D 
	WHERE [LotSizeInField] > 5
	UNION ALL
	SELECT 
		[WindowBladderLot],
		[Year],
		[Month],
		[Week],
		'LotSizeInLot' AS [Key],
		[FailType] AS [RecordedValue],
		[HoursBetweenBin],
		[LotSizeInField] AS [Record],
		[AllFailuresInLot] AS [AdjRecord]
	FROM
	(
		SELECT 
			YEAR([DateOfManufacturing]) AS [Year],
			MONTH([DateOfManufacturing]) AS [Month],
			DATEPART(ww,[DateOfManufacturing]) AS [Week],
			[WindowBladderLot],
			0 AS [EarlyFailuresInLot],
			0 AS [AllFailuresInLot],
			[LotSizeInField],
			NULL AS [HoursBetweenBin],
			NULL AS [FailType]
		FROM #lotsBySize 
		WHERE [WindowBladderLot] NOT IN (SELECT [WindowBladderLot] FROM #badLots) AND [DateOfManufacturing] IS NOT NULL
		UNION
		SELECT *
		FROM #badLots
	) D 
	WHERE [LotSizeInField] > 5
) T
WHERE [Year] IS NOT NULL

DROP TABLE #freePropPiv, #freePropPrePiv, #hasShipped, #partInfoPiv, #partInfoPrePiv, #partsUsedPrePiv, #rootCauseIndicatesFailure, #servCodeIndicatesFailure, 
			#badLots, #failByLot, #failedBladderStats, #lotsBySize, #preppedForAnalysis, #windowBladderAtBirth, #windowBladderLotUsed, #windowBladderReplacements, #complaints,
			#pressureFail, #relatedComplaints, #relatedRMA, #relateToSerial, #serialTrans
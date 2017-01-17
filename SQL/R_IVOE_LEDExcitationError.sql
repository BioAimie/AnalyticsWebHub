SET NOCOUNT ON

SELECT
	[TicketId],
	[TicketString],
	[CreatedDate],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #failureMode
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] = 'BFDX Part Number' AND [PropertyName] IN ('Failure Mode', 'Lot/Serial Number') AND [Tracker] = 'COMPLAINT'

SELECT
	[TicketId],
	[TicketString],
	[CreatedDate],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #relatedRMA
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] = 'Related RMAs' AND [Tracker] = 'COMPLAINT'

SELECT
	F.[TicketString],
	F.[CreatedDate],
	F.[Lot/Serial Number] AS [SerialNo],
	R.[RMA],
	R.[Description],
	CHARINDEX(REPLACE(F.[Lot/Serial Number], ' ', ''), R.[Description], 1) AS [Index]
INTO #pivoted
FROM
(
	SELECT *
	FROM #failureMode F
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
	WHERE [Failure Mode] = '7003 Failed Excitation Check-1-0'
) F LEFT JOIN 
(
	SELECT *
	FROM #relatedRMA  R
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
	ON F.[TicketId] = R.[TicketId]

SELECT *
INTO #complaints
FROM
(
	SELECT 
		[TicketString] AS [ComplaintNo],
		[SerialNo],
		[RMA],
		IIF([Index] > 0, 1, 0) AS [ReturnedToService],
		1 AS [FailCount]
	FROM #pivoted P
	WHERE [Index] > 0 OR [RMA] LIKE 'N%A'
) T

SELECT 
	[TicketId],
	[RecordedValue] AS [Disposition]
INTO #disposition
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] = 'Part Disposition' AND [Tracker] = 'RMA'

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[RecordedValue] AS [SerialNo]
INTO #partInfo
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] = 'Part Information' AND [PropertyName] = 'Lot/Serial Number' AND [Tracker] = 'RMA'

SELECT 
	[TicketId],
	SUBSTRING([TicketString], 5, 10) AS [RMA],
	[RecordedValue] AS [HoursRun]
INTO #hoursRun
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] = 'Hours Run' AND [RecordedValue] <> '' AND [RecordedValue] NOT LIKE '%n%a%'  AND [Tracker] = 'RMA'

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	UPPER(REPLACE(REPLACE(REPLACE([SerialNo],' ',''),'_',''),'-','')) AS [SerialNo]
INTO #partInfoAll
FROM
(
	SELECT 
		P.*,
		D.[Disposition]
	FROM #partInfo P LEFT JOIN #disposition D
		ON P.[TicketId] = D.[TicketId]
	WHERE LEFT([SerialNo], 2) IN ('2F','FA','TM') OR LEFT([SerialNo],4) LIKE 'HTPM'
) T

SELECT 
	[TicketId],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #partsUsed
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] = 'Parts Used' AND [TicketId] IN (SELECT [TicketId] FROM #partInfoAll) AND [Tracker] = 'RMA'

SELECT
	[CreatedDate],
	[TicketString],
	[SerialNo],
	IIF(CHARINDEX(':', [Config], 1) <> 0 , SUBSTRING([Config], 1, CHARINDEX(':', [Config], 1)-1), [Config]) AS [Config],
	[Part Used],
	[Lot/Serial Number],
	CAST([HoursRun] AS FLOAT) AS [HoursRun]
INTO #partsAdded
FROM
(
	SELECT 
		I.[TicketId],
		I.[CreatedDate],
		I.[TicketString],
		I.[SerialNo],
		IIF(I.[TicketId] < 35863, '071709', UPPER(U.[Lot/Serial Number])) AS [Config],
		U.[Part Used],
		U.[Lot/Serial Number]
	FROM #partInfoAll I INNER JOIN 
	(
		SELECT *
		FROM #partsUsed U
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
	) U
		ON I.[TicketId] = U.[TicketId]
	WHERE (U.[Part Used] LIKE '%MOTR%' OR U.[Part Used] LIKE '%FLM1-SUB-0006%')
) T LEFT JOIN #hoursRun H
	ON T.[TicketId] = H.[TicketId]
WHERE [Config] IS NOT NULL

SELECT
	P.[PartNumber],
	REPLACE(REPLACE(REPLACE(IIF(L.[LotNumber] LIKE 'KTM%', SUBSTRING(L.[LotNumber], 2, 12), L.[LotNumber]), '.',''),'_',''),'-','') AS [SerialNo],
	UPPP.[LotNumber] AS [SubLotNumber],
	IIF(CHARINDEX(':', UPPPP.[LotNumber], 1) <> 0 , SUBSTRING(UPPPP.[LotNumber], 1, CHARINDEX(':', UPPPP.[LotNumber], 1)-1), UPPPP.[LotNumber]) AS [LotNumber]
INTO #birthLots
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
WHERE (P.[PartNumber] LIKE 'FLM%-ASY-0001' OR P.[PartNumber] LIKE 'HTFA-ASY-0003%') 
	AND UPPPP.[PartNumber] LIKE 'MOTR-DCM-0006' AND UPPPP.[Quantity] > 0

SELECT *
INTO #Lots
FROM
(
	SELECT 
		L.[LotNumber] AS [SubLotNumber], 
		UL.[LotNumber]
	FROM [ProductionWeb].[dbo].[Parts] P INNER JOIN [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) 
		ON P.[PartNumberId] = L.[PartNumberId] INNER JOIN [ProductionWeb].[dbo].[UtilizedParts] U WITH(NOLOCK)
			ON L.[LotNumberId] = U.[LotNumberId] LEFT JOIN [ProductionWeb].[dbo].[Lots] UL WITH(NOLOCK)
				ON U.[LotNumber] = UL.[LotNumber]
	WHERE U.[PartNumber] LIKE 'MOTR-DCM-0006' AND U.[Quantity] > 0 
		AND UL.[LotNumber] IS NOT NULL
	GROUP BY 
		L.[LotNumber], 
		UL.[LotNumber]
UNION
	SELECT 
		L.[LotNumber] AS [SubLotNumber],
		SUBSTRING(U.[LotNumber], 1, CHARINDEX(':', U.[LotNumber],1) - 1) AS [LotNumber]
	FROM [ProductionWeb].[dbo].[UtilizedParts] U WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[Lots] UL WITH(NOLOCK)
		ON UL.[LotNumber] = SUBSTRING(U.[LotNumber], 1, CHARINDEX(':', U.[LotNumber],1) - 1) LEFT JOIN [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK)
			ON U.[LotNumberId] = L.[LotNumberId] LEFT JOIN [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK)
				ON L.[PartNumberId] = P.[PartNumberId]
	WHERE U.[PartNumber] LIKE 'MOTR-DCM-0006' AND CHARINDEX(':', U.[LotNumber], 1) <> 0 AND U.[Quantity] > 0
	GROUP BY 
		L.[LotNumber], 
		U.[LotNumber]
) T

SELECT
	[SerialNo],
	[CreatedDate],
	SUBSTRING([TicketString], 5, 10) AS [RMA],
	SUBSTRING([PriorRMA], 5, 10) AS [PriorRMA],
	IIF([PriorHours] IS NULL OR [PriorHours] > [HoursRun], [HoursRun], [HoursRun] - [PriorHours]) AS [HoursRun],
	IIF([LotRemoved] IS NULL, [BirthLot], [LotRemoved]) AS [LotRemovedInService]
INTO #servicedInstHistory
FROM
(
	SELECT *,
		LAG([TicketString],1) OVER(PARTITION BY [SerialNo] ORDER BY [TicketString]) AS [PriorRMA],
		LAG([LotAdded], 1) OVER(PARTITION BY [SerialNo] ORDER BY [TicketString]) AS [LotRemoved],
		LAG([HoursRun]) OVER(PARTITION BY [SerialNo] ORDER BY [TicketString]) AS [PriorHours]
	FROM
	(
		SELECT 
			[SerialNo],
			[CreatedDate],
			[TicketString],
			[BirthLot],
			IIF([PartReplaced] LIKE 'FLM1-SUB-0006' AND [LotInProdWeb] IS NOT NULL, [LotInProdWeb], [LotAdded]) AS [LotAdded],
			[HoursRun]
		FROM
		(
			SELECT
				R.[CreatedDate],
				R.[TicketString],
				R.[SerialNo],
				R.[HoursRun],
				R.[Part Used] AS [PartReplaced],
				R.[Config] AS [LotAdded],
				ISNULL(B.[SubLotNumber], '071709') AS [BirthSubLot],
				ISNULL(B.[LotNumber], '071709') AS [BirthLot],
				ISNULL(L.[LotNumber], LL.[LotNumber]) AS [LotInProdWeb]
			FROM #partsAdded R LEFT JOIN #birthLots B
					ON R.[SerialNo] = B.[SerialNo] LEFT JOIN #Lots L
						ON R.[Config] = L.[LotNumber] LEFT JOIN #Lots LL
							ON R.[Config] = LL.[SubLotNumber]
			GROUP BY
				R.[CreatedDate],
				R.[TicketString],
				R.[SerialNo],
				R.[HoursRun],
				R.[Part Used],
				R.[Config],
				B.[SubLotNumber],
				B.[LotNumber],
				L.[LotNumber], 
				LL.[LotNumber]
		) T
		GROUP BY
			[SerialNo],
			[CreatedDate],
			[TicketString],
			[BirthLot],
			[PartReplaced],
			[LotInProdWeb],
			[LotAdded],
			[HoursRun]
	) T
) T

SELECT
	REPLACE(S.[SerialNo], ' ','') AS [SerialNo],
	S.[CreatedDate],
	S.[RMA],
	S.[PriorRMA], 
	C.[ComplaintNo], 
	S.[HoursRun],
	S.[LotRemovedInService],
	ISNULL(C.[FailCount],0) AS [ExcitationErrorReported]
INTO #servicedWithAnnotations
FROM #servicedInstHistory S LEFT JOIN #complaints C
	ON S.[RMA] = C.[RMA]

SELECT 
	REPLACE(C.[SerialNo],' ','') AS [SerialNo],
	P.[CreatedDate],
	C.[RMA],
	C.[ComplaintNo],
	[HoursRun],
	ISNULL(B.[LotNumber],'071709') AS [LotToBeRemovedInService],
	C.[FailCount] AS [ExcitationErrorReported]
INTO #outstandingComplaints
FROM #complaints C LEFT JOIN #birthLots B
	ON C.[SerialNo] = B.[SerialNo] LEFT JOIN #partInfo P
		ON C.[RMA] = SUBSTRING(P.[TicketString], 5, 10) LEFT JOIN #hoursRun H
			ON P.[TicketId] = H.[TicketId]
WHERE C.[RMA] NOT IN (SELECT [RMA] FROM #servicedWithAnnotations) AND LEFT(C.[SerialNo] ,2) IN ('2F','FA','HT','TM')

SELECT 
	ISNULL(S.[SerialNo], O.[SerialNo]) AS [SerialNo],
	ISNULL(S.[CreatedDate], O.[CreatedDate]) AS [CreatedDate],
	ISNULL(S.[RMA], O.[RMA]) AS [RMA],
	S.[PriorRMA], 
	ISNULL(S.[ComplaintNo], O.[ComplaintNo]) AS [ComplaintNo],
	ISNULL(S.[HoursRun], O.[HoursRun]) AS [HoursRun],
	ISNULL(S.[LotRemovedInService], O.[LotToBeRemovedInService]) AS [BeadBeaterLot],
	ISNULL(S.[ExcitationErrorReported], O.[ExcitationErrorReported]) AS [ExcitationErrorReported],
	IIF(S.[RMA] IS NOT NULL, 1, 
		IIF(O.[RMA] IS NOT NULL AND O.[RMA] NOT LIKE 'N%A', 1, 0)) AS [ReturnedForService],
	IIF(O.[HoursRun] IS NOT NULL, 1, 0) AS [ErrorReportedLotNotReplaced]
INTO #fieldComplaints
FROM #servicedWithAnnotations S FULL OUTER JOIN #outstandingComplaints O
	ON S.[RMA] = O.[RMA]
WHERE S.[ExcitationErrorReported] = 1 OR O.[ExcitationErrorReported] = 1

SELECT 
	[SerialNo],
	MIN([TranDate]) AS [ShipDate]
INTO #shipped
FROM
(
	SELECT
		UPPER(REPLACE([SerialNo],'R','')) AS [SerialNo],
		[TranDate]
	FROM [PMS1].[dbo].[vSerialTransactions] WITH(NOLOCK)
	WHERE [TranType] LIKE 'SH' OR ([TranType] IN ('IS','SA') AND [DistQty] = -1)
) T
GROUP BY [SerialNo]

SELECT
	[SerialNo],
	[ShipDate],
	IIF([LotShipped] LIKE '071709', '071709',
		IIF([LotShipped] IN ('6483110515.00','6483012516.00') AND [SerialNo] IN
		(
			'2FA01832','2FA01886','2FA01905','2FA01907','2FA01921','2FA01934','2FA01938','2FA01941','2FA01942','2FA01943','2FA01945','2FA01962','2FA01970','2FA01971','2FA01977','2FA01982','2FA01983',
			'2FA01984','2FA01986','2FA01988','2FA01990','2FA01991','2FA01992','2FA01997','2FA01998','2FA01999','2FA02001','2FA02013','2FA02034','2FA02038','2FA02039','2FA02043','2FA02046','2FA02052',
			'2FA02056','2FA02057','2FA02060','2FA02062','2FA02063','2FA02064','2FA02065','2FA02067','2FA02070','2FA02072','2FA02073','2FA02074','2FA02077','2FA02078','2FA02080','2FA02086','2FA02087',
			'2FA02088','2FA02090','2FA02094','2FA02097','2FA02099','2FA02100','2FA02101','2FA02102','2FA02103','2FA02118','2FA02123','2FA02131','2FA02132','2FA02139','2FA02146','2FA02152','2FA02153',
			'2FA02154','2FA02155','2FA02156','2FA02159','2FA02160','2FA02162','2FA02163','2FA02168','2FA02169','2FA02170','2FA02171','2FA02174','2FA02179','2FA02180','2FA02181','2FA02182','2FA02183',
			'2FA02185','2FA02186','2FA02187','2FA02188','2FA02189','2FA02190','2FA02193','2FA02194','2FA02196','2FA02197','2FA02198','2FA02202','2FA02204','2FA02205','2FA02222','2FA02224','2FA02225',
			'2FA02226','2FA02227','2FA02228','2FA02230','2FA02231','2FA02232','2FA02235','2FA02243','2FA02245','2FA02247','2FA02250','2FA02252','2FA02253','2FA02256','2FA02257','2FA02258','2FA02259',
			'2FA02260','2FA02261','2FA02262','2FA02264','2FA02266','2FA02268','2FA02271','2FA02272','2FA02277','2FA02280','2FA02282','2FA02285','2FA02287','2FA02289','2FA02290','2FA02292','2FA02295',
			'2FA02296','2FA02297','2FA02298','2FA02299','2FA02301','2FA02307','2FA02309','2FA02310','2FA02312','2FA02316','2FA02317','2FA02320','2FA02321','2FA02322','2FA02323','2FA02325','2FA02327',
			'2FA02328','2FA02329','2FA02331','2FA02332','2FA02335','2FA02336','2FA02338','2FA02339','2FA02340','2FA02342','2FA02343','2FA02344','2FA02347','2FA02348','2FA02349','2FA02350','2FA02351',
			'2FA02352','2FA02354','2FA02356','2FA02357','2FA02359','2FA02360','2FA02361','2FA02362','2FA02363','2FA02365','2FA02366','2FA02367','2FA02368','2FA02369','2FA02370','2FA02373','2FA02374',
			'2FA02375','2FA02376','2FA02377','2FA02378','2FA02379','2FA02380','2FA02381','2FA02383','2FA02384','2FA02387','2FA02388','2FA02388','2FA02389','2FA02391','2FA02393','2FA02394','2FA02395',
			'2FA02396','2FA02399','2FA02400','2FA02401','2FA02402','2FA02406','2FA02408','2FA02409','2FA02410','2FA02411','2FA02414','2FA02415','2FA02417','2FA02421','2FA02422','2FA02426','2FA02427',
			'2FA02431','2FA02432','2FA02435','2FA02436','2FA02437','2FA02439','2FA02441','2FA02444','2FA02446','2FA02448','2FA02451','2FA02451','2FA02452','2FA02455','2FA02457','2FA02460','2FA02461',
			'2FA02462','2FA02464','2FA02465','2FA02466','2FA02468','2FA02469','2FA02470','2FA02471','2FA02472','2FA02473','2FA02474','2FA02476','2FA02478','2FA02480','2FA02481','2FA02482','2FA02485',
			'2FA02486','2FA02487','2FA02488','2FA02490','2FA02492','2FA02493','2FA02495','2FA02497','2FA02500','2FA02504','2FA02505','2FA02507','2FA02509','2FA02510','2FA02511','2FA02512','2FA02514',
			'2FA02515','2FA02516','2FA02517','2FA02518','2FA02520','2FA02522','2FA02525','2FA02528','2FA02533','2FA02534','2FA02540','2FA02541','2FA02544','2FA02546','2FA02547','2FA02549','2FA02550',
			'2FA02551','2FA02554','2FA02555','2FA02556','2FA02558','2FA02559','2FA02560','2FA02562','2FA02564','2FA02565','2FA02567','2FA02568','2FA02570','2FA02572','2FA02573','2FA02574','2FA02576',
			'2FA02578','2FA02580','2FA02585','2FA02587','2FA02590','2FA02591','2FA02593','2FA02594','2FA02595','2FA02596','2FA02601','2FA02602','2FA02603','2FA02604','2FA02605','2FA02606','2FA02607',
			'2FA02608','2FA02609','2FA02610','2FA02611','2FA02612','2FA02613','2FA02616','2FA02617','2FA02618','2FA02619','2FA02620''2FA02622','2FA02623','2FA02624','2FA02625','2FA02626','2FA02629',
			'2FA02630','2FA02633','2FA02635','2FA02636','2FA02638','2FA02639','2FA02640','2FA02641','2FA02642','2FA02643','2FA02644','2FA02645','2FA02648','2FA02672'
		), 'Bad-Reworked',
		IIF([LotShipped] IN ('6483110515.00','6483012516.00') AND [ShipDate] < CONVERT(DATETIME, '2016-04-19'), 'Bad-NoScreeningOrRework',
		IIF([LotShipped] IN ('6483110515.00','6483012516.00'), 'Bad-WithScreening', [LotShipped])))) AS [LotFlag]
INTO #lotGroupsShipped
FROM 
(
	SELECT 
		S.[SerialNo],
		S.[ShipDate],
		ISNULL(B.[LotNumber], '071709') AS [LotShipped]
	FROM #shipped S INNER JOIN #birthLots B
		ON S.[SerialNo] = B.[SerialNo]
) T

SELECT 
	ISNULL(F.[Lot], S.[Lot]) AS [Lot],
	ISNULL(F.[HoursBetweenBin], 'NoFailures') AS [Key],
	ISNULL(F.[Record], 0) AS [Record],
	S.[LotSizeInField]
INTO #master
FROM
(
	SELECT 
		ISNULL([LotFlag], [BeadBeaterLot]) AS [Lot],
		CASE
			WHEN [HoursRun] IS NULL THEN 'Unknown'
			WHEN [HoursRun] BETWEEN 0 AND 99.9999999 THEN '0-100'
			WHEN [HoursRun] BETWEEN 100 AND 499.9999999 THEN '100-500'
			WHEN [HoursRun] BETWEEN 500 AND 999.9999999 THEN '500-1000'
			ELSE '1000+'
		END AS [HoursBetweenBin],
		[ExcitationErrorReported] AS [Record]
	FROM #fieldComplaints C LEFT JOIN #lotGroupsShipped L
		ON C.[SerialNo] = L.[SerialNo]
) F FULL OUTER JOIN
(
	SELECT 
		[LotFlag] AS [Lot],
		SUM([LotShipped]) AS [LotSizeInField]
	FROM
	(
		SELECT 
			[LotFlag],
			COUNT([SerialNo]) AS [LotShipped]
		FROM #lotGroupsShipped
		GROUP BY [LotFlag]
		UNION ALL
		SELECT 
			[LotFlag],
			COUNT([SerialNo]) AS [LotShipped]
		FROM
		(
			SELECT 
				IIF([LotAdded]  IN ('6483110515.00','6483012516.00') AND [CreatedDate] < CONVERT(DATETIME, '2016-04-19'), 'Bad-NoScreeningOrRework', 
					IIF([LotAdded]  IN ('6483110515.00','6483012516.00'), 'Bad-WithScreening', [LotAdded])) AS [LotFlag],
				[SerialNo]
			FROM
			(
				SELECT 
					[SerialNo],
					[CreatedDate],
					[TicketString],
					[BirthLot],
					IIF([PartReplaced] LIKE 'FLM1-SUB-0006' AND [LotInProdWeb] IS NOT NULL, [LotInProdWeb], [LotAdded]) AS [LotAdded],
					[HoursRun]
				FROM
				(
					SELECT
						R.[CreatedDate],
						R.[TicketString],
						R.[SerialNo],
						R.[HoursRun],
						R.[Part Used] AS [PartReplaced],
						R.[Config] AS [LotAdded],
						ISNULL(B.[SubLotNumber], '071709') AS [BirthSubLot],
						ISNULL(B.[LotNumber], '071709') AS [BirthLot],
						ISNULL(L.[LotNumber], LL.[LotNumber]) AS [LotInProdWeb]
					FROM #partsAdded R LEFT JOIN #birthLots B
							ON R.[SerialNo] = B.[SerialNo] LEFT JOIN #Lots L
								ON R.[Config] = L.[LotNumber] LEFT JOIN #Lots LL
									ON R.[Config] = LL.[SubLotNumber]
					GROUP BY
						R.[CreatedDate],
						R.[TicketString],
						R.[SerialNo],
						R.[HoursRun],
						R.[Part Used],
						R.[Config],
						B.[SubLotNumber],
						B.[LotNumber],
						L.[LotNumber], 
						LL.[LotNumber]
				) T
				GROUP BY
					[SerialNo],
					[CreatedDate],
					[TicketString],
					[BirthLot],
					[PartReplaced],
					[LotInProdWeb],
					[LotAdded],
					[HoursRun]
			) A 
		) T
		GROUP BY [LotFlag]
	) S
	GROUP BY [LotFlag]
) S
	ON F.[Lot] = S.[Lot]
WHERE [LotSizeInField] > 5

SELECT 
	[Lot],
	[Key],
	SUM([Record]) AS [Record],
	AVG([LotSizeInField]) AS [LotSizeInField]
FROM
(
	SELECT 
		IIF(CHARINDEX(':', [Lot],1) <> 0, SUBSTRING([Lot], 1, CHARINDEX(':', [Lot], 1)-1), [Lot]) AS [Lot],
		[Key],
		[Record],
		[LotSizeInField]
	FROM #master
) T
GROUP BY
	[Lot],
	[Key]

DROP TABLE #failureMode, #relatedRMA, #pivoted, #complaints, #partInfo, #hoursRun, #partsUsed, #partsAdded, #birthLots, #Lots, #servicedInstHistory, #servicedWithAnnotations,
			#outstandingComplaints, #fieldComplaints, #shipped, #lotGroupsShipped, #disposition, #partInfoAll, #master

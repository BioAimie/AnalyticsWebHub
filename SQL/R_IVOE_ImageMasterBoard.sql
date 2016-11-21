SET NOCOUNT ON

SELECT 
	L.[LotNumber] AS [SerialNo],
	UPP.[PartNumber],
	SUBSTRING(ULLL.[LotNumber], 1, CHARINDEX('.', ULLL.[LotNumber],1)-1) AS [LotNumber],
	ULLL.[ActualLotSize]
INTO #pcbaLotsInProd
FROM [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) 
	ON P.[PartNumberId] = L.[PartNumberId] INNER JOIN [ProductionWeb].[dbo].[UtilizedParts] U WITH(NOLOCK)
		ON L.[LotNumberId] = U.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[Lots] UL WITH(NOLOCK)
			ON U.[LotNumber] = UL.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[UtilizedParts] UP WITH(NOLOCK)
				ON UL.[LotNumberId] = UP.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[Lots] ULL WITH(NOLOCK)
					ON UP.[LotNumber] = ULL.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[UtilizedParts] UPP WITH(NOLOCK)
						ON ULL.[LotNumberId] = UPP.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[Lots] ULLL WITH(NOLOCK)
							ON UPP.[LotNumber] = ULLL.[LotNumber]
WHERE P.[PartNumber] LIKE 'FLM%-ASY-0001' AND UP.[PartNumber] LIKE 'FLM%-SUB-0013' AND UPP.[PartNumber] LIKE 'PCBA-SUB-0839' AND UPP.[Quantity] > 0 AND ULLL.[LotNumber] NOT LIKE 'N/A'

SELECT DISTINCT
	SUBSTRING(L.[LotNumber], 1, CHARINDEX('.', L.[LotNumber],1)-1) AS [LotNumber],
	L.[ActualLotSize]
INTO #pcbaLots
FROM [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) 
	ON P.[PartNumberId] = L.[PartNumberId]
WHERE P.[PartNumber] LIKE 'PCBA-SUB-0839'

SELECT 
	[TicketId],
	[TicketString], 
	[CreatedDate],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #rawNCR
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Parts Affected' AND [PropertyName] IN ('Part Affected', 'Lot or Serial Number', 'Quantity Affected', 'Disposition')

SELECT 
	[LotNumber],
	SUM(CAST([ncrQty] AS INT)) AS [ncrQty]
INTO #pcbaNCRs
FROM
(
	SELECT 
		[TicketString],
		[CreatedDate],
		REPLACE(SUBSTRING(REPLACE([Lot or Serial Number],' ',''), 1, CHARINDEX('.', REPLACE([Lot or Serial Number],' ',''), 1)),'.','') AS [LotNumber],
		[Quantity Affected] AS [ncrQty],
		[Disposition]
	FROM #rawNCR P
	PIVOT
	(
		MAX([RecordedValue])
		FOR [PropertyName]
		IN
		(
			[Part Affected],
			[Lot or Serial Number],
			[Quantity Affected],
			[Disposition]
		)
	) PIV
	WHERE [Part Affected] LIKE 'PCBA-SUB-0839'
) T
GROUP BY [LotNumber]

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
WHERE [PropertyName] IN ('Hours Run','Complaint Number','RMA Type','RMA Title') 

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[Part Number], 
	UPPER([Lot/Serial Number]) AS [SerialNo],
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
		[Hours Run]
	)
) PIV

SELECT 
	P.[TicketId],
	P.[SerialNo],
	[TicketString],
	[CreatedDate],
	[Part Number],
	[Title],
	[CustFailType],
	[Type],
	CAST([HoursRun] AS FLOAT) AS [HoursRun],
	IIF([Type] LIKE '% - Failure', 1, 0) AS [FailureType],
	IIF([CustFailType] IN ('DOA','ELF'), 1, 0) AS [CustFailTypeProd],
	IIF(CAST([HoursRun] AS FLOAT) < 100.0001, 1, 0) AS [HoursRunLow],
	IIF([Title] LIKE '% error%' OR [Title] LIKE '% fail%' OR [Title] LIKE '%DOA%' OR [Title] LIKE '%ELF%',1, 0) AS [TitleFail],
	IIF(ISNUMERIC([Complaint])=1, 1, 0) AS [Complaint]
INTO #flaggedForFailures
FROM #partInfoPiv P LEFT JOIN #freePropPiv F
		ON P.[TicketId] = F.[TicketId]
WHERE [HoursRun] NOT LIKE 'N%A' AND [HoursRun] IS NOT NULL

SELECT 
	[TicketId],
	[SerialNo],
	IIF([FailureType] = 1 AND [HoursRunLow] = 1, 1,
		IIF([CustFailTypeProd] = 1 AND [HoursRunLow] = 1, 1,
		IIF([CustFailTypeProd] = 1 AND [HoursRun] IS NULL, 1,
		IIF([TitleFail] = 1 AND [HoursRunLow] = 1, 1, 
		IIF([Complaint] = 1 aND [HoursRunLow] = 1, 1, 0))))) AS [Failure]
INTO #failedInst
FROM #flaggedForFailures

SELECT 
	[TicketId],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #partsUsed
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Parts Used'

SELECT 
	F.[TicketId],
	F.[SerialNo],
	REPLACE(SUBSTRING(P.[LotNumber], 1, CHARINDEX('.', P.[LotNumber],1)),'.','') AS [LotNumber],
	F.[Failure]
INTO #pcbaRMAs
FROM #failedInst F INNER JOIN
(
	SELECT 
		[TicketId],
		[Lot/Serial Number] AS [LotNumber]
	FROM #partsUsed P
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
	WHERE [Part Used] LIKE 'PCBA-SUB-0839'
) P
	ON F.[TicketId] = P.[TicketId]

SELECT 
	L.[LotNumber],
	SUM(L.[ActualLotSize]) AS [ActualLotSize],
	ISNULL(N.[LotSizeUsed],0) + ISNULL(R.[LotSizeUsed],0) AS [LotSizeUsed]
INTO #lotSizes
FROM #pcbaLots L LEFT JOIN
(
	SELECT 
		[LotNumber],
		COUNT([SerialNo]) AS [LotSizeUsed]
	FROM #pcbaLotsInProd
	GROUP BY [LotNumber]
) N	
	ON L.[LotNumber] = N.[LotNumber] LEFT JOIN
	(
		SELECT 
			[LotNumber],
			COUNT([TicketId]) AS [LotSizeUsed]
		FROM #pcbaRMAs
		GROUP BY [LotNumber]
	) R
		ON L.[LotNumber] = R.[LotNumber]
GROUP BY 
	L.[LotNumber], 
	N.[LotSizeUsed],
	R.[LotSizeUsed]

SELECT 
	L.[LotNumber], 
	CAST(CONCAT(CONCAT('20', SUBSTRING(RIGHT(L.[LotNumber], 6), 5, 2)), '-', SUBSTRING(RIGHT(L.[LotNumber], 6), 1, 2), '-', SUBSTRING(RIGHT(L.[LotNumber], 6), 3, 2)) AS DATE) AS [Date],
	L.[ActualLotSize],
	L.[LotSizeUsed],
	N.[ncrQty],
	R.[rmaQty]
INTO #master
FROM #lotSizes L LEFT JOIN #pcbaNCRs N
	ON L.[LotNumber] = N.[LotNumber] LEFT JOIN 
	(
		SELECT 
			[LotNumber],
			COUNT([TicketId]) AS [rmaQty]
		FROM #pcbaRMAs
		WHERE [Failure] = 1
		GROUP BY [LotNumber]
	) R
		ON L.[LotNumber] = R.[LotNumber]
WHERE L.[ActualLotSize] > 0

SELECT
	[LotNumber],
	YEAR([Date]) AS [Year],
	DATEPART(ww, [Date]) AS [Week],
	[ActualLotSize],
	[LotSizeUsed],
	ISNULL([rmaQty], 0) AS [QtyFailedInField],
	ISNULL([ncrQty],0) AS [QtyFailedInHouse]
FROM #master
WHERE [ActualLotSize] > 5
ORDER BY [Date]

DROP TABLE  #failedInst, #flaggedForFailures, #freePropPiv, #freePropPivrops, #lotSizes, #master, #partInfo, #partInfoPiv, #partsUsed, #pcbaLots, #pcbaLotsInProd, #pcbaNCRs, #pcbaRMAs, #rawNCR
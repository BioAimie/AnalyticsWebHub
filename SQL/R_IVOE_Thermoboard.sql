SET NOCOUNT ON;

WITH [BirthLot] ([TopLotID], [BottomLot], [BottomPart])
AS (
	SELECT
		[LotNumberID] AS [TopLotID],
		[LotNumber] AS [BottomLot],
		[PartNumber] AS [BottomPart]
	FROM [ProductionWeb].[dbo].[UtilizedParts] WITH(NOLOCK)
	WHERE [Quantity]>0
	UNION ALL
	SELECT
		U.[LotNumberId] AS [TopLotID],
		D.[BottomLot] AS [BottomLot],
		D.[BottomPart] AS [BottomPart]
	FROM [BirthLot] D INNER JOIN [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK)
		ON D.[TopLotID] = L.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[UtilizedParts] U WITH(NOLOCK)
			ON L.[LotNumber] = U.[LotNumber]
	WHERE U.[Quantity]>0
)
SELECT DISTINCT
	REPLACE(REPLACE(REPLACE(TL.[LotNumber],'.',''),'_',''),' ','') AS [SerialNo],
	B.[BottomLot] AS [LotNumber],
	BL.[ActualLotSize]
INTO #pcbaLotsInProd
FROM [BirthLot] B INNER JOIN [ProductionWeb].[dbo].[Lots] BL WITH(NOLOCK)
	ON B.[BottomLot] = BL.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[Lots] TL WITH(NOLOCK)
		ON B.[TopLotID] = TL.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[Parts] TP WITH(NOLOCK)
			ON TP.[PartNumberId] = TL.[PartNumberId]
WHERE TP.[PartNumber] IN ('FLM1-ASY-0001','FLM2-ASY-0001','HTFA-SUB-0103')
	AND [BottomPart] = 'PCBA-SUB-0836' AND [BottomLot] != 'N/A'

SELECT DISTINCT
	L.[LotNumber],
	L.[ActualLotSize],
	L.[DesiredLotSize]
INTO #pcbaLots
FROM [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) 
	ON P.[PartNumberId] = L.[PartNumberId]
WHERE P.[PartNumber] LIKE 'PCBA-SUB-0836'

SELECT 
	[TicketId],
	[TicketString], 
	[CreatedDate],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #rawNCR
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE Tracker = 'NCR' AND [ObjectName] = 'Parts Affected' AND [PropertyName] IN ('Part Affected', 'Lot or Serial Number', 'Quantity Affected', 'Disposition')

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #partInfo
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE Tracker = 'RMA' AND [ObjectName] = 'Part Information'

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[PropertyName],
	[RecordedValue]
INTO #freePropPivrops
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE Tracker = 'RMA' AND [PropertyName] IN ('Hours Run','Complaint Number','RMA Type','RMA Title') 

SELECT 
	[TicketId],
	[TicketString],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #partsUsed
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE Tracker = 'RMA' AND [ObjectName] = 'Parts Used'

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[Part Number], 
	REPLACE(REPLACE(REPLACE(REPLACE(UPPER([Lot/Serial Number]),'.',''),'_',''),' ',''),'KTM','TM') AS [SerialNo],
	[Lot/Serial Number],
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
	[LotNumber],
	CAST([ncrQty] AS INT) AS [ncrQty],
	[Disposition]
INTO #pcbaNCRs
FROM
(
	SELECT 
		[TicketString],
		[CreatedDate],
		RTRIM(LTRIM(SUBSTRING([Lot or Serial Number], 1, CHARINDEX(':',[Lot or Serial Number]+':')-1))) AS [LotNumber],
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
	WHERE [Part Affected] LIKE 'PCBA-SUB-0836'
) T
--GROUP BY [LotNumber]

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
	F.[TicketId],
	P.[TicketString],
	F.[SerialNo],
	P.[LotNumber],
	F.[Failure]
INTO #pcbaRMAs
FROM #failedInst F INNER JOIN
(
	SELECT
		[TicketId],
		[TicketString],
		SUBSTRING(LTRIM([Lot/Serial Number]), 1, PATINDEX('%[:/ ]%',[Lot/Serial Number]+':')-1) AS [LotNumber],
		[Part Used],
		[Lot/Serial Number]
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
	WHERE [Part Used] = 'PCBA-SUB-0836'
) P
	ON F.[TicketId] = P.[TicketId]


SELECT * FROM #pcbaRMAs
WHERE [TicketString] IN ('RMA-8039', 'RMA-8855', 'RMA-9237', 'RMA-9321', 'RMA-10917', 'RMA-12665', 'RMA-6918', 'RMA-10063', 'RMA-10504', 'RMA-10920', 'RMA-13151')


SELECT
	L.[LotNumber],
	SUM(L.[ActualLotSize]) AS [ActualLotSize],
	SUM(L.[DesiredLotSize]) AS [DesiredLotSize],
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
    R.[SerialNo],
	LAG(R.[LotNumber],1) OVER(PARTITION BY R.[SerialNo] ORDER BY R.[TicketId]) AS [LotNumber],
	R.[Failure],
	P.[LotNumber] AS [BirthLot]
INTO #RMApreviousLot
FROM #pcbaRMAs R LEFT JOIN #pcbaLotsInProd P
	ON R.[SerialNo] = P.[SerialNo]

SELECT 
    [SerialNo],
	IIF([BirthLot] IS NULL, [LotNumber], [BirthLot]) AS [LotNumber],
	[Failure]
INTO #RMAfailingLot
FROM #RMApreviousLot

SELECT 
	L.[LotNumber], 
	CAST(CONCAT(CONCAT('20', SUBSTRING(RIGHT(L.[LotNumber], 9), 5, 2)), '-', SUBSTRING(RIGHT(L.[LotNumber], 9), 1, 2), '-', SUBSTRING(RIGHT(L.[LotNumber], 9), 3, 2)) AS DATE) AS [Date],
	L.[ActualLotSize],
	L.[LotSizeUsed],
	L.[DesiredLotSize],
	N.[ncrQty],
	R.[rmaQty],
	N.[Disposition]
--INTO #master
FROM #lotSizes L LEFT JOIN #pcbaNCRs N
	ON L.[LotNumber] = N.[LotNumber] LEFT JOIN
	(
		SELECT 
			[LotNumber],
			COUNT(*) AS [rmaQty]
		FROM #RMAfailingLot
		WHERE [Failure] = 1 AND [LotNumber] IS NOT NULL
		GROUP BY [LotNumber]
	) R
		ON L.[LotNumber] = R.[LotNumber]
--WHERE L.[ActualLotSize] > 0
--ORDER BY [LotNumber]
ORDER BY [Date]

SELECT
	[LotNumber],
	YEAR([Date]) AS [Year],
	DATEPART(ww, [Date]) AS [Week],
	[ActualLotSize],
	[LotSizeUsed],
	ISNULL([rmaQty], 0) AS [QtyFailedInField],
	ISNULL([ncrQty],0) AS [QtyFailedInHouse]
FROM #master
--WHERE [ActualLotSize] > 5
ORDER BY [Date]

--DROP TABLE  #failedInst, #flaggedForFailures, #freePropPiv, #freePropPivrops, #lotSizes, #master, #partInfo, #partInfoPiv, 
--	#partsUsed, #pcbaLots, #pcbaLotsInProd, #pcbaNCRs, #pcbaRMAs, #rawNCR, #RMAfailingLot, #RMApreviousLot

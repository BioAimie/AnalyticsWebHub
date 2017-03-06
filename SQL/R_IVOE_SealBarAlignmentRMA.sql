SET NOCOUNT ON

SELECT
	[TicketId],
	[TicketString],
	REPLACE(LTRIM(RTRIM([Lot/Serial Number])),'KTM','TM') AS [SerialNo],
	REPLACE([Part Number],' ','') AS [PartNo]
INTO #partInfo
FROM (
	SELECT 
		[TicketId],
		[TicketString],
		[ObjectId],
		[PropertyName],
		[RecordedValue]
	FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus]
	WHERE [Tracker]='RMA' AND [ObjectName]='Part Information'
) Q
PIVOT (
	MAX([RecordedValue])
	FOR [PropertyName] IN (
		[Lot/Serial Number],
		[Part Number]
	)
) P
WHERE [Part Number] LIKE 'FLM2%' OR [Part Number] LIKE 'HTFA%'
	
SELECT 
	[TicketId],
	[TicketString],
	[Sub-Failure Category] AS [SubfailureCategory]
INTO #rootCauses
FROM (
	SELECT 
		[TicketId],
		[TicketString],
		[ObjectId],
		[PropertyName],
		[RecordedValue]
	FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus]
	WHERE [Tracker]='RMA' AND [ObjectName]='Root Causes'
) Q
PIVOT (
	MAX([RecordedValue])
	FOR [PropertyName] IN (
		[Problem Area],
		[Sub-Failure Category]
	)
) P
WHERE [Problem Area] LIKE '%Seal Bar%' AND [Sub-Failure Category] LIKE '%alignment%'

SELECT
	[TicketId]
INTO #firstTickets
FROM (
	SELECT
		[TicketId],
		[SerialNo],
		[PartNo],
		ROW_NUMBER() OVER (PARTITION BY [SerialNo] ORDER BY [TicketId]) AS [VisitNo]
	FROM #partInfo
) Q
WHERE [VisitNo]=1 AND [TicketId] IN (SELECT [TicketId] FROM #rootCauses);

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
	WHERE U.[Quantity]>0 AND U.[LotNumber] != 'N/A'
)
SELECT DISTINCT
	REPLACE(REPLACE(REPLACE(TL.[LotNumber],'.',''),'_',''),' ','') AS [SerialNo],
	BL.[DateOfManufacturing]
INTO #manifoldDate
FROM [BirthLot] B INNER JOIN [ProductionWeb].[dbo].[Lots] BL WITH(NOLOCK)
	ON B.[BottomLot] = BL.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[Lots] TL WITH(NOLOCK)
		ON B.[TopLotID] = TL.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[Parts] TP WITH(NOLOCK)
			ON TP.[PartNumberId] = TL.[PartNumberId]
WHERE TP.[PartNumber] IN ('FLM2-ASY-0001','HTFA-SUB-0103')
	AND [BottomPart] IN ('FLM2-SUB-0055','FLM2-SUB-0081','HTFA-SUB-0110')

SELECT
	P.[TicketId],
	P.[TicketString],
	P.[SerialNo],
	P.[PartNo],
	M.[DateOfManufacturing],
	CASE
		WHEN P.[PartNo] LIKE '%FLM2-%' THEN 'FA2.0'
		WHEN P.[PartNo] LIKE '%HTFA-%' THEN 'Torch'
		ELSE 'Other'
	END AS [Version],
	DATEPART(ww, M.[DateOfManufacturing]) AS [Week],
	MONTH(M.[DateOfManufacturing]) AS [Month],
	YEAR(M.[DateOfManufacturing]) AS [Year],
	1 AS [Record]
FROM #partInfo P LEFT JOIN #manifoldDate M ON M.[SerialNo] = P.[SerialNo]
WHERE P.[TicketId] IN (SELECT [TicketId] FROM #firstTickets)
ORDER BY TicketId

DROP TABLE #partInfo, #rootCauses, #firstTickets, #manifoldDate

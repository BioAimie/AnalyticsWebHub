SET NOCOUNT ON

SELECT 
	[TicketString],
	[CreatedDate],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #ncrParts
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Parts Affected'

SELECT
	[TicketString], 
	[CreatedDate],
	REPLACE(UPPER([Part Affected]),' ','') AS [PartNumber],
	IIF(CHARINDEX(':',[Lot or Serial Number],1)<>0, REPLACE(UPPER(SUBSTRING([Lot or Serial Number], 1, CHARINDEX(':',[Lot or Serial Number],1)-1)), ' ',''), REPLACE(UPPER([Lot or Serial Number]), ' ','')) AS [LotNumber],
	REPLACE(REPLACE([Quantity Affected],' ',''),',','') AS [QtyAffected]
INTO #lookUpLots
FROM
(
	SELECT *
	FROM #ncrParts P
	PIVOT
	(
		MAX([RecordedValue])
		FOR [PropertyName]
		IN
		(
			[Part Affected],
			[Lot or Serial Number],
			[Quantity Affected]
		)
	) PIV
) T

SELECT 
	P.[PartNumber],
	L.[LotNumber],
	L.[ActualLotSize],
	L.[DesiredLotSize]
INTO #production
FROM [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK)
	ON P.[PartNumberId] = L.[PartNumberId]
WHERE P.[PartNumber] IN (SELECT [PartNumber] FROM #lookUpLots) AND L.[LotNumber] IN (SELECT [LotNumber] FROM #lookUpLots)

SELECT 
	L.[TicketString],
	[CreatedDate],
	L.[PartNumber],
	L.[LotNumber],
	IIF(ISNUMERIC(L.[QtyAffected]) = 1, L.[QtyAffected], '0') AS [Temp],
	P.[ActualLotSize],
	P.[DesiredLotSize]
INTO #master
FROM #lookUpLots L INNER JOIN #production P
	ON L.[LotNumber] = P.[LotNumber]
WHERE L.[LotNumber] NOT LIKE 'N%A' AND L.[PartNumber] NOT LIKE 'N%A' AND LEN(L.[QtyAffected]) <= 7

SELECT 
	[TicketString],
	[CreatedDate],
	[PartNumber],
	[LotNumber],
	CAST([Temp] AS DECIMAL) AS [QtyAffected],
	[DesiredLotSize],
	[ActualLotSize]
INTO #converted
FROM #master

SELECT 
	[TicketString],
	CAST([CreatedDate] AS DATE) AS [Date],
	[PartNumber],
	[LotNumber],
	[QtyAffected],
	IIF([DesiredLotSize] < [QtyAffected], [QtyAffected], [DesiredLotSize]) AS [LotSize]
FROM #converted

DROP TABLE #lookUpLots, #master, #ncrParts, #production, #converted
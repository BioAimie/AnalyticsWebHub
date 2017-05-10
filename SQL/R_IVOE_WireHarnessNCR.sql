SET NOCOUNT ON

SELECT 
	[TicketId],
	[TicketString],
	CAST([CreatedDate] AS DATE) AS [CreatedDate],
	REPLACE(LEFT([LotorSerialNumber],CHARINDEX(':',[LotorSerialNumber]+':')-1),' ','') AS [LotNumber],
	UPPER([PartAffected]) AS [PartAffected],
	[QuantityAffected]
INTO #NCRs
FROM [PMS1].[dbo].[NCRPartsAffected]
WHERE [PartAffected] LIKE 'WIRE-HAR%' AND [PartAffected] NOT IN ('WIRE-HAR-0554')
	AND [CreatedDate] >= '2014-01-01'

SELECT
	[Date],
	[TicketString],
	[CreatedDate],
	[ManufactureDate],
	[LotNumber],
	[PartAffected],
	[QuantityAffected],
	[ActualLotSize],
	YEAR([Date]) AS [Year],
	MONTH([Date]) AS [Month],
	DATEPART(ww,[Date]) AS [Week],
	1 AS [Record]
FROM (
	SELECT *,
		IIF(ISDATE([ManufactureDate])=1 AND [ManufactureDate] >= '2014-01-01' AND [ManufactureDate] <= GETDATE(), 
			CAST([ManufactureDate] AS DATE), [CreatedDate]) AS [Date]
	FROM (
		SELECT N.*,
			'20' + SUBSTRING(RIGHT(N.[LotNumber], 9), 5, 2) + '-' + SUBSTRING(RIGHT(N.[LotNumber], 9), 1, 2) + '-' + SUBSTRING(RIGHT(N.[LotNumber], 9), 3, 2) AS [ManufactureDate],
			(SELECT MAX(L.[ActualLotSize]) 
			FROM [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK)
			WHERE L.[LotNumber] = N.[LotNumber]) AS [ActualLotSize]
		FROM #NCRs N
	) Q1
) Q2
ORDER BY [PartAffected],[CreatedDate]

DROP TABLE #NCRs

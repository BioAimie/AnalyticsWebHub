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
	YEAR([Date]) AS [Year],
	MONTH([Date]) AS [Month],
	DATEPART(ww,[Date]) AS [Week],
	1 AS [Record]
FROM (
	SELECT *,
		IIF(ISDATE([ManufactureDate])=1 AND [ManufactureDate] >= '2014-01-01' AND [ManufactureDate] <= GETDATE(), 
			CAST([ManufactureDate] AS DATE), [CreatedDate]) AS [Date]
	FROM (
		SELECT *,
			'20' + SUBSTRING(RIGHT([LotNumber], 9), 5, 2) + '-' + SUBSTRING(RIGHT([LotNumber], 9), 1, 2) + '-' + SUBSTRING(RIGHT([LotNumber], 9), 3, 2) AS [ManufactureDate]
		FROM #NCRs
	) Q1
) Q2
ORDER BY [CreatedDate]

DROP TABLE #NCRs

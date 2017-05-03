SET NOCOUNT ON

SELECT 
	REPLACE(REPLACE([LotSerialNumber], ' ', ''), 'KTM', 'TM') AS [SerialNo],
	[TicketString]
INTO #failSerial
FROM [PMS1].[dbo].[ComplaintBFDXPartNumber]
WHERE [FailureMode] LIKE '%eject%'
	AND ([PartNumber] LIKE 'HTFA-ASY-0003%' OR [PartNumber] LIKE 'HTFA-SUB-0103%')

SELECT
	F.[TicketString],
	F.[SerialNo],
	L.[DateOfManufacturing],
	YEAR(L.[DateOfManufacturing]) AS [Year],
	MONTH(L.[DateOfManufacturing]) AS [Month],
	DATEPART(ww,[DateOfManufacturing]) AS [Week],
	1 AS [Record],
	'Torch' AS [Version]
FROM #failSerial F
LEFT JOIN [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) ON L.[LotNumber] = F.[SerialNo]

DROP TABLE #failSerial

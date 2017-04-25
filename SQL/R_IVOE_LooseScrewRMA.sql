SET NOCOUNT ON

SELECT
	[TicketId]
INTO #firstTicket
FROM (
	SELECT
		[TicketId],
		ROW_NUMBER() OVER(PARTITION BY REPLACE([LotSerialNumber],' ','') ORDER BY [TicketId]) AS [RMANo]
	FROM [PMS1].[dbo].[RMAPartInformation]
) Q
WHERE [RMANo] = 1

SELECT
	P.[TicketId],
	P.[TicketString],
	P.[CreatedDate],
	UPPER(REPLACE(P.[LotSerialNumber],' ','')) AS [SerialNo],
	C.[ProblemArea],
	C.[FailureCategory],
	C.[SubFailureCategory],
	C.[PartNumber],
	IIF(ISNUMERIC(R.[HoursRun])=1, CAST(R.[HoursRun] AS FLOAT), NULL) AS [HoursRun]
INTO #RMAs
FROM [PMS1].[dbo].[RMAPartInformation] P
LEFT JOIN [PMS1].[dbo].[RMARootCauses] C ON C.[TicketId] = P.[TicketId]
LEFT JOIN [PMS1].[dbo].[RMA] R ON R.[TicketId] = P.[TicketId]
WHERE ([FailureCategory] LIKE '%screw%' OR [SubFailureCategory] LIKE '%fastener%') 
	AND [FailureCategory] NOT LIKE '%harness%'
	AND P.[PartNumber] NOT LIKE '%COMP%'
	AND P.[TicketId] IN (SELECT * FROM #firstTicket)
ORDER BY [ProblemArea], [FailureCategory], [SubFailureCategory], [PartNumber]

SELECT
	R.*,
	L.[DateOfManufacturing],
	YEAR(L.[DateOfManufacturing]) AS [Year],
	MONTH(L.[DateOfManufacturing]) AS [Month],
	DATEPART(ww,L.[DateOfManufacturing]) AS [Week],
	CASE
		WHEN [HoursRun] BETWEEN 0 AND 100 THEN '0-100'
		WHEN [HoursRun] BETWEEN 100 AND 500 THEN '100-500'
		WHEN [HoursRun] BETWEEN 500 AND 1000 THEN '500-1000'
		WHEN [HoursRun]>1000 THEN '1000+'
		ELSE 'Unknown'
	END AS [HoursRunBin],
	1 AS [Record]
FROM #RMAs R
INNER JOIN [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) ON L.[LotNumber] = R.[SerialNo]
ORDER BY [DateOfManufacturing]

DROP TABLE #firstTicket, #RMAs


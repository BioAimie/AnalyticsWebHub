SET NOCOUNT ON

SELECT
	[TicketId],
	[TicketString],
	[CreatedDate],
	[SerialNo],
	[PartNumber],
	[CustomerId],
	[EarlyFailureType],
	[RMAType],
	[ComplaintFailureMode],
	[RootCauseFail]
INTO #failures
FROM (
	SELECT 	
		P.[TicketId],
		P.[TicketString],
		CAST(P.[CreatedDate] AS DATE) AS [CreatedDate],
		UPPER(REPLACE(P.[LotSerialNumber], ' ', '')) AS [SerialNo],
		UPPER(REPLACE(P.[PartNumber], ' ', '')) AS [PartNumber],
		P.[EarlyFailureType],
		R.[RMAType],
		(SELECT TOP 1 
			C.[FailureMode]
		FROM [PMS1].[dbo].[ComplaintBFDXPartNumber] C
		WHERE C.[TicketString] = 'COMPLAINT-'+R.[ComplaintNumber]
			AND REPLACE(C.[LotSerialNumber],' ','') = REPLACE(P.[LotSerialNumber],' ','')) AS [ComplaintFailureMode],
		IIF(EXISTS (SELECT 1 FROM [PMS1].[dbo].[RMARootCauses] C WHERE C.[TicketId] = P.[TicketId] AND
				[ProblemArea] NOT IN ('N/A', 'No failure complaint')), 1, 0) AS [RootCauseFail],
		REPLACE(R.[CustomerId], ' ', '') AS [CustomerId]
	FROM [PMS1].[dbo].[RMAPartInformation] P
	LEFT JOIN [PMS1].[dbo].[RMA] R ON R.[TicketId] = P.[TicketId]
) Q
WHERE ([RMAType] LIKE '%- Failure%' OR [ComplaintFailureMode] IS NOT NULL OR [RootCauseFail] = 1)
	AND ([PartNumber] LIKE '%HTFA-ASY-0001%' OR [PartNumber] LIKE '%HTFA-ASY-0104%')
	AND [CustomerId] != 'IDATEC'
ORDER BY [TicketId]

SELECT
	F.*,
	REPLACE(C.[ProblemArea], 'Instrument ', '') AS [ProblemArea],
	C.[FailureCategory],
	C.[SubfailureCategory],
	C.[PartNumber]
FROM #failures F 
LEFT JOIN [PMS1].[dbo].[RMARootCauses] C ON C.[TicketId] = F.[TicketId]

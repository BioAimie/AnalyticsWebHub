USE PMS1
GO

-- Instrument RMAs with classification as failure or non-failure
IF OBJECT_ID('[dbo].[bInstrumentFailure]') IS NOT NULL
DROP VIEW [dbo].[bInstrumentFailure]
GO

CREATE VIEW [dbo].[bInstrumentFailure] AS
SELECT
	[TicketId],
	[TicketString],
	[CreatedDate],
	[SerialNo],
	Q.[PartNumber] AS [PartNumber],
	V.[Version],
	V.[Refurb],
	[CustomerId],
	[EarlyFailureType],
	[RMAType],
	[ComplaintFailureMode],
	[RootCauseFail],
	[RMATitle],
	IIF([HoursRun] > [HoursOn], [HoursOn], [HoursRun]) AS [HoursRun],
	IIF([RMATitle] LIKE '%error%' OR [RMATitle] LIKE '%fail%' OR [RMATitle] LIKE '%DOA%' OR [RMATitle] LIKE '%ELF%' OR
		[RMAType] LIKE '%- Failure%' OR
		([ComplaintFailureMode] IS NOT NULL AND RIGHT([ComplaintFailureMode],3)='1-0') OR
		[RootCauseFail] = 1,
	1, 0) AS [Failure],
	[NormalSerial],
	ROW_NUMBER() OVER(PARTITION BY [NormalSerial] ORDER BY [TicketId]) AS [VisitNo]
FROM (
	SELECT 	
		P.[TicketId],
		P.[TicketString],
		CAST(P.[CreatedDate] AS DATE) AS [CreatedDate],
		UPPER(REPLACE(REPLACE(REPLACE(REPLACE(P.[LotSerialNumber], ' ', ''), '.', ''), '_', ''), 'KTM', 'TM')) AS [SerialNo],
		UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(P.[LotSerialNumber], ' ', ''), '.', ''), '_', ''), 'KTM', 'TM'), 'R', ''), '2FA', 'FA')) AS [NormalSerial],
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
		R.[RMATitle],
		TRY_CAST(IIF(ISNUMERIC(R.[HoursRun]) = 1, REPLACE(R.[HoursRun], ',', ''), NULL) AS FLOAT) AS [HoursRun],
		TRY_CAST(IIF(ISNUMERIC(R.[HoursOn]) = 1, REPLACE(R.[HoursOn], ',', ''), NULL) AS FLOAT) AS [HoursOn],
		REPLACE(R.[CustomerId], ' ', '') AS [CustomerId]
	FROM [PMS1].[dbo].[RMAPartInformation] P
	LEFT JOIN [PMS1].[dbo].[RMA] R ON R.[TicketId] = P.[TicketId]
) Q
INNER JOIN [PMS1].[dbo].[bInstrumentVersion] V ON V.[PartNumber] = Q.[PartNumber]
GO

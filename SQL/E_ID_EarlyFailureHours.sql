SET NOCOUNT ON

SELECT
	[TicketId],
	[SerialNo],
	[PartNumber],
	[EarlyFailureType]
INTO #firstRMAs
FROM (
	SELECT
		[TicketId],
		UPPER(REPLACE([LotSerialNumber],' ','')) AS [SerialNo],
		[PartNumber],
		[EarlyFailureType],
		ROW_NUMBER() OVER (PARTITION BY REPLACE([LotSerialNumber],' ','') ORDER BY [TicketId]) AS [RMANo]
	FROM [PMS1].[dbo].[RMAPartInformation]
	WHERE [PartNumber] LIKE 'FLM%-ASY-0001%' OR [PartNumber] LIKE 'HTFA-ASY-0001%' OR [PartNumber] LIKE 'HTFA-ASY-0003%' OR [PartNumber] LIKE 'HTFA-ASY-0104%' OR [PartNumber] LIKE 'HTFA-SUB-0103%'
) Q
WHERE [RMANo] = 1

SELECT
	*,
	YEAR([CreatedDate]) AS [Year],
	MONTH([CreatedDate]) AS [Month],
	DATEPART(ww,[CreatedDate]) AS [Week]
FROM (
	SELECT DISTINCT
		*,
		IIF([RMATitle] NOT LIKE '%upgrade%' AND
				([RMATitle] LIKE '%error%' OR [RMATitle] LIKE '%fail%' OR [RMATitle] LIKE '%DOA%' OR [RMATitle] LIKE '%ELF%' OR
				[RMAType] LIKE '%- Failure%' OR
				[EarlyFailureType] IN ('SDOA','DOA','ELF','SELF') OR
				([ComplaintFailureMode] IS NOT NULL AND RIGHT([ComplaintFailureMode],3)='1-0') OR 
				EXISTS (SELECT 1 FROM [PMS1].[dbo].[RMARootCauses] C WHERE C.[TicketId] = Q.[TicketId] AND
						ISNUMERIC([PartNumber]) = 0 AND [PartNumber] NOT LIKE 'N%A' AND [PartNumber] != '')),
			1, 0) AS [Failure],
		CASE 
			WHEN [PartNumber] LIKE 'FLM1-%' THEN 'FA1.5'
			WHEN [PartNumber] LIKE 'FLM2-%' THEN 'FA2.0'
			WHEN [PartNumber] LIKE 'HTFA-ASY-0001%' OR [PartNumber] LIKE 'HTFA-ASY-0104%' THEN 'Torch Base'
			ELSE 'Torch Module'
		END AS [Version]
	FROM (		
		SELECT
			P.[TicketId],
			R.[TicketString],
			CAST(R.[CreatedDate] AS DATE) AS [CreatedDate],
			P.[SerialNo],
			P.[PartNumber],
			P.[EarlyFailureType],
			R.[RMATitle],
			R.[RMAType],
			(SELECT TOP 1 C.[FailureMode]
			FROM [PMS1].[dbo].[ComplaintBFDXPartNumber] C
			WHERE C.[TicketString] = 'COMPLAINT-' + R.[ComplaintNumber] 
				AND REPLACE(C.[LotSerialNumber],' ','') = P.[SerialNo]
			ORDER BY [ObjectId]
			) AS [ComplaintFailureMode],
			IIF(ISNUMERIC(R.[HoursRun])=1, CAST(REPLACE(R.[HoursRun], ',', '') AS FLOAT), NULL) AS [HoursRun]
		FROM #firstRMAs P
		LEFT JOIN [PMS1].[dbo].[RMA] R ON R.[TicketId] = P.[TicketId]
	) Q
) Q2
WHERE [HoursRun]<100 AND [Failure]=1 
ORDER BY [CreatedDate]

DROP TABLE #firstRMAs

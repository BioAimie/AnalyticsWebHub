SET NOCOUNT ON 

-- Determine the date when the hours run were first recorded for each RMA.
SELECT
	BT.[TicketId],
	CAST(MIN(GH.[CreatedDate]) AS DATE) AS [HoursRunRecordedDate]
INTO #hoursRunDate
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON TS.[TicketId] = BT.[TicketId]
INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GH WITH(NOLOCK) ON GH.[TicketStageId] = TS.[TicketStageId]
INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketProperties] TP WITH(NOLOCK) ON TP.[GeneralTicketHistoryId] = GH.[GeneralTicketHistoryId]
INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH(NOLOCK) ON P.[PropertyId] = TP.[PropertyId]
INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[TrackableProperties] TKP WITH(NOLOCK) ON TKP.[TrackablePropertyId] = P.[TrackablePropertyId]
INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[DecimalProperties] DP WITH(NOLOCK) ON DP.[PropertyId] = TP.[PropertyId]
WHERE TKP.[Name] = 'Hours Run' AND ISNUMERIC(DP.[RecordedValue])=1
GROUP BY BT.[TicketId]

SELECT
	*,
	IIF(Q.[HoursRunRaw] < Q.[HoursOnRaw], Q.[HoursRunRaw], Q.[HoursOnRaw]) AS [HoursRun],
	H.[HoursRunRecordedDate],
	IIF([RMATitle] NOT LIKE '%upgrade%' AND
		([RMATitle] LIKE '%error%' OR [RMATitle] LIKE '%fail%' OR [RMATitle] LIKE '%DOA%' OR [RMATitle] LIKE '%ELF%' OR
		[RMAType] LIKE '%- Failure%' OR
		[EarlyFailureType] IN ('SDOA','DOA','ELF','SELF') OR
		([ComplaintFailureMode] IS NOT NULL AND RIGHT([ComplaintFailureMode],3)='1-0') OR
		EXISTS (SELECT 1 FROM [PMS1].[dbo].[RMARootCauses] C WHERE C.[TicketId] = Q.[TicketId] AND
				ISNUMERIC([PartNumber]) = 0 AND [PartNumber] NOT LIKE 'N%A' AND [PartNumber] != '')),
	1, 0) AS [Failure],
	ROW_NUMBER() OVER(PARTITION BY Q.[SerialNo] ORDER BY Q.[TicketId]) AS [RMANo]
FROM (
	SELECT 	
		P.[TicketId],
		P.[TicketString],
		UPPER(REPLACE(P.[LotSerialNumber],' ','')) AS [SerialNo],
		IIF(ISNUMERIC(R.[HoursRun])=1, CAST(R.[HoursRun] AS FLOAT), NULL) AS [HoursRunRaw],
		IIF(ISNUMERIC(R.[HoursOn])=1, CAST(R.[HoursOn] AS FLOAT), NULL) AS [HoursOnRaw],
		IIF(R.[RMATitle] LIKE '%IDATEC%' OR R.[RMAType] LIKE '%Internal%' OR R.[CustomerId] LIKE '%IDATEC%' OR R.[CustomerId] LIKE '%BFDX%', 1, 0) AS [Internal],
		P.[EarlyFailureType],
		R.[RMAType],
		(SELECT TOP 1 
			C.[FailureMode]
		FROM [PMS1].[dbo].[ComplaintBFDXPartNumber] C
		WHERE C.[TicketString] = 'COMPLAINT-'+R.[ComplaintNumber]
			AND REPLACE(C.[LotSerialNumber],' ','') = REPLACE(P.[LotSerialNumber],' ','')) AS [ComplaintFailureMode],
		R.[RMATitle]
	FROM [PMS1].[dbo].[RMAPartInformation] P
	LEFT JOIN [PMS1].[dbo].[RMA] R ON R.[TicketId] = P.[TicketId]
	WHERE LEFT(REPLACE([LotSerialNumber], ' ', ''),3) IN ('2FA','FA4')
) Q
LEFT JOIN #hoursRunDate H ON H.[TicketId] = Q.[TicketId]
ORDER BY [SerialNo], Q.[TicketId]

DROP TABLE #hoursRunDate

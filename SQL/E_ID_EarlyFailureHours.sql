SET NOCOUNT ON

SELECT
	Q.[TicketId],
	Q.[TicketString],
	Q.[SerialNo],
	Q.[PartNumber],
	CAST(Q.[CreatedDate] AS DATE) AS [CreatedDate],
	Q.[HoursRun],
	UPPER(REPLACE(R.[CustomerId], ' ', '')) AS [CustomerId],
	CASE 
		WHEN [PartNumber] LIKE 'FLM1-%' THEN 'FA1.5'
		WHEN [PartNumber] LIKE 'FLM2-%' THEN 'FA2.0'
		WHEN [PartNumber] LIKE 'HTFA-ASY-0003%' OR [PartNumber] LIKE 'HTFA-SUB-0103%' THEN 'Torch Module'
		ELSE 'Other'
	END AS [Version]
FROM (
	SELECT 
		*,
		ROW_NUMBER() OVER(PARTITION BY [NormalSerial] ORDER BY [TicketId]) AS [RowNo]
	FROM [PMS1].[dbo].[bInstrumentFailure]
) Q 
INNER JOIN [PMS1].[dbo].[RMA] R ON R.[TicketId] = Q.[TicketId]
WHERE Q.[RowNo] = 1  AND Q.[Failure] = 1 AND Q.[HoursRun]<100
ORDER BY [Version], [CreatedDate]
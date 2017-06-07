SET NOCOUNT ON 

SELECT
	I.[SerialNo],
	ROW_NUMBER() OVER (PARTITION BY I.[NormalSerial] ORDER BY I.[TicketId]) AS [VisitNo],
	I.[TicketString],
	I.[HoursRun],
	LAG(I.[HoursRun]) OVER (PARTITION BY [NormalSerial] ORDER BY I.[TicketId]) AS [PriorHours],
	CAST(R.[ServiceCompleted] AS DATE) AS [ServiceCompleted]
INTO #failures
FROM [PMS1].[dbo].[bInstrumentFailure] I
INNER JOIN [PMS1].[dbo].[RMA] R ON R.[TicketId] = I.[TicketId]
WHERE [Failure] = 1 AND R.[ServiceCompleted] IS NOT NULL

SELECT *
FROM (
	SELECT 
		YEAR([ServiceCompleted]) AS [Year],
		MONTH([ServiceCompleted]) AS [Month],
		[VisitNo],
		IIF([PriorHours] IS NULL, [HoursRun], ([HoursRun] - [PriorHours])) AS [MTBF]
	FROM #failures
) Q
WHERE [MTBF]>0

DROP TABLE #failures

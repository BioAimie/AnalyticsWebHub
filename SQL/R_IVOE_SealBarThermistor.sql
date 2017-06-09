SET NOCOUNT ON

SELECT [TicketId]
INTO #tickets
FROM (
	SELECT [TicketId] FROM [PMS1].[dbo].[RMAServiceCodes]
	WHERE TRY_CAST([ServiceCode] AS INT) = 254
	UNION
	SELECT [TicketId] FROM [PMS1].[dbo].[RMARootCauses]
	WHERE [FailureCategory] LIKE '%thermistor%' OR [SubfailureCategory] LIKE '%thermistor%'
) Q

SELECT DISTINCT
	P.[SerialNo],
	P.[Version],
	P.[DateOfManufacturing],
	I.[TicketString],
	I.[HoursRun]
FROM [PMS1].[dbo].[bInstrumentFailure] I
INNER JOIN [PMS1].[dbo].[bInstrumentProduced] P ON P.[NormalSerial] = I.[NormalSerial]
WHERE I.[TicketId] IN (SELECT * FROM #tickets) 
	AND I.[CustomerId] NOT LIKE '%IDATEC%' 
	AND P.[ProdNo] = 1

DROP TABLE #tickets
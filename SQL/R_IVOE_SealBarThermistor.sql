SET NOCOUNT ON

SELECT DISTINCT
	P.[SerialNo],
	P.[Version],
	P.[DateOfManufacturing],
	I.[TicketString],
	I.[HoursRun]
FROM [PMS1].[dbo].[bInstrumentFailure] I
INNER JOIN [PMS1].[dbo].[RMAServiceCodes] S ON S.[TicketId] = I.[TicketId]
INNER JOIN [PMS1].[dbo].[bInstrumentProduced] P ON P.[NormalSerial] = I.[NormalSerial]
WHERE TRY_CAST(S.[ServiceCode] AS INT) = 254 AND I.[CustomerId] NOT LIKE '%IDATEC%' AND P.[ProdNo] = 1

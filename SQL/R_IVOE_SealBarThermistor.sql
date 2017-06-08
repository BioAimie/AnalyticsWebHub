SET NOCOUNT ON

SELECT 
	I.[TicketString],
	I.[SerialNo],
	I.[Version],
	I.[HoursRun],
	MIN(CAST(P.[DateOfManufacturing] AS DATE)) AS [DateOfManufacturing]
FROM [PMS1].[dbo].[bInstrumentFailure] I
INNER JOIN [PMS1].[dbo].[RMAServiceCodes] S ON S.[TicketId] = I.[TicketId]
INNER JOIN [PMS1].[dbo].[bInstrumentProduced] P ON P.[NormalSerial] = I.[NormalSerial]
WHERE TRY_CAST(S.[ServiceCode] AS INT) = 254 AND I.[CustomerId] NOT LIKE '%IDATEC%'
GROUP BY I.[TicketString], I.[SerialNo], I.[Version], I.[HoursRun]
ORDER BY [DateOfManufacturing]

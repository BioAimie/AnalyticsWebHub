SET NOCOUNT ON

SELECT
	I.[Version],
	I.[TicketId],
	I.[TicketString],
	I.[SerialNo],
	I.[PartNumber],
	I.[CreatedDate],
	I.[HoursRun],
	I.[CustomerId] AS [CustomerId],
	I.[RMATitle],
	CASE 
		WHEN C.[ProblemArea] = 'Instrument Plunger' THEN 'Plunger Block'
		WHEN C.[ProblemArea] IS NULL THEN 'Unknown'
		ELSE REPLACE(C.[ProblemArea], 'Instrument ', '')
	END AS [ProblemArea]
FROM [PMS1].[dbo].[bInstrumentFailure] I
LEFT JOIN [PMS1].[dbo].[RMARootCauses] C ON C.[TicketId] = I.[TicketId]
WHERE I.[VisitNo] = 1 
	AND I.[Failure] = 1 
	AND I.[HoursRun]<100 
	AND I.[CustomerId] != 'IDATEC'
ORDER BY I.[Version], I.[TicketId]

SET NOCOUNT ON

SELECT DISTINCT
	N.[TicketString],
	CAST(N.[CreatedDate] AS DATE) AS [Date],
	REPLACE(N.[ProblemArea], 'Instrument ', '') AS [ProblemArea]
FROM [PMS1].[dbo].[NCR] N
INNER JOIN [PMS1].[dbo].[NCRPartsAffected] P ON P.[TicketId] = N.[TicketId]
INNER JOIN [PMS1].[dbo].[vInstrumentBillOfMaterials] B ON B.[ComponentItemID] = P.[PartAffected]
WHERE N.[WhereFound] = 'Incoming Inspection' 
ORDER BY [Date]

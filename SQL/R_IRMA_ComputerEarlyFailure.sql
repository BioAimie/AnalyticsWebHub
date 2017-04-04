SET NOCOUNT ON

SELECT DISTINCT
	*,
	CASE
		WHEN [PartNumber] LIKE 'COMP-SUB-0016%' THEN 'FA1.5'
		WHEN [PartNumber] LIKE 'COMP-SUB-0027%' THEN 'FA2.0'
		WHEN [PartNumber] LIKE 'HTFA-ASY-0001%' THEN 'Torch'
	END AS [Version],
	YEAR([CreatedDate]) AS [Year],
	MONTH([CreatedDate]) AS [Month],
	DATEPART(ww,[CreatedDate]) AS [Week],
	1 AS [Record]
FROM (
	SELECT 
		P.[TicketId],
		P.[TicketString],
		P.[CreatedDate],
		P.[LotSerialNumber],
		P.[EarlyFailureType] AS [Key],
		REPLACE(P.[PartNumber],' ','') AS [PartNumber],
		IIF(EXISTS (SELECT 1 FROM [PMS1].[dbo].[RMAPartsReceived] R 
			WHERE R.[TicketID] = P.[TicketID] 
			AND (R.[PartNumber] LIKE 'COMP-SUB-0016%' OR R.[PartNumber] LIKE 'COMP-SUB-0027%' OR R.[PartNumber] LIKE 'HTFA-ASY-0001%')),
			1, 0) AS [Received]
	FROM [PMS1].[dbo].[RMAPartInformation] P 
) Q
WHERE ([PartNumber] LIKE 'COMP-SUB-0016%' OR [PartNumber] LIKE 'COMP-SUB-0027%' OR [PartNumber] LIKE 'HTFA-ASY-0001%')
	AND [Key] IN ('DOA','ELF','SDOA','SELF')

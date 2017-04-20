SET NOCOUNT ON

SELECT
	YEAR([ShipDate]) AS [Year],
	MONTH([ShipDate]) AS [Month],
	DATEPART(ww,[ShipDate]) AS [Week],
	CASE
		WHEN [ItemId] LIKE 'COMP-SUB-0016%' THEN 'FA1.5' 
		WHEN [ItemId] LIKE 'FLM2-ASY-0003%' THEN 'FA2.0' 
		WHEN [ItemId] LIKE 'HTFA-ASY-0001%' THEN 'Torch' 
	END	AS [Version],
	'NewCompShip' AS [Key],
	1 AS [Record]
FROM (
	SELECT
		S.[ShipDate],
		I.[ItemId],
		ROW_NUMBER() OVER(PARTITION BY REPLACE(SER.[SerialNo],'KIT-','') ORDER BY S.[ShipDate]) AS [ShipNo]
	FROM [RO_MAS].[mas500_app].[dbo].[tsoShipLine] S WITH(NOLOCK)
	INNER JOIN [RO_MAS].[mas500_app].[dbo].[timItem] I WITH(NOLOCK) ON I.[ItemKey] = S.[ItemKey]
	INNER JOIN [RO_MAS].[mas500_app].[dbo].[tsoPackageContent] PC WITH(NOLOCK) ON PC.[ShipLineKey] = S.[ShipLineKey]
	INNER JOIN [RO_MAS].[mas500_app].[dbo].[timInvtSerial] SER WITH(NOLOCK) ON SER.[InvtSerialKey] = PC.[InvtSerialKey]
	WHERE [ItemId] LIKE 'COMP-SUB-0016%' OR [ItemId] LIKE 'FLM2-ASY-0003%' OR [ItemId] LIKE 'HTFA-ASY-0001%'
) Q
WHERE [ShipNo] = 1
ORDER BY [ShipDate]

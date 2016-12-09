SELECT 
	UPPER([LotNumber]) AS [Serial Number],
	CAST(MIN([DateOfManufacturing]) AS DATE) AS [Manufacturing Date]
FROM [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK)
	ON L.[PartNumberId] = P.[PartNumberId]
GROUP BY [LotNumber]

SELECT 
	UPPER([LotNumber]) AS [Serial Number],
	CAST(MIN([DateOfManufacturing]) AS DATE) AS [Manufacturing Date]
FROM [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) INNER JOIN [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[Parts] P WITH(NOLOCK)
	ON L.[PartNumberId] = P.[PartNumberId]
GROUP BY [LotNumber]

SELECT
	P.[DateOpened],
	YEAR(P.[DateOpened]) AS [Year],
	DATEPART(ww, P.[DateOpened]) AS [Week],
	G.[GroupName],
	T.[PassedPolarized]
FROM [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[InProcessTest] P WITH(NOLOCK) INNER JOIN [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[BurstTestResults] T WITH(NOLOCK)
	ON P.[TrendTestId] = T.[TrendTestId] INNER JOIN [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[ManufacturingEquipment] E WITH(NOLOCK)
		ON T.[EquipmentId] = E.[EquipmentId] INNER JOIN [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[EquipmentGroups] G WITH(NOLOCK)
			ON P.[EquipmentGroupId] = G.[EquipmentGroupId]
WHERE P.[DateOpened] > GETDATE() - 30
GROUP BY 
	P.[DateOpened],
	G.[GroupName],
	T.[PassedPolarized]
ORDER BY P.[DateOpened]

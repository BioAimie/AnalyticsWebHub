SELECT
	P.[LotNumber],
	P.[DateOpened],
	IIF(DATEPART(dw, GETDATE()) = 7 AND P.[DateOpened] >= GETDATE() - 2, 1,
		IIF(DATEPART(dw, GETDATE()) = 1 AND P.[DateOpened] >= GETDATE() - 3, 1, 
		IIF(DATEPART(dw, GETDATE()) = 2 AND P.[DateOpened] >= GETDATE() - 4, 1, 
		IIF(P.[DateOpened] >= GETDATE() - 1, 1, 0)))) AS [IncludeInIMR],
	YEAR(P.[DateOpened]) AS [Year],
	DATEPART(ww, P.[DateOpened]) AS [Week],
	T.[TestNumber],
	G.[GroupName],
	CAST(REPLACE(T.[PullStrength],',','') AS FLOAT) AS [Result]
FROM [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[InProcessTest] P WITH(NOLOCK) INNER JOIN [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[CannulaTestResults] T WITH(NOLOCK)
	ON P.[TrendTestId] = T.[TrendTestId] INNER JOIN [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[EquipmentGroups] G WITH(NOLOCK)
			ON P.[EquipmentGroupId] = G.[EquipmentGroupId]
WHERE ISNUMERIC(T.[PullStrength]) = 1  AND P.[DateClosed] IS NOT NULL
GROUP BY 
	P.[TrendTestId],
	P.[LotNumber],
	P.[DateOpened],
	G.[GroupName],
	T.[PullStrength],
	TestNumber
ORDER BY [LotNumber], [TestNumber]

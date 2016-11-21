SELECT
	--P.[TrendTestId],
	P.[LotNumber],
	P.[DateOpened],
	IIF(DATEPART(dw, GETDATE()) = 7 AND P.[DateOpened] >= GETDATE() - 2, 1,
		IIF(DATEPART(dw, GETDATE()) = 1 AND P.[DateOpened] >= GETDATE() - 3, 1, 
		IIF(DATEPART(dw, GETDATE()) = 2 AND P.[DateOpened] >= GETDATE() - 4, 1, 
		IIF(P.[DateOpened] >= GETDATE() - 1, 1, 0)))) AS [IncludeInIMR],
	YEAR(P.[DateOpened]) AS [Year],
	DATEPART(ww, P.[DateOpened]) AS [Week],
	ROW_NUMBER() OVER(PARTITION BY P.[TrendTestId] ORDER BY P.[TrendTestId]) AS [TestNumber],
	G.[GroupName],
	--T.[PassedPolarized],
	--SUBSTRING(E.[SerialNumber], CHARINDEX('MEQ-', E.[SerialNumber],1) + 4, 20) AS [SerialNumber],
	CAST(REPLACE(T.[Result],',','') AS FLOAT) AS [Result]
FROM [ProductionWeb].[dbo].[InProcessTest] P WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[BurstTestResults] T WITH(NOLOCK)
	ON P.[TrendTestId] = T.[TrendTestId] INNER JOIN [ProductionWeb].[dbo].[ManufacturingEquipment] E WITH(NOLOCK)
		ON T.[EquipmentId] = E.[EquipmentId] INNER JOIN [ProductionWeb].[dbo].[EquipmentGroups] G WITH(NOLOCK)
			ON P.[EquipmentGroupId] = G.[EquipmentGroupId]
WHERE ISNUMERIC(T.[Result]) = 1 
GROUP BY 
	P.[TrendTestId],
	P.[LotNumber],
	P.[DateOpened],
	G.[GroupName],
	--E.[SerialNumber],
	T.[PassedPolarized],
	T.[Result]
ORDER BY P.[TrendTestId]

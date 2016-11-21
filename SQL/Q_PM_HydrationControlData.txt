SELECT
	P.[LotNumber],
	P.[DateOpened],
	IIF(DATEPART(dw, GETDATE()) = 7 AND P.[DateOpened] >= GETDATE() - 2, 1,
		IIF(DATEPART(dw, GETDATE()) = 1 AND P.[DateOpened] >= GETDATE() - 3, 1, 
		IIF(DATEPART(dw, GETDATE()) = 2 AND P.[DateOpened] >= GETDATE() - 4, 1, 
		IIF(P.[DateOpened] >= GETDATE() - 1, 1, 0)))) AS [IncludeInIMR],
	T.[TestNumber],
	YEAR(P.[DateOpened]) AS [Year],
	DATEPART(ww, P.[DateOpened]) AS [Week],
	E.[GroupName],
	E.[OperationalStatus],
	T.[WaterSideWeight] - [PreWeight] AS [WaterSideWeight],
	T.[SampleSideWeight] - [WaterSideWeight] AS [SampleSideWeight],
	T.[SampleSideWeight] - [PreWeight] AS [TotalWeight],
	T.[HydrationTime],
	T.[SampleHydrationTime]
FROM [ProductionWeb].[dbo].[InProcessTest] P WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[HydrationTestResults] T WITH(NOLOCK)
	ON P.[TrendTestId] = T.[TrendTestId] INNER JOIN [ProductionWeb].[dbo].[EquipmentGroups] E WITH(NOLOCK)
		ON P.[EquipmentGroupId] = E.[EquipmentGroupId]
WHERE T.[HydrationTime] > 0
ORDER BY [DateOpened], [TestNumber]

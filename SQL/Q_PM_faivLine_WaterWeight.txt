SET NOCOUNT ON
SELECT
	P.[LotNumber],
	P.[DateOpened],
	IIF(DATEPART(dw, GETDATE()) = 7 AND P.[DateOpened] >= GETDATE() - 2, 1,
		IIF(DATEPART(dw, GETDATE()) = 1 AND P.[DateOpened] >= GETDATE() - 3, 1, 
		IIF(DATEPART(dw, GETDATE()) = 2 AND P.[DateOpened] >= GETDATE() - 4, 1, 
		IIF(P.[DateOpened] >= GETDATE() - 1, 1, 0)))) AS [IncludeInIMR],
	YEAR(P.[DateOpened]) AS [Year],
	DATEPART(ww, P.[DateOpened]) AS [Week],
	ROW_NUMBER() OVER(PARTITION BY W.[TrendTestId] ORDER BY W.[WaterWeightTestResultId]) AS [TestNumber],
	G.[GroupName],
	CAST(REPLACE(W.[WaterWeight],',','') AS FLOAT) AS [Result]
FROM [ProductionWeb].[dbo].[InProcessTest] P WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[WaterWeightTestResults] W WITH(NOLOCK)
	ON P.[TrendTestId] = W.[TrendTestId] INNER JOIN [ProductionWeb].[dbo].[EquipmentGroups] G WITH(NOLOCK)
			ON P.[EquipmentGroupId] = G.[EquipmentGroupId]
WHERE ISNUMERIC(W.[WaterWeight]) = 1 
AND DateClosed IS NOT NULL
GROUP BY 
	W.[TrendTestId],
	P.[LotNumber],
	P.[DateOpened],
	G.[GroupName],
	W.[WaterWeight],
	W.[WaterWeightTestResultId]
ORDER BY LotNumber, TestNumber
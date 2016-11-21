SELECT
	YEAR([DateOfManufacturing]) AS [Year],
	DATEPART(ww,[DateOfManufacturing]) AS [Week],
	IIF(LEFT([PartNumber],4) LIKE 'FLM1', 'FA1.5',
		IIF(LEFT([PartNumber],4) LIKE 'FLM2', 'FA2.0','Torch')) AS [Version],
	'InstBuild' AS [Key],
	COUNT(L.[LotNumber]) AS [Record]
FROM [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK)
	ON L.[PartNumberId] = P.[PartNumberId]
WHERE (P.[PartNumber] LIKE 'FLM%-ASY-0001' OR P.[PartNumber] LIKE 'HTFA-ASY-0003') AND [DateOfManufacturing] > CONVERT(DATETIME, '2014-06-01')
GROUP BY
	YEAR([DateOfManufacturing]),
	DATEPART(ww,[DateOfManufacturing]),
	[PartNumber]
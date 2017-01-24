SET NOCOUNT ON

SELECT 
	REPLACE(REPLACE(REPLACE(REPLACE(L.[LotNumber],' ',''),'_',''),'-',''),'.','') AS [LotNo],
	IIF(LEFT(P.[PartNumber],4) IN ('FLM2','HTFA'), SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(L.[LotNumber],' ',''),'_',''),'-',''),'.',''), 1, 8),
		SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(L.[LotNumber],' ',''),'_',''),'-',''),'.',''), 1, 6)) AS [SerialNo],
	P.[PartNumber],
	L.[DateOfManufacturing],
	L.[VersionId],
	IIF(L.[VersionId] IN ('IP','01','02','03'), 1, 0) AS [New]
INTO #cleanSerials
FROM [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK)
	ON L.[PartNumberId] = P.[PartNumberId]
WHERE (P.[PartNumber] LIKE 'FLM%-ASY-0001%' OR P.[PartNumber] LIKE 'HTFA-ASY-0003%') AND [DateOfManufacturing] > CONVERT(DATETIME, '2014-06-01')

SELECT
	YEAR(MIN([DateOfManufacturing])) AS [Year],
	DATEPART(ww,MIN([DateOfManufacturing])) AS [Week],
	IIF(LEFT(MIN([PartNumber]),4) LIKE 'FLM1', 'FA1.5',
		IIF(LEFT(MIN([PartNumber]),4) LIKE 'FLM2', 'FA2.0','Torch')) AS [Version],
	'InstBuild' AS [Key],
	COUNT(DISTINCT [SerialNo]) AS [Record]
FROM #cleanSerials
WHERE [New] = 1
GROUP BY [SerialNo]

DROP TABLE #cleanSerials
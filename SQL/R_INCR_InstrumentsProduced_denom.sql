SET NOCOUNT ON

SELECT 
	REPLACE(REPLACE(REPLACE(REPLACE(L.[LotNumber],' ',''),'_',''),'-',''),'.','') AS [LotNo],
	IIF(LEFT(P.[PartNumber],4) IN ('FLM2','HTFA'), SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(L.[LotNumber],' ',''),'_',''),'-',''),'.',''), 1, 8),
		SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(L.[LotNumber],' ',''),'_',''),'-',''),'.',''), 1, 6)) AS [SerialNo],
	P.[PartNumber],
	L.[DateOfManufacturing],
	L.[VersionId],
	IIF(L.[VersionId] IN ('IP','01','02','03','05','FrNew'), 1, 0) AS [New]
INTO #cleanSerials
FROM [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK)
	ON L.[PartNumberId] = P.[PartNumberId]
WHERE (P.[PartNumber] LIKE 'FLM%-ASY-0001%' OR P.[PartNumber] LIKE 'HTFA-ASY-0003%')

SELECT
	YEAR(MIN([DateOfManufacturing])) AS [Year],
	MONTH(MIN([DateOfManufacturing])) AS [Month],
	DATEPART(ww,MIN([DateOfManufacturing])) AS [Week],
	IIF(LEFT(MIN([PartNumber]),4) LIKE 'FLM1', 'FA1.5',
		IIF(LEFT(MIN([PartNumber]),4) LIKE 'FLM2', 'FA2.0','Torch')) AS [Version],
	'InstBuild' AS [Key],
	[SerialNo], 
	COUNT(DISTINCT [SerialNo]) AS [Record]
FROM 
(
	SELECT 
		[LotNo],
		IIF([SerialNo] LIKE '%R', SUBSTRING([SerialNo],1, PATINDEX('%R',[SerialNo])-1), [SerialNo]) AS [SerialNo],
		[PartNumber],
		[DateOfManufacturing],
		[VersionId],
		[New] 
	FROM #cleanSerials
) A
WHERE [New] = 1
GROUP BY [SerialNo]

DROP TABLE #cleanSerials

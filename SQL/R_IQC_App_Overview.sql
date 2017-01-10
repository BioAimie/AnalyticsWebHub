SET NOCOUNT ON

SELECT
	'PouchQC' AS [Key],
	IIF(LEFT([Instrument],3) IN ('FA1','FA2','FA3','FA5'), 'FA1.5', 'FA2.0') AS [Version],
	[Instrument],
	RIGHT([PouchVersion],3) AS [PouchVersion],
	[LotNo],
	IIF(LEN([SerialNo]) < 8, CONCAT('0',[SerialNo]), [SerialNo]) AS [SerialNo],
	[Date],
	YEAR([Date]) AS [Year],
	MONTH([Date]) AS [Month],
	DATEPART(ww,[Date]) AS [Week],
	[PouchResult],
	[RNACpMean] AS [Cp_RNA],
	[RNATmMean] AS [Tm_RNA],
	[RNA],
	[60MPTmMin] AS [Tm_60min],
	[60TmMin],
	[60MPTmMax] AS [Tm_60max],
	[60TmMax],
	[60MPTmRange] AS [DTm_60],
	[60TmRange],
	[60MPDFMed] AS [DF_60],
	[60DFMed],
	[60MPDFRom] AS [DDF_60],
	[60DFRoM],
	[NoiseMed] AS [Noise_med],
	[Noise],
	1 AS [Record]
INTO #pouchQC
FROM [PMS1].[dbo].[tIQC_Overview] WITH(NOLOCK)
WHERE [SampId] LIKE '%PouchQC%'

SELECT
	'Production' AS [Key],
	IIF(LEFT([Instrument],3) IN ('FA1','FA2','FA3','FA5'), 'FA1.5', 'FA2.0') AS [Version],
	[Instrument],
	RIGHT([PouchVersion],3) AS [PouchVersion],
	[LotNo],
	IIF(LEN([SerialNo]) < 8, CONCAT('0',[SerialNo]), [SerialNo]) AS [SerialNo],
	[Date],
	YEAR([Date]) AS [Year],
	MONTH([Date]) AS [Month],
	DATEPART(ww,[Date]) AS [Week],
	[PouchResult],
	[RNACpMean] AS [Cp_RNA],
	[RNATmMean] AS [Tm_RNA],
	[RNA],
	[60MPTmMin] AS [Tm_60min],
	[60TmMin],
	[60MPTmMax] AS [Tm_60max],
	[60TmMax],
	[60MPTmRange] AS [DTm_60],
	[60TmRange],
	[60MPDFMed] AS [DF_60],
	[60DFMed],
	[60MPDFRom] AS [DDF_60],
	[60DFRoM],
	[NoiseMed] AS [Noise_med],
	[Noise],
	1 AS [Record]
INTO #newBuild
FROM [PMS1].[dbo].[tIQC_Overview] WITH(NOLOCK)
WHERE [SampId] LIKE '%New%Build%' AND [LotNo] IN (SELECT DISTINCT [LotNo] FROM #pouchQC)

SELECT
	'Service' AS [Key],
	IIF(LEFT([Instrument],3) IN ('FA1','FA2','FA3','FA5'), 'FA1.5', 'FA2.0') AS [Version],
	[Instrument],
	RIGHT([PouchVersion],3) AS [PouchVersion],
	[LotNo],
	IIF(LEN([SerialNo]) < 8, CONCAT('0',[SerialNo]), [SerialNo]) AS [SerialNo],
	[Date],
	YEAR([Date]) AS [Year],
	MONTH([Date]) AS [Month],
	DATEPART(ww,[Date]) AS [Week],
	[PouchResult],
	[RNACpMean] AS [Cp_RNA],
	[RNATmMean] AS [Tm_RNA],
	[RNA],
	[60MPTmMin] AS [Tm_60min],
	[60TmMin],
	[60MPTmMax] AS [Tm_60max],
	[60TmMax],
	[60MPTmRange] AS [DTm_60],
	[60TmRange],
	[60MPDFMed] AS [DF_60],
	[60DFMed],
	[60MPDFRom] AS [DDF_60],
	[60DFRoM],
	[NoiseMed] AS [Noise_med],
	[Noise],
	1 AS [Record]
INTO #postRepair
FROM [PMS1].[dbo].[tIQC_Overview] WITH(NOLOCK)
WHERE [SampId] LIKE '%Post%Repair%' AND [LotNo] IN (SELECT DISTINCT [LotNo] FROM #pouchQC)

SELECT 
	CAST([Date] AS DATETIME) AS [Date],
	[Year],
	[Month],
	[Week],
	[Instrument],
	[Key],
	[Version],
	[LotNo],
	[Record],
	[PouchResult],
	[Cp_RNA],
	[Tm_RNA],
	[RNA],
	[Tm_60min],
	[60TmMin],
	[Tm_60max],
	[60TmMax],
	[DTm_60] AS [TmRange_60],
	[60TmRange],
	[DF_60] AS [medianDeltaRFU_60],
	[60DFMed],
	[DDF_60] AS [normalizedRangeRFU_60],
	[60DFRoM],
	[Noise_med],
	[Noise]
INTO #table
FROM
(
	SELECT *
	FROM #pouchQC
	UNION ALL
	SELECT *
	FROM #newBuild
	UNION ALL
	SELECT *
	FROM #postRepair
) D
WHERE [Date] > GETDATE() - 400
GROUP BY 
	[Date],
	[Year],
	[Month],
	[Week],
	[Instrument],
	[Key],
	[Version],
	[LotNo],
	[PouchResult],
	[Cp_RNA],
	[Tm_RNA],
	[RNA],
	[Tm_60min],
	[60TmMin],
	[Tm_60max],
	[60TmMax],
	[DTm_60],
	[60TmRange],
	[DF_60],
	[60DFMed],
	[DDF_60],
	[60DFRoM],
	[Noise_med],
	[Noise],
	[Record]

SELECT 
	[SerialNo],
	MAX([ItemID]) AS [PartNo]
INTO #partNo
FROM [PMS1].[dbo].[vSerialTransactions] WITH(NOLOCK)
GROUP BY [SerialNo]

SELECT 
	[Year],
	[Month],
	[Week],
	LEFT([LotNo],6) AS [LotNo],
	[Key],
	IIF(LEFT([PartNo],4) LIKE 'FLM1', 'FA1.5',
		IIF(LEFT([PartNo],4) LIKE 'FLM2', 'FA2.0', [Version])) AS [Version],
	[PouchResult],
	[Cp_RNA],
	[Tm_RNA],
	[RNA],
	[TmRange_60],
	[60TmRange],
	[medianDeltaRFU_60],
	[60DFMed],
	[Noise_med],
	[Noise],
	1 AS [Record]
FROM #table T LEFT JOIN #partNo P
	ON T.[Instrument] = P.[SerialNo]
WHERE ISNUMERIC(LEFT([LotNo],6)) = 1
ORDER BY [Date]

DROP TABLE #newBuild, #postRepair, #pouchQC, #table, #partNo
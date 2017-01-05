SET NOCOUNT ON

SELECT 
	CAST([Date] AS DATE) AS [Date],
	[SerialNo],
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
	SELECT
		'Production' AS [Key],
		IIF(LEFT([Instrument],3) IN ('FA1','FA2','FA3','FA5'), 'FA1.5', 
			IIF(LEFT([Instrument],3) IN ('FA4','2FA'), 'FA2.0',
			IIF(LEFT([Instrument],2) IN ('HT','TM'), 'Torch','Other'))) AS [Version],
		[Instrument],
		RIGHT([PouchVersion],3) AS [PouchVersion],
		[LotNo],
		IIF(LEN([SerialNo]) < 8, CONCAT('0',[SerialNo]), [SerialNo]) AS [SerialNo],
		[Date],
		YEAR([Date]) AS [Year],
		MONTH([Date]) AS [Month],
		DATEPART(ww,[Date]) AS [Week],
		IIF([PouchResult] <> 'Pass' AND [PCR1]  = 'Pass' AND [PCR2]  = 'Pass' AND [RNA] = 'Pass' AND [60TmRange] = 'Pass' AND [60DFMed] = 'Pass' AND [Noise] = 'Pass', 'Pass', [PouchResult]) AS [PouchResult],
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
	FROM [PMS1].[dbo].[tIQC_Overview] WITH(NOLOCK)
	WHERE [SampId] LIKE '%New%Build%'
	UNION
	SELECT
		'Service' AS [Key],
		IIF(LEFT([Instrument],3) IN ('FA1','FA2','FA3','FA5'), 'FA1.5', 
			IIF(LEFT([Instrument],3) IN ('FA4','2FA'), 'FA2.0',
			IIF(LEFT([Instrument],2) IN ('HT','TM'), 'Torch','Other'))) AS [Version],
		[Instrument],
		RIGHT([PouchVersion],3) AS [PouchVersion],
		[LotNo],
		IIF(LEN([SerialNo]) < 8, CONCAT('0',[SerialNo]), [SerialNo]) AS [SerialNo],
		[Date],
		YEAR([Date]) AS [Year],
		MONTH([Date]) AS [Month],
		DATEPART(ww,[Date]) AS [Week],
				IIF([PouchResult] <> 'Pass' AND [PCR1]  = 'Pass' AND [PCR2]  = 'Pass' AND [RNA] = 'Pass' AND [60TmRange] = 'Pass' AND [60DFMed] = 'Pass' AND [Noise] = 'Pass', 'Pass', [PouchResult]) AS [PouchResult],
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
	FROM [PMS1].[dbo].[tIQC_Overview] WITH(NOLOCK)
	WHERE [SampId] LIKE '%Post%Repair%'
	UNION
	SELECT
		'PouchQC' AS [Key],
		IIF(LEFT([Instrument],3) IN ('FA1','FA2','FA3','FA5'), 'FA1.5', 
			IIF(LEFT([Instrument],3) IN ('FA4','2FA'), 'FA2.0',
			IIF(LEFT([Instrument],2) IN ('HT','TM'), 'Torch','Other'))) AS [Version],
		[Instrument],
		RIGHT([PouchVersion],3) AS [PouchVersion],
		[LotNo],
		IIF(LEN([SerialNo]) < 8, CONCAT('0',[SerialNo]), [SerialNo]) AS [SerialNo],
		[Date],
		YEAR([Date]) AS [Year],
		MONTH([Date]) AS [Month],
		DATEPART(ww,[Date]) AS [Week],
				IIF([PouchResult] <> 'Pass' AND [PCR1]  = 'Pass' AND [PCR2]  = 'Pass' AND [RNA] = 'Pass' AND [60TmRange] = 'Pass' AND [60DFMed] = 'Pass' AND [Noise] = 'Pass', 'Pass', [PouchResult]) AS [PouchResult],
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
	FROM [PMS1].[dbo].[tIQC_Overview] WITH(NOLOCK)
	WHERE [SampId] LIKE '%PouchQC%'
) D
WHERE [Date] > GETDATE() - 400
GROUP BY 
	[Date],
	[SerialNo],
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

SELECT *
INTO #protocolNo
FROM
(
	SELECT
		[PouchSerialNumber] AS [SerialNo],
		[SampleType] AS [Protocol]
	FROM [FILMARRAYDB].[FilmArray2].[dbo].[ExperimentRun] WITH(NOLOCK)
	WHERE [PouchSerialNumber] IN (SELECT [SerialNo] FROM #table)
	UNION
	SELECT
		[PouchSerialNumber] AS [SerialNo],
		[SampleType] AS [Protocol]
	FROM [FILMARRAYDB].[FilmArray1].[FilmArray].[ExperimentRun] WITH(NOLOCK)
	WHERE [PouchSerialNumber] IN (SELECT [SerialNo] FROM #table)
) D

SELECT 
	[Year],
	[Month],
	[Week],
	LEFT([LotNo],6) AS [LotNo],
	[Key],
	IIF([Protocol] LIKE 'QC v3.0' AND [Version] LIKE 'Torch', 'Torch', 
		IIF([Protocol] LIKE 'QC v3.0', 'FA2.0', 
		IIF([Protocol] LIKE 'QC v2.0', 'FA1.5', 'Other'))) AS [Version],
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
FROM #table T LEFT JOIN #protocolNo P
	ON T.[SerialNo] = P.[SerialNo]
WHERE ISNUMERIC(LEFT([LotNo],6)) = 1 AND [Protocol] IS NOT NULL AND [Version] NOT LIKE 'Other'
ORDER BY [Date]

DROP TABLE #table, #protocolNo
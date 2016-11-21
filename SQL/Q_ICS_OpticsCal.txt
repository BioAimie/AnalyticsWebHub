SET NOCOUNT ON

DECLARE @shipments TABLE 
(
	[SerialNo] VARCHAR(20),
	[ItemID] VARCHAR(20),
	[TranDate] DATETIME,
	[TranNo] INT
)

INSERT INTO @shipments
SELECT
	[SerialNo],
	[ItemID],
	[TranDate],
	ROW_NUMBER() OVER(PARTITION BY [SerialNo] ORDER BY [TranDate]) AS [TranNo]
FROM [PMS1].[dbo].[vSerialTransactions] WITH(NOLOCK)
WHERE [TranType] LIKE 'SH' OR ([TranType] IN ('SA','IS') AND [DistQty] = -1)

SELECT 
	[SerialNo],
	CAST([TranDate] AS DATE) AS [BreakDate]
INTO #location
FROM @shipments 
WHERE [TranNo] = 1

SELECT 
	YEAR(CAST([DateCalibrated] AS DATE)) AS [Year],
	DATEPART(ww, CAST([DateCalibrated] AS DATE)) AS [Week],
	[SerialNumber] AS [SerialNo],
	IIF(LEFT([SerialNumber], 2) IN ('FA','2F'), 'FA2.0', 'Torch') AS [Version], 
	[DCID],
	[ChangeOrder],
	[LP65],
	[calcLP65],
	[LP65CoeffVerify.Result] AS [LPResult],
	IIF(CAST([DateCalibrated] AS DATE) < [BreakDate], 'Production',
		IIF([BreakDate] IS NULL, 'Production', 'Service')) AS [Location]
FROM
(
	SELECT 
		[DateCalibrated],
		[SerialNumber],
		[DCID],
		[ChangeOrder],
		[LP65],
		[calcLP65],
		[LP65CoeffVerify.Result]
	FROM 
	(
		SELECT
			[DateCalibrated],
			RIGHT([DateCalibrated], 4) AS [Year],
			[SerialNumber],
			[DCID],
			[ChangeOrder],
			[LP65],
			[calcLP65],
			[LP65CoeffVerify.Result]
		FROM
		(
			SELECT
				[id],
				[lastUpdate],
				[propertyName],
				[recordedValue]
			FROM [PMS1].[dbo].[tMongoICS_OpticsCal] WITH(NOLOCK)
			WHERE [propertyName] IN ('SerialNumber','DateCalibrated','ChangeOrder','DCID') OR [propertyName] LIKE '%LP65%'
		) P PIVOT 
		(
			MAX([recordedValue])
			FOR [propertyName]
			IN
			(
				[LP65],
				[LP65CoeffVerify.Actual],
				[LP65CoeffVerify.Result],
				[SerialNumber],
				[ChangeOrder],
				[LP65dac.value],
				[DateCalibrated],
				[LP65CoeffVerify.Expected],
				[LP65current.value],
				[DCID],
				[calcLP65]
			)
		) PIV
		GROUP BY 
			[id],
			[DateCalibrated],
			[SerialNumber],
			[DCID],
			[ChangeOrder],
			[LP65],
			[calcLP65],
			[LP65CoeffVerify.Result]
	) T
	WHERE CHARINDEX('/', [Year], 1) = 0
) ICS LEFT JOIN #location L
	ON ICS.[SerialNumber] = L.[SerialNo]
WHERE [LP65CoeffVerify.Result] IS NOT NULL
ORDER BY CAST([DateCalibrated] AS DATE)

DROP TABLE #location
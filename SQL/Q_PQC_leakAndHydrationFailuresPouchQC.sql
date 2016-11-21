SELECT
	R.[SerialNumber],
	P.[LotNumber],
	YEAR(ISNULL(R.[RunDate], R.[PreRunObservationDate])) AS [Year],
	DATEPART(ww, ISNULL(R.[RunDate], R.[PreRunObservationDate])) AS [Week],
	'HydrationFailure' AS [Key],
	IIF(P.[PostfillWeight] - P.[PrefillWeight] < 1, 1, 0) AS [Record]
FROM [PouchQC].[dbo].[QcPouch] P WITH(NOLOCK) INNER JOIN [PouchQC].[dbo].[PouchQcRun] R WITH(NOLOCK)
	ON P.[SerialNumber] = R.[SerialNumber]
WHERE ISNUMERIC(P.[LotNumber]) = 1
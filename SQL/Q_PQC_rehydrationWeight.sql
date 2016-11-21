SET NOCOUNT ON

SELECT 
	--P.[SerialNumber],
	YEAR(R.[DateOfRun]) AS [Year],
	MONTH(R.[DateOfRun]) AS [Month],
	DATEPART(ww,R.[DateOfRun]) AS [Week],
	'DeltaWeight' AS [Key],
	/*
	P.[PouchType] AS [Version],
	P.[LotNumber],
	P.[BatchNumber],
	IIF(P.[SampleLabel] LIKE '%RP%', 'RP',
		IIF(P.[SampleLabel] LIKE '%GI%', 'GI',
		IIF(P.[SampleLabel] LIKE '%ME%', 'ME',
		IIF(P.[SampleLabel] LIKE '%BCID%', 'BCID', 'Other')))) AS [Version],
	IIF(P.[SampleLabel] LIKE '%Negative%', 'Negative', 
		IIF(P.[SampleLabel] LIKE '%Omega%', 'Omega', 'Other')) AS [Key],
	R.[LastUpdated],
	R.[PostedToPwDate],
	R.[StationId],
	R.[Username],*/
	P.[PostfillWeight] - P.[PrefillWeight] AS [Record]
	--ISNULL(O.[IsFailingError],0) AS [Failure],
	--O.[Description] AS [FailureDesc]
FROM [PouchQC].[dbo].[QcRunData] R WITH(NOLOCK) LEFT JOIN [PouchQC].[dbo].[QcPouch] P WITH(NOLOCK)
	ON R.[Id] = P.[QcRunDataId] LEFT JOIN [PouchQC].[dbo].[QcPouchObservation] O WITH(NOLOCK)
		ON P.[Id] = O.[QcPouchId]
WHERE ISNUMERIC(P.[LotNumber]) = 1
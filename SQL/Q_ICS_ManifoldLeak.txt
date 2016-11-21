SELECT 
	YEAR(M.[DateSaved]) AS [Year],
	DATEPART(ww, M.[DateSaved]) AS [Week],
	M.[UserName],
	V.[ValveId],
	V.[PsiDiff],
	V.[Passed]
FROM [FILMARRAYDB].[TestCalibration].[dbo].[ManifoldValveData] V WITH(NOLOCK) INNER JOIN [FILMARRAYDB].[TestCalibration].[dbo].[ManifoldCalibratorData] M WITH(NOLOCK)
	ON V.[ManifoldCalibratorData_id] = M.[Id]
WHERE M.[DateSaved] > GETDATE() - 400
ORDER BY M.[DateSaved]
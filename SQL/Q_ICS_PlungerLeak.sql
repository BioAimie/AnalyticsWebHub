SELECT
	M.[SerialNumber],
	YEAR(F.[DateSaved]) AS [Year],
	DATEPART(ww, F.[DateSaved]) AS [Week],
	F.[IsForService],
	F.[UserName],
	P.[PlungePsi],
	P.[Passed]
FROM [FILMARRAYDB].[TestCalibration].[dbo].[PlungerValveData] P WITH(NOLOCK) INNER JOIN [FILMARRAYDB].[TestCalibration].[dbo].[FunctionalCalibrator] F WITH(NOLOCK)
	ON P.[FunctionalCalibrator_id] = F.[Id] INNER JOIN [FILMARRAYDB].[TestCalibration].[dbo].[MachineCalibrator] M WITH(NOLOCK)
		ON F.[Machine_id] = M.[Id]
WHERE F.[DateSaved] > GETDATE() - 400 AND F.[IsForService] = 0
ORDER BY F.[DateSaved]
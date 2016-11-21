SELECT
	[CreatedDate],
	YEAR([CreatedDate]) AS [Year],
	DATEPART(qq,[CreatedDate]) AS [Quarter],
	MONTH([CreatedDate]) AS [Month],
	DATEPART(ww, [CreatedDate]) AS [Week],
	[WhereFound],
	[ProblemArea],
	[FailureCategory],
	[SubFailureCategory],
	[Type], 
	[Qty]
FROM [PMS1].[dbo].[InfoStore_ncrSummary_Trackers] WITH(NOLOCK)

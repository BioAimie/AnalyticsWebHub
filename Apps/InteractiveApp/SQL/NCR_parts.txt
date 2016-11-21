SELECT 
	[CreatedDate],
	YEAR([CreatedDate]) AS [Year],
	DATEPART(qq,[CreatedDate]) AS [Quarter],
	MONTH([CreatedDate]) AS [Month],
	DATEPART(ww, [CreatedDate]) AS [Week],
	[PartAffected],
	[Type], 
	[Qty] 
FROM [PMS1].[dbo].[InfoStore_ncrParts_Trackers] WITH(NOLOCK)

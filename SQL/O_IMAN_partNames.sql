SELECT DISTINCT  
	UPPER([PartNumber]) AS [PartNumber],
	[Name] 
FROM [ProductionWeb].[dbo].[Parts] WITH(NOLOCK)

SELECT DISTINCT  
	UPPER([PartNumber]) AS [PartNumber],
	REPLACE([Name], ', ',' - ') as [Name] 
FROM [ProductionWeb].[dbo].[Parts] WITH(NOLOCK)

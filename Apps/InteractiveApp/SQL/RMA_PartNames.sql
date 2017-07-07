SELECT DISTINCT  
	UPPER([PartNumber]) AS [PartNumber],
	REPLACE([Name], ', ',' - ') as [Name] 
FROM [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[Parts] WITH(NOLOCK)

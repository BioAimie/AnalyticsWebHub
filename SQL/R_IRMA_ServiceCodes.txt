SET NOCOUNT ON

SELECT
	[TicketId],
	[TicketString],
	[ServiceDate],
	[Year],
	[Month],
	[Week],
	[ServiceCode] AS [Key],
	[NumericCode]
INTO #T
FROM
(
	SELECT 
		P.[TicketString],
		P.[TicketId],
		CAST(P.[RecordedValue] AS nvarchar(50)) AS [ServiceDate],
		YEAR(P.[RecordedValue]) AS [Year],
		MONTH(P.[RecordedValue]) AS [Month],
		DATEPART(ww,P.[RecordedValue]) AS [Week],
		O.[RecordedValue] AS [ServiceCode],
		IIF(ISNUMERIC(O.[RecordedValue])=1, 1, NULL) AS [NumericCode]
	FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] O WITH(NOLOCK) LEFT JOIN [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] P WITH(NOLOCK)
		ON O.[TicketId] = P.[TicketId]
	WHERE O.[PropertyName] LIKE 'Service Code' AND P.[PropertyName] LIKE 'Service Completed' AND P.[RecordedValue] IS NOT NULL
) D

SELECT 
	[TicketId],
	[Year],
	[Month],
	[Week],
	CAST([Key] AS INT) AS [Key],
	1 AS [Record]
INTO #Z
FROM #T 
WHERE [NumericCode] IS NOT NULL AND [Key] < '999' AND [ServiceDate] >= GETDATE() - 400

SELECT 
	[TicketId],
	[RecordedValue] AS [PartNo]
INTO #P
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Part Information' AND [PropertyName] LIKE 'Part Number'

SELECT
	[Year],
	[Week],
	IIF(LEFT([PartNo],4) LIKE 'FLM1', 'FA1.5',
		IIF(LEFT([PartNo],4) LIKE 'FLM2', 'FA2.0', 'Torch')) AS [Version],
	[Key],
	SUM([Record]) AS [Record]
FROM #Z Z INNER JOIN 
(
	SELECT *
	FROM #P 
	WHERE [PartNo] LIKE 'FLM%-ASY-0001%' OR [PartNo] LIKE 'HTFA-ASY-0003%'
) P
	ON Z.[TicketId] = P.[TicketId]
WHERE [Key] IN 
(
	'0','10','100','103','109','11','110','115','12','14','17','203','204','205','206','207','254','256','257','258','301','302','304','351','355','358','359','4','400','402',
	'450','451','452','5','503','504','507','509','51','511','512','52','53','600','601','602','604','605','606','651','655','657','702','750','807',
	'810','9','900','901','902','950'
)
GROUP BY [Year], [Week], [PartNo], [Key]
ORDER BY [Year], [Week], [Key]

DROP TABLE #T, #Z, #P
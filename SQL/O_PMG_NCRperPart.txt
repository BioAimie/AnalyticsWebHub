SET NOCOUNT ON

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	MAX([RecordedValue]) AS [Type]
INTO #Tickets
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'NCR Type' AND ([RecordedValue] LIKE 'Raw Material' OR [RecordedValue] LIKE 'BioReagents')
GROUP BY [TicketId], [TicketString], [CreatedDate]

SELECT 
	[TicketId],
	[TicketString], 
	[RecordedValue] AS [WhereFound], 
	[Stage] 
INTO #Where
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Where Found' AND [TicketId] IN (SELECT [TicketId] FROM #Tickets)
	AND [Stage] LIKE 'Reporting'

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[Status],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #PartInfo
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [TicketId] IN (SELECT [TicketId] FROM #Tickets) 
	AND [ObjectName] LIKE 'Parts Affected' AND [PropertyName] IN ('Part Affected','Lot or Serial Number')

SELECT 
	[TicketId],
	[TicketString],
	[CreatedDate],
	[Status],
	[Part Affected] AS [PartAffected],
	[Lot or Serial Number] AS [SerialNo],
	1 AS [Record]
INTO #NCRParts
FROM 
(
	SELECT *
	FROM #PartInfo
	PIVOT
	(
		MAX([RecordedValue])
		FOR [PropertyName]
		IN
		(
			[Part Affected],
			[Lot or Serial Number]
		)
	) PIV
) T
WHERE [Part Affected] IS NOT NULL AND [Part Affected] NOT LIKE 'N/A'

SELECT 
	N.[TicketId],
	N.[TicketString],
	N.[CreatedDate],
	N.[Status], 
	N.[PartAffected],
	N.[SerialNo],
	R.[Type],
	W.[WhereFound],
	N.[Record] 
INTO #Type
FROM #NCRParts N INNER JOIN #Tickets R ON N.[TicketId] = R.[TicketId]
	INNER JOIN #Where W ON N.[TicketId] = W.[TicketId] 

SELECT 
	[TicketId],
	[Status], 
	[TicketString],
	[CreatedDate],
	[PartAffected],
	[SerialNo],
	[Type],
	[WhereFound],
	[Record] 
INTO #final
FROM #Type T 
ORDER BY [CreatedDate] 

SELECT 
	[TicketId],
	[RecordedValue] AS [SupplierResponsible]
INTO #Supplier
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Supplier responsibility identified' AND [TicketId] IN (SELECT [TicketId] FROM #Tickets)

SELECT 
	[TicketId],
	[TicketString],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #FailInfo
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [TicketId] IN (SELECT [TicketId] FROM #Tickets) 
	AND [ObjectName] LIKE 'Failure Details' AND [PropertyName] IN ('Failure Category','Sub-failure Category')

SELECT
	[TicketId],
	[TicketString],
	[Failure Category] AS [FailCat],
	[Sub-failure Category] AS [SubFailCat]
INTO #NCRFail
FROM 
(
	SELECT *
	FROM #FailInfo
	PIVOT
	(
		MAX([RecordedValue])
		FOR [PropertyName]
		IN
		(
			[Failure Category],
			[Sub-failure Category]
		)
	) PIV
) T
WHERE [Failure Category] IS NOT NULL AND [Failure Category] NOT LIKE 'N/A'

SELECT
	YEAR([CreatedDate]) AS [Year],
	MONTH([CreatedDate]) AS [Month],
	DATEPART(ww, [CreatedDate]) AS [Week],
	CAST([CreatedDate] AS DATE) AS [CreatedDate],
	UPPER([PartAffected]) AS [PartAffected],
	UPPER([SerialNo]) AS [SerialNo], 
	IIF([Status] LIKE 'Closed%', 'Closed', 'Open') AS [Status],
	[Type],
	[WhereFound],
	ISNULL([SupplierResponsible], 'Unknown') AS [SupplierResponsible],
	ISNULL([FailCat], 'None given') AS [FailCat],
	ISNULL([SubFailCat], 'None given') AS [SubFailCat],
	[Record]
FROM #final f LEFT JOIN #Supplier s ON f.[TicketId] = s.[TicketId]
	LEFT JOIN #NCRFail n ON f.[TicketId] = n.[TicketId]

DROP TABLE #Tickets, #NCRParts, #Supplier, #Type, #final, #Where, #PartInfo, #FailInfo, #NCRFail
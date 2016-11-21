SET NOCOUNT ON

SELECT 
	[TicketId],
	[CreatedDate],
	[PropertyName],
	[RecordedValue]
INTO #properties
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] IN ('NCR Type','Where Found','Problem Area','Supplier Corrective Action Request','Supplier responsibility identified')

SELECT 
	[TicketId],
	[RecordedValue] AS [Vendor]
INTO #vendors
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Vendor'

SELECT ROW_NUMBER() OVER(PARTITION BY PIV.[TicketId] ORDER BY [Vendor]) AS [TicketCounter],
	PIV.[TicketId],
	CAST([CreatedDate] AS DATE) AS [Date],
	IIF([NCR Type] LIKE '% Instrument WIP','Instrument', [NCR Type]) AS [Type],
	[Where Found] AS [WhereFound],
	[Problem Area] AS [ProblemArea],
	[Vendor],
	IIF([Supplier Corrective Action Request] LIKE 'Yes', 'Yes', 'No') AS [SCAR],
	IIF([Supplier responsibility identified] LIKE 'Yes', 1, 0) AS [SupplierAtFault]
INTO #unique
FROM #properties P
PIVOT
(
	MAX([RecordedValue])
	FOR [PropertyName]
	IN
	(
		[NCR Type],
		[Where Found],
		[Problem Area],
		[Supplier Corrective Action Request],
		[Supplier responsibility identified]
	)
) PIV LEFT JOIN #vendors V
	ON PIV.[TicketId] = V.[TicketId] 
WHERE YEAR([CreatedDate]) > 2013

SELECT
	[TicketId],
	[Date],
	[Type],
	[WhereFound],
	[ProblemArea],
	[Vendor],
	[SCAR],
	[SupplierAtFault]
FROM #unique
WHERE [TicketCounter] = 1 
ORDER BY [TicketId]

DROP TABLE #properties, #vendors, #unique
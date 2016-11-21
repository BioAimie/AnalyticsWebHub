SET NOCOUNT ON

SELECT 
	[TicketId],
	[CreatedDate],
	[ObjectId],
	[ObjectName],
	[PropertyName],
	[RecordedValue]
INTO #objects
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] IN ('Parts Affected','Failure Details')

SELECT 
	[TicketId],
	[CreatedDate],
	'Parts Affected' AS [Key],
	[Part Affected] AS [Class],
	[Lot or Serial Number] AS [Order],
	[Quantity Affected] AS [Record]
INTO #parts
FROM #objects O
PIVOT
(
	MAX([RecordedValue]) 
	FOR [PropertyName]
	IN
	(
		[Part Affected],
		[Lot or Serial Number],
		[Quantity Affected]
	)
) PIV
WHERE YEAR([CreatedDate]) > 2013 AND [ObjectName] LIKE 'Parts Affected'

SELECT 
	[TicketId],
	[CreatedDate],
	'Failure Details' AS [Key],
	[Failure Category] AS [Class],
	[Sub-failure Category] AS [Order],
	1 AS [Record]
INTO #failures
FROM #objects O
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
WHERE YEAR([CreatedDate]) > 2013 AND [ObjectName] LIKE 'Failure Details'

SELECT *
FROM
(
	SELECT
		[TicketId],
		[Key],
		[Class],
		[Order],
		CAST([Record] AS INT) AS [Record]
	FROM
	(
		SELECT
			[TicketId],
			[CreatedDate],
			[Key],
			REPLACE(UPPER([Class]),' ','') AS [Class],
			IIF(CHARINDEX(':',[Order],1)<>0, REPLACE(UPPER(SUBSTRING([Order], 1, CHARINDEX(':',[Order],1)-1)), ' ',''), REPLACE(UPPER([Order]), ' ','')) AS [Order],
			REPLACE(REPLACE(REPLACE([Record], ' ',''),',',''),'.','') AS [Record]
		FROM #parts
		WHERE ISNUMERIC([Record]) = 1 AND LEN([Record]) < 8
	) T

	UNION ALL

	SELECT 
		[TicketId],
		[Key],
		[Class],
		[Order],
		[Record]
	FROM #failures
) T
WHERE [Class] IS NOT NULL AND [Order] IS NOT NULL
ORDER BY [TicketId]

DROP TABLE #objects, #parts, #failures
SET NOCOUNT ON

SELECT
	[TicketId],
	[RecordedValue] AS [Date]
INTO #awareDate
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] = 'COMPLAINT' AND [PropertyName] = 'Became Aware Date' AND [CreatedDate] > GETDATE()  - 800

SELECT 
	[TicketId],
	[TicketString],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #fail
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] = 'COMPLAINT' AND [ObjectName] = 'BFDX Part Number' AND [CreatedDate] > GETDATE() - 800

SELECT 
	[TicketId],
	[RecordedValue] AS [CustId]
INTO #cust
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [Tracker] = 'COMPLAINT' AND [PropertyName] = 'Customer Id' AND [CreatedDate] > GETDATE() - 800

SELECT 
	[TicketString],
	YEAR(D.[Date]) AS [Year],
	DATEPART(ww,D.[Date]) AS [Week],
	[CustId],
	[Version],
	[PartNumber],
	SUBSTRING([RecordedValue], LEN([RecordedValue]) - 2, 1) AS [Key],
	[RecordedValue],
	IIF(ISNUMERIC([Record])=1,REPLACE([Record],',',''),1) AS [Record]
INTO #cat
FROM #awareDate D INNER JOIN 
(
	SELECT 
		[TicketId],
		[TicketString],
		ISNULL([Product Line],'FilmArray') AS [Version],
		[Part Number] AS [PartNumber],
		[Failure Mode] AS [RecordedValue],
		[Quantity Affected] AS [Record]
	FROM #fail
	PIVOT
	(
		MAX([RecordedValue])
		FOR [PropertyName]
		IN
		(
			[Lot/Serial Number],
			[Part Number],
			[Failure Mode] ,
			[Quantity Affected],
			[Product Line]
		)
	) PIV 
) F 
	ON D.[TicketId] = F.[TicketId] LEFT JOIN #cust C
		ON F.[TicketId] = C.[TicketId]
--WHERE ISNUMERIC([Record]) = 1

SELECT DISTINCT
	[CustID],
	IIF([SalesTerritoryID] LIKE 'International', 'International', 'Domestic') AS [CustType]
INTO #custType
FROM [PMS1].[dbo].[vPouchShipmentsWithAnnotations_IOID] WITH(NOLOCK)
WHERE [CustID] IS NOT NULL

SELECT 
	[TicketString],
	[Year],
	[Week],
	IIF([CustType] IS NULL AND (C.[CustId] LIKE 'BMX-%' OR C.[CustId] LIKE '%BIOMED%'), 'International', [CustType]) AS [CustType],
	IIF([Key] = '1', 'Instrument', 
		IIF([Key] = '2', 'Chemistry',
		IIF([Key] = '3', 'Pouch',
		IIF([Key] = '4', 'Software',
		IIF([Key] = '5', 'Accessory/Kitting', 
		IIF([RecordedValue] LIKE 'Control Failure' OR [RecordedValue] LIKE '%False Positive%','Chemistry',
		IIF([RecordedValue] LIKE '%Pressure Error%','Instrument',
		IIF([RecordedValue] LIKE '%Failure to Hydrate%','Pouch','Other')))))))) AS [KeyByString],
	[RecordedValue],
	[Record]
INTO #agg
FROM #cat C LEFT JOIN #custType T
	ON C.[CustId] = T.[CustId]

SELECT
	[Year],
	[Week],
	[CustType] AS [Version],
	[KeyByString] AS [Key],
	IIF(ISNUMERIC(RIGHT([RecordedValue],1))=1, SUBSTRING([RecordedValue],1,LEN([RecordedValue])-4), [RecordedValue]) AS [RecordedValue],
	IIF([KeyByString]='Instrument',1,[Record]) AS [Record]
FROM #agg
ORDER BY [Year], [Week]

DROP TABLE #awareDate, #fail, #cat, #cust, #custType, #agg

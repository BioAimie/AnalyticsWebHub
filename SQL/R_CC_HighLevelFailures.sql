SET NOCOUNT ON

SELECT
	[TicketId],
	[RecordedValue] AS [Date]
INTO #aware
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Became Aware Date' AND [Tracker] LIKE 'COMPLAINT' 

SELECT 
	[TicketId],
	[TicketString],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #fail
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'BFDX Part Number' AND [Tracker] LIKE 'COMPLAINT' 

SELECT DISTINCT
	[ItemID],
	[Panel]
INTO #panels
FROM [PMS1].[dbo].[vPouchShipments] WITH(NOLOCK)

SELECT 
	[TicketString],
	YEAR([Date]) AS [Year],
	MONTH([Date]) AS [Month],
	DATEPART(ww,[Date]) AS [Week],
	[Version],
	[PartNumber],
	SUBSTRING([RecordedValue], LEN([RecordedValue]) - 2, 1) AS [Key],
	[RecordedValue],
	IIF(ISNUMERIC([Record])=1,REPLACE([Record],',',''),1) AS [Record]
INTO #cat
FROM #aware A INNER JOIN  
(
	SELECT 
		[TicketId],
		[TicketString],
		[ObjectId],
		ISNULL([Product Line],'FilmArray') AS [Version],
		[Part Number] AS [PartNumber],
		[Failure Mode] AS [RecordedValue],
		[Quantity Affected] AS [Record]
	FROM #fail F
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
) D
ON A.[TicketId] = D.[TicketId]
ORDER BY DATE

SELECT 
	[TicketString],
	[Year],
	[Month],
	[Week],
	[Version],
	[Panel],
	IIF(([Key] IN ('1','4') OR [PartNumber] LIKE '%FLM1-ASY-000%') AND [Version] LIKE 'FilmArray', 'FA1.5', 
		IIF(([Key] IN ('1','4') OR [PartNumber] LIKE '%FLM2-ASY-000%') AND [Version] LIKE 'FilmArray 2.0', 'FA2.0',
		IIF(([Key] IN ('1','4') OR [PartNumber] LIKE '%HTFA-ASY-0003%'), 'Torch',
		IIF([Panel] IS NOT NULL, [Panel],
		IIF([Key] IN ('2','3') AND [PartNumber] IN ('RFIT-ASY-0008','RFIT-ASY-0016'), 'GI',
		IIF([Key] LIKE '5' AND [Version] LIKE 'FilmArray 2.0', '2.0',
		IIF([Key] LIKE '5' AND [Version] LIKE 'FilmArray', '1.5', 'Other'))))))) AS [VersionByPart],
	[PartNumber],
	[Key],
	IIF([Key] = '1', 'Instrument', 
		IIF([Key] = '2', 'Chemistry',
		IIF([Key] = '3', 'Pouch',
		IIF([Key] = '4', 'Software',
		IIF([Key] = '5', 'Accessory/Kitting', 
		IIF([RecordedValue] LIKE 'Control Failure' OR [RecordedValue] LIKE '%False Positive%','Chemistry',
		IIF([RecordedValue] LIKE '%Pressure Error%','Instrument',
		IIF([RecordedValue] LIKE '%Failure to Hydrate%','Pouch','Other')))))))) AS [KeyByString],
	[RecordedValue],
	CAST([Record] AS INT) AS [Record]
INTO #agg
FROM #cat C LEFT JOIN #panels P
	ON C.[PartNumber] = P.[ItemID]

SELECT 
	[Year],
	[Week],
	[VersionByPart] AS [Version],
	[KeyByString] AS [Key],
	IIF(ISNUMERIC(RIGHT([RecordedValue],1))=1, SUBSTRING([RecordedValue],1,LEN([RecordedValue])-4), [RecordedValue]) AS [RecordedValue],
	IIF([KeyByString]='Instrument',1,[Record]) AS [Record]
INTO #final
FROM #agg

SELECT 
	[Year],
	[Week],
	[Version],
	[Key],
	IIF(ISNUMERIC(LEFT([RecordedValue],1)) = 1, SUBSTRING([RecordedValue],5,LEN([RecordedValue])), 
		IIF([RecordedValue] LIKE '%Pressure Error%', 'Pressure Error',
		IIF([RecordedValue] LIKE '%Seal Bar Error%', 'Seal Bar Error',
		IIF([RecordedValue] LIKE '%Fan Error%', 'Fan Error',
		IIF([RecordedValue] LIKE '%Lid Lock%', 'Lid Lock Error', [RecordedValue]))))) AS [RecordedValue],
	SUM([Record]) AS [Record]
FROM #final
GROUP BY [Year], [Week], [Version], [Key], [RecordedValue]
ORDER BY [Year], [Week]

DROP TABLE #aware, #fail, #cat, #panels, #agg, #final

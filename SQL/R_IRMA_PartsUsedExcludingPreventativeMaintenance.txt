SET NOCOUNT ON 

SELECT 
	[TicketId],
	[TicketString],
	YEAR([RecordedValue]) AS [Year], 
	DATEPART(ww, [RecordedValue]) AS [Week]
INTO #date
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Service Completed' AND [RecordedValue] IS NOT NULL AND [CreatedDate] >= GETDATE() - 400

SELECT 
	[TicketId],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #parts
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Parts Used' AND [TicketId] IN (SELECT [TicketId] FROM #date)

SELECT 
	[TicketId],
	[RecordedValue] AS [ServiceCode],
	IIF(ISNUMERIC([RecordedValue]) = 1, 1, 0) AS [Numeric]
INTO #codes
FROM  [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Service Codes' AND [PropertyName] LIKE 'Service Code' AND [TicketId] IN (SELECT [TicketId] FROM #date)

SELECT
	C.[ServiceCode] AS [ServiceCode],
	P.[PartNumber] AS [PartNumber]
INTO #codeParts
FROM [RO_TRACKERS].[Trackers].[dbo].[ServiceCodes] C WITH(NOLOCK) INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[ServiceCodeParts] P WITH(NOLOCK)
	ON C.[ServiceCodeId] = P.[ServiceCodeId]
WHERE C.[ServiceCode] = 20 OR 
      C.[ServiceCode] = 13 OR
	  C.[ServiceCode] = 19 OR
	  C.[ServiceCode] = 807 OR
	  C.[ServiceCode] = 809 OR
	  C.[ServiceCode] = 659
INSERT INTO #codeParts
VALUES(111, 'FLM1-MOD-0008')
INSERT INTO #codeParts
VALUES(111, 'FLM1-MOL-0023')
INSERT INTO #codeParts
VALUES(112, 'FLM1-GAS-0015')
INSERT INTO #codeParts
VALUES(113, 'FLM1-MOL-0023')

SELECT
	[TicketId],
	[Part Used] AS [PartNumber],
	CAST([Quantity] AS INT) AS [Qty]
INTO #pivParts
FROM #parts P
PIVOT
(
	MAX([RecordedValue])
	FOR [PropertyName]
	IN
	(
		[Part Used],
		[Quantity]
	)
) PIV
WHERE [Part Used] IS NOT NULL AND [Part Used] NOT LIKE 'N%A' AND ISNUMERIC([Quantity]) = 1

SELECT 
	P.[TicketId],
	P.[PartNumber],
	C.[Numeric] AS [RemovePart]
INTO #remove
FROM #pivParts P INNER JOIN #codeParts I
	ON P.[PartNumber] = I.[PartNumber] INNER JOIN #codes C
		ON P.[TicketId] = C.[TicketId] AND C.[ServiceCode] = I.[ServiceCode]
WHERE C.[Numeric] = 1

SELECT 
	[TicketId],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #partInfo
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Part Information'

SELECT 
	[TicketId],
	[Part Number] AS [PartNo],
	[Lot/Serial Number]
INTO #partInfoPiv
FROM
(
	SELECT *
	FROM #partInfo P
	PIVOT
	(
		MAX([RecordedValue])
		FOR [PropertyName]
		IN
		(
			[Part Number],
			[Lot/Serial Number]
		)
	) PIV
) D
WHERE [Part Number] LIKE 'FLM%-ASY-0001%' OR [Part Number] LIKE 'HTFA-ASY-0003%' OR [Part Number] LIKE 'HTFA-SUB-0103%'

SELECT 
	[TicketId],
	MAX([RecordedValue]) AS [HoursRun]
INTO #hours
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Hours Run'
GROUP BY [TicketId] 

SELECT 
	D.[TicketId], 
	UPPER([Lot/Serial Number]) AS [SerialNo], 
	D.[Year],
	D.[Week],
	V.[PartNo],
	IIF(LEFT([PartNo],4) LIKE 'FLM1', 'FA1.5',
		IIF(LEFT([PartNo],4) LIKE 'FLM2', 'FA2.0', 'Torch')) AS [Version],
	CASE 
		WHEN P.[PartNumber] IN ('FLM1-GAS-0009', 'FLM1-GAS-0018') THEN 'Plunger Gasket'
		WHEN P.[PartNumber] IN ('FLM1-SUB-0029', 'FLM1-SUB-0074') THEN 'Peltier Assembly'
		WHEN P.[PartNumber] IN ('FLM1-SUB-0053', 'FLM1-SUB-0078') THEN 'Sealbar Assembly'
		WHEN P.[PartNumber] LIKE 'FLM1-MAC-0285' THEN 'Sample Piston'
		WHEN P.[PartNumber] LIKE 'FLM1-MOD-0014' THEN 'Hardseal Gasket'
		WHEN P.[PartNumber] LIKE 'FLM1-MOL-0023' THEN 'Molded Bladder'
		WHEN P.[PartNumber] LIKE 'FLM1-SUB-0002' THEN 'Magnet Assembly'
		WHEN P.[PartNumber] LIKE 'FLM1-SUB-0006' THEN 'Bead Beater'
		WHEN P.[PartNumber] LIKE 'FLM1-SUB-0044' THEN 'Window Bladder'
		WHEN P.[PartNumber] LIKE 'PCBA-SUB-0836' THEN 'Thermo Board'
		WHEN P.[PartNumber] LIKE 'PCBA-SUB-0847' THEN 'Valve Board'
		WHEN P.[PartNumber] LIKE 'PCBA-SUB-0856' THEN '2.0 Excitation LED'
		WHEN P.[PartNumber] LIKE 'WIRE-HAR-0554' THEN '-0554 Valve'
		WHEN P.[PartNumber] LIKE 'PCBA-SUB-0839' THEN 'Master Board'
		WHEN P.[PartNumber] LIKE 'PCBA-SUB-0838' THEN '2.0 Camera Board'
		ELSE 'Other'
	END AS [Key],
	[HoursRun],
	[Qty] AS [Record]  
INTO #partsReplaced
FROM #date D LEFT JOIN #pivParts P
	ON D.[TicketId] = P.[TicketId] LEFT JOIN #remove R
		ON D.[TicketId] = R.[TicketId] AND P.[PartNumber] = R.[PartNumber] LEFT JOIN #partInfoPiv V
			ON D.[TicketId] = V.[TicketId] LEFT JOIN #hours H
					ON D.[TicketId] = H.[TicketId]
WHERE [RemovePart] IS NULL AND P.[PartNumber] IN
(
	'FLM1-MOL-0023',
	'FLM1-SUB-0044',
	'FLM1-MOD-0014',
	'WIRE-HAR-0554',
	'FLM1-GAS-0009',
	'FLM1-MAC-0285',
	'FLM1-SUB-0029',
	'FLM1-SUB-0053',
	'PCBA-SUB-0836',
	'FLM1-SUB-0006',
	'FLM1-SUB-0002',
	'PCBA-SUB-0847',
	'PCBA-SUB-0856',
	'FLM1-GAS-0018',
	'PCBA-SUB-0839',
	'PCBA-SUB-0838',
	'FLM1-SUB-0074',
	'FLM1-SUB-0078'
) AND D.[Year] > 1900 AND (V.[PartNo] LIKE 'FLM%-ASY-0001%' OR V.[PartNo] LIKE 'HTFA-ASY-0003%' OR V.[PartNo] LIKE 'HTFA-SUB-0103%')
ORDER BY D.[Year], D.[Week], V.[PartNo], P.[PartNumber]

SELECT 
	[TicketId],
	[SerialNo],
	[HoursRun]
INTO #tickets
FROM #partsReplaced
GROUP BY [TicketId], [SerialNo], [HoursRun]

SELECT 
	ROW_NUMBER() OVER(PARTITION BY [SerialNo] ORDER BY [TicketId]) AS [VisitNo],
	[SerialNo],
	[TicketId],
	CAST(REPLACE([HoursRun],',','') AS FLOAT) AS [HoursRun]
INTO #visitOrdered
FROM #tickets 
WHERE (ISNUMERIC([HoursRun]) = 1 OR [HoursRun] IS NULL)

SELECT 
	v.[VisitNo],
	p.[SerialNo],
	p.[Year],
	p.[Week],
	p.[PartNo],
	p.[Version],
	p.[Key],
	v.[HoursRun],
	p.[Record]
FROM #partsReplaced p LEFT JOIN #visitOrdered v
	ON p.[TicketId] = v.[TicketId]
ORDER BY [SerialNo], [VisitNo]

DROP TABLE #date, #parts, #codes, #codeParts, #pivParts, #remove, #partInfo, #partInfoPiv, #partsReplaced, #hours,
	#visitOrdered, #tickets 
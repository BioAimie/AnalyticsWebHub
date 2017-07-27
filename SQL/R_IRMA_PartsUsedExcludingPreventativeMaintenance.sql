SET NOCOUNT ON 

SELECT
	C.[ServiceCode] AS [ServiceCode],
	P.[PartNumber] AS [PartNumber]
INTO #codeParts
FROM [RO_TRACKERS].[Trackers].[dbo].[ServiceCodes] C WITH(NOLOCK) 
INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[ServiceCodeParts] P WITH(NOLOCK) ON C.[ServiceCodeId] = P.[ServiceCodeId]
WHERE C.[ServiceCode] IN (20, 13, 19, 807, 809, 659)

INSERT INTO #codeParts
VALUES (111, 'FLM1-MOD-0008'), (111, 'FLM1-MOL-0023'), (112, 'FLM1-GAS-0015'), (113, 'FLM1-MOL-0023')

SELECT 
	I.[TicketId], 
	I.[SerialNo], 
	I.[Version],
	R.[ServiceCompleted],
	I.[PartNumber],
	U.[PartUsed],
	I.[HoursRun],
	I.[VisitNo],
	CAST(U.[Quantity] AS INT) AS [Record]  
INTO #partsReplaced
FROM [PMS1].[dbo].[bInstrumentFailure] I
INNER JOIN [PMS1].[dbo].[RMAPartsUsed] U ON U.[TicketId] = I.[TicketId]
INNER JOIN [PMS1].[dbo].[RMA] R ON R.[TicketId] = I.[TicketId]
WHERE U.[PartUsed] NOT LIKE 'N%A' AND ISNUMERIC(U.[Quantity]) = 1
	AND NOT EXISTS (
		SELECT 1 
		FROM [PMS1].[dbo].[RMAServiceCodes] S
		INNER JOIN #codeParts C ON C.[ServiceCode] = TRY_CAST(S.[ServiceCode] AS INT) AND C.[PartNumber] = U.[PartUsed]
		WHERE S.[TicketId] = I.[TicketId]
	)
	AND U.[PartUsed] IN (
		'FLM1-MOL-0023', 'FLM1-SUB-0044', 'FLM1-MOD-0014', 'WIRE-HAR-0554',	'FLM1-GAS-0009', 'FLM1-MAC-0285',
		'FLM1-SUB-0029', 'FLM1-SUB-0053', 'PCBA-SUB-0836', 'FLM1-SUB-0006',	'FLM1-SUB-0002', 'PCBA-SUB-0847',
		'PCBA-SUB-0856', 'FLM1-GAS-0018', 'PCBA-SUB-0839', 'PCBA-SUB-0838',	'FLM1-SUB-0074', 'FLM1-SUB-0078'
	)
	AND ISNUMERIC(U.[Quantity]) = 1
	AND R.[ServiceCompleted] IS NOT NULL

SELECT 
	[VisitNo],
	[SerialNo],
	YEAR([ServiceCompleted]) AS [Year],
	DATEPART(ww, [ServiceCompleted]) AS [Week],
	[PartNumber] AS [PartNo],
	CASE 
		WHEN [PartUsed] IN ('FLM1-GAS-0009', 'FLM1-GAS-0018') THEN 'Plunger Gasket'
		WHEN [PartUsed] IN ('FLM1-SUB-0029', 'FLM1-SUB-0074') THEN 'Peltier Assembly'
		WHEN [PartUsed] IN ('FLM1-SUB-0053', 'FLM1-SUB-0078') THEN 'Sealbar Assembly'
		WHEN [PartUsed] LIKE 'FLM1-MAC-0285' THEN 'Sample Piston'
		WHEN [PartUsed] LIKE 'FLM1-MOD-0014' THEN 'Hardseal Gasket'
		WHEN [PartUsed] LIKE 'FLM1-MOL-0023' THEN 'Molded Bladder'
		WHEN [PartUsed] LIKE 'FLM1-SUB-0002' THEN 'Magnet Assembly'
		WHEN [PartUsed] LIKE 'FLM1-SUB-0006' THEN 'Bead Beater'
		WHEN [PartUsed] LIKE 'FLM1-SUB-0044' THEN 'Window Bladder'
		WHEN [PartUsed] LIKE 'PCBA-SUB-0836' THEN 'Thermo Board'
		WHEN [PartUsed] LIKE 'PCBA-SUB-0847' THEN 'Valve Board'
		WHEN [PartUsed] LIKE 'PCBA-SUB-0856' THEN '2.0 Excitation LED'
		WHEN [PartUsed] LIKE 'WIRE-HAR-0554' THEN '-0554 Valve'
		WHEN [PartUsed] LIKE 'PCBA-SUB-0839' THEN 'Master Board'
		WHEN [PartUsed] LIKE 'PCBA-SUB-0838' THEN '2.0 Camera Board'
		ELSE 'Other'
	END AS [Key],
	[Version],
	[HoursRun],
	[Record]
FROM #partsReplaced
ORDER BY [Version], [Year], [Week], [SerialNo]

DROP TABLE #codeParts, #partsReplaced

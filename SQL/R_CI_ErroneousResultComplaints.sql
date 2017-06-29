SET NOCOUNT ON

SELECT 
	[TicketId],
	[Issue CI] AS [ciIssued],
	[Justification for Complaint Escalation] AS [ciJustification]
INTO #ciInfo
FROM
(
	SELECT 
		[TicketId],
		[PropertyName],
		[RecordedValue]
	FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
	WHERE [PropertyName] IN ('Issue CI','Justification for Complaint Escalation') AND [CreatedDate] > GETDATE() - 800 AND [Tracker] LIKE 'COMPLAINT'
) P
PIVOT
(
	MAX([RecordedValue])
	FOR [PropertyName]
	IN
	(
		[Issue CI],
		[Justification for Complaint Escalation]
	)
) PIV

SELECT 
	[TicketId],
	[RecordedValue] AS [preCriteria]
INTO #pre
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'PRE' AND [CreatedDate] > GETDATE() - 800 AND [Tracker] LIKE 'COMPLAINT'

SELECT *
INTO #bfdxPartNo
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'BFDX Part Number' AND [CreatedDate] > GETDATE() - 800 AND [Tracker] LIKE 'COMPLAINT'

SELECT 
	[TicketId],
	[RecordedValue] AS [RelatedCI]
INTO #ciLink
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Related CI' AND [RecordedValue] IS NOT NULL AND [RecordedValue] NOT IN ('','N/A') AND [CreatedDate] > GETDATE() - 800 AND [Tracker] LIKE 'COMPLAINT'

SELECT
	[CreatedDate], 
	YEAR([CreatedDate]) AS [Year],
	DATEPART(ww, [CreatedDate]) AS [Week],
	[PartNo] AS [Version],
	[FailureMode] AS [Key],
	[QtyAffected] AS [Record]
INTO #master
FROM #ciInfo C LEFT JOIN #pre P
	ON C.[TicketId] = P.[TicketId] LEFT JOIN
	(
		SELECT 
			[TicketId],
			[TicketString],
			[CreatedDate],
			[Lot/Serial Number] AS [SerialNo],
			[Part Number] AS [PartNo],
			[Failure Mode] AS [FailureMode],
			[Quantity Affected] AS [QtyAffected]
		FROM
		(
			SELECT 
				[TicketId],
				[TicketString],
				[CreatedDate],
				[ObjectId],
				[PropertyName],
				[RecordedValue]
			FROM #bfdxPartNo
		) P
		PIVOT
		(
			MAX([RecordedValue])
			FOR [PropertyName]
			IN
			(
				[Lot/Serial Number],
				[Part Number],
				[Failure Mode],
				[Quantity Affected]
			)
		) PIV
	) N
		ON C.[TicketId] = N.[TicketId] LEFT JOIN #ciLink L
			ON C.[TicketId] = L.[TicketId]
WHERE [preCriteria] LIKE 'Erroneous Result%' AND [ciIssued] = 1

SELECT DISTINCT 
	[ItemID],
	[Panel]
INTO #panels
FROM [PMS1].[dbo].[vPouchShipments] WITH(NOLOCK)

SELECT 
	M.[Year],
	M.[Week],
	IIF(M.[Key] LIKE '%-1-%', 'Instrument',
		IIF(M.[Key] LIKE '%-2-%', 'Chemistry',
		IIF(M.[Key] LIKE '%-3-%', 'Pouch',
		IIF(M.[Key] LIKE '%-4-%', 'Software',
		IIF(M.[Key] LIKE '%-5-%', 'Accessory/Kitting', 'Other'))))) AS [Version],
	UPPER(M.[Version]) AS [Key],
	IIF(CHARINDEX('-',M.[Key]) = 0, M.[Key], SUBSTRING(M.[Key],1,CHARINDEX('-',M.[Key])-1)) AS [RecordedValue],
	CAST(M.[Record] AS INT) AS [Record]
INTO #final
FROM #master M LEFT JOIN #panels P
	ON M.[Version] = P.[ItemID]
WHERE ISNUMERIC([Record]) = 1 AND M.[CreatedDate] > GETDATE() - 800

SELECT 
	F.[Year],
	F.[Week],
	F.[Version],
	F.[Key],
	F.[RecordedValue],
	SUM(F.[Record]) AS [Record]
FROM #final F
GROUP BY 
	F.[Year],
	F.[Week],
	F.[Version],
	F.[Key],
	F.[RecordedValue]

DROP TABLE #bfdxPartNo, #ciInfo, #pre, #ciLink, #master, #panels, #final

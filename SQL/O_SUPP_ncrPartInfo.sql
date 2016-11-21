SET NOCOUNT ON

SELECT DISTINCT
	[ItemID]
INTO #vend
FROM [PMS1].[dbo].[vSupplierReceipts] WITH(NOLOCK)

SELECT
	[TicketId],
	[TicketString],
	[CreatedDate],
	[RecordedValue] AS [Type]
INTO #type
FROM [PMS1].[dbo].[vTrackers_AllPropertiesByStatus]
WHERE [PropertyName] LIKE 'NCR Type'

SELECT 
	[TicketId],
	[ObjectId],
	[PropertyName],
	[RecordedValue]
INTO #partsAffectedPrePiv
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE --[TicketId] >= 26282 AND 
[ObjectName] LIKE 'Parts Affected'

SELECT 
	[TicketId],
	[Part Affected],
	[Lot or Serial Number],
	[Quantity Affected],
	[Unit of Measure],
	[Disposition]
INTO #partsAffected
FROM
(
	SELECT *
	FROM #partsAffectedPrePiv
) P 
PIVOT
(
	MAX([RecordedValue])
	FOR [PropertyName]
	IN
	(
		[Part Affected],
		[Lot or Serial Number],
		[Quantity Affected],
		[Unit of Measure],
		[Disposition]
	)
) PIV

SELECT 
	T.[TicketId],
	T.[TicketString],
	T.[CreatedDate],
	T.[Type],
	A.[Part Affected] AS [PartNumber],
	A.[Lot or Serial Number] AS [LotOrSerialNo],
	REPLACE(A.[Quantity Affected],',','') AS [Qty],
	A.[Unit of Measure],
	A.[Disposition]
INTO #temp
FROM #type T LEFT JOIN #partsAffected A
	ON T.[TicketId] = A.[TicketId]
--WHERE T.[CreatedDate] > CONVERT(DATETIME,'2014-06-01')

SELECT 
	[TicketId],
	[RecordedValue] AS [VendName]
INTO #ncrVend
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [PropertyName] LIKE 'Vendor'


SELECT 
	CAST([CreatedDate] AS DATE) AS [Date],
	YEAR([CreatedDate]) AS [Year],
	MONTH([CreatedDate]) AS [Month],
	DATEPART(ww,[CreatedDate]) AS [Week],
	[Type],
	IIF(UPPER([VendName]) LIKE 'NA','N/A', [VendName]) AS [VendName],
	UPPER([PartNumber]) AS [PartNumber],
	CAST([Qty] AS BIGINT) AS [Qty],
	[Disposition]
FROM #temp T LEFT JOIN #ncrVend V
	ON T.[TicketId] = V.[TicketId]
WHERE [PartNumber] IN (SELECT [ItemID] FROM #vend) AND ISNUMERIC([Qty]) = 1

DROP TABLE #type, #partsAffectedPrePiv, #partsAffected, #temp, #vend, #ncrVend
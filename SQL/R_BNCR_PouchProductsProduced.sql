SELECT 
	YEAR([Date]) AS [Year],
	DATEPART(ww, [Date]) AS [Week],
	[Key],
	SUM([Record]) AS [Record]
FROM 
(
	SELECT 
		IIF([DateOfManufacturing] > GETDATE(), [DateCompleted], [DateOfManufacturing]) AS [Date],
		'Array' AS [Key],
		[DesiredLotSize] AS [Record]
	FROM [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK)
		ON L.[PartNumberId] = P.[PartNumberId] INNER JOIN [ProductionWeb].[dbo].[LotApprovals] LA WITH(NOLOCK)
			ON LA.[LotNumber] = L.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[Approvals] A WITH(NOLOCK)
				ON A.[LotApprovalId] = LA.[LotApprovalId]
	WHERE [PartNumber] IN 
	(
		'RFIT-SUB-0076',
		'RFIT-SUB-0111',
		'RFIT-SUB-0114',
		'RFIT-SUB-0212',
		'RFIT-SUB-0213',
		'RFIT-SUB-0348',
		'RFIT-SUB-0384'
	)

	UNION ALL
	
	SELECT
		IIF([DateOfManufacturing] > GETDATE(), [DateCompleted], [DateOfManufacturing]) AS [Date],
		'Oligo' AS [Key],
		[DesiredLotSize] AS [Record]
	FROM [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK)
		ON L.[PartNumberId] = P.[PartNumberId] INNER JOIN [ProductionWeb].[dbo].[LotApprovals] LA WITH(NOLOCK)
			ON LA.[LotNumber] = L.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[Approvals] A WITH(NOLOCK)
				ON A.[LotApprovalId] = LA.[LotApprovalId]
	WHERE [PartNumber] LIKE 'I%[~a-z]'

	UNION ALL

	SELECT 
		IIF([DateOfManufacturing] > GETDATE(), [DateCompleted], [DateOfManufacturing]) AS [Date],
		'Final' AS [Key],
		[DesiredLotSize] AS [Record]
	FROM [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK)
		ON L.[PartNumberId] = P.[PartNumberId] INNER JOIN [ProductionWeb].[dbo].[LotApprovals] LA WITH(NOLOCK)
			ON LA.[LotNumber] = L.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[Approvals] A WITH(NOLOCK)
				ON A.[LotApprovalId] = LA.[LotApprovalId]
	WHERE [BatchRecordId] LIKE 'FA-201C'

	UNION ALL

	SELECT 
		IIF([DateOfManufacturing] > GETDATE(), [DateCompleted], [DateOfManufacturing]) AS [Date],
		'Pouch' AS [Key],
		[DesiredLotSize] AS [Record]
	FROM [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK)
		ON L.[PartNumberId] = P.[PartNumberId] INNER JOIN [ProductionWeb].[dbo].[LotApprovals] LA WITH(NOLOCK)
			ON LA.[LotNumber] = L.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[Approvals] A WITH(NOLOCK)
				ON A.[LotApprovalId] = LA.[LotApprovalId]
	WHERE [BatchRecordId] LIKE 'FA-201A'

	UNION ALL

	SELECT 
		IIF([DateOfManufacturing] > GETDATE(), [DateCompleted], [DateOfManufacturing]) AS [Date],
		'FAIV' AS [Key],
		[DesiredLotSize] AS [Record]
	FROM [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK)
		ON L.[PartNumberId] = P.[PartNumberId] INNER JOIN [ProductionWeb].[dbo].[LotApprovals] LA WITH(NOLOCK)
			ON LA.[LotNumber] = L.[LotNumber] INNER JOIN [ProductionWeb].[dbo].[Approvals] A WITH(NOLOCK)
				ON A.[LotApprovalId] = LA.[LotApprovalId]
	WHERE [PartNumber] IN 
	(
		'FAIV-SUB-0001',
		'FAIV-SUB-0002'
	)
) D
WHERE [Date] > GETDATE() - 400
GROUP BY 
	YEAR([Date]),
	DATEPART(ww, [Date]),
	[Key]
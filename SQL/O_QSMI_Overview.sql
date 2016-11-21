SET NOCOUNT ON

SELECT
	--I.[CreateDate],
	I.[InspectionDate] AS [Date],
	P.[PartNumber],
	P.[Name] AS [Description],
	
	S.[Quantity],
	
	I.[QuantityFail],
	
	I.[SampleSize],
	E.[Value] AS [PassOrFail],
	I.[NCRNumber],
	I.[Inspector],
	S.[Warehouse],
	I.[InspectionArea] AS [InspectionType],
	S.[Location],
	I.[Comment] AS [Comments],
	CONCAT(L.[LotNumber],':',S.[SublotId]) AS [BFDxLotNumber:SublotNumber],
	L.[ManufacturerLotNumber],
	I.[MinutesToInspect],
	L.[DateOfManufacturing],
	I.[DaysToInspect],

	I.[IncludeInReporting],

	L.[ProcessStateId],
	L.[QcStateIdOld],
	S.[QcStateIdOld],
	S.[QcStateId]
FROM [ProductionWeb].[dbo].[LotInspectionData] I WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK)
	ON I.[LotNumberId] = L.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK)
		ON L.[PartNumberId] = P.[PartNumberId] INNER JOIN [ProductionWeb].[dbo].[Sublots] S WITH(NOLOCK)
			ON L.[LotNumberId] = S.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[ReagentWebEnums] E WITH(NOLOCK)
				ON S.[QcStateIdOld] = E.[ReagentWebEnumId]
WHERE I.[InspectionDate] = CONVERT(DATETIME, '2016-04-18') AND I.[InspectionArea] LIKE 'SMI'
ORDER BY P.[PartNumber]

/*
SELECT TOP 1 
	P.[PartNumber],
	P.[Name],
	P.[PartType],
	L.[LotNumber],
	L.[DateOfManufacturing],
	L.[ManufacturerLotNumber],
	L.[ProcessStateId],
	L.[QcStateIdOld],
	A.[RecordedValue],
	R.[Department],
	R.[Enum],
	R.[Value],
	W.*,
	E.*,
	A.[LotNumberIdOld],
	A.[LotAttributeId],
	A.[LotNumberId],
	T.[PartNumberId],
	T.[ReagentWebEnumId]
FROM [ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[LotAttributes] A WITH(NOLOCK) 
	ON L.[LotNumberId] = A.[LotNumberId] INNER JOIN [ProductionWeb].[dbo].[TrackableAttributes] T WITH(NOLOCK)
		ON A.[TrackableAttributeId] = T.[TrackableAttributeId] INNER JOIN [ProductionWeb].[dbo].[Parts] P WITH(NOLOCK)
			ON T.[PartNumberId] = P.[PartNumberId] INNER JOIN [ProductionWeb].[dbo].[ReagentWebEnums] R WITH(NOLOCK)
				ON T.[ReagentWebEnumId] = R.[ReagentWebEnumId] INNER JOIN [ProductionWeb].[dbo].[ReagentWebEnums] W WITH(NOLOCK)
					ON L.[ProcessStateId] = W.[ReagentWebEnumId] INNER JOIN [ProductionWeb].[dbo].[ReagentWebEnums] E WITH(NOLOCK)
						ON L.[QcStateIdOld] = E.[ReagentWebEnumId]
WHERE L.[DateOfManufacturing] <= GETDATE()
ORDER BY L.[DateOfManufacturing] DESC

SELECT TOP 1 *
FROM [ProductionWeb].[dbo].[Sublots] S WITH(NOLOCK) INNER JOIN [ProductionWeb].[dbo].[ReagentWebEnums] B WITH(NOLOCK)
	ON S.[QcStateIdOld] = B.[ReagentWebEnumId]
	*/
SELECT
	I.[ItemID],
	C.[ItemClassID] AS [ItemClass],
	C.[ItemClassName] AS [ItemDesc],
	D.[CommodityCodeID] AS [CommodityClass],
	D.[Description] AS [CommodityDesc],
	--I.[ItemType],
	--I.[ItemSubType],
	--I.[ItemClassKey],
	--I.[CommClassKey],
	--I.[CommodityCodeKey],
	IIF(S.[InspectinReceiving] IS NULL, 0, 1) AS [InspectedAtReceipt],
	IIF(S.[SMI] IS NULL OR S.[SMI] = 0, 'No', 'Yes') AS [SMI]
FROM [SQL1-RO].[mas500_app].[dbo].[timItem] I WITH(NOLOCK) INNER JOIN [SQL1-RO].[mas500_app].[dbo].[timItemUDF_MAC] S WITH(NOLOCK)
	ON I.[ItemKey] = S.[ItemKey] INNER JOIN [SQL1-RO].[mas500_app].[dbo].[timItemClass] C WITH(NOLOCK)
		ON I.[ItemClassKey] = C.[ItemClassKey] LEFT JOIN [SQL1-RO].[mas500_app].[dbo].[timCommodityCode] D WITH(NOLOCK)
			ON I.[CommodityCodeKey] = D.[CommodityCodeKey]
USE [PMS1]
GO
IF OBJECT_ID('dbo.vInstrumentBillOfMaterials','V') IS NOT NULL
DROP VIEW [dbo].[vInstrumentBillOfMaterials]
USE [PMS1]
GO
CREATE VIEW [dbo].[vInstrumentBillOfMaterials]
AS 
SELECT
	[ItemID],
	[ItemKey],
	[ShortDesc],
	[ComponentItemID],
	[ComponentItemKey],
	[ComponentItemShortDesc]
FROM [SQL1-RO].[mas500_app].[dbo].[vdvBillofMaterials] WITH(NOLOCK)
WHERE [ItemID] LIKE 'FLM%-%-%' OR [ItemID] LIKE 'HTFA-%-%'
GROUP BY
	[ItemID],
	[ItemKey],
	[ShortDesc],
	[ComponentItemKey],
	[ComponentItemID],
	[ComponentItemShortDesc]
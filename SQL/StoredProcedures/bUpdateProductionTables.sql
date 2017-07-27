-- Updates the tables bInstrumentParts and bInstrumentProduced
USE PMS1
GO

IF OBJECT_ID('[dbo].[bUpdateProductionTables]') IS NOT NULL
DROP PROCEDURE [dbo].[bUpdateProductionTables]
GO

CREATE PROCEDURE [dbo].[bUpdateProductionTables]
AS
BEGIN TRAN

-- Update [dbo].[bInstrumentParts]
SELECT
	L.[LotNumberId],
	L.[LotNumber],
	P.[PartNumber] AS [PartNumber],
	1 AS [Quantity]
INTO #parts
FROM [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[Lots] L WITH(NOLOCK)
INNER JOIN [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[Parts] P ON P.[PartNumberId] = L.[PartNumberId]
WHERE P.[PartNumber] IN (SELECT [PartNumber] FROM [PMS1].[dbo].[bInstrumentVersion])

SELECT 
	L.[LotNumber] AS [OuterLot],
	U.[LotNumber] AS [InnerLot],
	U.[PartNumber] AS [InnerPart],
	U.[Quantity]
INTO #edge
FROM [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[UtilizedParts] U WITH(NOLOCK)
INNER JOIN [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[Lots] L WITH(NOLOCK) ON L.[LotNumberId] = U.[LotNumberId]
WHERE U.[Quantity]>0 AND U.[PartNumber] NOT IN (SELECT [PartNumber] FROM [PMS1].[dbo].[bInstrumentVersion])

SELECT *
INTO #newParts
FROM #parts

DECLARE @cnt INT = 0;
WHILE @cnt < 15
BEGIN
	SELECT * 
	INTO #newParts2
	FROM (
		SELECT
			P.[LotNumberId],
			E.[InnerLot] AS [LotNumber],
			E.[InnerPart] AS [PartNumber],
			E.[Quantity]
		FROM #newParts P
		INNER JOIN #edge E ON E.[OuterLot] = P.[LotNumber]
		WHERE E.[OuterLot] NOT IN ('N/A', 'NA')
		EXCEPT
		SELECT * FROM #parts
	) Q

	INSERT INTO #parts
	SELECT * FROM #newParts2
	TRUNCATE TABLE #newParts
	INSERT INTO #newParts SELECT * FROM #newParts2
	DROP TABLE #newParts2
    SET @cnt = @cnt + 1;
END;

SELECT 
	[NormalSerial],
	[DatePlaced],
	IIF([LotNumber] IN ('NA', 'N/A'), NULL,
		REPLACE(SUBSTRING([LotNumber], 1, PATINDEX('%[:/]%', [LotNumber] + ':') - 1), ' ', '')) AS [LotNumber],
	[PartNumber],
	[Quantity],
	[HoursRun]
INTO [dbo].[bInstrumentParts_TEMP]
FROM (
	SELECT 
		REPLACE(REPLACE(REPLACE(REPLACE(IL.[LotNumber], '.', ''), '_', ''), 'R', ''), '2FA', 'FA') AS [NormalSerial],
		IL.[DateOfManufacturing] AS [DatePlaced],
		P.[LotNumber],
		P.[PartNumber],
		P.[Quantity],
		0 AS [HoursRun]
	FROM #parts P
	INNER JOIN [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[Lots] IL ON IL.[LotNumberId] = P.[LotNumberId]
	UNION ALL
	SELECT
		I.[NormalSerial],
		I.[CreatedDate] AS [DatePlaced],
		CASE
			WHEN REPLACE(U.[LotSerialNumber], ' ', '') IN ('NA', 'N/A') THEN NULL
			ELSE REPLACE(SUBSTRING(U.[LotSerialNumber], 1, PATINDEX('%[:/]%', U.[LotSerialNumber]+':')-1), ' ', '')
		END AS [LotNumber],
		UPPER(REPLACE(U.[PartUsed], ' ', '')) AS [PartNumber],
		CAST(U.[Quantity] AS INT) AS [Quantity],
		I.[HoursRun] AS [HoursRun]
	FROM [PMS1].[dbo].[bInstrumentFailure] I
	INNER JOIN [PMS1].[dbo].[RMAPartsUsed] U ON U.[TicketId] = I.[TicketId]
	WHERE TRY_CAST(U.[Quantity] AS INT)>0
) Q


CREATE INDEX [idx_NormalSerial] ON [dbo].[bInstrumentParts_TEMP]([NormalSerial])
CREATE INDEX [idx_PartNumber] ON [dbo].[bInstrumentParts_TEMP]([PartNumber])

IF OBJECT_ID('dbo.bInstrumentParts') IS NOT NULL
DROP TABLE [dbo].[bInstrumentParts]
EXEC sp_rename 'dbo.bInstrumentParts_TEMP', 'bInstrumentParts';
DROP TABLE #edge, #parts, #newParts

-- Update [dbo].[bInstrumentProduced]
SELECT 
	*,
	ROW_NUMBER() OVER(PARTITION BY [NormalSerial] ORDER BY [DateOfManufacturing]) AS [ProdNo]
INTO [dbo].[bInstrumentProduced_TEMP]
FROM (
	SELECT
		CAST(L.[DateOfManufacturing] AS DATE) AS [DateOfManufacturing],
		UPPER(REPLACE(REPLACE(REPLACE(REPLACE(L.[LotNumber], ' ', ''), '.', ''), '_', ''), 'KTM', 'TM')) AS [SerialNo],
		P.[PartNumber],
		V.[Version],
		V.[Refurb],
		UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(L.[LotNumber], ' ', ''), '.', ''), '_', ''), 'KTM', 'TM'), 'R', ''), '2FA', 'FA')) AS [NormalSerial]
	FROM [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[Lots] L
	INNER JOIN [RO_PRODUCTIONWEB].[ProductionWeb].[dbo].[Parts] P ON P.[PartNumberId] = L.[PartNumberId]
	INNER JOIN [PMS1].[dbo].[bInstrumentVersion] V ON V.[PartNumber] = P.[PartNumber]
) Q

CREATE INDEX [idx_NormalSerial] ON [dbo].[bInstrumentProduced_TEMP]([NormalSerial])
CREATE INDEX [idx_SerialNo] ON [dbo].[bInstrumentProduced_TEMP]([SerialNo])

IF OBJECT_ID('dbo.bInstrumentProduced') IS NOT NULL
DROP TABLE [dbo].[bInstrumentProduced]
EXEC sp_rename 'dbo.bInstrumentProduced_TEMP', 'bInstrumentProduced';

COMMIT
GO

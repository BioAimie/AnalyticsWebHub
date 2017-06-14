USE PMS1
GO

IF OBJECT_ID('[dbo].[bInstrumentVersion]') IS NOT NULL
DROP VIEW [dbo].[bInstrumentVersion]
GO

CREATE VIEW [dbo].[bInstrumentVersion] AS
SELECT *
FROM (VALUES 
	('FLM1-ASY-0001', 'FA1.5', 0),
	('FLM1-ASY-0001R', 'FA1.5', 1),
	('FLM2-ASY-0001', 'FA2.0', 0),
	('FLM2-ASY-0001R', 'FA2.0', 1),
	('HTFA-ASY-0003', 'Torch', 0),
	('HTFA-ASY-0003R', 'Torch', 1),
	('HTFA-SUB-0103', 'Torch', 0),
	('HTFA-SUB-0103R', 'Torch', 1)
) V([PartNumber], [Version], [Refurb])
GO

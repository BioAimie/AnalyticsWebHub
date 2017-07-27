USE [PMS1]
GO

IF OBJECT_ID('dbo.vSerialTransactions','V') IS NOT NULL
DROP VIEW [dbo].[vSerialTransactions]

USE [PMS1]
GO

CREATE VIEW [dbo].[vSerialTransactions]
AS

/*
		FLM1-ASY-0001	FilmArray Instrument Final Assembly*
		FLM1-ASY-0001D	Demo FilmArray Instrument w/ pwr cord*
		FLM1-ASY-0001R	FilmArray Instrument, REFURBISHED*
		FLM2-ASY-0001	FilmArray 2.0 Instrument Final Assembly*
		FLM2-ASY-0001R	FilmArray 2.0 Inst. Final Assy, REFURB*
		HTFA-ASY-0003	Torch Instrument
		HTFA-ASY-0003R	Torch Instrument, REFURB ??????????
		HTFA-ASY-0001	Torch Base
		HTFA-ASY-0001R	Torch Base (refurb)
*/

WITH [Serials] ([SerialNo], [DistQty], [TranKey])
	AS 
	(
		SELECT
			S.[SerialNo],
			S.[DistQty],
			S.[TranKey]
		FROM [RO_MAS].[mas500_app].[dbo].[vdvSerialTransactions] S WITH(NOLOCK)	
		WHERE (S.[ItemID] LIKE 'FLM1-ASY-0001%' OR S.[ItemID] LIKE 'FLM2-ASY-0001%' OR S.[ItemID] LIKE 'HTFA-ASY-0003%' OR S.[ItemID] LIKE 'HTFA-ASY-0001%')
	),

	[Trans] ([TranKey], [TranID], [TranDate], [ItemID], [ItemDesc], [TranType], [WhseID], [TranQty]) 
	AS 
	( 
		SELECT
			T.[TranKey],
			T.[TranID],
			T.[TranDate],
			T.[ItemID],
			T.[ItemDesc],
			T.[TranType],
			T.[WhseID],
			T.[TranQty]
		FROM [RO_MAS].[mas500_app].[dbo].[vdvInventoryTran] T WITH(NOLOCK)	
		WHERE (T.[ItemID] LIKE 'FLM1-ASY-0001%' OR T.[ItemID] LIKE 'FLM2-ASY-0001%' OR T.[ItemID] LIKE 'HTFA-ASY-0003%' OR T.[ItemID] LIKE 'HTFA-ASY-0001%')
	)

	SELECT
		UPPER(REPLACE(REPLACE(S.[SerialNo],'_',''),'.','')) AS [SerialNo],
		T.[ItemID] AS [ItemID],
		T.[ItemDesc] AS [ItemDesc],
		T.[TranType] AS [TranType],
		T.[WhseID] AS [WhseID],
		T.[TranDate] AS [TranDate],
		IIF(T.[TranQty] < 0, -1, 1) AS [DistQty],
		T.[TranID], 
		T.[TranKey]/*
		S.[TranID],
		T.[InvtTranKey],
		S.[TranKey]	*/
	FROM [Trans] T WITH(NOLOCK) INNER JOIN [Serials] S
		ON T.[TranKey] = S.[TranKey]

GO
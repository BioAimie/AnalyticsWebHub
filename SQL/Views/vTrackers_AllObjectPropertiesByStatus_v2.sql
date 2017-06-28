USE [PMS1]
GO
IF OBJECT_ID('dbo.vTrackers_AllObjectPropertiesByStatus','V') IS NOT NULL
DROP VIEW [dbo].[vTrackers_AllObjectPropertiesByStatus]
USE [PMS1]
GO
CREATE VIEW [dbo].[vTrackers_AllObjectPropertiesByStatus]
AS

WITH 
	[Right] ([Tracker], [TicketId], [TicketString], [Status], [CreatedBy], [CreatedDate], [InitialCloseDate], [Stage], [ObjectId], [ObjectName], [PropertyId], [PropertyName]) 
	AS
	(
		SELECT
			BT.[Tracker],
			BT.[TicketId],
			BT.[TicketString],
			BT.[Status],
			BT.[CreatedBy],
			BT.[CreatedDate],
			BT.[InitialCloseDate],
			ST.[StageName] AS [Stage],
			O.[ObjectId],
			TRO.[Name] AS [ObjectName],
			OP.[PropertyId],
			TKP.[Name] AS [PropertyName]
		FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK) INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[GeneralTickets] GT WITH(NOLOCK)
			ON BT.[TicketId] = GT.[TicketId] INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK)
				ON GT.[TicketId] = TS.[TicketId] INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[StageTypes] ST WITH(NOLOCK)
					ON TS.[StageTypeId] = ST.[StageTypeId] INNER JOIN 
					(
						SELECT 
							GTH.[TicketStageId],
							MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId],
							MAX(GTH.[CreatedDate]) AS [CreatedDate]
						FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
						GROUP BY GTH.[TicketStageId]
					) GTH
						ON TS.[TicketStageId] = GTH.[TicketStageId] INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) 
							ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId] INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] O WITH (NOLOCK) 
								ON TKO.[ObjectId] = O.[ObjectId] INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[TrackableObjects] TRO WITH (NOLOCK) 
									ON O.[TrackableObjectId] = TRO.[TrackableObjectId] INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK) 
										ON TKO.[ObjectId] = OP.[ObjectId] INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK)
											ON OP.[PropertyId] = P.[PropertyId] INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[TrackableProperties] TKP WITH (NOLOCK) 
												ON P.[TrackablePropertyId] = TKP.[TrackablePropertyId]
		WHERE BT.[Status] NOT IN ('ClosedDuplicate', 'ClosedVoided')
	), 

	[Text] ([PropertyId], [RecordedValue]) 
	AS
	(
		SELECT
			P.[PropertyId],
			T.[RecordedValue]
		FROM [RO_TRACKERS].[Trackers].[dbo].[Properties] P INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[ApproverUserProperties] T
			ON P.[PropertyId] = T.[PropertyId]
		UNION
		SELECT
			P.[PropertyId],
			T.[RecordedValue]
		FROM [RO_TRACKERS].[Trackers].[dbo].[Properties] P INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[DecimalProperties] T
			ON P.[PropertyId] = T.[PropertyId]
		UNION
		SELECT
			P.[PropertyId],
			T.[RecordedValue]
		FROM [RO_TRACKERS].[Trackers].[dbo].[Properties] P INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[UserProperties] T
			ON P.[PropertyId] = T.[PropertyId]
		UNION
		SELECT
			P.[PropertyId],
			T.[RecordedValue]
		FROM [RO_TRACKERS].[Trackers].[dbo].[Properties] P INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T
			ON P.[PropertyId] = T.[PropertyId]
		UNION
		SELECT
			P.[PropertyId],
			T.[RecordedValue]
		FROM [RO_TRACKERS].[Trackers].[dbo].[Properties] P INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T
			ON P.[PropertyId] = T.[PropertyId]
		UNION
		SELECT 
			P.[PropertyId],
			T.[RecordedValue]
		FROM [RO_TRACKERS].[Trackers].[dbo].[Properties] P INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[PartNumberProperties] T
			ON P.[PropertyId] = T.[PropertyId]
		UNION
		SELECT 
			P.[PropertyId],
			T.[RecordedValue]
		FROM [RO_TRACKERS].[Trackers].[dbo].[Properties] P INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[TimestampButtonProperties] T
			ON P.[PropertyId] = T.[PropertyId]
		UNION
		SELECT
			P.[PropertyId],
			T.[RecordedValue]
		FROM [RO_TRACKERS].[Trackers].[dbo].[Properties] P INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T
			ON P.[PropertyId] = T.[PropertyId]
		UNION
		SELECT
			P.[PropertyId],
			T.[RecordedValue]
		FROM [RO_TRACKERS].[Trackers].[dbo].[Properties] P INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[MoneyProperties] T
			ON P.[PropertyId] = T.[PropertyId]
		UNION
		SELECT
			P.[PropertyId],
			T.[RecordedValue]
		FROM [RO_TRACKERS].[Trackers].[dbo].[Properties] P INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[LotNumberProperties] T
			ON P.[PropertyId] = T.[PropertyId]
		UNION
		SELECT
			P.[PropertyId],
			T.[RecordedValue]
		FROM [RO_TRACKERS].[Trackers].[dbo].[Properties] P INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[YesNoNAProperties] T
			ON P.[PropertyId] = T.[PropertyId]
		UNION
		SELECT
			P.[PropertyId],
			T.[RecordedValue]
		FROM [RO_TRACKERS].[Trackers].[dbo].[Properties] P INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[TitleProperties] T
			ON P.[PropertyId] = T.[PropertyId]
		UNION
		SELECT	
			P.[PropertyId],
			T.[RecordedValue]
		FROM [RO_TRACKERS].[Trackers].[dbo].[Properties] P INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[ProblemDescriptionProperties] T
			ON P.[PropertyId] = T.[PropertyId]
		UNION
		SELECT
			P.[PropertyId],
			T.[RecordedValue]
		FROM [RO_TRACKERS].[Trackers].[dbo].[Properties] P INNER JOIN  [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T
			ON P.[PropertyId] = T.[PropertyId]
	),

	[Float] ([PropertyId], [RecordedValue])
	AS
	(
		SELECT
			P.[PropertyId],
			T.[RecordedValue]
		FROM [RO_TRACKERS].[Trackers].[dbo].[Properties] P INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[SummedServiceHourProperties] T
			ON P.[PropertyId] = T.[PropertyId]
	),

	[Binary] ([PropertyId], [RecordedValue])
	AS
	(
		SELECT
			P.[PropertyId],
			T.[RecordedValue]
		FROM [RO_TRACKERS].[Trackers].[dbo].[Properties] P INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[CheckboxProperties] T
			ON P.[PropertyId] = T.[PropertyId]
	),

	[Datetime] ([PropertyId], [RecordedValue])
	AS
	(
		SELECT 
			P.[PropertyId],
			T.[RecordedValue]
		FROM [RO_TRACKERS].[Trackers].[dbo].[Properties] P INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[DateTimeProperties] T
			ON P.[PropertyId] = T.[PropertyId]
	)

SELECT 
	R.[TicketId],
	R.[Tracker],
	R.[TicketString],
	R.[Status],
	R.[CreatedBy],
	R.[CreatedDate],
	R.[InitialCloseDate],
	R.[Stage],
	R.[ObjectId],
	R.[ObjectName],
	R.[PropertyId],
	R.[PropertyName],
	CASE 
		WHEN T.[RecordedValue] IS NULL AND F.[RecordedValue] IS NULL AND B.[RecordedValue] IS NULL THEN CAST(D.[RecordedValue] AS VARCHAR(200))
		WHEN T.[RecordedValue] IS NULL AND F.[RecordedValue] IS NULL THEN CAST(B.[RecordedValue] AS VARCHAR(20))
		WHEN T.[RecordedValue] IS NULL THEN CAST(F.[RecordedValue] AS VARCHAR(40))
		ELSE T.[RecordedValue]
	END AS [RecordedValue]
FROM [Right] R LEFT JOIN [Text] T
	ON R.[PropertyId] = T.[PropertyId] LEFT JOIN [Float] F
		ON R.[PropertyId] = F.[PropertyId] LEFT JOIN [Binary] B
			ON R.[PropertyId] = B.[PropertyId] LEFT JOIN [Datetime] D
				ON R.[PropertyId] = D.[PropertyId]
GO
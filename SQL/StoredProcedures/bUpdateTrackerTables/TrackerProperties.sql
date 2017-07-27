SET NOCOUNT ON

SELECT
	BT.[Tracker],
	TRP.[TrackablePropertyId],
	TRP.[Name],
	Q.[Table],
	TS.[StageTypeId],
	ST.[StageName],
	COUNT(*) AS [Count],
	MIN(GTH.[MinCreatedDate]) AS [MinDate],
	MAX(GTH.[MaxCreatedDate]) AS [MaxDate],
	TRP.IsActive AS [PropertyActive],
	ST.IsActive AS [StageActive]
INTO #props
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
	INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
		INNER JOIN 	(
			SELECT 
				GTH.[TicketStageId],
				MAX(GTH.[CreatedDate]) AS [MaxCreatedDate],
				MIN(GTH.[CreatedDate]) AS [MinCreatedDate],
				MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
			FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
			GROUP BY GTH.[TicketStageId]
		) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
			INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketProperties] TP WITH(NOLOCK) ON TP.[GeneralTicketHistoryId] = GTH.[GeneralTicketHistoryId]
				INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH(NOLOCK) ON P.[PropertyId] = TP.[PropertyId]
					INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[TrackableProperties] TRP WITH(NOLOCK) ON TRP.[TrackablePropertyId] = P.[TrackablePropertyId]
						INNER JOIN (
							SELECT A.[PropertyId], 'ApproverUserProperties'	AS [Table] 
							FROM [RO_TRACKERS].[Trackers].[dbo].[ApproverUserProperties] A
							UNION
							SELECT A.[PropertyId], 'CheckboxProperties'	AS [Table] 
							FROM [RO_TRACKERS].[Trackers].[dbo].[CheckboxProperties] A
							UNION
							SELECT A.[PropertyId], 'DateTimeProperties'	AS [Table] 
							FROM [RO_TRACKERS].[Trackers].[dbo].[DateTimeProperties] A
							UNION
							SELECT A.[PropertyId], 'DecimalProperties' AS [Table] 
							FROM [RO_TRACKERS].[Trackers].[dbo].[DecimalProperties] A
							UNION
							SELECT A.[PropertyId], 'DropdownProperties'	AS [Table] 
							FROM [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] A
							UNION
							SELECT A.[PropertyId], 'IntegerProperties' AS [Table] 
							FROM [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] A
							UNION
							SELECT A.[PropertyId], 'LongTextProperties'	AS [Table] 
							FROM [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] A
							UNION
							SELECT A.[PropertyId], 'LotNumberProperties' AS [Table] 
							FROM [RO_TRACKERS].[Trackers].[dbo].[LotNumberProperties] A
							UNION
							SELECT A.[PropertyId], 'MoneyProperties' AS [Table] 
							FROM [RO_TRACKERS].[Trackers].[dbo].[MoneyProperties] A
							UNION
							SELECT A.[PropertyId], 'PartNumberProperties' AS [Table] 
							FROM [RO_TRACKERS].[Trackers].[dbo].[PartNumberProperties] A
							UNION
							SELECT A.[PropertyId], 'ProblemDescriptionProperties' AS [Table] 
							FROM [RO_TRACKERS].[Trackers].[dbo].[ProblemDescriptionProperties] A
							UNION
							SELECT A.[PropertyId], 'ShortTextProperties' AS [Table] 
							FROM [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] A
							UNION
							SELECT A.[PropertyId], 'SummedServiceHourProperties' AS [Table] 
							FROM [RO_TRACKERS].[Trackers].[dbo].[SummedServiceHourProperties] A
							UNION
							SELECT A.[PropertyId], 'TimestampButtonProperties' AS [Table] 
							FROM [RO_TRACKERS].[Trackers].[dbo].[TimestampButtonProperties] A
							UNION
							SELECT A.[PropertyId], 'TitleProperties' AS [Table] 
							FROM [RO_TRACKERS].[Trackers].[dbo].[TitleProperties] A
							UNION
							SELECT A.[PropertyId], 'UserProperties' AS [Table] 
							FROM [RO_TRACKERS].[Trackers].[dbo].[UserProperties] A
							UNION
							SELECT A.[PropertyId], 'YesNoNAProperties' AS [Table] 
							FROM [RO_TRACKERS].[Trackers].[dbo].[YesNoNAProperties] A
						) Q ON Q.[PropertyId] = P.[PropertyId]
							INNER JOIN [RO_TRACKERS].[Trackers].[dbo].[StageTypes] ST ON ST.[StageTypeId] = TS.[StageTypeId]
GROUP BY
	TRP.[TrackablePropertyId], BT.[Tracker], TRP.[name], Q.[Table], TS.[StageTypeId], ST.[StageName], TRP.[IsActive], ST.[IsActive]
HAVING COUNT(*) >= 100

SELECT *
FROM (
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY [Tracker], [Name] ORDER BY [TrackablePropertyId]) AS [Rank]
	FROM #props
	WHERE [PropertyActive] = 1 AND [StageActive] = 1	
) Q
WHERE [Rank] = 1
ORDER BY [Tracker], [Name], [Rank]

DROP TABLE #props

SET NOCOUNT ON

SELECT
	B.[bug_id],
	[creation_ts],
	[delta_ts],
	[product_id],
	[component_id],
	[cf_component],
	[cf_parentpn],
	[cf_lotserial],
	[cf_quantity],
	[cf_complaint],
	[cf_bfdxproduct],
	AA0.[value] AS [ComplaintAffectedAssay],
	CCS.[value] AS [CauseOfComplaintSummary]
INTO #masterCI
FROM CI...bugs B WITH(NOLOCK) INNER JOIN CI...bug_cf_affectedassay AA0 WITH(NOLOCK)
		ON B.[bug_id] = AA0.[bug_id] INNER JOIN CI...bug_cf_causeofcomplaintsummary CCS WITH(NOLOCK)
			ON B.[bug_id] = CCS.[bug_id]

SELECT 
	M.[bug_id],
	YEAR([creation_ts]) AS [Year],
	DATEPART(ww, [creation_ts]) AS [Week],
	[Version],
	[Key],
	[RecordedValue],
	[Note],
	1 AS [Record]
FROM #masterCI M INNER JOIN
(
	SELECT 
		[bug_id],
		[cf_bfdxproduct] AS [Version],
		[ComplaintAffectedAssay] AS [Key],
		[CauseOfComplaintSummary] AS [RecordedValue],
		IIF(LOWER([cf_bfdxproduct]) LIKE '%panel%','Panel','Other') AS [Note]
	FROM #masterCI
) D
	ON M.[bug_id] = D.[bug_id]
GROUP BY 
	M.[bug_id],
	[creation_ts],
	[Version],
	[Key],
	[Note],
	[RecordedValue]

DROP TABLE #masterCI
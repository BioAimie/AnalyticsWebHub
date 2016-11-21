SET NOCOUNT ON

SELECT 
	B.[bug_id],
	B.[creation_ts],
	B.[cf_serialnumber1] AS [SerialNo],
	B.[cf_specimentype1] AS [SpecimenType],
	O.[value] AS [Observation],
	A.[value] AS [Assay]
INTO #obs1
FROM CI...bugs B WITH(NOLOCK) INNER JOIN CI...bug_cf_observation1 O WITH(NOLOCK)
	ON B.[bug_id] = O.[bug_id] INNER JOIN CI...bug_cf_affectedassay1 A WITH(NOLOCK)
		ON B.[bug_id] = A.[bug_id]

SELECT 
	B.[bug_id],
	B.[creation_ts],
	B.[cf_serialnumber2] AS [SerialNo],
	B.[cf_specimentype2] AS [SpecimentType],
	O.[value] AS [Observation],
	A.[value] AS [Assay]
INTO #obs2
FROM CI...bugs B WITH(NOLOCK) INNER JOIN CI...bug_cf_observation2 O WITH(NOLOCK)
	ON B.[bug_id] = O.[bug_id] INNER JOIN CI...bug_cf_affectedassay2 A WITH(NOLOCK)
		ON B.[bug_id] = A.[bug_id]

SELECT 
	B.[bug_id],
	B.[creation_ts],
	B.[cf_serialnumber3] AS [SerialNo],
	B.[cf_specimentype3] AS [SpecimenType],
	O.[value] AS [Observation],
	A.[value] AS [Assay]
INTO #obs3
FROM CI...bugs B WITH(NOLOCK) INNER JOIN CI...bug_cf_observation3 O WITH(NOLOCK)
	ON B.[bug_id] = O.[bug_id] INNER JOIN CI...bug_cf_affectedassay3 A WITH(NOLOCK)
		ON B.[bug_id] = A.[bug_id]

SELECT 
	B.[bug_id],
	B.[creation_ts],
	B.[cf_serialnumber4] AS [SerialNo],
	B.[cf_specimentype4] AS [SpecimenType],
	O.[value] AS [Observation],
	A.[value] AS [Assay]
INTO #obs4
FROM CI...bugs B WITH(NOLOCK) INNER JOIN CI...bug_cf_observation4 O WITH(NOLOCK)
	ON B.[bug_id] = O.[bug_id] INNER JOIN CI...bug_cf_affectedassay4 A WITH(NOLOCK)
		ON B.[bug_id] = A.[bug_id]

SELECT 
	B.[bug_id],
	B.[creation_ts],
	B.[cf_serialnumber5] AS [SerialNo],
	B.[cf_specimentype5] AS [SpeimenType],
	O.[value] AS [Observation],
	A.[value] AS [Assay]
INTO #obs5
FROM CI...bugs B WITH(NOLOCK) INNER JOIN CI...bug_cf_observation5 O WITH(NOLOCK)
	ON B.[bug_id] = O.[bug_id] INNER JOIN CI...bug_cf_affectedassay5 A WITH(NOLOCK)
		ON B.[bug_id] = A.[bug_id]

SELECT 
	[bug_id],
	[SerialNo],
	YEAR([creation_ts]) AS [Year],
	DATEPART(ww,[creation_ts]) AS [Week],
	[SpecimenType] AS [Version],
	[Assay] AS [Key],
	[Observation] AS [RecordedValue]
FROM
(
	SELECT *
	FROM #obs1
	UNION ALL
	SELECT *
	FROM #obs2
	UNION ALL
	SELECT *
	FROM #obs3
	UNION ALL
	SELECT *
	FROM #obs4
	UNION ALL
	SELECT *
	FROM #obs5
) D
ORDER BY [bug_id], [SerialNo]

DROP TABLE #obs1, #obs2, #obs3, #obs4, #obs5
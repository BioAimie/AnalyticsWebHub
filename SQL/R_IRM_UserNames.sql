SET NOCOUNT ON

SELECT *
INTO #faUsers
FROM 
(
	SELECT DISTINCT
		[UserID] AS [UserID],
		IIF(CHARINDEX('(',[UserID]) > 0, UPPER(SUBSTRING([UserID], 1, CHARINDEX('(',[UserID])-1)), UPPER([UserID])) AS [User],
		IIF(CHARINDEX(' ',[UserID]) > 0, UPPER(SUBSTRING([UserID], 1, CHARINDEX(' ',[UserID])-1)), '') AS [FirstName],
		IIF(CHARINDEX(' ',[UserID]) > 0 AND CHARINDEX('(',[UserID]) > 0, UPPER(SUBSTRING([UserID], CHARINDEX(' ',[UserID]) + 1, CHARINDEX('(', [UserID]) - CHARINDEX(' ',[UserID])-2)),
			IIF(CHARINDEX(' ',[UserID]) > 0 AND CHARINDEX('(',[UserID]) = 0, UPPER(SUBSTRING([UserID], CHARINDEX(' ',[UserID]) + 1, 10)),[UserID])) AS [LastName],
		MAX([SampleId]) AS [SampId],
		MAX([EndTime]) AS [LastDate]
	FROM [FILMARRAYDB].[FilmArray1].[FilmArray].[ExperimentRun] R WITH(NOLOCK)
	WHERE [SampleId] NOT LIKE 'Anonymous'
	GROUP BY  [UserID]
	UNION
	SELECT DISTINCT
		[UserID] AS [UserID],
		IIF(CHARINDEX('(',[UserID]) > 0, UPPER(SUBSTRING([UserID], 1, CHARINDEX('(',[UserID])-1)), UPPER([UserID])) AS [User],
		IIF(CHARINDEX(' ',[UserID]) > 0, UPPER(SUBSTRING([UserID], 1, CHARINDEX(' ',[UserID])-1)), '') AS [FirstName],
		IIF(CHARINDEX(' ',[UserID]) > 0 AND CHARINDEX('(',[UserID]) > 0, UPPER(SUBSTRING([UserID], CHARINDEX(' ',[UserID]) + 1, CHARINDEX('(', [UserID]) - CHARINDEX(' ',[UserID])-2)),
			IIF(CHARINDEX(' ',[UserID]) > 0 AND CHARINDEX('(',[UserID]) = 0, UPPER(SUBSTRING([UserID], CHARINDEX(' ',[UserID]) + 1, 10)),[UserID])) AS [LastName],
		MAX([SampleId]) AS [SampId],
		MAX([EndTime]) AS [LastDate]
	FROM [FILMARRAYDB].[FilmArray2].[dbo].[ExperimentRun] R WITH(NOLOCK)
	WHERE [SampleId] NOT LIKE 'Anonymous'
	GROUP BY  [UserID]
) D

SELECT
	UPPER(IIF(CHARINDEX(',',[chrEmployeeName]) > 0, CONCAT(SUBSTRING([chrEmployeeName], CHARINDEX(',',[chrEmployeeName])+2, LEN([chrEmployeeName])),' ',SUBSTRING([chrEmployeeName], 1, CHARINDEX(',',[chrEmployeeName])-1)), [chrEmployeeName])) AS [Name],
	IIF(CHARINDEX(',',[chrEmployeeName]) > 0, UPPER(SUBSTRING([chrEmployeeName], CHARINDEX(',',[chrEmployeeName])+2, LEN([chrEmployeeName]))), UPPER(SUBSTRING([chrEmployeeName],1,CHARINDEX(' ',[chrEmployeeName])-1))) AS [FirstName],
	IIF(CHARINDEX(',',[chrEmployeeName]) > 0, UPPER(SUBSTRING([chrEmployeeName], 1, CHARINDEX(',',[chrEmployeeName])-1)), UPPER(SUBSTRING([chrEmployeeName],CHARINDEX(' ',[chrEmployeeName])+1,LEN([chrEmployeeName])-1))) AS [LastName],
	[chrDivisionNumber] AS [DivisionNumber],
	[chrDivisionName] AS [DivisionName],
	MAX([dtePeriodEndDate]) AS [LastDate]
INTO #mas
FROM [SQL1-RO].[mas500_app].[dbo].[vdvTimesheet] WITH(NOLOCK) 
GROUP BY 
	[chrEmployeeName],
	[chrDivisionNumber],
	[chrDivisionName]

SELECT 
	M.[Name],
	F.[UserID],
	M.[DivisionNumber],
	M.[DivisionName],
	'FirstTier' AS [Key]
INTO #firstTier
FROM #mas M INNER JOIN #faUsers F
	ON M.[Name] = F.[User]

SELECT 
	M.[Name],
	F.[UserID],
	M.[DivisionNumber],
	M.[DivisionName],
	'SecondTier' AS [Key]
INTO #secondTier
FROM #mas M INNER JOIN #faUsers F
	ON LEFT(M.[LastName],3) = LEFT(F.[LastName],3) AND LEFT(M.[FirstName],3) = LEFT(F.[FirstName],3) 
WHERE M.[Name] NOT IN (SELECT [Name] FROM #firstTier)

SELECT 
	M.[Name],
	F.[UserID],
	M.[DivisionNumber],
	M.[DivisionName],
	'ThirdTier' AS [Key]
INTO #thirdTier
FROM #mas M INNER JOIN #faUsers F
	ON M.[LastName] = F.[LastName] AND RIGHT(M.[FirstName],3) = RIGHT(F.[FirstName],3)
WHERE M.[Name] NOT IN (SELECT [Name] FROM #firstTier) AND M.[Name] NOT IN (SELECT [Name] FROM #secondTier)

SELECT [UserID], [DivisionName]
FROM #firstTier
UNION
SELECT [UserID], [DivisionName]
FROM #secondTier
UNION 
SELECT [UserID], [DivisionName]
FROM #thirdTier

DROP TABLE #faUsers, #mas, #firstTier, #secondTier, #thirdTier
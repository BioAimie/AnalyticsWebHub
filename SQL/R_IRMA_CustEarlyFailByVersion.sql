SET NOCOUNT ON
SELECT 
	CAST([CreatedDate] AS DATE) AS [Date],
	YEAR([CreatedDate]) AS [Year],
	MONTH([CreatedDate]) AS [Month],
	DATEPART(ww,[CreatedDate]) AS [Week],
	CASE
		WHEN LEFT([PartNumber], 4) = 'FLM1' THEN 'FA1.5'
		WHEN LEFT([PartNumber], 4) = 'FLM2' THEN 'FA2.0'
		WHEN LEFT([PartNumber], 4) = 'HTFA' THEN 'Torch'
		ELSE 'Other'
	END AS [Version],
	[EarlyFailureType] AS [Key],
	1 AS [Record]
FROM [PMS1].[dbo].[RMAPartInformation]
WHERE [EarlyFailureType] IS NOT NULL AND [EarlyFailureType] NOT IN ('', 'N/A')
	AND ([PartNumber] LIKE 'FLM%-ASY-0001%' OR [PartNumber] LIKE 'HTFA-ASY-0003%' OR [PartNumber] LIKE 'HTFA-SUB-0103%')

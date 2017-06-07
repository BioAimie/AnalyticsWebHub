SET NOCOUNT ON

SELECT 
	*,
	COUNT(*) AS [Record]
FROM (
	SELECT
		YEAR([ServiceCompleted]) AS [Year],
		DATEPART(ww, [ServiceCompleted]) AS [Week],
		CASE
			WHEN LEFT(I.[PartNumber],4) = 'FLM1' THEN 'FA1.5'
			WHEN LEFT(I.[PartNumber],4) = 'FLM2' THEN 'FA2.0'
			WHEN LEFT(I.[PartNumber],4) = 'HTFA' THEN 'Torch'
			ELSE 'Other'
		END AS [Version],
		REPLACE(S.[ServiceCode], ' ', '') AS [Key]
	FROM [PMS1].[dbo].[bInstrumentFailure] I
	INNER JOIN [PMS1].[dbo].[RMA] R ON R.[TicketId] = I.[TicketId]
	INNER JOIN [PMS1].[dbo].[RMAServiceCodes] S ON S.[TicketId] = I.[TicketId]
	WHERE [ServiceCompleted] IS NOT NULL
) Q
WHERE [Key] IN (
	'0','10','100','103','109','11','110','115','12','14','17','203','204','205','206','207','254','256','257','258','301','302','304','351','355','358','359','4','400','402',
	'450','451','452','5','503','504','507','509','51','511','512','52','53','600','601','602','604','605','606','651','655','657','702','750','807',
	'810','9','900','901','902','950'
)
GROUP BY [Year], [Week], [Version], [Key]

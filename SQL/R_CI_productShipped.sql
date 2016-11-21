SET NOCOUNT ON
SELECT
	YEAR([ShipDate]) AS [Year]
	,DATEPART(wk,[ShipDate]) AS [Week]
	,[Panel] AS [Version]
	,'Shipped' AS [Note]
	,SUM(IIF([QtyShipped] < 0, -1*[QtyShipped],[QtyShipped])) AS [Record]	
FROM [PMS1].[dbo].[vPouchShipmentsWithAnnotations_IOID]
WHERE ShipDate > GETDATE()-735
	GROUP BY YEAR([ShipDate]),DATEPART(wk,[ShipDate]),[Panel]
	ORDER BY [Year],[Week]
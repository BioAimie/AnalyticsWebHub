SET NOCOUNT ON

SELECT DISTINCT
	P.[NormalSerial],
	P.[DateOfManufacturing] AS [DateOfManufacturing],
	P.[Version]
FROM [PMS1].[dbo].[bInstrumentProduced] P
INNER JOIN [PMS1].[dbo].[bInstrumentShipment] I ON I.[NormalSerial] = P.[NormalSerial]
WHERE I.[CustId] != 'IDATEC' AND P.[ProdNo] = 1
ORDER BY [DateOfManufacturing]

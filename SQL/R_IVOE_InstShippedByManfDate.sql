SET NOCOUNT ON

SELECT
	MIN(L.[DateOfManufacturing]) AS [DateOfManufacturing],
	I.[Version]
FROM [PMS1].[dbo].[bInstrumentShipment] I
INNER JOIN [PMS1].[dbo].[bInstrumentProduced] L ON L.[NormalSerial] = I.[NormalSerial]
WHERE I.[CustId] != 'IDATEC'
GROUP BY I.[NormalSerial], I.[Version]
ORDER BY [DateOfManufacturing]
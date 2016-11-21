SET NOCOUNT ON

--RMA Serial Numbers
SELECT
	[TicketId],
	[TicketString],
	[CreatedDate],
	[PropertyName],
	UPPER([RecordedValue]) AS [RecordedValue]
INTO #lotSerial
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Part Information' AND [PropertyName] LIKE 'Lot/Serial Number' AND Tracker = 'RMA'
                          
--capture service codes                         
SELECT 
	[TicketId],
	[TicketString],
	[RecordedValue] AS [ServiceCode]
INTO #codes
FROM [PMS1].[dbo].[vTrackers_AllObjectPropertiesByStatus] WITH(NOLOCK)
WHERE [ObjectName] LIKE 'Service Codes' AND [PropertyName] LIKE 'Service Code'  
                          
                          
--find serviced thermoboards based on Service Codes provided by Victor                          
SELECT 
	S.[TicketId],
	S.[TicketString],
	S.[CreatedDate],
	S.[RecordedValue],
	IIF((C.[ServiceCode] IS NOT NULL), 'ThermoService', 'NoService') AS [Note]
INTO #thermoServiced
FROM #lotSerial S LEFT JOIN
(	
	SELECT 
		[TicketId],
		[ServiceCode]	
	FROM #codes 
	WHERE [ServiceCode] LIKE '511' OR ServiceCode = '512' OR ServiceCode = '513'
) C
	ON S.[TicketId] = C.[TicketId]
WHERE [ServiceCode] IS NOT NULL
                          
                          
--find all filmarray serial numbers through MAS in the past year
SELECT 
	UPPER(ST.SerialNo) AS SerialNo,
	ST.WhseDesc,
	ST.WhseID,
	ItemId,
	DistQty,
	ST.TranId,
	ShortDesc,
	CAST(TranDate AS DATE) AS TranDate,
	TranCmnt
INTO #serial
FROM [SQL1-RO].[mas500_app].[dbo].[vdvSerialTransactions] ST LEFT JOIN [SQL1-RO].[RO_mas500_app].[dbo].[timInvtTran] IT
	ON ST.TranID = IT.TranID
WHERE (ItemId LIKE 'FLM_-ASY-0001%' OR ItemId = 'HTFA-ASY-0003') AND (WhseID = 'STOCK' OR WhseID = 'IFSTK' OR WhseID = 'DNGN')
                          
                          
--find the most recent date that an instrument was sent to floor stock for the numerator
SELECT DISTINCT 
	MAX(TranDate) AS toTranDate,
	UPPER(SerialNo) AS SerialNo
INTO #ifstkTO
FROM #serial
WHERE TranId LIKE '%-TO' AND (WhseID = 'IFSTK' OR WhseID = 'DNGN')
GROUP BY SerialNo
ORDER BY SerialNo
                          
--find earliest date an instrument was sent to controlled stock for the denominator
SELECT DISTINCT 
	TranDate AS tiTranDate,
	UPPER(SerialNo) AS SerialNo
INTO #stockTI
FROM #serial
WHERE TranId LIKE '%-TI' AND WhseID = 'STOCK' AND DistQty = 1
GROUP BY SerialNo, TranDate
ORDER BY SerialNo
                          
SELECT DISTINCT 
	TranDate AS shTranDate,
	UPPER(SerialNo) AS SerialNo
INTO #stockSH
FROM #serial
WHERE (TranId LIKE '%-SH' OR TranId LIKE '%-SA' OR TranId LIKE '%-IS')
GROUP BY SerialNo, TranDate
ORDER BY SerialNo
                          
                          
SELECT 
	CASE 
		WHEN MAX(toTranDate) <= MAX(shTranDate) THEN MAX(toTranDate)
		WHEN MAX(toTranDate) >= MIN(shTranDate) THEN MIN(shTranDate)
		ELSE NULL 
	END AS TranDate,
	UPPER(S.SerialNo) AS SerialNo
INTO #ifstkTOSH
FROM #stockSH S INNER JOIN #ifstkTO O
	ON S.SerialNo = O.SerialNo
GROUP BY S.SerialNo
                          
                          
SELECT 
	toTranDate AS TranDate,
	UPPER(O.SerialNo) AS SerialNo
INTO #stockTITO
FROM #stockTI I INNER JOIN #ifstkTO O
	ON I.SerialNo = O.SerialNo
GROUP BY tiTranDate, toTranDate, I.SerialNo, O.SerialNo
HAVING I.tiTranDate >= MAX(O.toTranDate)
                          
                          
                          
SELECT TranDate, SerialNo
,IIF(SerialNo IN ('2FA01909','2FA01910','2FA01911','2FA01912',
'2FA01913','2FA01914','2FA01915','2FA01916','2FA01917','2FA01918','2FA01919',
'2FA01920','2FA01921','2FA01922','2FA01923','2FA00926','2FA00822','2FA00975','2FA01032','2FA01040','2FA01227','2FA01164','2FA01904','2FA01466',
'2FA01359','2FA01834','2FA01814','2FA01825','2FA01804','2FA01828','2FA01831','2FA01907','2FA01908','2FA00749','2FA00792','2FA00847','2FA00913','2FA01028','2FA01045','2FA01182','2FA01189','2FA01214',
'2FA01223','2FA01237','2FA01265','2FA01324','2FA01327','2FA01330','2FA01339','2FA01381','2FA01387','2FA01403','FA01032','FA01040','2FA01423','2FA01486','2FA01499','2FA01511','2FA01519','2FA01530',
'FA5120','FA5127','FA5129','FA5131','FA5132','FA5137','FA5138','FA5139','FA5140','FA5142','FA1379','FA2695','FA3192','FA00926','FA2214','FA00822','FA00975','2FA01534','2FA01556','2FA01558','2FA01576','2FA01583',
'2FA01592','2FA01594','2FA01598','2FA01606','2FA01607','2FA01608','2FA01609','2FA01610','2FA01611','2FA01612',
'2FA01613','2FA01614','2FA01615','2FA01616','2FA01617','2FA01618','2FA01619','2FA01620','2FA01621','2FA01622',
'2FA01623','2FA01624','2FA01625','2FA01626','2FA01627','2FA01628','2FA01629','2FA01630','2FA01631','2FA01632',
'2FA01633','2FA01634','2FA01635','2FA01636','2FA01637','2FA01638','2FA01639','2FA01640','2FA01641','2FA01642',
'2FA01643','2FA01644','2FA01645','2FA01646','2FA01647','2FA01648','2FA01649','2FA01650','2FA01651','2FA01652',
'2FA01653','2FA01654','2FA01655','2FA01656','2FA01657','2FA01658','2FA01660','2FA01661','2FA01662','2FA01663',
'2FA01664','2FA01665','2FA01666','2FA01667','2FA01668','2FA01669','2FA01670','2FA01672','2FA01674','2FA01675',
'2FA01676','2FA01677','2FA01678','2FA01680','2FA01681','2FA01682','2FA01683','2FA01684','2FA01685','2FA01686',
'2FA01687','2FA01688','2FA01689','2FA01690','2FA01691','2FA01692','2FA01699','2FA01700','2FA01703','2FA01704',
'2FA01705','2FA01706','2FA01707','2FA01711','2FA01712','2FA01723','2FA01729','2FA01730','2FA01731','2FA01732',
'2FA01733','2FA01734','2FA01735','2FA01736','2FA01737','2FA01738','2FA01739','2FA01740','2FA01741','2FA01742',
'2FA01743','2FA01744','2FA01745','2FA01746','2FA01747','2FA01749','2FA01750','2FA01751','2FA01752','2FA01753',
'2FA01754','2FA01755','2FA01756','2FA01757','2FA01758','2FA01759','2FA01760','2FA01761','2FA01762','2FA01763',
'2FA01765','2FA01766','2FA01767','2FA01768','2FA01769','2FA01770','2FA01771','2FA01772','2FA01773','2FA01774','2FA01775','2FA01776','2FA01777',
'2FA01778','2FA01779','2FA01780','2FA01781','2FA01782','2FA01783','2FA01784','2FA01785','2FA01786','2FA01787',
'2FA01788','2FA01789','2FA01790','2FA01791','2FA01792','2FA01793','2FA01794','2FA01797','2FA01798','2FA01799','2FA01800',
'2FA01801','2FA01802','2FA01803','2FA01806','2FA01808','2FA01810','2FA01811','2FA01812','2FA01813','2FA01818','2FA01820',
'2FA01821','2FA01822','2FA01823','2FA01826','2FA01827','2FA01829','2FA01830','2FA01832','2FA01833',
'2FA01835','2FA01836','2FA01837','2FA01838','2FA01839','2FA01840','2FA01841','2FA01842','2FA01843','2FA01844','2FA01845','2FA01846','2FA01847','2FA01848','2FA01849','2FA01850','2FA01851','2FA01852',
'2FA01853','2FA01854','2FA01855','2FA01856','2FA01857','2FA01858','2FA01859','2FA01860','2FA01861','2FA01862','2FA01864','2FA01865','2FA01866','2FA01867','2FA01869','2FA01870',
'2FA01871','2FA01872','2FA01873','2FA01874','2FA01875','2FA01876','2FA01877','2FA01878','2FA01879','2FA01880','2FA01881','2FA01882','2FA01883','2FA01884','2FA01885','2FA01886','2FA01887',
'2FA01888','2FA01889','2FA01890','2FA01891','2FA01892','2FA01893','2FA01894','2FA01895','2FA01896','2FA01897','2FA01924','2FA01925','2FA01926','2FA01927','2FA01928','2FA01929','2FA01930','2FA01931',
'2FA01932','2FA01933','2FA01934','2FA01935','2FA01936','2FA01937','2FA01938','2FA01939','2FA01940','2FA01941','2FA01942','2FA01943','2FA01944','FA5109','FA5115','FA5117',
'FA5118'), 'BioFireRework',
IIF (TranDate > '2016-02-19', 'AfterAction', 'BeforeAction')) AS [Key]
INTO #reworkNote
FROM #ifstkTOSH
ORDER BY SerialNo
                          
--master list for Serial Numbers that captures rework info and thermoservice info						  
SELECT DATEPART(yy,TranDate) AS [Year]
,DATEPART(mm,TranDate) AS [Month]
,DATEPART(wk,TranDate) AS [Week]
,R.[Key]
,ISNULL((T.Note),'NoFailure') AS RecordedValue
,COUNT(SerialNo) AS Record
FROM #reworkNote R LEFT JOIN #thermoServiced T
ON R.SerialNo = T.RecordedValue
WHERE TranDate > GETDATE()-400
GROUP BY DATEPART(yy,TranDate),DATEPART(mm,TranDate), DATEPART(wk,TranDate), [Key],[Note]
UNION
SELECT DATEPART(yy,TranDate) AS [Year]
,DATEPART(mm,TranDate) AS [Month]
,DATEPART(wk,TranDate) AS [Week]
,'StockSize' AS [Key]
,'NoFailure' AS RecordedValue
,COUNT(SerialNo) AS Record
FROM #stockTITO
WHERE TranDate > GETDATE()-400
GROUP BY DATEPART(yy,TranDate),DATEPART(mm,TranDate), DATEPART(wk,TranDate)
ORDER BY DATEPART(yy,TranDate),DATEPART(mm,TranDate), DATEPART(wk,TranDate)
                          
DROP TABLE #lotSerial, #codes, #thermoServiced, #serial, #ifstkTO, #stockTI, #stockSH, #reworkNote, #ifstkTOSH, #stockTITO
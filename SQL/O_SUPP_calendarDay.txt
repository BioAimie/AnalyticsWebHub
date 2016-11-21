DECLARE @DateFrom DATETIME, @DateTo DATETIME;
SET @DateFrom = CONVERT(DATETIME, '2007-01-01');
SET @DateTo = GETDATE();
WITH T(date)
AS
(
	SELECT @DateFrom
	UNION ALL
	SELECT DATEADD(day, 1, T.date) FROM T WHERE T.date < @DateTo
)
SELECT 
	YEAR(date) AS [Year],
	MONTH(date) AS [Month],
	DATEPART(ww,date) AS [Week],
	DATEPART(dd,date) AS [Day]
FROM T
GROUP BY YEAR(date), MONTH(date), DATEPART(ww,date), DATEPART(dd,date)
OPTION(MAXRECURSION 32767);

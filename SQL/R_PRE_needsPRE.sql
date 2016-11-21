--open CI that need PRE and time since opened
SET NOCOUNT ON
SELECT CONVERT(CHAR(7),creation_ts, 120) AS CreatedDate,
bug_id,
DATEDIFF(dd,creation_ts,GETDATE()) AS daysSinceCreated,
IIF(assigned_to= '1682' OR assigned_to='1737' OR assigned_to='1730' OR assigned_to='1756' OR assigned_to='1758','CI Team','Other') AS assigned_to
FROM CI...bugs
WHERE bug_status = 'Open'
AND cf_regulatory_review = 'Yes'
AND CONVERT(NVARCHAR(MAX),cf_corrective) = N''
AND bug_id > '13000'
ORDER BY bug_id
--Dana: 1682
--Kimone:1737
--Yarema:1730
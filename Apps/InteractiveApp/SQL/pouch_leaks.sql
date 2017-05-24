

select
	[SerialNumber] as [PouchSerialNumber],  
	isnull([PouchLeak], 0) as [PouchLeak]
from [PouchTracker].[dbo].[PostRunPouchObservations]
/*
side effects:
During the freeze, transactions cannot commit; 
with good testing and engineering, you can bring that freeze period down to a few seconds or so while making the external calls to the storage, 
but if a DB has a response time SLAs measured in milliseconds, it would be severely impacted by such a freeze


While SUSPEND_FOR_SNAPSHOT_BACKUP is enabled, all write IO is suspended on the data files and log file. 
New writing transactions can begin by using memory buffers and the appearance of writes to the tables will proceed using asynchronous buffer writes (all totally normal), 
but COMMIT TRANSACTION commands stall until the suspend is reverted or the metadata backup is performed. For many applications, this may be acceptable or even unnoticeable 
if the duration is only a few seconds and would be comparable to a tlog autogrow event. 

However, extremely sensitive apps which have double-digit millisecond latency requirements or SLAs can notice and be impacted. 

*/
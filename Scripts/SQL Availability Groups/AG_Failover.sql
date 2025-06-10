/*Before failing over an AG (including a Distributed Availability Group),
there are counters that can be monitored to ensure a smooth failover.
Same applies to failing back, since there is a revert process that occurs on the
database once a failover is initiated.  This process may take much longer for a DAG failback.*/

--counter to monitor before a failover (data waiting to be applied):
SELECT *
FROM sys.dm_os_performance_counters
WHERE counter_name IN ('Redo Queue KB','Redo Bytes Remaining','Recovery Queue')   
  

--**********After a failover ***************************************************
/*
When an Availability Group database is in a reverting state, it means the secondary 
replica is catching up with the primary replica.
The reverting process involves "undoing" transactions that were committed on the 
primary replica but not yet applied on the secondary replica. 

*/
 
SELECT [object_name],
[counter_name], [cntr_value], instance_name
FROM sys.dm_os_performance_counters
WHERE [object_name] LIKE '%Database Replica%'
AND [counter_name] = 'Log remaining for undo'

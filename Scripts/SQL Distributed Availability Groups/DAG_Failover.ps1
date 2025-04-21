<#*******************************************************************************
In a distributed availability group, we can do a manual failover.  
Automatic failovers are not supported because the replicas are in different Windows clusters.
In a failover, the DAG becomes unavailable and all connections to the AG of the global primary replica 
are terminated.

In SQL 2022, REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT was introduced to guarantee no data loss in 
the failover.


#>
$AG1=""
$AG2=""
$List1=""
$List2=""
$DAGname=""

To do an emergency failover, allowing data loss:
$Query="ALTER AVAILABILITY GROUP $DAGname FORCE_FAILOVER_ALLOW_DATA_LOSS;"
Invoke-Sqlcmd -ServerInstance $List1 -Query $Query 


#To ensure no data is lost, follow the script below
#verify all replicas in the AG are in sync commit mode:
$query="
SELECT DISTINCT replica_server_name, synchronization_state_desc, failover_mode_desc
FROM sys.dm_hadr_database_replica_states dr inner join sys.availability_replicas ar on ar.replica_id=dr.replica_id
INNER JOIN sys.availability_databases_cluster dc on dc.group_database_id=dr.group_database_id
INNER JOIN sys.dm_hadr_availability_replica_states rs on rs.replica_id=ar.replica_id"
Invoke-Sqlcmd -ServerInstance $List1 -Query $Query 
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query 

#To ensure no data is lost, set the DAG to Synchronous commit
#execute on both the global primary and the forwarder
$Query="ALTER AVAILABILITY GROUP [$DAGname]  
   MODIFY  
   AVAILABILITY GROUP ON    
      '$AG1' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT),  
      '$AG2' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT);    
GO"
Invoke-Sqlcmd -ServerInstance $List1 -Query $Query 
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query 


#verify that the availability group synchronization_state_desc is SYNCHRONIZED
$Query = "SELECT ag.name, drs.database_id AS [Availability Group], db_name(drs.database_id) AS database_name,
       drs.synchronization_state_desc, drs.last_hardened_lsn
FROM sys.dm_hadr_database_replica_states AS drs
     INNER JOIN sys.availability_groups AS ag ON drs.group_id = ag.group_id
WHERE ag.name = `'$DAGname`'"
Invoke-Sqlcmd -ServerInstance $List1 -Query $Query 

#for SQL 2022 (16.x) and later, on the global primary:
$Query="ALTER AVAILABILITY GROUP $DAGname SET (REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT = 1);"
Invoke-Sqlcmd -ServerInstance $List1 -Query $Query 



#wait until the status of the DAG is changed to SYNCHRONIZED on all replicas:
#proceed after last_hardened_lsn is the same per database on both the global primary and the forwarder
$query="SELECT ag.name
         , drs.database_id
         , db_name(drs.database_id) as database_name
         , drs.group_id
         , drs.replica_id
         , drs.synchronization_state_desc
         , drs.last_hardened_lsn  
FROM sys.dm_hadr_database_replica_states drs 
INNER JOIN sys.availability_groups ag on drs.group_id = ag.group_id;"
Invoke-Sqlcmd -ServerInstance $List1 -Query $Query 
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query 


#on the global primary, set the DAG role to SECONDARY
#the DAG will become unavailable
$Query="ALTER AVAILABILITY GROUP [$DAGname] SET (ROLE = SECONDARY);"
Invoke-Sqlcmd -ServerInstance $List1 -Query $Query 

#use SSMS to verify that both AGs in the DAG show the same AG as the primary


#Now, fail over from the global primary by running the following on the FORWARDER to transition the AGs
#and bring the distributed availability group back online
$query="ALTER AVAILABILITY GROUP $DAGname FORCE_FAILOVER_ALLOW_DATA_LOSS;"
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query 

#At this point, the global primary will transition to the forwarder
#the global forwarder will transition to the old primary
#the DAG will become available

#clear requirement to synchronize secondaries to commit, on the new secondary:
#this needs to be done to allow the database to be readable on the original AG
#otherwise there will be errors in the log that cluster has no quorum
$Query="ALTER AVAILABILITY GROUP $DAGname SET (REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT = 0);"
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query 
Invoke-Sqlcmd -ServerInstance $List1 -Query $Query 

#change back to asynchronous commit:
$Query="ALTER AVAILABILITY GROUP $DAGname
	MODIFY AVAILABILITY GROUP ON 
		'$AG1' WITH (AVAILABILITY_MODE=ASYNCHRONOUS_COMMIT),
		'$AG2' WITH (AVAILABILITY_MODE=ASYNCHRONOUS_COMMIT);"
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query 
Invoke-Sqlcmd -ServerInstance $List1 -Query $Query 

#check if there are ny logs remaining for undo:
$Query = "SELECT [object_name],
[counter_name], [cntr_value], instance_name
FROM sys.dm_os_performance_counters
WHERE [object_name] LIKE '%Database Replica%'
AND [counter_name] = 'Log remaining for undo'"
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query 
Invoke-Sqlcmd -ServerInstance $List1 -Query $Query 
$AG1=""
$AG2=""

$List1=""
$List2=""

$DAG=""


<#*******************************************************************************
In a distributed availability group, we can do a manual failover. 
It does not support automatic failovers because the replicas are in different clusters.
It modifies the DAG to become unavailable and all connections to the AG of the global primary replica will be terminated.

In SQL 2022, REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT was introduced to guarantee no data loss in the failover.
#>

#To ensure no data is lost, set the DAG to Synchronous commit, let it synchronize, then failover
#both AGs must have SYNCHRONOUS_COMMIT availability mode in order for the DAG to be in that mode:
$Query="ALTER AVAILABILITY GROUP $DAG
	MODIFY AVAILABILITY GROUP ON 
		'$AG1' WITH (AVAILABILITY_MODE=SYNCHRONOUS_COMMIT),
		'$AG2' WITH (AVAILABILITY_MODE=SYNCHRONOUS_COMMIT);"
Invoke-Sqlcmd -ServerInstance $List1 -Query $Query 

 #verify the commit state of the distributed availability group 
$Query=" select ag.name, ag.is_distributed, ar.replica_server_name, ar.availability_mode_desc, ars.connected_state_desc, ars.role_desc, 
     ars.operational_state_desc, ars.synchronization_health_desc from sys.availability_groups ag  
     join sys.availability_replicas ar on ag.group_id=ar.group_id
     left join sys.dm_hadr_availability_replica_states ars
     on ars.replica_id=ar.replica_id
     where ag.is_distributed=1 "
Invoke-Sqlcmd -ServerInstance $List1 -Query $Query 
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query 

#for SQL 2022 (16.x) and later, on the global primary:
$Query="ALTER AVAILABILITY GROUP $DAG SET (REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT = 1);"
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


#on the global primary, set the DAG role to SECONDARY; the DAG will become unavailable:
$query="ALTER AVAILABILITY GROUP $DAG SET (ROLE = SECONDARY);"
Invoke-Sqlcmd -ServerInstance $List1 -Query $Query 

#Once the last_hardened_lsn is the same per database on both sides
#We can Fail over from the primary availability group to the secondary availability group. 
#Run the following command on the forwarder, the SQL Server instance that hosts the primary replica of the secondary availability group.
$Query="ALTER AVAILABILITY GROUP $DAG FORCE_FAILOVER_ALLOW_DATA_LOSS;"
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query 


#clear requirement to synchronize secondaries to commit:
$Query="ALTER AVAILABILITY GROUP $DAG 
  SET (REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT = 0);"
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query 

#change back to asynchronous commit:
$Query="ALTER AVAILABILITY GROUP $DAG
	MODIFY AVAILABILITY GROUP ON 
		'$AG1' WITH (AVAILABILITY_MODE=SYNCHRONOUS_COMMIT),
		'$AG2' WITH (AVAILABILITY_MODE=SYNCHRONOUS_COMMIT);"
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query 


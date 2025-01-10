--this command will stop then restart the endpoint:
ALTER ENDPOINT Hadr_endpoint STATE=STARTED

--to stop database from syncing: (this alone will not clear log on primary)
ALTER  DATABASE Docusign SET HADR OFF

--to clear log on primary, remove replica or the database from the AG
ALTER AVAILABILITY GROUP [AGName] REMOVE REPLICA on 'ServerName';


--add database back:
ALTER  DATABASE Docusign SET HADR AVAILABILITY GROUP = AGDSNA2P01
ALTER  DATABASE Docusign SET HADR RESUME


--if we have a bad replica that is either offline or can't keep up
--remove the bad replica, then resume HADR if databases are not synchronizing
ALTER AVAILABILITY GROUP AGDSNA2P01 REMOVE REPLICA ON  'cusqldsna2s5p01'
--add it back:
ALTER AVAILABILITY GROUP AGDSNA2P01 ADD REPLICA ON 'cusqldsna2s5p01' WITH 
	(ENDPOINT_URL = 'TCP://cusqldsna2s5p01.CORP.DOCUSIGN.NET:5022', FAILOVER_MODE = MANUAL, AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, 
	SEEDING_MODE=MANUAL, SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL));
--from the added node:
ALTER AVAILABILITY GROUP AGDSNA4P01 JOIN; 
--redo grants to create databases if in auto seeding mode:
ALTER AVAILABILITY GROUP AGDSNA4P01 GRANT CREATE ANY DATABASE;;


--see if secondary replicas are ready for a failover:
select * from sys.dm_hadr_database_replica_cluster_states
--for asynchronous commit, the state will never be "synchronized" and is_failover_ready will always be 0

--check health of replicas
select synchronization_health_desc,* from sys.dm_hadr_availability_replica_states

--connect to primary and check last_hardened_lsn for all replicas and if they are the same, it's safe to do a planned/test failover
select last_received_lsn, synchronization_state_desc, synchronization_health_desc, * from sys.dm_hadr_database_replica_states;


--to manually force failover an availability group to the replica I am currently connected to: all cluster nodes must be synchronized
--otherwise, I can force failover with data loss only
--to temporarily change the availability mode to synchronous commit:
ALTER AVAILABILITY GROUP AG_Datamart MODIFY REPLICA ON N'servername' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT);
ALTER AVAILABILITY GROUP AG_Datamart FAILOVER; 

--for asynchronous commit mode, this is the only type of failover supported
--the failover target will transition to the primary role and the remaining secondary databases, along with the former primary database, will be suspended
--until I manually resume them individually
ALTER AVAILABILITY GROUP AG_Datamart FORCE_FAILOVER_ALLOW_DATA_LOSS;     

--after forced failover, resume secondary replicas (connect to secondary cluster nodes first)
ALTER DATABASE Datamart SET HADR RESUME;
ALTER DATABASE APP_ADMIN SET HADR RESUME;



/**Error:  Database is stuck in “Initializing / In Recovery” and it is the primary replica of a 
secondary AG of a DAG
Solution:  Restart the VM ->  database will go into Restoring mode -> restore t-logs ->add database 
back to AG
*/


--***to remove a database from a DAG temporarily and add it back later:
--on the secondary replicas of the secondary AG:
ALTER DATABASE Docusign SET HADR OFF;
--repeat on the forwarder:
ALTER DATABASE Docusign SET HADR OFF;

--databases will go into restoring mode



/**
--if we have 2 DAGs that connect databases in a linear fashion and want to restructure the DAG,
--set HADR OFF first to prevent the 3rd linear AG from breaking from the 1st AG and staying in synchronized mode
--execute on all secondary AG replicas (2nd AG & 3rd AG replicas)
ALTER DATABASE Docusign SET HADR OFF;

--tear down DAG that we no longer want:
DROP AVAILABILITY GROUP [DAGname]

--create new DAG, then join the second AG to the DAG
--now, add databases back:
ALTER  DATABASE $db1 SET HADR AVAILABILITY GROUP = $AG3



--if adding a database to the third AG (second DAG) fails with this:
Error:  The connection to the primary replica is not active.  The command cannot be processed.
Fix:  
1.  check if the database is in the AG, with a yellow warning triangle, t-sql will not work to get rid of it, 
	use the UI...it will throw an error but the database will be removed
2.  check if DAG exists on both AGs...it may not exist on the primary (drop then recreate)
	there may be an error related to a firewall issue when establishing a connection
	wait for a minute or 2 and it should go away


**/


--view replica details:
select rs.synchronization_health_desc, replica_server_name, database_name, role_desc, synchronization_state_desc, availability_mode_desc, failover_mode_desc,* 
from sys.dm_hadr_database_replica_states dr inner join sys.availability_replicas ar on ar.replica_id=dr.replica_id
inner join sys.availability_databases_cluster dc on dc.group_database_id=dr.group_database_id
inner join sys.dm_hadr_availability_replica_states rs on rs.replica_id=ar.replica_id


select replica_server_name, database_name, rs.synchronization_health_desc, log_send_queue_size, last_redone_time 
from sys.dm_hadr_database_replica_states dr inner join sys.availability_replicas ar on ar.replica_id=dr.replica_id
inner join sys.availability_databases_cluster dc on dc.group_database_id=dr.group_database_id
inner join sys.dm_hadr_availability_replica_states rs on rs.replica_id=ar.replica_id where log_send_queue_size IS NOT NULL;


--view seeding status:
SELECT r.session_id, r.status, r.command, r.wait_type,  r.percent_complete, r.estimated_completion_time
	FROM sys.dm_exec_requests r JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
	WHERE r.session_id <> @@SPID AND s.is_user_process = 0 AND r.command like 'VDI%' and wait_type ='BACKUPTHREAD'


SELECT local_database_name, remote_machine_name,role_desc ,internal_state_desc,transfer_rate_bytes_per_second/1024/1024 
	as transfer_rate_MB_per_second ,transferred_size_bytes/1024/1024 as transferred_size_MB,transferred_size_bytes/1024/1024/1024 as transferred_size_GB
	,database_size_bytes/1024/1024/1024 as Database_Size_GB,
	is_compression_enabled     from sys.dm_hadr_physical_seeding_stats



/***
--*******************permissions error*******************************************************************
Error:  A connection timeout has occurred while attempting to establish a connection to availability replica 'xxx' with 
id [xxx]. Either a networking or firewall issue exists, or the endpoint address provided for 
the replica is not the database mirroring endpoint of the host server instance.
Fix:  GRANT CONNECT ON ENDPOINT:Hadr_Endpoint TO [SERVICEACCOUNT]


--*******************synchronous commit mode*******************************************************************
Error:  Always On Availability Groups data movement for database 'DocuSign' has been suspended for the following reason: "system" 
(Source ID 4; Source string: 'SUSPEND_FROM_APPLY'). To resume data movement on the database, you will need to resume the database manually. 
For information about how to resume an availability database, see SQL Server Books Online.
This occurred because we ran out of space on the log disk.

Repair:
ALTER DATABASE Docusign SET HADR RESUME;


Error:  Database is in Not Synchronizing status
Repair:
ALTER DATABASE Docusign SET HADR RESUME;


Error:  Database is stuck in “Initializing / In Recovery” and it is the rp

--with manual failover, asynchronous commit mode: 
if 1 of the servers with secondary replica goes down:  once server comes back, replica starts synchronizing automatically
if server with primary replica goes down:  once server comes back, replicas start synchronizing (failover does not occur)
if primary & secondary replicas go down & only 1 secondary replica remains:  it can still be accessed with synchronization state=not healthy
	and synchronization state=not synchronizing; when other replicas come back online:  everything returns to normal
if synchronization state='not synchronizing', the database will still be accessible by users but HADR has to be manually resumed
if a server stops synchronizing and the database has to be manually set to resume HADR, then the database will have to go through recovery which should take just a few seconds
DO NOT remove the database from the high availability group unless absolutely necessary



--*********Troubleshooting********************************************************************
Error after deleting the AG & trying to recreate:  Failed to create the Windows Server Failover Clustering (WSFC) group with name 'A1CMSDBC6DAG'.  The WSFC 
group with the specified name already exists.  Retry the operation with a group name that is unique in the cluster.

Fix:  
1.  Delete the registry key “HKEY_LOCAL_MACHINE\Cluster \HadrAgNameToldMap” from all nodes participating in cluster
2.  Turn off the Always On Availability Feature in SQL Server Configuration Manager
3.  Reboot server
4.  Check the registry and if the key is back, delete it
5.  Open the Server Manager then the Failover Cluster Manager and check if the AG exists under the Roles node.  If yes, remove it.
6.  Reboot server
7.  Turn the the Always On Availability Feature in SQL Server Configuration Manager back on and try again.




Error:  Msg 35220, Level 16, State 1, Line 124
Could not process the operation. Always On Availability Groups replica manager is waiting for the host computer to start a Windows Server Failover Clustering (WSFC) 
cluster and join it. Either the local computer is not a cluster node, or the local cluster node is not online. If the computer is a cluster node, wait for it 
to join the cluster. If the computer is not a cluster node, add the computer to a WSFC cluster. Then, retry the operation.
Fix:  Open Failover Cluster Manager on one of the replicas and if cluster is offline, bring it online.  Then restart SQL services on primary node.


Error:  Need to remove a database from an AG but get an error Msg 35281, Level 16, State 0, Line 23
Database 'CMS_DM_Staging' cannot be removed from availability group 'A1CMSDBC3SAG'.  The database is not joined to the specified availability group.
Upon checking the Availability Databases in the Availability Groups node, I don't see the database there and I already dropped it on the secondaries.
Also, in the error log, I see repeated messages of the database being set to SINGLE_USER mode then to MULTI_USER mode.
Fix:  Fail over to a secondary node and the database will go into a restoring mode and then can be dropped.  
If a failover cannot be performed in case the AG is single node, just restart SQL services.



Error:  I added a file to the database and the path did not exist on secondary, database became "Not Synchronizing/Corrupt" on secondary
Fix:
--on primary:
ALTER AVAILABILITY GROUP [AG_Datamart] REMOVE REPLICA on 'dr-biodswin01';
--Create the path on secondary and then Add database back to the AG from the primary replica:
ALTER AVAILABILITY GROUP [AG_Datamart] ADD REPLICA ON 'dr-biodswin01' WITH 
(ENDPOINT_URL = 'TCP://dr-biodswin01.centene.com:5022', FAILOVER_MODE = MANUAL, AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, 
SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL));
--Now, it's showing as "Restoring.."; from the secondary, add the database to the High Availability Gorup:
ALTER AVAILABILITY GROUP [AG_Datamart] JOIN;
GO
ALTER DATABASE Datamart SET HADR AVAILABILITY GROUP=AG_Datamart;
GO
ALTER DATABASE Datamart SET HADR RESUME;

Note:  If I cannot add the path on a secondary for some reason, then I have no choice but remove that file from the primary replica & remove the secondary from the availability
group and then take backups and do a restore to add it back

Issue:  Secondary replica shows that the database is in Restricted User mode but the primary replica is not.
Fix:	Secondary is probably still applying logs from the primary and has not reached the point of allowing user access into the database.  If I restart
		SQL Services, the database will become unhealthy until all logs are applied and all checks are completed.  Check Error Log for % complete.


Error:  A connection timeout has occurred while attempting to establish a connection to availability replica 'P-BIODSWIN01' with id [282A0E54-2519-4603-B680-4F8791142051]. 
		Either a networking or firewall issue exists, or the endpoint address provided for the replica is not the database mirroring endpoint of the host server instance.
Fix:  Reboot server that is throwing these errors.  
	Occurred on 5/18/17 on dr-biodswin01 and reboot fixed the issue.  All availability replicas became healthy again.



Error:  Always On Availability Groups transport has detected a missing log block for availability database 
Fix:  The log fill most likely get fixed on its own.  If not, try removing the database from the availability group and have it auto reseed from the primary.


Error:  Transaction log is full, drive is full.  This can happen if transaction log backups failed.  If space is identical on all replicas, I can take transaction log
backup, then shrink the log file,  and database will go back to normal.  However, if a secondary replica has less space on drive, I will not be able to fix the issue 
just by taking a backup.  Since the log already got extended on the primary, it needs to be replicated to the secondary in the exact same way.  Until there is enough 
space on the log drive on replica, db on there will be unhealthy and not synchronizing.
Fix Option 1: Add space to the drive.  If database is in suspect mode on a read replica, run below
statement to resume HADR.
ALTER DATABASE CMS_PreProd_App SET HADR RESUME;

Fix Option 2:  Add a new log file to the database on a different drive.

Fix Option 3:  Move database transaction log to bigger drive.  To do this, remove secondary database from the group and add it back once all files are in the right new locations.
Esure that the log backups are disabled on all replicas so that the log file remains intact (not truncated), otherwise will need to perform a full backup and log backup
and apply that to the secondary to re-initialize replica.
	EXEC [p-biodswin02].msdb.dbo.sp_update_job  
		@job_name = N'Backup_Datamart_Log',  
		@enabled = 0 ;  
	GO 
	EXEC [dr-biodswin01].msdb.dbo.sp_update_job  
		@job_name = N'Backup_Datamart_Log',  
		@enabled = 0 ;  
	GO 
	--From primary, remove secondary replica from group:
	ALTER DATABASE Test_Cluster SET HADR OFF;
	ALTER AVAILABILITY GROUP [AG_Test] REMOVE REPLICA on 'p-biodswin02';
	--move files to the desired location
	ALTER AVAILABILITY GROUP [AG_Test] ADD REPLICA ON 'P-BIODSWIN02' WITH 
		(ENDPOINT_URL = 'TCP://P-BIODSWIN02.centene.com:5022', FAILOVER_MODE = MANUAL, AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, 
		SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL));
	--from secondary:
	ALTER AVAILABILITY GROUP [AG_Test] JOIN;
	GO
	ALTER DATABASE Test_Cluster SET HADR AVAILABILITY GROUP=AG_Test;
	GO
	ALTER DATABASE Test_Cluster SET HADR RESUME;


Error:  Database won't start synchronizing after SQL Server engine cycling with suspend reason:  SUSPEND_FROM_RESTART
Issue:  Secondary database is stuck in 'Not Synchronizing/In Recovery'
Details:  Error log shows 0% recovery completed repeatedly
		  Stopping SQL services is not working
		  Can't delete database because there is a snapshot which won't delete either, a background SQL process is running recovery on the HA database.
Fix:  issue the stmt to resume HADR then wait a few minutes for the database to recover (will see % of recovery process in the error log)
ALTER DATABASE [know-CenterProfiles] SET HADR RESUME;


Error:  Always On Availability Groups data movement for database 'SSISDB' has been suspended for the following reason: "system" (Source ID 2; Source string: 
'SUSPEND_FROM_REDO'). To resume data movement on the database, you will need to resume the database 
manually. 
Fix:  issue the stmt to resume HADR, should resume immediately...there will be a message in the error log that some # of transactions rolled forward in the database
ALTER DATABASE [know-CenterProfiles] SET HADR RESUME;


*/
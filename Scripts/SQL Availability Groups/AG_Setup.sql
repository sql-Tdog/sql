/*introduced in 2012 Enterprise Edition, became available in Standard Edition SQL2016  
--create a Windows Failover Cluster (WSFC) first

--see if AlwaysOn is enabled and connected to a windows failover cluster :
select * from sys.dm_hadr_cluster

--view cluster nodes:
select * from sys.dm_hadr_cluster_members

--view existing endpoints and their owners:
SELECT  SUSER_NAME(principal_id) AS endpoint_owner, name AS endpoint_name, state_desc
FROM sys.database_mirroring_endpoints;


--create endpoint:
CREATE ENDPOINT [Hadr_endpoint] AUTHORIZATION [CORP\OneCMSAGsrv] AS TCP (LISTENER_PORT = 5022)
       FOR DATA_MIRRORING (ROLE = ALL, ENCRYPTION = REQUIRED ALGORITHM AES)

GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [TKAD\gmSQAZAGTK$]  
GRANT ALTER ANY AVAILABILITY GROUP TO [TKAD\gmSQAZAGTK$];
GRANT CONNECT SQL TO [TKAD\gmSQAZAGTK$];
GRANT VIEW SERVER STATE TO [TKAD\gmSQAZAGTK$];
GO
ALTER AUTHORIZATION ON ENDPOINT::Hadr_endpoint TO [TKAD\gmSQAZAGTK$];
GO


--check owner of Availability Group:
SELECT ar.replica_server_name,ag.name AS ag_name,ar.owner_sid,sp.name
FROM sys.availability_replicas ar LEFT JOIN sys.server_principals sp ON sp.sid = ar.owner_sid 
INNER JOIN sys.availability_groups ag ON ag.group_id = ar.group_id;

ALTER AUTHORIZATION ON AVAILABILITY GROUP::TESTAG to [sa] ;

--view AG settings such as session_timeout (in seconds):
select ag.name, arcn.replica_server_name, arcn.node_name, ars.role, ars.role_desc, 
ars.connected_state_desc, ars.synchronization_health_desc, ar.availability_mode_desc,
ag.failure_condition_level,ar.failover_mode_desc, ar.session_timeout
from sys.availability_replicas ar with (nolock)
inner join sys.dm_hadr_availability_replica_states ars with (nolock) on ars.replica_id=ar.replica_id and ars.group_id=ar.group_id
inner join sys.availability_groups ag with (nolock) on ag.group_id=ar.group_id
inner join sys.dm_hadr_availability_replica_cluster_nodes arcn with (nolock) on arcn.group_name=ag.name and arcn.replica_server_name=ar.replica_server_name


--*****************SET UP AlwaysOn Availability Group for a database ******************************************
--set up AlwaysOn Availability Group; run this on the primary replica where database is not in restoring mode:
USE [master]
GO
CREATE AVAILABILITY GROUP [AG_Test]
WITH (AUTOMATED_BACKUP_PREFERENCE = SECONDARY)
FOR DATABASE [Test_Cluster]
REPLICA ON N'P-BIODSWIN01' WITH (ENDPOINT_URL = N'TCP://P-BIODSWIN01.centene.com:5022', FAILOVER_MODE = MANUAL, AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT, 
	BACKUP_PRIORITY = 50, SEEDING_MODE = AUTOMATIC, SECONDARY_ROLE(ALLOW_CONNECTIONS = NO)),
	N'P-BIODSWIN02' WITH (ENDPOINT_URL = N'TCP://P-BIODSWIN02.centene.com:5022', FAILOVER_MODE = MANUAL, AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT, 
	BACKUP_PRIORITY = 50, SEEDING_MODE = AUTOMATIC, SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL));


--important permissions:  run on all replicas
ALTER AUTHORIZATION ON AVAILABILITY GROUP::AZAGtkintgrp TO [TKAD\gmSQAZAGTK$];
GO
ALTER AVAILABILITY GROUP AZAGtkintgrp GRANT CREATE ANY DATABASE;


--***************listener for synchronous commit mode*********************************************************
--create a listener resource with a static IP address
ALTER AVAILABILITY GROUP [A1CMSDBC1LAG]	ADD LISTENER N'P1BNGIMC1QAG' 
	(WITH IP((N'10.4.19.63', N'255.255.255.0')), PORT=1433);

ALTER AVAILABILITY GROUP AG_Datamart MODIFY REPLICA ON N'biodswin02' WITH (SEEDING_MODE = AUTOMATIC);

--make sure database is in FULL recovery mode:
SELECT name, recovery_model_desc FROM sys.databases where database_id=db_id('Datamart');

--*****************if in manual seeding mode**********************************************
--take a full backup and a log backup of database on primary replica:
BACKUP DATABASE Test_Cluster TO DISK = 'L:\Test_Cluster.bak';
GO
BACKUP LOG Test_Cluster TO DISK ='L:\Test_Cluster.trn';
GO

--connect to secondary replicas and restore backups with no recovery option, then join to the AG group:
RESTORE DATABASE [Datamart]  FROM  DISK = '\\p-biodswin02\Datamart\Datamart_20200217_1.bak', DISK = '\\p-biodswin02\Datamart\Datamart_20200217_2.bak',
	DISK = '\\p-biodswin02\Datamart\Datamart_20200217_3.bak',DISK = '\\p-biodswin02\Datamart\Datamart_20200217_4.bak',
	DISK = '\\p-biodswin02\Datamart\Datamart_20200217_5.bak',DISK = '\\p-biodswin02\Datamart\Datamart_20200217_6.bak',
	DISK = '\\p-biodswin02\Datamart\Datamart_20200217_7.bak',DISK = '\\p-biodswin02\Datamart\Datamart_20200217_8.bak'
 WITH REPLACE, NORECOVERY;
RESTORE DATABASE [Datamart]  FROM  DISK = '\\p-biodswin02\Datamart\Datamart_2020021712.trn' WITH NORECOVERY;
GO
RESTORE DATABASE [Datamart]  FROM  DISK = '\\p-biodswin02\Datamart\Datamart_2020021713.trn' WITH NORECOVERY;
GO

--***************************************************



--To just add the database on secondary replica to the Availability Group, connect to primary and Add:
--(this will allow all connections but the database will remain in read-only mode on the secondary replica)
USE [master]
GO
ALTER AVAILABILITY GROUP [AG_Datamart] ADD REPLICA ON 'DR-BIODSWIN01' WITH 
	(ENDPOINT_URL = 'TCP://DR-BIODSWIN01.centene.com:5022', FAILOVER_MODE = MANUAL, AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, 
	SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL));

--connect to secondary replica and join:
ALTER AVAILABILITY GROUP [AG_Datamart] JOIN;  --if already joined, this will throw an error
ALTER DATABASE Datamart SET HADR AVAILABILITY GROUP=AG_Datamart;

--synchronization_state_desc will show INITIALIZING on this replica (NOT-HEALTHY if viewing from another replica)
--it will change to SYNCHRONIZING once CHECKDB completes on this replica

--If I get this error:  Msg 1412, Level 16, State 211, Line 49  The remote copy of database "Datamart" has not been rolled 
forward to a point in time that is encompassed in the local copy of the database log.
A new transaction log has been taken on primary or other secondary and has not been applied to the replica I am trying to join to the cluster.


--to REMOVE a primary database from an availability group:
ALTER AVAILABILITY GROUP PDX1CMSDBCSAG REMOVE DATABASE CMS_S1_App;

ALTER AVAILABILITY GROUP [AG_Datamart] REMOVE REPLICA on 'dr-biodswin01';


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
ALTER AVAILABILITY GROUP AG_Datamart MODIFY REPLICA ON N'p-biodswin02' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT);
ALTER AVAILABILITY GROUP AG_Datamart FAILOVER; 

--for asynchronous commit mode, this is the only type of failover supported
--the failover target will transition to the primary role and the remaining secondary databases, along with the former primary database, will be suspended
--until I manually resume them individually
ALTER AVAILABILITY GROUP AG_Datamart FORCE_FAILOVER_ALLOW_DATA_LOSS;     

--after forced failover, resume secondary replicas (connect to secondary cluster nodes first)
ALTER DATABASE Datamart SET HADR RESUME;
ALTER DATABASE APP_ADMIN SET HADR RESUME;


--to remove a secondary database from an availability group (this works for DAGs too)
ALTER DATABASE Datamart SET HADR OFF;

--after catching up restoring t-logs, put the database back in the DAG's secondary AG:
ALTER DATABASE Datamart SET HADR AVAILABILITY GROUP = AG2;"


--add database to the AG:
ALTER AVAILABILITY GROUP AG_Datamart ADD DATABASE dbbb;

--to verify whether the listeners are online (should be 1 listener for each database HA group, port 5022):
SELECT * FROM sys.dm_tcp_listener_states;

*/
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
Fix:  Fail over to a secondary node and the database will go into a restoring mode and then can be dropped.  If a failover cannot be performed in case the AG is 
single node, just restart SQL services.



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

Fix Option 2:  Move database transaction log to bigger drive.  To do this, remove secondary database from the group and add it back once all files are in the right new locations.
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
'SUSPEND_FROM_REDO'). To resume data movement on the database, you will need to resume the database manually. For information about how to resume an
availability database, see SQL Server Books Online.
Fix:  issue the stmt to resume HADR, should resume immediately...there will be a message in the error log that some # of transactions rolled forward in the database
ALTER DATABASE [know-CenterProfiles] SET HADR RESUME;



ALTER DATABASE SSISDB SET HADR RESUME;


--in case of very slow send speed and the send queue building up, restart the endpoint:
ALTER ENDPOINT Mirroring STATE=STOPPED
go
ALTER ENDPOINT Mirroring STATE=STARTED


--***********************************************************
--to force failover without data loss, connect to the target replica, & change the mode to synchronous commit:
ALTER AVAILABILITY GROUP AG_APP_ADMIN MODIFY REPLICA ON 'erxdwssas1500' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT);
--now, the health of the replica should say NOT_HEALTHY, NOT SYNCHRONIZING; resume HADR manually:
ALTER DATABASE APP_ADMIN SET HADR RESUME;
--now connect to the primary and set its availability mode to SYNCHRONOUS as well:
ALTER AVAILABILITY GROUP AG_APP_ADMIN MODIFY REPLICA ON 'erxrxprsm1002' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT);
--now, we can do the failover (connect to the target primary):
ALTER AVAILABILITY GROUP AG_APP_ADMIN FAILOVER; 
--this works perfectly when I fail over to the Windows server, but when trying to fail over back to the Linux server, I get an error:
Cannot failover an availability replica for availability group 'AG_APP_ADMIN' since it has CLUSTER_TYPE = NONE. Only force failover is supported in this version of SQL Server.
--so the only option is to force failover with data loss, but will make both replicas think they are primary



*/
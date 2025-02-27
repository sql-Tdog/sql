/*
*********To Move Data Files with Minimum Downtime for Async Nodes*************************
For alwaysON HADR, we can only issue ALTER DATABASE commands without breaking HADR since 
the database is in mirror/sync mode
Detach/attach wil not work and backup/restore requires breaking from the HADR
*/

--Execute in ***SQLCMD Mode**** so that I can connect to execute from different replicas seamlessly

--idetify last full/transaction log backup across all replicas:
:CONNECT biodswin01
select TOP 3 name 'database_name', backup_finish_date 'last_backup_date', [type], backup_size, backup_size/compressed_backup_size'compression_ratio'
	, physical_device_name
FROM sys.databases d
OUTER APPLY (SELECT TOP 1 database_name, server_name, backup_finish_date, [type], backup_size, media_set_id,compressed_backup_size FROM msdb.dbo.backupset 
	WHERE database_name=d.name  ORDER BY backup_finish_date DESC) B
LEFT JOIN msdb.dbo.backupmediafamily AS F ON F.media_set_id = B.media_set_id WHERE name='Datamart' ORDER BY last_backup_date DESC
GO
:CONNECT biodswin02
select TOP 3 name 'database_name', backup_finish_date 'last_backup_date', [type], backup_size, backup_size/compressed_backup_size'compression_ratio'
	, physical_device_name
FROM sys.databases d
OUTER APPLY (SELECT TOP 1 database_name, server_name, backup_finish_date, [type], backup_size, media_set_id,compressed_backup_size FROM msdb.dbo.backupset 
	WHERE database_name=d.name ORDER BY backup_finish_date DESC) B
LEFT JOIN msdb.dbo.backupmediafamily AS F ON F.media_set_id = B.media_set_id WHERE name='Datamart' ORDER BY last_backup_date DESC
GO
:CONNECT biodswin01
select TOP 3 name 'database_name', backup_finish_date 'last_backup_date', [type], backup_size, backup_size/compressed_backup_size'compression_ratio'
	, physical_device_name
FROM sys.databases d
OUTER APPLY (SELECT TOP 3 database_name, server_name, backup_finish_date, [type], backup_size, media_set_id,compressed_backup_size FROM msdb.dbo.backupset 
	WHERE database_name=d.name ORDER BY backup_finish_date DESC) B
LEFT JOIN msdb.dbo.backupmediafamily AS F ON F.media_set_id = B.media_set_id WHERE name='Datamart' ORDER BY last_backup_date DESC
GO

--Since we are going to be stopping SQL Services, stop all backups
--We should not break the backup chain else the restoration will not be possible

:CONNECT biodswin01
SELECT * FROM msdb.dbo.sysjobs where name='Backup_Datamart_Log';
UPDATE msdb.dbo.sysjobs SET enabled=0 where name='Backup_Datamart_Log';
GO
:CONNECT biodswin02
SELECT * FROM msdb.dbo.sysjobs where name='Backup_Datamart_Log';
UPDATE msdb.dbo.sysjobs SET enabled=0 where name='Backup_Datamart_Log';
GO



--check health:
select replica_server_name, database_name, rs.synchronization_health_desc, log_send_queue_size, last_redone_time 
from sys.dm_hadr_database_replica_states dr inner join sys.availability_replicas ar on ar.replica_id=dr.replica_id
inner join sys.availability_databases_cluster dc on dc.group_database_id=dr.group_database_id
inner join sys.dm_hadr_availability_replica_states rs on rs.replica_id=ar.replica_id where log_send_queue_size IS NOT NULL;

/*
DBCC SQLPERF(logspace)
--note where the current files are:
:CONNECT p-biodswin01
SELECT db_name(a.database_id), a.name, a.physical_name, size/128.0 AS CurrentSizeMB
FROM sys.master_files a JOIN sys.databases b on a.database_id=b.database_id WHERE db_name(a.database_id)='Datamart';
:CONNECT p-biodswin02
SELECT db_name(a.database_id), a.name, a.physical_name, size/128.0 AS CurrentSizeMB
FROM sys.master_files a JOIN sys.databases b on a.database_id=b.database_id WHERE db_name(a.database_id)='Datamart';
:CONNECT dr-biodswin01
SELECT db_name(a.database_id), a.name, a.physical_name, size/128.0 AS CurrentSizeMB
FROM sys.master_files a JOIN sys.databases b on a.database_id=b.database_id WHERE db_name(a.database_id)='Datamart';

--for async replicas:
--on primary node, disallow connections and stop data movement to all secondary databases to catch up
:CONNECT p-biodswin01
USE master
GO
ALTER AVAILABILITY GROUP [AG_Datamart] MODIFY REPLICA ON 'P-BIODSWIN02' WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = NO));
GO
ALTER AVAILABILITY GROUP [AG_Datamart] MODIFY REPLICA ON 'DR-BIODSWIN01' WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = NO));
GO
ALTER DATABASE Datamart SET HADR suspend;
GO

--now, the database status will be in Not Synchronizing state on all nodes

--on secondary, modify the location of the data file 
:CONNECT dr-biodswin01
USE master
GO
ALTER DATABASE Datamart MODIFY FILE (NAME='DW_PBM_log', FILENAME = N'V:\SQLlogs\DW_PBM_log.ldf');

--in PowerShell on this secondary replica, open SQLCMD and stop services, then move files, the start services
NET STOP sqlserveragent
NET STOP mssqlserver
move "U:\SQLlogs\Datamart.ldf" V:\SQLlogs\
NET START mssqlserver
NET START sqlserveragent


--at this point, database log movement can be resumed from the primary
:CONNECT p-biodswin01
USE master
GO
ALTER DATABASE Datamart SET HADR resume;
GO

--failover back to original node if needed:
ALTER AVAILABILITY GROUP AG_Test FAILOVER;

--enable read-only access on secondary replicas, from primary node
:CONNECT p-biodswin01
USE master
GO
ALTER AVAILABILITY GROUP [AG_Datamart] MODIFY REPLICA ON 'P-BIODSWIN02' WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL));
GO
ALTER AVAILABILITY GROUP [AG_Datamart] MODIFY REPLICA ON 'DR-BIODSWIN01' WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL));

--enable log backups
:CONNECT dr-biodswin01
UPDATE msdb.dbo.sysjobs SET enabled=1 where name='Backup_Datamart_Log';
SELECT * FROM msdb.dbo.sysjobs where name='Backup_Datamart_Log';
GO
:CONNECT p-biodswin02
UPDATE msdb.dbo.sysjobs SET enabled=1 where name='Backup_Datamart_Log';
SELECT * FROM msdb.dbo.sysjobs where name='Backup_Datamart_Log';






*/
--set default for database backups compression:
EXEC sp_configure 'backup compression default', 1 ;
RECONFIGURE WITH OVERRIDE ;

SELECT value FROM sys.configurations WHERE name = 'backup compression default' ;


--take a back up of the tail of the transaction log, leave the database in the restoring state:
--this is useful when failing over to a secondary database or when saving the tail of the log before a RESTORE operation
USE MASTER
GO
BACKUP LOG FilegroupFull TO DISK = N'C:\Temp\backup.trn' 
WITH NORECOVERY, NO_TRUNCATE;

BACKUP LOG EPO_SOURCE TO DISK = N'K:\EPOTemp_SOURCE\Temp.trn' WITH CONTINUE_AFTER_ERROR; 


 
--backup database and password protect backup file:
BACKUP DATABASE DB_NAME TO DISK='C:\Temp.BAK' WITH MEDIAPASSWORD='password123'

--backup a secondary filegroup by itself:
----In SIMPLE recovery all read-write filegroups must be included in a backup
BACKUP DATABASE Sales FILEGROUP='ColdStorageFG' TO DISK='C:\SQL Backups\ColdData.bak'


--database snapshot (before deployment, to speed up recovery in case the need arises):
CREATE DATABASE gpas_beforedeploy ON (NAME=gpas, FILENAME='G:/db_files/gpas.mdf')
AS SNAPSHOT OF gpas;
GO

--backup with backup encryption:
BACKUP DATABASE [dbname] TO DISK = '\\server\share\database.bak'
	WITH COMPRESSION, 	maxtransfersize=4194304, blocksize=65536, buffercount=200, 
	ENCRYPTION (ALGORITHM = AES_256, SERVER CERTIFICATE = BackupCert);


/***********SNAPSHOT BACKUP*******************************************************************************************************************
https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/create-a-transact-sql-snapshot-backup?view=sql-server-ver16
--can be done for one database or a set of databases with one command
1.  suspend backup  (will BLOCK inserts/updates, reads will be allowed)
2.  Use Powershell to initiate and perform the actual snapshot backup of the disk
3.  backup database


--limitations:
cannot be done on a database that is already participating in an Availability Group
*/
--for single database:
ALTER DATABASE DB1 SET SUSPEND_FOR_SNAPSHOT_BACKUP = ON;

--By default suspend for snapshot backup commands will clear the differential bitmap. 
--use the COPY_ONLY keyword to perform a copy only backup:
ALTER DATABASE DB1 SET SUSPEND_FOR_SNAPSHOT_BACKUP = ON (MODE = COPY_ONLY)

--AZ SNAPSHOT CREATE (AZURE SQL VMS); execute powershell command
EXEC xp_cmdshell 'C:\SQL\getsnapshot.cmd', no_output;

BACKUP DATABASE DB1 TO DISK = 'D:\SQL\DB.bkm' WITH METADATA_ONLY;
--this will immediately remove locks on the user database
--if this command fails, manually thaw database:
ALTER DATABASE DB1 SET SUSPEND_FOR_SNAPSHOT_BACKUP = OFF;


--for multiple databases:
ALTER SERVER CONFIGURATION SET SUSPEND_FOR_SNAPSHOT_BACKUP = ON (GROUP=(DB1,DB2,DB3));

--AZ SNAPSHOT CREATE (AZURE SQL VMS)

BACKUP GROUP DB1, DB2, DB3 TO DISK = 'D:\SQL\DB.bkm' WITH METADATA_ONLY, FORMAT;

BACKUP SERVER TO DISK = 'D:\SQL\DB.bkm' WITH METADATA_ONLY, FORMAT;

/*LOCKS:
suspending the database for the snapshot takes 3 locks:
shared lock on the master database:  BULKOP_BACKUP_FREEZE
exclusive lock on the user database: BULKOP_BACKUP_FREEZE
shared lock on the user database

DMVs:
sys.dm_server_suspend_status (db_id, db_name, suspend_session_id, suspend_time_ms, is_diffmap_cleared, is_writeio_frozen)

SELECT resource_type, resource_subtype, resource_database_id, resource_lock_partition, request_mode, request_type, request_status, 
request_owner_type, request_session_id FROM sys.dm_tran_locks WHERE request_owner_type='SESSION'
*/


--restore:
--1.  mount the snapshot:
EXEC xp_cmdshell 'C:\SQL\getsnapshot.cmd', no_output;
--2.  restore:  (fast, irrespective of the size of the database)
RESTORE DATABASE DB1 FROM DISK = 'D:\SQL\DB.bkm' WITH METADATA_ONLY, FILE = 3;
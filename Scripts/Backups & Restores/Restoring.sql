/**RESTORING MASTER DATABASE*****************************************************************************************************************
Restoring master is tricky because it contains all the info about all the other databases in the instance
and is required for startup.  In the case when you have a master database to start from, you have to start
in single-user mode using the -m flag.  
using sqlcmd:  Net Start MSSQLSERVER /m"SQLCMD"
using SQL Server Configuration Manager, open SQL Server service properties>Startup Parameters and add -m, then restart SQL Server
*/
--restore:
RESTORE DATABASE [master] FROM DISK = 'F:\Data\master.bak' WITH REPLACE;


ALTER AUTHORIZATION ON database::testdb TO DisabledLogin;
--********OPTION:  WITH ROLLBACK IMMEDIATE - will roll back any incomplete transactions and will immediately disconnect any other connections to the database

USE master ALTER DATABASE EVEREST SET SINGLE_USER WITH ROLLBACK IMMEDIATE
EXEC master.dbo.sp_detach_db @dbname='EVEREST'

--revert back to multi user mode:
ALTER DATABASE EVEREST SET MULTI_USER WITH ROLLBACK IMMEDIATE


--look at LSN number of backup file:
RESTORE HEADERONLY FROM DISK='XX.BAK';
--then look at 
Select name, physical_name, create_lsn, redo_start_lsn from sys.master_files 
where database_id=DB_ID('docusign') 

--Let's look at files in the backups 
RESTORE HEADERONLY FROM DISK = N'F:\SQL Backups\SalesTueRW.bak';
RESTORE FILELISTONLY FROM DISK = N'F:\SQL Backups\SalesTueRW.bak';

--************restore with STANDBY,  leaves the database in a standby state, which allows for limited read-only access
--************a recovery file must be specified which will allow the recovery effects to be undone
RESTORE DATABASE [eh] FROM  DISK = N'D:\SQL\backups\eh.bak'  WITH STANDBY = 'D:\SQL\backups\ROLLBACK_UNDO_eh.BAK'
	, MOVE 'EH_Data' TO 'D:\SQL\DATA\eh_test.mdf', MOVE 'EH_Log' TO 'D:\SQL\DATA\eh_test.LDF'
 
--************restore log
RESTORE LOG [eh]
 FROM  DISK = N'D:\SQL\backups\eh_2014_06_20_02_50.trn' WITH  FILE = 1,  NOUNLOAD,  STATS = 10
GO

--***RESTORE a database that's currently in restoring state******
RESTORE DATABASE NavigatorsGrant


--************restore and replace:
RESTORE DATABASE [master] FROM DISK='F:\data\master.bak' WITH REPLACE;


--****RESTORING A DATABASE THAT HAS BEEN CORRUPTED******************************************************************************
--Database mode:  (In Recovery), SQL Server is trying to run recovery and the database cannot be altered or detached
ALTER DATABASE Staging SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

Msg 5011, Level 14, State 7, Line 1
User does not have permission to alter database 'Staging', the database does not exist, or the database is not in a state that allows access checks.
Msg 5069, Level 16, State 1, Line 1
ALTER DATABASE statement failed.

EXEC sp_Detach_db 'EPO_Source_Old'
Msg 1222, Level 16, State 37, Line 12
Lock request time out period exceeded.

Msg 3702, Level 16, State 4, Line 17
Cannot drop database "Staging" because it is currently in use.

--to stop SQL Server from trying to recover the database, stop SQL Services and delete one of the db files:
--now the mode is (Recovery Pending) and the database can be dropped, the DROP stmt does not delete backup files when db is not ONLINE
DROP DATABASE Staging;


--*************attach database data file and log**************************************************
USE [master]
CREATE DATABASE sttts ON ( FILENAME = N'C:\SQLData\sttts.mdf'),
( FILENAME = N'C:\SQLData\sttts.LDF')  FOR ATTACH 

--**attach database data file without a transaction log***
--**SQL Server will create a new transaction log*******************
 
USE [master]
CREATE DATABASE Everest ON
( FILENAME = N'C:\Everest_backup_2014_10_16.mdf')
FOR ATTACH



/*****************************single filegroup restore **********************************************/
--database must be in full recovery mode OR
--Under the simple recovery model, the file must belong to a read-only filegroup
--In SIMPLE recovery all read-write filegroups must be included in a backup

--view current file location:
SELECT name, physical_name, state_desc FROM sys.master_files WHERE database_id=DB_ID('Sales');

--view objects location:
SELECT OBJECT_NAME(t.object_id) AS ObjetName, s.name AS FileGroup
	FROM sys.data_spaces s JOIN sys.indexes i on i.data_space_id = s.data_space_id
	JOIN sys.tables t on t.object_id=i.object_id
	WHERE i.index_id<2 AND t.type='U';

--in order to restore a single secondary filegroup, primary filegroup needs to be online and properly functioning
--a filegroup can be restored without affecting any other filegroups in the database and database can be online and fully functioning to begin with

--before restoring, need to take a tail log backup first:
--to terminate any connections:
ALTER DATABASE Sales SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
BACKUP LOG Sales TO DISK='C:\SQL Backups\Sales_Tail.trn' WITH NO_TRUNCATE;  --database will remain online, unlike with NORECOVERY option
RESTORE DATABASE Sales FILE = 'ColdData', FILEGROUP = 'ColdStorageFG' FROM DISK = 'C:\SQL Backups\ColdData.bak' WITH NORECOVERY;
RESTORE LOG Sales FROM DISK ='C:\SQL Backups\Sales_Tail.trn' WITH RECOVERY;



/*****************************Piecemeal restore **********************************************
Enterprise edition of SQL Server: online restore
Standard edition that contain multiple files or filegroups: offline restore 
Under the simple model, only for read-only filegroups.

DB must be (FULL recovery) OR (SIMPLE recovery AND secondary filegroup read-only)

Restore with PARTIAL option to bring the primary filegroup online first, primary must be restored first
This sequence restores and recovers the primary filegroup and, under the simple recovery model, all read/write filegroups. 
During this piecemeal-restore sequence, the whole database must go offline first
After primary filegroup is restored, any unrestored secondary filegroups remain offline and are not accessible but can be restored and brought online later by a file restore
When the partial restore sequence finishes and the database is brought online, the state of the remaining files becomes "recovery pending" because their recovery has been postponed

In the Enterprise edition, any offline secondary filegroup can be restored and recovered while the database remains online. 
If a specific read-only file is undamaged and consistent with the database, the file does not have to be restored
*/
--check files:
SELECT FG.name as FilegroupName, 	DF.name as [FileName] 
FROM sys.database_files DF 	INNER JOIN sys.filegroups FG ON FG.data_space_id = DF.data_space_id; 

--check default filegroup:
SELECT name, data_space_id, [type], type_desc, is_default, filegroup_guid, log_filegroup_id, is_read_only 
FROM sys.filegroups  WHERE is_default=1;

--check objects:
SELECT FG.name AS FilegroupName, 
	OBJ.name AS ObjectName, 
	OBJ.type_desc AS ObjectType, 
	PA.index_id AS IndexID 
FROM sys.filegroups FG
    INNER JOIN sys.allocation_units AU ON AU.data_space_id = FG.data_space_id
    INNER JOIN sys.partitions PA ON PA.partition_id = AU.container_id 
	INNER JOIN sys.objects OBJ ON OBJ.object_id = PA.object_id
WHERE OBJ.type_desc NOT IN ('SYSTEM_TABLE', 'INTERNAL_TABLE')
ORDER BY FG.name;


/* Mark ArchiveLego read-only */
ALTER DATABASE OrganizeMyLego SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
ALTER DATABASE OrganizeMyLego MODIFY FILEGROUP ArchiveLego READONLY;
ALTER DATABASE OrganizeMyLego SET MULTI_USER;

/* Full backup. */
BACKUP DATABASE OrganizeMyLego TO DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\OrganizeMyLego_full.bak'; 

--To do a piecemeal restore, first, back up tail of log 
BACKUP LOG Sales TO DISK=N'F:\SQL_Backups\Sales_Tail.trn' WITH NO_TRUNCATE;

--restore with PARTIAL, indicating the start of a piecemeal restore
--Use any full database backup that contains the primary filegroup
--database will be in Restoring state
RESTORE DATABASE OrganizeMyLego FILEGROUP = 'Primary' FROM DISK = N'C:\SQL_Backups\OrganizeMyLego_full.bak' WITH PARTIAL, 	NORECOVERY; 
--now restore the log, with recovery if this is the last log to bring the Primary filegroup online:
RESTORE LOG OrganizeMyLego FROM DISK = N'C:\SQL_Backups\OrganizeMyLego_tlog1.trn' 	WITH NORECOVERY; 
RESTORE LOG OrganizeMyLego FROM DISK = N'C:\SQL_Backups\OrganizeMyLego_tlogtail.trn'  WITH RECOVERY;  --database will no longer be in Restoring state

/* Check file state. */
SELECT [name], [state_desc] FROM OrganizeMyLego.sys.database_files;

/* Restore the secondary filegroup,  NOTE: no "PARTIAL" here.  Partial is only used to start the Filegroup-restore sequence. */
USE master;
GO
RESTORE DATABASE OrganizeMyLego FILEGROUP = 'LargeLego' FROM DISK = N'C:\SQL_Backups\OrganizeMyLego_full.bak' 	WITH NORECOVERY;
RESTORE LOG OrganizeMyLego FROM DISK = N'C:\SQL_Backups\OrganizeMyLego_tlog1.trn' WITH NORECOVERY; 
RESTORE LOG OrganizeMyLego FROM DISK = N'C:\SQL_Backups\OrganizeMyLego_tlogtail.trn' WITH RECOVERY;


--to restore a secondary read-only filegroup, there is no need to restore any logs:
USE master;
GO
RESTORE DATABASE OrganizeMyLego FILEGROUP = 'LargeLego3' FROM DISK = N'C:\SQL_Backups\OrganizeMyLego_full.bak' 	WITH RECOVERY;



/*****Restoring to a Marked transaction ********************************************************************************/
--ClientA 
--ClientB 
--Each DB is for a separate client's sales. We have a shared product table. Prices need to be updated across them. 

/* MUST have full backup of each database in place for marked transactions to work. */
BACKUP DATABASE ClientA TO DISK = N'E:\SQL Backups\ClientA.bak';
BACKUP DATABASE ClientB TO DISK = N'E:\SQL Backups\ClientB.bak';

--Create a marked transaction :
BEGIN TRAN UpdateProductPrices 	WITH MARK 'Update product prices' 

--do stuff then
COMMIT TRANSACTION UpdateProductPrices

--Later after additional activity and a Transaction log backup 
BACKUP LOG ClientB TO DISK = N'E:\SQL Backups\ClientBWithMark.trn';

--Restore to marked transaction: 
RESTORE DATABASE ClientA FROM DISK = N'E:\SQL Backups\ClientA.bak' 	WITH NORECOVERY;
RESTORE LOG ClientA FROM DISK = N'E:\SQL Backups\ClientAWithMark.trn' WITH NORECOVERY, 
	--STOPBEFOREMARK = 'UpdateProductPrices';
	STOPATMARK = 'UpdateProductPrices';
RESTORE DATABASE ClientA  	WITH RECOVERY; 

/* check msdb.dbo.logmarkhistory */
SELECT * FROM msdb.dbo.logmarkhistory;


--*******************restore encrypted database:********************************************************
USE Master
OPEN MASTER KEY DECRYPTION BY PASSWORD = '23987hxJKL95tanya1210TNV4369#ghf0%lekjg5k3fd117r$$#1946kcj$n44ncjhdlj';
RESTORE DATABASE sttts FROM DISK ='C:\SQLData\backups\sttts.bak'
	WITH MOVE 'sttts' TO 'C:\SQLData\sttts.mdf',MOVE 'sttts' TO 'C:\SQLData\sttts.ldf',RECOVERY,REPLACE
	GO
--attach encrypted database:
CREATE DATABASE sttts ON ( FILENAME = N'C:\SQLData\sttts.mdf'), ( FILENAME = N'C:\SQLData\sttts.LDF')  FOR ATTACH 


--*********************to restore a database with TDE encryption on a new server**************************
--The database can be restored on a new server without using the same SMK or DMK:
--1. Create a DMK, it must be encrypted by a password (SMK is generated when SQL server is installed)
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'vmL223TW2W3jv3AlQ1gz' 
--2.  Backup certs on the old servers
BACKUP CERTIFICATE TDECert2 TO FILE = 'U:\Keys\TDECert2.cert' WITH PRIVATE KEY (file='U:\Keys\TDECert2.key', ENCRYPTION BY PASSWORD='Password123.#');
--3.  Restore backup encryption certificate on the new server:
CREATE CERTIFICATE BackupCert FROM FILE = '\\w3pltsqltools01\SQL\BackupCert\BackupCert.cert' WITH PRIVATE KEY (file='\\w3sqldbawu3i01\share\BackupCert.key', 
	DECRYPTION BY PASSWORD='TracyOctonaut$33123Day'); 

--restore the database


--second method, backup keys on the old server and copy them to the new one:
USE Master;
GO
BACKUP SERVICE MASTER KEY TO FILE = 'U:\Backup\SMK.key' ENCRYPTION BY PASSWORD='Password123.#';
GO
USE SSISDB
GO
BACKUP MASTER KEY TO FILE = 'U:\Backup\DMK.key' ENCRYPTION BY PASSWORD='Password123.#';
GO
	
--on the new server:  restore encryption keys, create Certs, encrypt MK by SMK
RESTORE SERVICE MASTER KEY FROM FILE ='U:\Keys\SMK.key' DECRYPTION BY PASSWORD ='Password123.#';
GO
RESTORE MASTER KEY FROM FILE='U:\Keys\DMK.key' DECRYPTION BY PASSWORD='Password123.#' ENCRYPTION BY PASSWORD='Turbul3ntPhras3!&';
GO
OPEN MASTER KEY DECRYPTION BY PASSWORD='Turbul3ntPhras3!&';
ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY;  --encrypt MK by SMK so that opening the MK by password is not needed every time database is altered
GO
CREATE CERTIFICATE TDECert2 FROM FILE = 'U:\Keys\TDECert2.cert' WITH PRIVATE KEY (FILE='U:\Keys\TDECert2.key', DECRYPTION BY 
	PASSWORD='Password123.#');
GO




--********restore database and move data & log files to new location ***************************
 RESTORE DATABASE Everest
	FROM DISK ='C:\Everest_backup_2014_10_16.bak'
	WITH MOVE 'Everest' TO 'C:\SQLData\Everest.mdf',
		MOVE 'Everest_log' TO 'C:\SQLData\Everest.ldf',
		RECOVERY--,REPLACE
	GO

 RESTORE DATABASE Everest_old
	FROM DISK ='C:\SQLData\EVEREST_backup_2014_10_16_030000_9864527.bak'
	WITH MOVE 'Everest' TO 'C:\SQLData\Everest_old.mdf',
		MOVE 'Everest_log' TO 'C:\SQLData\Everest_old.ldf',
		RECOVERY--,REPLACE
	GO

 RESTORE DATABASE CCESBucket
	FROM DISK ='K:\NavigatorsGrant\NavigatorsGrant_backup_2014_08_05_150001_8420437.trn'
	WITH NORECOVERY
 GO

 RESTORE LOG NVtemp2
 	FROM DISK ='G:\backups\NVtemp2\NavigatorsGrant_backup_2014_07_26_210002_9894152.trn'
	WITH NORECOVERY
 GO
  RESTORE LOG NVtemp2
 	FROM DISK ='G:\backups\NVtemp2\NavigatorsGrant_backup_2014_07_27_070001_0947787.trn'
	WITH RECOVERY
 GO


--*****************to restore to a point in time*************************
--first, take a tail-log backup (which puts db in restoring mode)
ALTER DATABASE ActiveBatch SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
BACKUP LOG ActiveBatch TO DISK ='I:\ActiveBatch\ActiveBatch_backup_logtail.trn' WITH NO RECOVERY;
GO
--now restore starting with a full backup:
RESTORE DATABASE ActiveBatch  FROM DISK ='D:\backups\fullbackup.bak' WITH NORECOVERY;
GO
RESTORE LOG dbname FROM DISK ='D:\backups\log.trn' WITH NORECOVERY;
GO
RESTORE LOG dbname FROM DISK ='D:\backups\log.trn' WITH RECOVERY, STOPAT = '2014-04-16 14:20';

GO
ALTER DATABASE ActiveBatch SET MULTI_USER;
select getdate(); --check server time






sp_helpdb tempdb
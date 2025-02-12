/*****database page repair/restore ***********************************************************/
--when a database is marked suspect, never detach it
SELECT DATABASEPROPERTYEX (N'Datamart', N'STATUS') AS N'Status';


--when a page is damaged, DBCC CHECKDB will return an error and msdb.dbo.suspect_pages will contain info about the damaged page(s) (up to 1,000)
DBCC CHECKDB (Test) --this command can take a long time for large databases

--To minimize downtime:
--PHYSICAL_ONLY will limit the checking to the integrity of the physical structure of the page and record headers and the allocation consistency of the database (small overhead check of the physical 
--consistency of the database, but can also detect torn pages, checksum failures, and common hardware failures that can compromise a  user's data)
--NOINDEX will skip non-sytem index checks
DBCC CHECKDB (Test, NOINDEX) WITH PHYSICAL_ONLY;  --00:01:04, longer than DBCC CHECKDB without any options
DBCC CHECKDB (Test, NOINDEX);  --00:00:00, much faster than PHYSICAL_ONLY
DBCC CHECKDB (DBAWork, NOINDEX) WITH ESTIMATEONLY;  --will estimate space needed in tempdb to create the snapshop to run CHECKDB

SELECT * FROM msdb.dbo.suspect_pages;

--if database is in suspect mode, it will be inaccessible and recovery cannot be performed until flag is cleared
--then, it can be set to emergency mode (allows multiple connections from the members of the sysadmin role)
--for restores, it must be in single user mode (setting it into single user mode might take a while, % complete can be checked)
--PARALLEL_REDO_FLOW_CONTROL may occur 
ALTER DATABASE Datamart SET EMERGENCY;

--if setting the database into EMERGENCY mode fails, try setting it offline and then online again
ALTER DATABASE Datamart SET OFFLINE;
ALTER DATABASE Datamart SET ONLINE;

--if that doesn't work either, there may be a background SQL Server process running that is accessing the database
--another option is to stop SQL Services, delete a database file, then restart them; db will be offline and can be dropped

EXEC sp_resetstatus Datamart;
ALTER DATABASE Datamart SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
RESTORE DATABASE Datamart PAGE='40:1286143' FROM DISK='\\dr-biodswin-01\DatamartBackups\Datamart_20190107_1.bak',
	 DISK='\\dr-biodswin-01\DatamartBackups\Datamart_20190107_2.bak',
	 DISK='\\dr-biodswin-01\DatamartBackups\Datamart_20190107_3.bak',
	 DISK='\\dr-biodswin-01\DatamartBackups\Datamart_20190107_4.bak'
	 WITH RECOVERY;
 
RESTORE DATABASE Datamart WITH RECOVERY;

DBCC CHECKDB (Datamart, REPAIR_ALLOW_DATA_LOSS)
DBCC CHECKDB ('AdventureWorks2012', REPAIR_REBUILD); 

--**perform emergency repair on a database when a log file is corrupt or is missing
--check what state a database is in:

SELECT DATABASEPROPERTYEX ('ipas', 'STATUS');
GO

--check sys.databases for database state:
SELECT [state_desc] FROM [sys].[databases] WHERE [name] = 'ipas';
GO

--**EMERGENCY MODE REPAIR:  very last resort!

--set database into EMERGENCY mode so we can get in and look at data
--the database will be marked READ_ONLY, logging will be disabled and access will be limited to sysadmin role members
ALTER DATABASE [Datamart] SET EMERGENCY;
GO

--run EMERGENCY-mode repair, think of this as 'recovery with CONTINUE_AFTER_ERROR, some data may be lost
--salvage as much transactional information as possible from the log before we throw it away and build a new one
--any uncommitted transactions will not be rolled back and data will be inconsistent
ALTER DATABASE [EmergencyDemo] SET SINGLE_USER;
GO
DBCC CHECKDB (N'Datamart', REPAIR_ALLOW_DATA_LOSS) WITH ALL_ERROMSGS, NO_INFOMSGS;
GO


/*********************restore damaged pages**********************************************************************************************
--with online page restore, start restoring the last full backup:
RESTORE DATABASE dbname PAGE='1:57' FROM DISK ='D:\backups\fullbackup.bak' WITH NORECOVERY;
--then restore log, do not recover yet:
RESTORE LOG dbname FROM DISK ='D:\backups\log1.trn' WITH NORECOVERY;
--take a log backup and now recover:
BACKUP LOG dbname TO DISK ='D:\backups\logbackuprecover.trn';
RESTORE LOG dbname FROM DISK ='D:\backups\logbackuprecover.trn' WITH RECOVERY;


--with offline page restore, first take a transaction log tail backup, this will put entire database into a restoring state:
BACKUP LOG dbname TO DISK ='I:\backups\dbtailbackup.trn' WITH NORECOVERY;
--restore db using page option:
RESTORE DATABASE dbname PAGE='1:57' FROM DISK ='D:\backups\fullbackup.bak' WITH NORECOVERY;
--then restore any logs, do not recover yet:
RESTORE LOG dbname FROM DISK ='D:\backups\log.trn' WITH NORECOVERY;
--restore transaction log tail and recover:
RESTORE LOG dbname FROM DISK ='D:\backups\dbtailbackup.trn' WITH RECOVERY;

-- Restoring one page if corruption is found : Standard - offline , Enterprise - online 

--Set database offline 
USE master;
GO
ALTER DATABASE AdventureWorks2012 SET OFFLINE;

--Run a DBCC CHECKDB 
DBCC CHECKDB (AdventureWorks2012); 
GO

--Find page ID - should be in CHECKDB, or CHECKSUM:_____

--What object(s)? Heap? Clustered index? Nonclustered index? 
USE AdventureWorks2012;
GO
SELECT * 
FROM sys.objects
WHERE object_id = 1533248517;

--Set DB to single user mode 
ALTER DATABASE AdventureWorks2012 SET SINGLE_USER WITH ROLLBACK IMMEDIATE; 

--Tail log backup 
BACKUP LOG AdventureWorks2012 TO DISK=N'E:\SQL Backups\AdventureWorks2012_tail.trn'
	WITH NO_TRUNCATE;

--Apply full backup with PAGE clause listing pages to be restored 
--NORECOVERY is a must here 

USE master;
GO
RESTORE DATABASE AdventureWorks2012 PAGE='' 
FROM DISK = N'E:\SQL Backups\AdventureWorks2012_Full_20140415_1520.bak'
	WITH NORECOVERY;

--Apply any differentials 

--Apply any log files 
RESTORE LOG AdventureWorks2012 FROM DISK = N'E:\SQL Backups\AdventureWorks2012_201404151525.trn'
	WITH NORECOVERY; 

--Restore tail log backup 
RESTORE LOG AdventureWorks2012
FROM DISK = N'E:\SQL Backups\AdventureWorks2012_tail.trn'
	WITH NORECOVERY; 

RESTORE DATABASE AdventureWorks2012 
	WITH RECOVERY; 

--Run DBCC CHECKDB to ensure it's clean 
DBCC CHECKDB (AdventureWorks2012);

--Multi user mode 
--ALTER DATABASE AdventureWorks2012 SET MULTI_USER; 


**/
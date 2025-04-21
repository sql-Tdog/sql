/**script to create a database with multiple filegroups and files
***and then practice piecemeal restores


--create database
USE master;
GO
CREATE DATABASE FilegroupFull ON PRIMARY
(NAME = FGFull1_dat,
 FILENAME = 'C:\SQLData\FGFull1_dat.mdf'),
FILEGROUP FGFullFG2
(NAME = FGFull2_dat,
 FILENAME = 'C:\SQLData\FGFull2_dat.mdf'), 
FILEGROUP FGFullFG3 
 (NAME = FGFull3_dat,
 FILENAME = 'C:\SQLData\FGFull3_dat.mdf') 
LOG ON
(NAME = FGFull_log,
 FILENAME = 'C:\SQLData\FGFull_log.ldf')


--change recovery model
ALTER DATABASE FilegroupFull SET RECOVERY FULL;
GO


--add a filegroup:
ALTER DATABASE FilegroupFull ADD FILEGROUP FGFullFG4 
ALTER DATABASE FilegroupFull ADD FILE
(NAME = FGFull4_dat,
 FILENAME = 'C:\SQLData\FGFull4_dat.mdf')
TO FILEGROUP FGFullFG4


--change default filegroup:
ALTER DATABASE FilegroupFull
MODIFY FILEGROUP FGFullFG2 DEFAULT


--view filegroups and files:
USE FilegroupFull;
GO
SELECT name, data_space_id, type, type_desc, is_default, filegroup_guid, log_filegroup_id, is_read_only
FROM sys.filegroups;


--create table:
CREATE TABLE Orders2011 
(OrderID INT NOT NULL, 
 OrderDate DATETIME NOT NULL 
 CONSTRAINT PKOrders PRIMARY KEY CLUSTERED (OrderID))


 --check which filegroup table is created on:
 SELECT PA.OBJECT_ID, FG.name
FROM sys.filegroups FG
    INNER JOIN sys.allocation_units AU ON AU.data_space_id = FG.data_space_id
    INNER JOIN sys.partitions PA ON PA.partition_id = AU.container_id
WHERE PA.OBJECT_ID =
    (SELECT OBJECT_ID(N'FilegroupFull.dbo.Orders2011'))


--create more tables specifying filegroup:
CREATE TABLE Orders2010 
(OrderID INT NOT NULL, 
 OrderDate DATETIME NOT NULL 
 CONSTRAINT PKOrders2010 PRIMARY KEY CLUSTERED (OrderID)) 
ON FGFullFG3;
GO
 
;WITH InsertOrders (OrderID, OrderDate) AS 
(
SELECT 300100, 
    CAST('2010/05/01' AS DATETIME)
UNION ALL 
SELECT OrderID + 1, 
    DATEADD(dd, 1, OrderDate)
FROM InsertOrders 
WHERE DATEADD(dd, 1, OrderDate) <= DATEADD(dd, 100, '2010/05/01')
)
INSERT INTO Orders2010 
SELECT OrderID, OrderDate
FROM InsertOrders 
OPTION (MAXRECURSION 100);
CREATE TABLE Orders2009 
(OrderID INT NOT NULL, 
 OrderDate DATETIME NOT NULL 
 CONSTRAINT PKOrders2009 PRIMARY KEY CLUSTERED (OrderID)) 
ON FGFullFG4;
GO
 
;WITH InsertOrders (OrderID, OrderDate) AS 
(
SELECT 200100, 
    CAST('2009/05/01' AS DATETIME)
UNION ALL 
SELECT OrderID + 1, 
    DATEADD(dd, 1, OrderDate)
FROM InsertOrders 
WHERE DATEADD(dd, 1, OrderDate) <= DATEADD(dd, 100, '2009/05/01')
)
INSERT INTO Orders2009
SELECT OrderID, OrderDate
FROM InsertOrders 
OPTION (MAXRECURSION 100);


--set one of the filegroups as read-only:
ALTER DATABASE FilegroupFull SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
GO
ALTER DATABASE FilegroupFull MODIFY FILEGROUP FGFullFG4 READONLY;
GO
ALTER DATABASE FilegroupFull SET MULTI_USER;
GO


--take a full backup of database:
BACKUP DATABASE FilegroupFull TO DISK = N'C:\SQLData\backups\BackupFilegroupFull_full.bak'


--add some records to a table:
INSERT INTO Orders2011 
VALUES(400202, '2011/08/29');

--take a transaction log backup:
BACKUP LOG FilegroupFull TO DISK = N'C:\SQLData\backups\BackupFilegroupFull_tlog1.trn'

--add another record to the table:
INSERT INTO Orders2011 
VALUES(400203, '2011/08/30');


--take a back up of the tail of transaction log:
USE Master
GO
BACKUP LOG FilegroupFull TO DISK = N'C:\SQLData\backups\BackupFilegroupFull_tlogtail.trn' 
WITH NORECOVERY, NO_TRUNCATE;


-restore primary filegroup:
RESTORE DATABASE FilegroupFull 
FILEGROUP = 'Primary'
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_full.bak' 
WITH PARTIAL, NORECOVERY 

RESTORE LOG FilegroupFull 
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_tlog1.trn' 
WITH NORECOVERY 

RESTORE LOG FilegroupFull 
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_tlogtail.trn' 
WITH NORECOVERY;
GO


--check the status of each file (Enterprise Edition Only):
SELECT [name], [state_desc] 
FROM FilegroupFull.sys.database_files;
GO

--try to select data:
USE FilegroupFull;
GO
SELECT OrderID, OrderDate
FROM Orders2011 
WHERE OrderID = 400189

--restore another filegroup:  (filegroup-restore sequence)

RESTORE DATABASE FilegroupFull 
FILEGROUP = 'FGFullFG2'
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_full.bak' 
WITH PARTIAL, NORECOVERY 

RESTORE LOG FilegroupFull 
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_tlog1.trn' 
WITH NORECOVERY 

RESTORE LOG FilegroupFull 
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_tlogtail.trn' 
WITH NORECOVERY;
GO


RESTORE DATABASE FilegroupFull 
FILEGROUP = 'FGFullFG3'
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_full.bak' 
WITH PARTIAL, NORECOVERY 

RESTORE LOG FilegroupFull 
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_tlog1.trn' 
WITH NORECOVERY 

RESTORE LOG FilegroupFull 
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_tlogtail.trn' 
WITH NORECOVERY;
GO


--restore the final ***read-only***  filegroup and brind database online:
RESTORE DATABASE FilegroupFull 
FILEGROUP = 'FGFullFG4'
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_full.bak' 
WITH RECOVERY 

GO


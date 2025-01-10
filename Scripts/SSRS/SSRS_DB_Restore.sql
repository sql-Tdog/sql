ALTER DATABASE ReportServer SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
DROP DATABASE ReportServer;
GO;

RESTORE FILELISTONLY FROM DISK='K:\MigrationBackups\ReportServerMigrate.bak';

RESTORE DATABASE ReportServer FROM DISK='K:\MigrationBackups\ReportServerMigrate.bak'
	WITH MOVE 'ReportServer' TO 'G:\SQLData\ReportServer.mdf', MOVE 'ReportServer_log' TO 'I:\SQLData\ReportServer_log.ldf';
ALTER AUTHORIZATION ON database::ReportServer TO sa;
ALTER DATABASE ReportServer SET COMPATIBILITY_LEVEL=150

USE ReportServer
GO
DELETE FROM ReportSchedule
GO
DELETE FROM Subscriptions
GO
DELETE FROM Schedule



ALTER DATABASE ReportServerTempDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
DROP DATABASE ReportServerTempDB;
GO
RESTORE FILELISTONLY FROM DISK='K:\MigrationBackups\ReportServerTempDBMigrate.bak';

RESTORE DATABASE ReportServerTempDB FROM DISK='K:\MigrationBackups\ReportServerTempDBMigrate.bak'
	WITH MOVE 'ReportServerTempDB' TO 'G:\SQLData\ReportServerTempDB.mdf', MOVE 'ReportServerTempDB_log' TO 'I:\SQLData\ReportServerTempDB_log.ldf';
ALTER AUTHORIZATION ON database::ReportServerTempDB TO sa;
ALTER DATABASE ReportServerTempDB SET COMPATIBILITY_LEVEL=150


/*****Errors********************************************************
When trying to restore the encryption key: "The feature “Scale-out deployment” is not supported in this edition of Reporting Services"
You are most probably using a Standard Edition of SSRS/SQL Server, along with the fact that if you check the “Keys” table in the “ReportServer” database, 
you will most probably have 2 records there, one that has the “MSSQLServer” value in the “InstanceName” column, and another one that has the “SSRS” value.
To this end, SSRS sees these 2 key values, and considers that you are using two servers instead of one, hence the scale-out deployment feature, 
even if this is not the actual case.
SELECT * FROM ReportServer.dbo.Keys;

Solution:
1.  Backup the keys table in the ReportServer database to a new table:
USE ReportServer;
GO
SELECT * 
INTO KeysTempBackup
FROM dbo.Keys;
GO

2.Stop the SSRS Instance
Delete from the “Keys” table, the entry that references the old SSRS instance name. So if for example, indeed the record that references the old SSRS instance has the value “MSSQLServer” in the “InstanceName” column in the “Keys” table, then, you can try deleting that entry with the below command:
USE ReportServer;
GO
DELETE FROM dbo.Keys
WHERE InstanceName='HBEXSQLPRODM';
GO

3.  Start the SSRS instance
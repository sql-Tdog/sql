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


SELECT * FROM ReportServer.dbo.Keys;

--Error:  This edition of reporting services doesn't support scale out, but the database has other servers registered. We'll need to remove those to continue.
--Solution:
--1.  Backup the keys table in the ReportServer database to a new table:
USE ReportServer;
GO
SELECT * INTO KeysTempBackup FROM dbo.Keys;
GO
SELECT * FROM KeysTempBackup;


--2.Stop the SSRS Instance
--Delete from the “Keys” table, the entry that references the old SSRS instance name. So if for example, indeed the record that references the old SSRS instance has the value “MSSQLServer” in the “InstanceName” column in the “Keys” table, then, you can try deleting that entry with the below command:
USE ReportServer;
GO
DELETE FROM dbo.Keys WHERE InstanceName='MSSQLSERVER';
GO

--3.Start the SSRS instance
/** script to rename user database and files associated with it
--1.  rename database in Object Explorer
--2.  rename files in database properties wizard
 
select db_name(18), file_name(1)
 
SELECT      name, physical_name
FROM        sys.database_files
 
--3.  detach database
--WITH ROLLBACK IMMEDIATE option will roll back any incomplete transactions and will
--immediately disconnect any other connections to the database
 
USE master ALTER DATABASE EVEREST
SET SINGLE_USER WITH ROLLBACK IMMEDIATE
 
 
USE master ALTER DATABASE EVEREST
SET MULTI_USER WITH ROLLBACK IMMEDIATE
 
EXEC master.dbo.sp_detach_db @dbname='gpassandbox_20140115'
 
 
--4.  rename data files in the drive
 
--5.  reattach database
USE [master]
CREATE DATABASE gpassandbox_20140115 ON
( FILENAME = N'G:\Data\gpassandbox_20140115.mdf'),
( FILENAME = N'G:\Data\gpassandbox_20140115_log.LDF')
FOR ATTACH
 
 
**/
 
 /** for system databases: except master and resource databases **
--1.  check current database name and location
SELECT name, physical_name AS CurrentLocation, state_desc
FROM sys.master_files
WHERE database_id = DB_ID(N'msdb');
 
--2.  alter database filename by executing statements below
ALTER DATABASE tempdb MODIFY FILE ( NAME = tempdev , FILENAME = 'G:\DATA\tempdb.mdf' );
ALTER DATABASE tempdb MODIFY FILE ( NAME = templog , FILENAME = 'G:\DATA\templog.ldf' );
 
--3.  using cmd shell, net stop MSSQLSERVER
--4.  move database file physically to new location (tempdb files are recreated each time
              SQL Server is restarted so no need to move them)
--5.  net start MSSQLSERVER
 
--6.  for msdb database, verify that the Service Broker is enabled, if server is configured for database mail
       SELECT is_broker_enabled
       FROM sys.databases
       WHERE name = N'msdb';
**/
 
--see database size, id, create date, status, etc.
sp_helpdb tempdb
 
 
 
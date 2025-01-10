/** to rename or move user databases

--to move and/or rename user databases:  detach, rename/move, then reattach
--WITH ROLLBACK IMMEDIATE option will roll back any incomplete transactions and will 
--immediately disconnect any other connections to the database

USE master ALTER DATABASE USRGRP_REPORTING SET SINGLE_USER WITH ROLLBACK IMMEDIATE
EXEC master.dbo.sp_detach_db @dbname='USRGRP_REPORTING'

--move data files to desired location and/or rename, then reattach:
USE [master] CREATE DATABASE USRGRP_REPORTING ON
( FILENAME = N'D:\SQLData\USRGRP_REPORTING.mdf'),
( FILENAME = N'J:\SQLLogs\USRGRP_REPORTING_log.ldf')  FOR ATTACH

--to just move certain files of a database:
USE master 
GO
alter availability group p1bngbsc1sag remove database DW_Base
GO
ALTER DATABASE DW_Base SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
ALTER DATABASE DW_Base SET OFFLINE;
--move the files in the directory
--run the below ALTER stmt at any time before setting database back online:
ALTER DATABASE DW_Base MODIFY FILE (Name= DW_Base_log, FILENAME='L:\Logs\DW_Base_log.ldf');
GO
ALTER DATABASE DW_Base SET ONLINE;
GO
ALTER DATABASE DW_Base SET MULTI_USER;
GO

:CONNECT P1BNGBSN1S02
DROP DATABASE DW_Base;

alter availability group p1bngbsc1sag add database DW_Base


--if I accidentally specify an incorrect location for the file move, I can re-issue the ALTER DATABASE stmt with the correct location and try 
--to set the database back online again

--to rename logical file name:  (can be done while database is online)
ALTER DATABASE AspnetState_D6 MODIFY FILE (Name= AspnetState_dev6,NEWNAME=AspnetState_D6);
GO
ALTER DATABASE AspnetState_D6 MODIFY FILE (Name= AspnetState_dev6_log,  NEWNAME=AspnetState_D6_log);


**/ 
 
 /** for system databases: except master and resource databases **
 --1.  check current database name and location
SELECT name, physical_name AS CurrentLocation, state_desc
FROM sys.master_files
WHERE database_id = DB_ID(N'DW_Base');

 --2.  alter database filename by executing statements below
 ALTER DATABASE tempdb MODIFY FILE ( NAME = tempdev , FILENAME = 'M:\tempdb.mdf' );
 ALTER DATABASE tempdb MODIFY FILE ( NAME = tempdev2 , FILENAME = 'N:\tempdb2.mdf' );
 ALTER DATABASE tempdb MODIFY FILE ( NAME = tempdev3 , FILENAME = 'M:\tempdb3.mdf' );
 ALTER DATABASE tempdb MODIFY FILE ( NAME = tempdev4 , FILENAME = 'N:\tempdb4.mdf' );


 --3.  using cmd shell, net stop MSSQLSERVER
 --4.  move database file physically to new location (tempdb files are recreated each time
		SQL Server is restarted so no need to move them)
 --5.  net start MSSQLSERVER

 --6.  for msdb database, verify that the Service Broker is enabled, if server is configured for database mail
	SELECT is_broker_enabled 
	FROM sys.databases
	WHERE name = N'msdb';
**/

--see database size, id, create date, status, etc.
sp_helpdb tempdb

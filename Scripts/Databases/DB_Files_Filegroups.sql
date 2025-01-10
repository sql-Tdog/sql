/****NOTES***********************************************************************************************
Tables and indexes are stored in filegroups and are normally spread across the files in the filegroup (proportionally by default),
so unless the files are in separate filegroups, we cannot isolate tables and specify that they be in a certain file.  Files in a single filegroup can
be spread over different drives.
 
If you use multiple files, create a second filegroup for the additional file and make that filegroup the default filegroup. This way, the primary file will contain only system tables and objects.
To maximize performance, create files or filegroups on as many different available local physical disks as possible. Put objects that compete heavily for space in different filegroups.
 
Use filegroups to enable placement of objects on specific physical disks.
 
Put different tables used in the same join queries in different filegroups. This will improve performance, because of parallel disk I/O searching for joined data.
 
Put heavily accessed tables and the nonclustered indexes that belong to those tables on different filegroups. This will improve performance,
because of parallel I/O if the files are located on different physical disks and different users are accessing the table at the same time.
 
Do not put the transaction log file or files on the same physical disk that has the other files and filegroups.
 
If all database files are located on one LUN, it can still be beneficial to create separate files and filegroups for large tables because SQL Server manages reading and writing to individual files
separately (multipathing), not as good as having dedicated disks per file but needs to be tested on database level
 
Microsoft recommends:  The number of data files within a single filegroup should equal to the number of CPU cores.  However,
according to Brent Ozar, a good rule of thumb is 4 files per filegroup for databases that will potentially become 1TB of real data.  This should be done early on because files
are filled proportionally.
If additional files are added later, rebuild indexes to even things out on all files in the filegroup.
 
 
Advice:  create table on one drive and nonclustered indexes on a different drive
Problem:  Have to keep track of all new indexes to make sure they are created on correct filegroup; INSERTS, UPDATES, DELETES & DBCC commands will not be faster because we will be hitting all indexes anyway
Database restores:  all indexes have to be restored before database is available (unless we modify system tables to get rid of nonclustered indexes after restoring clustered)
 
Binaries:  SharePoint, Fax software, medical & billing images, Word docs & Excel files, possibly XML too
This is a different type of data with different access patterns:  usually insert only, history stays in db, huge size per record, not speed critical (don't care how long it takes to commit),
       great for RAID 5 and/or SATA drives
 
Storage:  if possible to fit entire db on SSD drive, it would make sense to get rid of some nonclustered indexes just so entire db can fit on SSD
 
--check current database name and location
SELECT file_id, name, physical_name AS CurrentLocation, state_desc, size*8./1024/1024 size_GB, growth
FROM sys.master_files
WHERE database_id = DB_ID(N'datamart');
 
select * from sys.databases;
 
--check if volume is compressed, read only, etc.
select * from sys.dm_os_volume_stats(7,1);
 
--modify database file sizes/locations
ALTER DATABASE tempdb MODIFY FILE ( NAME = tempdb4 , SIZE=95GB );
ALTER DATABASE tempdb MODIFY FILE ( NAME = tempdb2 , FILENAME = 'F:\SQLTemp\tempdb2.ndf' );
ALTER DATABASE Analytics MODIFY FILE (NAME='Analytics', SIZE=150GB )
 
 
--check database object sizes
SELECT object_name(i.object_id) as objectName,i.[name] as indexName,sum(a.total_pages) as totalPages,
	sum(a.used_pages) as usedPages,sum(a.data_pages) as dataPages,(sum(a.total_pages) * 8) /1024./1024 as totalSpace_GB,
	(sum(a.used_pages) * 8) /1024./1024 as usedSpace_GB,(sum(a.data_pages) * 8) /1024./1024 as dataSpace_GB
	, FG.name 'filegroup_name'
FROM sys.indexes i INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
LEFT JOIN sys.filegroups FG ON FG.data_space_id=a.data_space_id
LEFT JOIN sys.partitions PA ON PA.partition_id = a.container_id
GROUP BY i.object_id, i.index_id, i.[name], FG.name
ORDER BY sum(a.total_pages) DESC, object_name(i.object_id)


--to add a file to a database
ALTER DATABASE tempdb ADD FILE (NAME='tempdb3', FILENAME='F:\SQLTemp\tempdb3.ndf', SIZE=75GB, FILEGROWTH=10%)
ALTER DATABASE tempdb ADD FILE (NAME='tempdb4', FILENAME='F:\SQLTemp\tempdb4.ndf', SIZE=1GB, FILEGROWTH=10%)
 
--shrink db file (size in MB)
dbcc shrinkfile  (templog, 10000)
 
--if shrinking does not seem to have an effect:
SELECT name ,size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS AvailableSpaceInMB
FROM sys.database_files;
 
--** for system databases **
--using cmd shell, net stop MSSQLSERVER after modifying file
--then, move database file physically if not tempdb (no need to move tempdb file as it will be recreated when SQL server restarts)
!!net start SQLSERVERAGENT
!!net stop MSSQLSERVER
 
 !!net start MSSQLSERVER


--see database size, id, create date, status, etc.
sp_helpdb tempdb
 
--to create a new database with multiple filegroups:
CREATE DATABASE FilegroupTest
ON PRIMARY
(NAME = FGTest1_dat,
 FILENAME = 'C:Program FilesMicrosoft SQL ServerMSSQL10_50.MSSQLSERVERMSSQLDATAFGTest1_dat.mdf'),
FILEGROUP FGTestFG2
(NAME = FGTest2_dat,
 FILENAME = 'C:Program FilesMicrosoft SQL ServerMSSQL10_50.MSSQLSERVERMSSQLDATAFGTest2_dat.mdf')
LOG ON
(NAME = FGTest_log,
 FILENAME = 'C:Program FilesMicrosoft SQL ServerMSSQL10_50.MSSQLSERVERMSSQLDATAFGTest_log.ldf')
 
 
--to add a file to a database
ALTER DATABASE CC_ConsumerData ADD FILE (NAME='CC_ConsumerData', FILENAME='F:\CC_ConsumerData.ndf', SIZE=216MB, FILEGROWTH=10%)
 
 
--to add a new filegroup to an existing database:
ALTER DATABASE gpas_partition  ADD FILEGROUP test1fg;
GO
 
--to add a new file to a filegroup:
ALTER DATABASE gpas_partition ADD FILE (
       NAME = test1dat1,    FILENAME='G:\db_files\\test1dat1.ndf',   SIZE=80MB     )      TO FILEGROUP test1fg;
 
--to set a new default filegroup:
ALTER DATABASE gpas_partition MODIFY FILEGROUP test1fg DEFAULT;
 
 
--view filegroups in a database:
SELECT * FROM sys.filegroups;
SELECT *--file_id, name, physical_name AS CurrentLocation, state_desc, size*8./1024/1024 size_GB, growth
FROM sys.master_files
WHERE database_id = DB_ID(N'datamart') and name='MemoryOptimized';
 
 
--remove filegroup/files from a database:
ALTER DATABASE Datamart REMOVE FILE MemoryOptimized ;
ALTER DATABASE Datamart REMOVE FILEGROUP MemoryOptimized ;
 
--see what is in a filegroup:
SELECT groupid, name FROM dbo.sysindexes WHERE  groupid= 15
 
--unmark a filegroup if it cannot be removed
ALTER PARTITION SCHEME Datamart NEXT USED
--or empty the file:
DBCC SHRINKFILE (MemoryOptimized, EMPTYFILE);
 
--if emptyfile operation throws an error that there is insufficient space in the filegroup to remove it,
--most likely there is a table in that filegroup

--to create a table on a specified filegroup:
CREATE TABLE Orders2010 (OrderID INT NOT NULL, OrderDate DATETIME NOT NULL CONSTRAINT PKOrders2010 PRIMARY KEY CLUSTERED (OrderID)) ON FGFullFG3;
GO
 
--**************************to move a table to a different filegroup*******************************:
1.  Drop all nonclustered indexes on the table (they will be resorted and rebuilt when the clustered index is moved, if not dropped)
2.  Create the clustered index on the target filegroup with the DROP_EXISTING=ON option
3.  Recreate nonclustered indexes on their own filegroup if needed

For heap tables: create a clustered index for it on the target filegroup, then drop it
For primary key constraints & unique constraints:  2 options:
	1.  First drop the constraint, then build the clustered index, then build the constraint OR
	2.  CREATE UNIQUE CLUSTERED INDEX on the new filegroup, note the UNIQUE keyword  
		(This preserves the logical PK property despite it not being mentioned in the syntax)

If there are foreign keys referencing the primary key, those may be dropped then recreated if the DROP_EXISTING=ON option is not used
and the primary key index is first dropped then re-created

 
 
--check free space in the database:
SELECT DB_NAME() AS DbName,  name AS FileName, size/128.0/1024 AS CurrentSizeGB,  
size/128.0/1024 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0/1024 AS FreeSpaceGB
FROM sys.database_files;
 
select @@version
select * from sys.sysprocesses where spid>50
 
--see what filegroup a table is in
SELECT PA.object_id, FG.name 'filegroup_name' , index_id, data_compression_desc FROM sys.filegroups FG 
    INNER JOIN sys.allocation_units AU ON AU.data_space_id = FG.data_space_id
    INNER JOIN sys.partitions PA ON PA.partition_id = AU.container_id
WHERE PA.object_id =     (SELECT object_id(N'lkup_transaction'))
 
 
--set a filegroup as read-only:
ALTER DATABASE FilegroupFull SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
GO
ALTER DATABASE FilegroupFull MODIFY FILEGROUP FGFullFG4 READONLY;
GO
ALTER DATABASE FilegroupFull SET MULTI_USER;
GO
 
 
--***************************************************************
--see what is stored in each database filegroup:
SELECT o.[name], o.[type], i.[name], i.[index_id], f.[name]
FROM sys.indexes i
INNER JOIN sys.filegroups f
ON i.data_space_id = f.data_space_id
INNER JOIN sys.all_objects o
ON i.[object_id] = o.[object_id]
WHERE i.data_space_id = f.data_space_id
AND o.type = 'U' -- User Created Tables
AND f.name='MemoryOptimized'
GO
 
--see partitioned tables in a filegroup:
SELECT object_name(I.object_id) TableName FROM sys.filegroups FG 
    INNER JOIN sys.allocation_units AU ON AU.data_space_id = FG.data_space_id 
    INNER JOIN sys.partitions PA ON PA.partition_id = AU.container_id 
	INNER JOIN sys.indexes I on I.object_id=PA.object_id AND I.index_id=PA.index_id
WHERE FG.Name='DURMA4'


--to see physical location of table records:
--Physical RID: (file:page:slot)
SELECT sys.fn_PhysLocFormatter (%%physloc%%) AS [Physical RID], * FROM CC_Consumerdata.dbo.ConsumerData;
       GO
 
 
--see how fast or slow each file is:
SELECT db_name(mf.database_id) 'database', mf.physical_name   , num_of_reads --number of reads issued on the file
       , num_of_bytes_read --number of bytes read on this file      
       , io_stall_read_ms --total time (ms) users waited for reads issued on the file'
       , num_of_bytes_read/io_stall_read_ms 'ave_stall_read' --the bigger the better
       , num_of_writes --number of writes made on this file
       , num_of_bytes_written --total number of bytes written to the file
       , io_stall_write_ms --total time (ms) users waited for writes to be completed on the file
       , num_of_bytes_written/io_stall_write_ms 'ave_stall_write' --the bigger the better
       , io_stall  --total time (ms) that users waited for I/O to be completed on the file
       --, size_on_disk_bytes --Number of bytes used on the disk for this file. For sparse files, this number is the actual number of bytes on the disk that are used for database snapshots.
       ,getdate()
       FROM sys.dm_io_virtual_file_stats(null, null) divfs
       JOIN sys.master_files mf ON mf.database_id=divfs.database_id AND mf.file_id=divfs.file_id
       WHERE mf.database_id=db_id('Datamart')
       ORDER BY ave_stall_read
 
*/
 
 
 
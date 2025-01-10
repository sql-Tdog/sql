--check current database name and location
SELECT file_id, name, physical_name AS CurrentLocation, state_desc, size*8/1024./1024 size_GB, growth
FROM sys.master_files
WHERE database_id = DB_ID(N'tempdb');


--use dm_os_volume_stats to view more info about files
SELECT DISTINCT DB_NAME(v.database_id) DBName, v.database_id AS DatabaseID, v.file_id AS FileID, m.physical_name FilePath,
	size*8/1024./1024 size_GB, v.available_bytes/1024./1048576 AS Available_GB_on_Drive
FROM sys.master_files m CROSS APPLY sys.dm_os_volume_stats(m.database_id,m.FILE_ID) v ORDER BY DBName;



--check for free space in databases:
SELECT DB_NAME() AS DbName, name AS FileName, size/128.0 CurrentSizeMB, size/128.0/1024 AS CurrentSizeGB,  
size/128.0/1024 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0/1024 AS FreeSpaceGB 
FROM sys.database_files; 

--to move database files (including system databases), go to db_files_move.sql script


--see database size, id, create date, status, etc.
sp_helpdb tempdb

--add file to a database
ALTER DATABASE tempdb MODIFY FILE (NAME='tempdev',SIZE=86GB, MAXSIZE=86GB)
ALTER DATABASE tempdb MODIFY FILE (NAME='temp2', SIZE=86GB,MAXSIZE=86GB)
ALTER DATABASE tempdb MODIFY FILE (NAME='temp3',SIZE=86GB, MAXSIZE=86GB)
ALTER DATABASE tempdb MODIFY FILE (NAME='temp4', SIZE=86GB,MAXSIZE=86GB)
ALTER DATABASE tempdb MODIFY FILE (NAME='temp5',SIZE=86GB, MAXSIZE=86GB)
ALTER DATABASE tempdb MODIFY FILE (NAME='temp6',SIZE=86GB, MAXSIZE=86GB)
ALTER DATABASE tempdb MODIFY FILE (NAME='temp7',SIZE=86GB, MAXSIZE=86GB)
ALTER DATABASE tempdb MODIFY FILE (NAME='temp8',SIZE=86GB, MAXSIZE=86GB)

ALTER DATABASE tempdb ADD FILE (NAME='tempdev5', FILENAME='F:\tempdb5.ndf', SIZE=60GB, FILEGROWTH=10%)
ALTER DATABASE tempdb ADD FILE (NAME='tempdev6', FILENAME='F:\tempdb6.ndf', SIZE=60GB, FILEGROWTH=10%)
ALTER DATABASE tempdb ADD FILE (NAME='tempdev7', FILENAME='F:\tempdb7.ndf', SIZE=60GB, FILEGROWTH=10%)
ALTER DATABASE tempdb ADD FILE (NAME='tempdev8', FILENAME='F:\tempdb8.ndf', SIZE=60GB, FILEGROWTH=10%)

--modify database file size
ALTER DATABASE Datamart MODIFY FILE (NAME='Datamart1', SIZE=66560MB )
ALTER DATABASE Datamart MODIFY FILE (NAME='Datamart2', SIZE=66560MB )
ALTER DATABASE Datamart MODIFY FILE (NAME='Datamart3', SIZE=66560MB )
ALTER DATABASE Datamart MODIFY FILE (NAME='Datamart4', SIZE=66560MB )

--create a new filegroup
ALTER DATABASE gpas_partition ADD FILEGROUP test1fg;
GO

--add a new file to the new filegroup
ALTER DATABASE gpas_partition ADD FILE (
	NAME = test1dat1,
	FILENAME='G:\db_files\\test1dat1.ndf',
	SIZE=80MB
	)
	TO FILEGROUP test1fg;





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
GO


--to see physical location of table records:
--Physical RID: (file:page:slot)
SELECT sys.fn_PhysLocFormatter (%%physloc%%) AS [Physical RID], * FROM CC_Consumerdata.dbo.ConsumerData;
	GO


*/
/*
 --check current database name and location
SELECT file_id, name, physical_name AS CurrentLocation, state_desc, size*8/1024./1024 size_GB, growth
FROM sys.master_files
WHERE database_id = DB_ID(N'tempdb');

--check for free space in databases:
SELECT DB_NAME() AS DbName,  name AS FileName, size/128.0 CurrentSizeMB, size/128.0/1024 AS CurrentSizeGB,  
size/128.0/1024 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0/1024 AS FreeSpaceGB 
FROM sys.database_files; 

--to move database files (including system databases), go to db_files_move.sql script

--shrink:
DBCC SHRINKFILE ('DW_PBM_log', 200000)


--see database size, id, create date, status, etc.
sp_helpdb tempdb

--add file to a database
ALTER DATABASE tempdb MODIFY FILE (NAME='tempdev', SIZE=60GB)
ALTER DATABASE tempdb MODIFY FILE (NAME='tempdev2', SIZE=60GB)
ALTER DATABASE tempdb MODIFY FILE (NAME='tempdev3', SIZE=60GB)
ALTER DATABASE tempdb MODIFY FILE (NAME='tempdev4', SIZE=60GB)
ALTER DATABASE tempdb ADD FILE (NAME='tempdev5', FILENAME='F:\tempdb5.ndf', SIZE=60GB, FILEGROWTH=10%)
ALTER DATABASE tempdb ADD FILE (NAME='tempdev6', FILENAME='F:\tempdb6.ndf', SIZE=60GB, FILEGROWTH=10%)
ALTER DATABASE tempdb ADD FILE (NAME='tempdev7', FILENAME='F:\tempdb7.ndf', SIZE=60GB, FILEGROWTH=10%)
ALTER DATABASE tempdb ADD FILE (NAME='tempdev8', FILENAME='F:\tempdb8.ndf', SIZE=60GB, FILEGROWTH=10%)

--modify database file size
ALTER DATABASE Datamart MODIFY FILE (NAME='Datamart1', SIZE=66560MB )
ALTER DATABASE Datamart MODIFY FILE (NAME='Datamart2', SIZE=66560MB )
ALTER DATABASE Datamart MODIFY FILE (NAME='Datamart3', SIZE=66560MB )
ALTER DATABASE Datamart MODIFY FILE (NAME='Datamart4', SIZE=66560MB )

--create a new filegroup
ALTER DATABASE gpas_partition  ADD FILEGROUP test1fg;
GO

--add a new file to the new filegroup
ALTER DATABASE gpas_partition ADD FILE (
	NAME = test1dat1,
	FILENAME='G:\db_files\\test1dat1.ndf',
	SIZE=80MB
	)
	TO FILEGROUP test1fg;





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
GO


--to see physical location of table records:
--Physical RID: (file:page:slot)
SELECT sys.fn_PhysLocFormatter (%%physloc%%) AS [Physical RID], * FROM CC_Consumerdata.dbo.ConsumerData;
	GO


*/

/** for system databases **
--check how long tempdb has been up:
select * from sys.databases;

--check current database name and location
--size:  # of 8KB pages==> multiply by 8 to get KB
SELECT name, physical_name AS CurrentLocation, size*8/1024/1024. [Size (GB)], state_desc
FROM sys.master_files
WHERE database_id = DB_ID(N'tempdb');

--change files
--if resizing to a bigger size: file will be resized immediately
--if resizing to a smaller size: file will be resized upon service restart
 ALTER DATABASE tempdb MODIFY FILE ( NAME = tempdb1 , FILENAME = 'D:\TempDB\tempdb.mdf', SIZE=115GB, maxsize=115GB );
 ALTER DATABASE tempdb MODIFY FILE ( NAME = tempdb2 , FILENAME = 'G:\TempDB\tempdb2.mdf',SIZE=115GB, maxsize=115GB);
 ALTER DATABASE tempdb MODIFY FILE ( NAME = tempdb3 , FILENAME = 'G:\TempDB\tempdb3.mdf',SIZE=115GB, maxsize=115GB );
 ALTER DATABASE tempdb MODIFY FILE ( NAME = tempdb4 , FILENAME = 'H:\TempDB\tempdb4.mdf',SIZE=115GB, maxsize=115GB );


--if modifying an existing secondary file and filename does not exist, MSSQLSERVER will create a new file with a size of 0 but tempdb will reset to just 1 file
--then, the logical file names of the secondary files will need to be removed manually; otherwise they will persist in the sys.master_files table but not in the db properties dialogue
--if specified filename does not exist for primary file, it will be created upon service restart
ALTER DATABASE tempdb REMOVE FILE tempdev2;
ALTER DATABASE tempdb REMOVE FILE tempdev3;
ALTER DATABASE tempdb REMOVE FILE tempdev4;


--add files:
--when adding new files, SQL Server will create, initialize and begin using those files immediately
ALTER DATABASE tempdb ADD FILE (NAME='tempdb5', FILENAME='F:\SQLTemp\tempdb5.ndf', SIZE=45GB, FILEGROWTH=10%)
ALTER DATABASE tempdb ADD FILE (NAME='tempdb6', FILENAME='F:\SQLTemp\tempdb6.ndf', SIZE=45GB, FILEGROWTH=10%)
ALTER DATABASE tempdb ADD FILE (NAME='tempdb7', FILENAME='F:\SQLTemp\tempdb7.ndf', SIZE=45GB, FILEGROWTH=10%)
ALTER DATABASE tempdb ADD FILE (NAME='tempdb8', FILENAME='F:\SQLTemp\tempdb8.ndf', SIZE=45GB, FILEGROWTH=10%)

ALTER DATABASE tempdb ADD FILE (NAME='tempdb2', FILENAME='E:\SQLData\tempdb2.ndf', SIZE=2GB, FILEGROWTH=10%)
ALTER DATABASE tempdb ADD FILE (NAME='tempdb3', FILENAME='E:\SQLData\tempdb3.ndf', SIZE=2GB, FILEGROWTH=10%)
ALTER DATABASE tempdb ADD FILE (NAME='tempdb4', FILENAME='E:\SQLData\tempdb4.ndf', SIZE=2GB, FILEGROWTH=10%)


--prfsql
ALTER DATABASE tempdb ADD FILE (NAME='tempdb2', FILENAME='E:\SQLData\Data\tempdb2.ndf', SIZE=2GB, FILEGROWTH=10%)
ALTER DATABASE tempdb ADD FILE (NAME='tempdb3', FILENAME='E:\SQLData\Data\tempdb3.ndf', SIZE=2GB, FILEGROWTH=10%)
ALTER DATABASE tempdb ADD FILE (NAME='tempdb4', FILENAME='E:\SQLData\Data\tempdb4.ndf', SIZE=2GB, FILEGROWTH=10%)
ALTER DATABASE tempdb MODIFY FILE ( NAME = tempdev , SIZE=2GB );

**/

--see database size, id, create date, status, etc.
sp_helpdb tempdb
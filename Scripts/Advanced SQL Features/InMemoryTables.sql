--to create memory optimized tables, we need to first add a memory optimized filegroup to the database
USE master
GO

ALTER DATABASE Datamart ADD FILEGROUP Datamart_MOD CONTAINS MEMORY_OPTIMIZED_DATA;
GO
ALTER DATABASE Datamart ADD FILE (NAME='Datamart_MOD',FILENAME='D:\SQLData\Datamart_MOD.ndf', SIZE=2GB) TO FILEGROUP Datamart_MOD;
GO
--now create a memory optimized table:
USE Datamart
GO
CREATE TABLE dbo.MODtest (...)
	WITH (MEMORY_OPTIMIZED=ON, DURABILITY=SCHEMA_AND_DATA);
GO

--Durability options:
--SCHEMA_AND_DATA (default): This option ensures that data is recovered to the Memory-Optimized table when SQL Server is restarted, or is recovering from a crash.
--SCHEMA_ONLY: Like Tempdb data, the SCHEMA_ONLY bound Memory-Optimized table will be truncated if/when SQL Server is restarted or is recovering from a crash,
-- but unlike the tables in Tempdb, the Memory-Optimized table will be re-created as a blank table at the end of the restart/recovery operation.

--drop a file:
ALTER DATABASE Datamart REMOVE FILE Datamart_MOD
--change file size, The properties SIZE or FILEGROWTH cannot be specified for the FILESTREAM data file:
ALTER DATABASE Datamart MODIFY FILE (NAME='Datamart_MOD', SIZE=1GB )
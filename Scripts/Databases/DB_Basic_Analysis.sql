/*****view recovery model setting of all user databases********************************************
select database_id, name, create_date, user_access_desc, recovery_model_desc
from sys.databases where database_id>4;


--are any databases owned by a user other than sa
SELECT name, suser_sname(owner_sid),owner_sid FROM sys.databases where owner_sid<>0x01;

--*********************are any databases read_only?************************************************
IF EXISTS (select database_id from sys.databases where is_read_only<>0)
select database_id, name, is_read_only from sys.databases where is_read_only<>0;


--********************any databases have auto close ON?********************************************
IF EXISTS (select database_id from sys.databases where is_auto_close_on<>0
) select database_id, name, is_auto_close_on from sys.databases where is_auto_close_on<>0;


--********************any database have auto shrink ON?********************************************
IF EXISTS (select database_id from sys.databases where is_auto_shrink_on<>0
) select database_id, name, is_auto_shrink_on from sys.databases where is_auto_shrink_on<>0;


--********************are any encrypted?***********************************************************
IF EXISTS (select database_id from sys.databases where is_encrypted<>0
) select database_id, name, is_encrypted from sys.databases where is_encrypted<>0;


--****get database sizes and file locations***********************************************************************************
SELECT 'DB_NAME' = db.name, sum(size*8/1024./1024) [Size (GB)]
FROM sys.databases db INNER JOIN sys.master_files mf ON db.database_id = mf.database_id
GROUP BY db.name

SELECT 'DB_NAME' = db.name, compatibility_level, recovery_model_desc, size*8/1024./1024 [Size (GB)], 'FILE_NAME' = mf.name, 'FILE_TYPE' = mf.type_desc, 
'FILE_PATH' = mf.physical_name  FROM sys.databases db INNER JOIN sys.master_files mf ON db.database_id = mf.database_id
WHERE db.state = 6 -- OFFLINE

--**********is the query store turned on?**********applies to SQL 2016+*******************************************************
SELECT  desired_state_desc , actual_state_desc , readonly_reason, current_storage_size_mb , max_storage_size_mb , max_plans_per_query 
FROM    sys.database_query_store_options ;


--********where are the backups being written to and when was the last full backup taken?************************************************************
select name 'database_name', backup_finish_date 'last_backup_date', [type], backup_size, backup_size/compressed_backup_size'compression_ratio'
	, physical_device_name
FROM sys.databases d
OUTER APPLY (SELECT TOP 1 database_name, server_name, backup_finish_date, [type], backup_size, media_set_id,compressed_backup_size FROM msdb.dbo.backupset 
	WHERE database_name=d.name AND [type]='D' ORDER BY backup_finish_date DESC) B
LEFT JOIN msdb.dbo.backupmediafamily AS F ON F.media_set_id = B.media_set_id
where database_id<>2

*****************************/

/***********transaction log size check*******************************************************************************************************
***for databases in SIMPLE recovery mode, take a look at their transaction log size and % being used and if it ever was backed up*************
CREATE TABLE #logspace_utilization (
   Database_Name VARCHAR(50),
   [Log_Size (MB)] DECIMAL(20,5),
   Log_Space_Used DECIMAL(20,5),
   [Status] INT)
 
INSERT #logspace_utilization EXEC('DBCC SQLPERF(logspace) ')
GO
WITH CTE AS (
select d.name database_name, backup_finish_date 'last_transaction_log_backup', backup_size, physical_device_name
FROM sys.databases d
OUTER APPLY (SELECT TOP 1 database_name, server_name, backup_finish_date, [type], backup_size, media_set_id FROM msdb.dbo.backupset 
	WHERE database_name=d.name AND [type]='L' ORDER BY backup_finish_date DESC) B
LEFT JOIN msdb.dbo.backupmediafamily AS F ON F.media_set_id = B.media_set_id
WHERE recovery_model_desc='SIMPLE'
)
SELECT *
FROM CTE
INNER JOIN #logspace_utilization l ON l.database_name=cte.database_name
WHERE Log_Space_Used<50 AND [Log_Size (MB)] >100

DROP TABLE #logspace_utilization

*/

/**********when was the last transaction log backup taken of each database in FULL recovery mode?*********************************************
**********also, check log size for databases with no transaction log backups******************************************************************

CREATE TABLE #logspace_utilization (
   Database_Name VARCHAR(50),
   [Log_Size (MB)]  DECIMAL(20,5),
   Log_Space_Used DECIMAL(20,5),
   [Status] INT)
 
INSERT #logspace_utilization EXEC('DBCC SQLPERF(logspace) ')
GO
WITH CTE AS (
select d.name database_name, backup_finish_date 'last_transaction_log_backup', backup_size, physical_device_name
FROM sys.databases d
OUTER APPLY (SELECT TOP 1 database_name, server_name, backup_finish_date, [type], backup_size, media_set_id FROM msdb.dbo.backupset 
	WHERE database_name=d.name AND [type]='L' ORDER BY backup_finish_date DESC) B
LEFT JOIN msdb.dbo.backupmediafamily AS F ON F.media_set_id = B.media_set_id
WHERE recovery_model_desc='FULL'
)
SELECT *
FROM CTE
INNER JOIN #logspace_utilization l ON l.database_name=cte.database_name

DROP TABLE #logspace_utilization

*/


/***check when statistics were last udpated:
SELECT o.name TableName, s.name AS Stats,

STATS_DATE(s.object_id, stats_id) AS LastStatsUpdate

FROM sys.stats s
inner join sys.objects o on o.object_id=s.object_id
order by LastStatsUpdate desc


SELECT name AS index_name,
STATS_DATE(object_id, index_id) AS statistics_update_date
FROM sys.indexes
WHERE object_id = 142623551;
GO

**/

/*
Indexes in all databases with their usage
declare @SQL nvarchar(max)
if object_id('tempdb..#Result','U') IS not NULL
 drop table #Result
create table #Result (DBName sysname, TableName Sysname, IndexName sysname, Usage bigint)
 
select @SQL = coalesce(@SQL,'') + CHAR(13) + CHAR(10) + ' use ' + QUOTENAME([Name]) + ';
insert into #Result select ' + quotename([Name],'''') + ' as DbName, 
object_name(i.object_id) as tablename,  i.name as indexname, 
s.user_seeks + s.user_scans + s.user_lookups + s.user_updates as usage
from sys.indexes i   
inner join sys.dm_db_index_usage_stats s        
on s.object_id = i.object_id                    
and s.index_id = i.index_id              
and s.database_id = db_id()
where objectproperty(i.object_id, ''IsUserTable'') = 1   
and i.index_id > 0 
order by usage;' from sys.databases 
--print (@SQL)
execute (@SQL)
select * from #Result order by [DbName],[Usage]
drop table #Result


Indexes in all databases with their physical stats
declare @SQL nvarchar(max)
set @SQL = ''
select @SQL = @SQL +
'Select ' + quotename(name,'''') + ' as [DB Name], 
object_Name(PS.Object_ID,' + convert(varchar(10),database_id) + ') as [Object],
I.Name as [Index Name], PS.Partition_Number, PS.Index_Type_Desc, 
PS.alloc_unit_type_desc,    PS.index_depth, PS.index_level,
PS.avg_fragmentation_in_percent,    PS.fragment_count,  PS.avg_fragment_size_in_pages,
PS.page_count,  PS.avg_page_space_used_in_percent,  PS.record_count,    
PS.ghost_record_count,  PS.version_ghost_record_count,
PS.min_record_size_in_bytes,    PS.max_record_size_in_bytes,    PS.avg_record_size_in_bytes,
PS.forwarded_record_count,  PS.compressed_page_count
 from ' + quotename(name) + '.sys.dm_db_index_physical_stats(' + 
convert(varchar(10),database_id) + ', NULL, NULL, NULL, NULL) PS 
INNER JOIN ' + quotename(name) + 
'.sys.Indexes I on PS.Object_ID = I.Object_ID and PS.Index_ID = I.Index_ID ' 
+ CHAR(13)
 
 from sys.databases where state_desc = 'ONLINE'
 
execute(@SQL)

Count of all objects in all databases
declare @Qry nvarchar(max) 
select @Qry = coalesce(@Qry + char(13) + char(10) + ' UNION ALL ','') + '
select ' + quotename([Name],'''') + ' as DBName, [AGGREGATE_FUNCTION], [CHECK_CONSTRAINT],[DEFAULT_CONSTRAINT], 
[FOREIGN_KEY_CONSTRAINT],
[SQL_SCALAR_FUNCTION], 
[CLR_SCALAR_FUNCTION], 
[CLR_TABLE_VALUED_FUNCTION], 
[SQL_INLINE_TABLE_VALUED_FUNCTION], 
[INTERNAL_TABLE],[SQL_STORED_PROCEDURE],[CLR_STORED_PROCEDURE],[PLAN_GUIDE],[PRIMARY_KEY_CONSTRAINT],
[RULE],[REPLICATION_FILTER_PROCEDURE],[SYNONYM],[SERVICE_QUEUE],[CLR_TRIGGER],[SQL_TABLE_VALUED_FUNCTION],[SQL_TRIGGER],
[TABLE_TYPE],[USER_TABLE],[UNIQUE_CONSTRAINT],[VIEW],[EXTENDED_STORED_PROCEDURE] 
from (select [Name], type_Desc from ' + quotename([Name]) + '.sys.objects where is_ms_shipped = 0) src 
PIVOT (count([Name]) FOR type_desc in ([AGGREGATE_FUNCTION], [CHECK_CONSTRAINT],[DEFAULT_CONSTRAINT], 
[FOREIGN_KEY_CONSTRAINT], 
[SQL_SCALAR_FUNCTION], 
[CLR_SCALAR_FUNCTION], 
[CLR_TABLE_VALUED_FUNCTION], 
[SQL_INLINE_TABLE_VALUED_FUNCTION], 
[INTERNAL_TABLE],[SQL_STORED_PROCEDURE],[CLR_STORED_PROCEDURE],[PLAN_GUIDE],[PRIMARY_KEY_CONSTRAINT],
[RULE],[REPLICATION_FILTER_PROCEDURE],[SYNONYM],[SERVICE_QUEUE],[CLR_TRIGGER],[SQL_TABLE_VALUED_FUNCTION],[SQL_TRIGGER],
[TABLE_TYPE],[USER_TABLE],[UNIQUE_CONSTRAINT],[VIEW],[EXTENDED_STORED_PROCEDURE])) pvt' from sys.databases 
where [name] NOT IN ('master','tempdb','model','msdb') order by [Name]
 execute(@Qry)

Record Count in every table in a database
DECLARE  @DynamicSQL NVARCHAR(MAX)
 
SELECT   @DynamicSQL = COALESCE(@DynamicSQL + CHAR(13) + ' UNION ALL ' + CHAR(13),
                                '') + 
                                'SELECT ' + quotename(table_schema,'''') + ' as [Schema Name], ' +
                                QUOTENAME(TABLE_NAME,'''') + 
                                ' as [Table Name], COUNT(*) AS [Records Count] FROM ' + 
                                quotename(Table_schema) + '.' + QUOTENAME(TABLE_NAME)
FROM     INFORMATION_SCHEMA.TABLES
ORDER BY TABLE_NAME
 
--print (@DynamicSQL) -- we may want to use PRINT to debug the SQL
EXEC( @DynamicSQL)



Quick Record Count in All Tables in All Databases
declare @SQL nvarchar(max)
 
set @SQL = ''
--select * from sys.databases 
select @SQL = @SQL + CHAR(13) + 'USE ' + QUOTENAME([name]) + ';
SELECT ' +quotename([name],'''') + 'as [Database Name], 
   SchemaName=s.name
  ,TableName=t.name
  ,CreateDate=t.create_date
  ,ModifyDate=t.modify_date
  ,p.rows
  ,DataInKB=sum(a.used_pages)*8
FROM sys.schemas s
JOIN sys.tables t on s.schema_id=t.schema_id
JOIN sys.partitions p on t.object_id=p.object_id
JOIN sys.allocation_units a on a.container_id=p.partition_id
GROUP BY s.name, t.name, t.create_date, t.modify_date, p.rows
ORDER BY SchemaName, TableName' from sys.databases  
 
execute (@SQL)    

Quick Record Count in All Tables in All Databases
declare @SQL nvarchar(max)
 
set @SQL = ''
--select * from sys.databases 
select @SQL = @SQL + CHAR(13) + 'USE ' + QUOTENAME([name]) + ';
SELECT ' +quotename([name],'''') + 'as [Database Name], so.name AS [Table Name],   
    rows AS [RowCount]   
FROM sysindexes AS si   
    join sysobjects AS so on si.id = so.id   
WHERE indid IN (0,1)   
    AND xtype = ''U''' from sys.databases  
 
Sizes of All Tables in a Database
--exec sp_MSforeachtable 'print ''?'' exec sp_spaceused ''?'''
if OBJECT_ID('tempdb..#TablesSizes') IS NOT NULL
   drop table #TablesSizes
   
create table #TablesSizes (TableName sysname, Rows bigint, reserved varchar(100), data varchar(100), index_size varchar(100), unused varchar(100))
 
declare @sql varchar(max)
select @sql = coalesce(@sql,'') + '
insert into #TablesSizes execute sp_spaceused ' + QUOTENAME(Table_Name,'''') from INFORMATION_SCHEMA.TABLES
 
--print (@SQL)
execute (@SQL)
 
select * from #TablesSizes order by TableName

Database Files Sizes in All Databases
create  table #FileSizes (DBName sysname, [File Name] varchar(max), [Physical Name] varchar(max),
Size decimal(12,2))
declare @SQL nvarchar(max)
set @SQL = ''
select @SQL = @SQL + 'USE'  + QUOTENAME(name) + '
insert into #FileSizes
select ' + QUOTENAME(name,'''') + ', Name, Physical_Name, size/1024.0 from sys.database_files ' 
from sys.databases
 
execute (@SQL)
select * from #FileSizes order by DBName, [File Name]

declare @Sql varchar(max)
select @SQL =coalesce(@SQL + char(13) + 'UNION ALL 
' ,'') + 'SELECT ''' + name + ''' AS DBNAME,' + 
'sum(size * 8 /1024.0) AS MB from ' + quotename(name) + '.dbo.sysfiles' 
from sys.databases
order by name
 
execute (@SQL)


Database Files Sizes in All Databases and used space
Note, that this script assumes that database files have the same name as the database itself. If this is not true, this script will not return correct result.

create table #Test (DbName sysname, TotalSize decimal(20,2), Used decimal(20,2), [free space percentage] decimal(20,2))
 
declare @SQL nvarchar(max)
select @SQL = coalesce(@SQL,'') + 
'USE ' + QUOTENAME(Name) + '
insert into #Test
select DB.name, ssf.size*8 as total, 
FILEPROPERTY (AF.name, ''spaceused'')*8 as used, 
((ssf.size*8) - (FILEPROPERTY (AF.name, ''spaceused'')*8))*100/(ssf.size*8) as [free space percentage]
from sys.sysALTfiles AF 
inner join sys.sysfiles ssf on ssf.name=AF.name COLLATE SQL_Latin1_General_CP1_CI_AS
INNER JOIN sys.databases DB ON AF.dbid=DB.database_id 
where ssf.groupid<>1' from sys.databases
 
execute(@SQL)
 
select * from #Test order by DbName 
This script will backup all databases (using compression):

Backup All Databases with Compression (SQL 2008)
Declare @ToExecute VarChar(8000)
 
Select @ToExecute = Coalesce(@ToExecute + 'Backup Database ' + quotename([Name]) + 
' To Disk = ''C:SQL DB BackupsAll DBs' + [Name] + '.bak'' 
WITH NOFORMAT, NOINIT,  
 SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10' + char(13),'')
 
From sys.databases
 
Where [Name] Not In ('tempdb') and databasepropertyex ([Name],'Status') = 'online'
 
Execute (@ToExecute)
 
--print @ToExecute


All Schema Names in All Databases
declare @Sql nvarchar(max)
create table AllDBSchemas ([DB Name] sysname, [Schema Name] sysname)
 
select @Sql = coalesce(@Sql,'') + '
insert into AllDBSchemas
 
select ' + QUOTENAME(name,'''') + ' as [DB Name], [Name] as [Schema Name] from ' + 
QUOTENAME(Name) + '.sys.schemas order by [DB Name],[Name];' from sys.databases
order by name
 
execute(@SQL)
 
select * from AllDBSchemas order by [DB Name],[SCHEMA NAME]  

List of All Tables in All Databases
CREATE TABLE AllTables ([DB Name] sysname, [Schema Name] sysname, [Table Name] sysname)
 
DECLARE @SQL NVARCHAR(MAX)
 
SELECT @SQL = COALESCE(@SQL,'') + '
insert into AllTables
 
select ' + QUOTENAME(name,'''') + ' as [DB Name], [Table_Schema] as [Table Schema], [Table_Name] as [Table Name] from ' +
QUOTENAME(Name) + '.INFORMATION_SCHEMA.Tables;' FROM sys.databases
ORDER BY name
 
EXECUTE(@SQL)
 
SELECT * FROM AllTables ORDER BY [DB Name],[SCHEMA NAME], [Table Name]
Alternative way to get all tables in all databases:

List of All Tables in All Databases
if object_ID('TempDB..#AllTables','U') IS NOT NULL drop table #AllTables
CREATE TABLE #AllTables ([DB Name] sysname, [Schema Name] nvarchar(128) NULL, [Table Name] sysname, create_date datetime, modify_date datetime)
 
DECLARE @SQL NVARCHAR(MAX)
 
SELECT @SQL = COALESCE(@SQL,'') + 'USE ' + quotename(name) + '
insert into #AllTables 
select ' + QUOTENAME(name,'''') + ' as [DB Name], schema_name(schema_id) as [Table Schema], [Name] as [Table Name], Create_Date, Modify_Date
 from ' +
QUOTENAME(Name) + '.sys.Tables;' FROM sys.databases
ORDER BY name
--print @SQL 
EXECUTE(@SQL)
List of all Stored Procedures in All Databases
T-SQL
create table #SPList ([DB Name] sysname, [SP Name] sysname, create_date datetime, modify_date datetime)
 
declare @SQL nvarchar(max)
set @SQL = ''
select @SQL = @SQL + ' insert into #SPList 
select ' + QUOTENAME(name, '''') + ', name, create_date, modify_date
from ' + QUOTENAME(name) + '.sys.procedures' from sys.databases
 
execute (@SQL)
 
select * from #SPList order by [DB Name], [SP Name]


Database Files Growth

--select * from sys.sysfiles  
 
declare @SQL nvarchar(max)
select @SQL = coalesce(@SQL + '
UNION ALL ','') + 
 
'SELECT CONVERT(varchar(100),
SERVERPROPERTY(''Servername'')) AS Server, ' + 
quotename(name,'''') +'  as DatabaseName,
    CAST(name as varchar(128)) COLLATE SQL_Latin1_General_CP1_CI_AS as name,
    CAST(filename as varchar(128)) COLLATE SQL_Latin1_General_CP1_CI_AS as FileName,
    Autogrowth = ''Autogrowth: ''
        +
        CASE
            WHEN (status & 0x100000 = 0 AND CEILING((growth * 8192.0) / (1024.0 * 1024.0)) = 0.00) OR growth = 0 THEN ''None''
            WHEN status & 0x100000 = 0 THEN ''By '' + 
            CONVERT(VARCHAR,CEILING((growth * 8192.0) / (1024.0 * 1024.0))) + '' MB''
            ELSE ''By '' + CONVERT(VARCHAR,growth) + '' percent''
        END
        +
        CASE
            WHEN (status & 0x100000 = 0 AND CEILING((growth * 8192.0) / (1024.0 * 1024.0)) = 0.00) OR growth = 0 THEN ''''
            WHEN CAST([maxsize] * 8.0 / 1024 AS DEC(20,2)) <= 0.00 THEN '', unrestricted growth''
            ELSE '', restricted growth to '' + CAST(CAST([maxsize] * 8.0 / 1024 AS DEC(20)) AS VARCHAR) + '' MB''
        END
FROM '  + quotename(name) + '.sys.sysfiles  s'
from sys.databases
 
set @SQL = @SQL + ' 
ORDER BY DatabaseName'
 
print @SQL
 
execute(@SQL)
*/
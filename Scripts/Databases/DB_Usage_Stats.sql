EXEC sp_spaceused; 

--check white space in each file of database:
SELECT DB_NAME() AS DbName, 
name AS FileName, 
size/128.0 AS CurrentSizeMB, 
size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeSpaceMB 
FROM sys.database_files; 


/**

--check when database was accessed last:
USE NavigatorsGrant03212014;
GO

SET ANSI_WARNINGS OFF;
SET NOCOUNT ON;
GO

WITH agg AS
(
    SELECT
        last_user_seek,
        last_user_scan,
        last_user_lookup,
        last_user_update
    FROM
        sys.dm_db_index_usage_stats
    WHERE
        database_id = DB_ID()
)
SELECT
    last_read = MAX(last_read),
    last_write = MAX(last_write)
FROM
(
    SELECT last_user_seek, NULL FROM agg
    UNION ALL
    SELECT last_user_scan, NULL FROM agg
    UNION ALL
    SELECT last_user_lookup, NULL FROM agg
    UNION ALL
    SELECT NULL, last_user_update FROM agg
) AS x (last_read, last_write);

*/
/**select the last object that was updated or scanned last: */

    SELECT TOP 10 o.name, o.type_desc, last_user_seek, last_user_scan, last_user_lookup, last_user_update
    FROM sys.dm_db_index_usage_stats s
	INNER JOIN sys.objects O ON O.object_id=s.object_id
    WHERE database_id = DB_ID()
	ORDER BY last_user_update DESC, COALESCE(last_user_seek, last_user_scan) DESC

/**script to check database objects and usage

--check what objects take up most space in a certain database
--to check sizes of objects and the filegroups they are on, go to db_files_filegroups script

SELECT object_name(i.object_id) as objectName, i.[name] as indexName, sum(a.total_pages) as totalPages,
	sum(a.used_pages) as usedPages, sum(a.data_pages) as dataPages, (sum(a.total_pages) * 8) /1024./1024 as totalSpace_GB,
	(sum(a.used_pages) * 8) /1024./1024 as usedSpace_GB, (sum(a.data_pages) * 8) /1024./1024 as dataSpace_GB
FROM sys.indexes i 
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
GROUP BY i.object_id, i.index_id, i.[name]
ORDER BY sum(a.total_pages) DESC, object_name(i.object_id)
GO

--group object sizes by table name (indexes in a table grouped together)
SELECT object_name(i.object_id) as objectName,
sum(a.total_pages) as totalPages,
sum(a.used_pages) as usedPages,
sum(a.data_pages) as dataPages,
(sum(a.total_pages) * 8) /1024./1024 as totalSpace_GB,
(sum(a.used_pages) * 8) /1024./1024 as usedSpace_GB,
(sum(a.data_pages) * 8) /1024./1024 as dataSpace_GB
FROM sys.indexes i
INNER JOIN sys.partitions p
ON i.object_id = p.object_id
AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a
ON p.partition_id = a.container_id
GROUP BY i.object_id
ORDER BY sum(a.total_pages) DESC, object_name(i.object_id)
GO

**/
/**
--check how often stored procedures are executed in all databases
SELECT 
 DB_NAME(database_id) 'database'
 , OBJECT_NAME(object_id, database_id) 'proc name'
--, ps.object_id
, ps.execution_count AS 'Execution Count'
, ps.total_worker_time/ps.execution_count AS 'AvgWorkerTime'
, ps.total_worker_time AS 'TotalWorkerTime'
, ps.total_physical_reads AS 'PhysicalReads'
, ps.cached_time 'Time Added to Cache'
, ps.last_execution_time AS 'Last Execution'
FROM sys.dm_exec_procedure_stats ps
WHERE database_id=DB_ID('Datamart')--OBJECT_NAME(object_id, database_id) LIKE 'usp%' 
order by execution_count desc

**/
/**
--select most expensive non-ad hoc queries
INSERT INTO DBAWork.dbo.MostExpensiveNonAdHoc
SELECT TOP 50 total_worker_time/execution_count AS [Avg CPU Time]
	, db_name(st.dbid) 'database' --null for ad hoc and preprared sql statements
	, object_name(st.objectid,st.dbid) 'object'--null for ad hoc and prepared sql statements
   , SUBSTRING(st.text, (qs.statement_start_offset/2)+1, 
        ((CASE qs.statement_end_offset
          WHEN -1 THEN DATALENGTH(st.text)
         ELSE qs.statement_end_offset
         END - qs.statement_start_offset)/2) + 1) AS statement_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
WHERE st.dbid is not null
ORDER BY total_worker_time/execution_count DESC;

select * from DBAWork.dbo.MostExpensiveNonAdHoc where [database]='ipas'
order by datechecked desc, [avg cpu time] desc

select getdate()

**/

/**
--select most often non-ad hoc executed queries
INSERT INTO DBAWork.dbo.ExpensiveQueries
SELECT db_name(st.dbid) 'database'
	, object_name(st.objectid,st.dbid) 'object'--null for ad hoc and prepared sql statements
	, execution_count
	,last_worker_time
	,last_execution_time
	,total_worker_time/execution_count 'ave_execution_time'
	,total_elapsed_time
	,getdate()
FROM  sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
WHERE db_name(st.dbid) is not null --and object_name(st.objectid,st.dbid) not like '%audit%'
ORDER BY ave_execution_time desc
**/

/**see how often views are pulled 

    SELECT S.[name] AS [Name], S.type,
		SUM(IUS.user_lookups + IUS.user_scans + IUS.user_seeks) AS [Reads],
		SUM(IUS.user_updates) AS [Updates]
    FROM sys.dm_db_index_usage_stats IUS
    INNER JOIN sys.objects S ON S.object_id = IUS.object_id
  --  WHERE --s.name like 'fn%'--v%'	 S.type = 'U' -- V = Views, U = User Tables...
    GROUP BY [Name], [Type] ORDER BY Reads DESC;

**/

/****
Return a row for each object that is a SQL language-defined module in SQL Server

select db_name(database_id) 'database', * from sys.dm_db_index_usage_stats order by last_user_scan desc

select db_name(database_id) 'database', count(last_user_scan) Scans, count(last_user_seek) seeks, count(last_user_update) Updates  from sys.dm_db_index_usage_stats 
WHERE last_user_scan IS NOT NULL OR last_user_seek IS NOT NULL OR last_user_update IS NOT NULL
group by database_id 

***/

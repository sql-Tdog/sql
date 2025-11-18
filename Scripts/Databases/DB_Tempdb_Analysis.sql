/**perform tempdb analysis
--!!!!!!!!!!!!Remember:  tempdb is located on disk, not in RAM!!!!!!!!!!!!!!!
--check how many CPUs a particular instance of SQL Server can see,
--recommend 1 tempdb files per system processor if cpu_count<=8:
select cpu_count from sys.dm_os_sys_info
 
--**if CPU affinity is being used to assign specific CPUs to SQL server, cpu_id column will always be less than 255
--find out how many CPUs a particular instance is actually using
select scheduler_id,cpu_id, status, is_online from sys.dm_os_schedulers where status='VISIBLE ONLINE'
 
--****************** IO bottlenecks********************************:
--check read & write latencies:
use tempdb
go
--write/read stall over 40ms is bad....
SELECT files.physical_name, files.name,   stats.num_of_writes, (1.0 * stats.io_stall_write_ms / stats.num_of_writes) AS avg_write_stall_ms,
  stats.num_of_reads, (1.0 * stats.io_stall_read_ms / stats.num_of_reads) AS avg_read_stall_ms
FROM sys.dm_io_virtual_file_stats(2, NULL) as stats INNER JOIN master.sys.master_files AS files
  ON stats.database_id = files.database_id  AND stats.file_id = files.file_id
 
 
--** check for memory pressure using performance monitor counters:
--**  SQLServer:Buffer Manager:  Buffer Cache Hit Ratio, Free list stalls/sec, Free pages, Page life expectancy, Page reads/sec
--** BCHR:  if high: server is efficiently caching the data pages in memory, reads from disk are relatively low (>95% for OLTP systems, >90% for OLAT and data warehouse systems)
 
 --get details on how memory is being used:
 DBCC MEMORYSTATUS
 
--see if any logs are full:
select name, log_reuse_wait_desc from sys.databases;
 
--what is the recovery interval set to?:
EXEC sp_configure 'recovery interval', 30;
GO
RECONFIGURE;
 
 
--get memory counters from DMV
SELECT * FROM sys.dm_os_performance_counters WHERE object_name like '%Memory%'
 
--get amount of free space:
USE tempdb
GO
SELECT SUM(unallocated_extent_page_count) AS [free pages],
(SUM(unallocated_extent_page_count)*1.0/128/1024) AS [free space in GB]
FROM sys.dm_db_file_space_usage;
 
--get active transactions:
SELECT *
FROM sys.dm_tran_active_snapshot_database_transactions
ORDER BY elapsed_time_seconds DESC;
 
--get amount of user objects in tempdb:
SELECT SUM(user_object_reserved_page_count) AS [user object pages used],
(SUM(user_object_reserved_page_count)*1.0/128) AS [user object space in MB]
FROM sys.dm_db_file_space_usage;
 
 
--get # of pages allocated internally for internal objects
select sum(internal_objects_alloc_page_count*8/1024./1024) internal_objects_alloc_page_count_GB, sum(user_objects_alloc_page_count*8/1024./1024) user_objects_alloc_page_count_GB
from sys.dm_db_session_space_usage where database_id=2;
 
 
--page is 8KB
 
select 8680*8/1024./1024 [gb]
--VAS Reservation memory view:  special contiguous memory area for use by external consumers and for allocations
--larger than 8KB (extremely large and complex query plans)
 
 
    WITH VASummary(Size,Reserved,Free) AS
    (SELECT
        Size = VaDump.Size,
        Reserved =  SUM(CASE(CONVERT(INT, VaDump.Base)^0)
        WHEN 0 THEN 0 ELSE 1 END),
        Free = SUM(CASE(CONVERT(INT, VaDump.Base)^0)
        WHEN 0 THEN 1 ELSE 0 END)
    FROM
    (
        SELECT  CONVERT(VARBINARY, SUM(region_size_in_bytes))
        AS Size, region_allocation_base_address AS Base
        FROM sys.dm_os_virtual_address_dump
        WHERE region_allocation_base_address <> 0x0
        GROUP BY region_allocation_base_address
     UNION 
        SELECT CONVERT(VARBINARY, region_size_in_bytes), region_allocation_base_address
        FROM sys.dm_os_virtual_address_dump
        WHERE region_allocation_base_address  = 0x0
    )
    AS VaDump
    GROUP BY Size)
 
    SELECT SUM(CONVERT(BIGINT,Size)*Free)/1024 AS [Total avail mem, KB] ,CAST(MAX(Size) AS BIGINT)/1024 AS [Max free size, KB]
    FROM VASummary
    WHERE Free <> 0
 
       select 8559800276-8551693184
 
 
      
    SELECT type, virtual_memory_committed_kb, multi_pages_kb
    FROM sys.dm_os_memory_clerks
    WHERE virtual_memory_committed_kb > 0 OR multi_pages_kb > 0
 
select
    type,
    sum(virtual_memory_reserved_kb) as [VM Reserved],
    sum(virtual_memory_committed_kb) as [VM Committed],
    sum(awe_allocated_kb) as [AWE Allocated],
    sum(shared_memory_reserved_kb) as [SM Reserved],
    sum(shared_memory_committed_kb) as [SM Committed],
    sum(multi_pages_kb) as [MultiPage Allocator],
    sum(single_pages_kb) as [SinlgePage Allocator]
from sys.dm_os_memory_clerks
group by type
order by 8 desc
 
select * from sys.dm_os_memory_clerks
where virtual_memory_committed_kb>=virtual_memory_reserved_kb and virtual_memory_reserved_kb!=0
 
--Queries Waiting For Memory
 
select text, query_plan
, requested_memory_kb
, granted_memory_kb
, used_memory_kb
 from sys.dm_exec_query_memory_grants MG
 CROSS APPLY sys.dm_exec_sql_text(sql_handle) 
CROSS APPLY sys.dm_exec_query_plan(MG.plan_handle)
 
--Queries that are generating the most IOs:
SELECT TOP 10    (total_logical_reads/execution_count) AS   avg_logical_reads,
    (total_logical_writes/execution_count) AS avg_logical_writes,
    (total_physical_reads/execution_count)  AS avg_phys_reads,
    execution_count,
    statement_start_offset as stmt_start_offset,
    (SELECT SUBSTRING(text, statement_start_offset/2 + 1,
        (CASE WHEN statement_end_offset = -1
            THEN LEN(CONVERT(nvarchar(MAX),text)) * 2
                ELSE statement_end_offset
            END - statement_start_offset)/2)
     FROM sys.dm_exec_sql_text(sql_handle)) AS query_text,
         dateadd(hour,-8,last_execution_time) AS last_execution_time
FROM sys.dm_exec_query_stats
ORDER BY
  (total_logical_reads + total_logical_writes) DESC
 
 
--DMV query to find any latch waits that occur in allocation pages, enable TF-1118 if
--there are latches in SGAM structures
 
select  session_id, wait_duration_ms,   resource_description
      from    sys.dm_os_waiting_tasks
      where   wait_type like 'PAGE%LATCH_%' and
              resource_description like '2:%'
 
**/
 
/**identify how much cache memory is being used by SQL Server on a per database level
 
SELECT
(CASE WHEN ([is_modified] = 1) THEN 'Dirty' ELSE 'Clean' END) AS 'Page State', --if dirty, page has been modified after it was read from the disk.
(CASE WHEN ([database_id] = 32767) THEN 'Resource Database' ELSE DB_NAME (database_id) END) AS 'Database Name',
file_name(file_id) AS [File Name],
COUNT (*) AS 'Page Count'
FROM sys.dm_os_buffer_descriptors
GROUP BY [database_id], file_id, [is_modified]
ORDER BY [database_id], [is_modified];
GO
 
 
**/
 
 
/**see database size, id, create date, status, etc.
 
sp_helpdb tempdb
**/
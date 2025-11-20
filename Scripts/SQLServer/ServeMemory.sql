/***************************************************View how much data is cached in the buffer pool and how much free space is on the pages************************
Too much free space on pages in the buffer pool is detrimental to performance>>>free space will take up space in the buffer pool that can be used for actual data instead
Consider how much free space should be left on pages when doing index defragmentation
Beware of HEAP tables, they do not release space on pages after a delete

DBCC MEMORYSTATUS
--look at Memory Manager:  Pages Allocated vs Pages Free and Pages In Use
**************************************************************************************************
--how much memory is SQL server using:
SELECT * FROM sys.dm_os_process_memory;

dm_os_buffer_descriptors dmv contains info about all the pages that are in buffer pool for memory

look for index_id=0, these are HEAP tables and they do NOT release empty space after deletes, so if the table had 10GB of
data and 9GB of data were deleted, the size will still remain at 10GB and a search on this table will require SQL Server to
go through 10GB of data to find that 1GB of data still there


**************************************************************************************************
--view memory configuration**********************************************************************

SELECT [name], [value], [value_in_use]
FROM sys.configurations
WHERE [name] = 'max server memory (MB)' OR [name] = 'min server memory (MB)';

SELECT sql_memory_model_desc,physical_memory_kb/1024./1024 memory_GB,physical_memory_kb*.9/1024 [90_Percent_memory]  FROM sys.dm_os_sys_info;

--set max memory:
sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'max server memory', 58982;
GO
RECONFIGURE;

*/
SELECT * FROM sys.dm_os_process_memory --Not supported in Azure SQL Database


--check how much of current database is cached in memory
SELECT TOP 10 	isnull(name,'TOTAL') 'object_name',isnull(convert(varchar(15),index_id),'SUBTOTAL') index_id
	--count all pages in the buffer pool (8K in size) and convert to MB
	,CAST(COUNT(*)/1024./1024.*8 AS NUMERIC(38,1)) 'cached_GB'
	,CAST(100.*sum(CONVERT(bigint,free_space_in_bytes))/1024./1024. /(COUNT(*)*8./1024.) AS NUMERIC(38,1)) 'free_space_%'
	--,SUM(row_count) 'total_rows', CAST(SUM(row_count)/(1.*COUNT(*)) AS NUMERIC(25,1)) 'avg_rows_per_page'
FROM sys.dm_os_buffer_descriptors bd  
INNER JOIN (
	SELECT object_name(object_id) 'name', index_id, allocation_unit_id 
	FROM sys.allocation_units au JOIN sys.partitions p ON au.container_id=p.hobt_id AND (au.type IN (1,3))
	UNION ALL 
	SELECT object_name(object_id), index_id, allocation_unit_id FROM sys.allocation_units au
	JOIN sys.partitions p ON au.container_id=p.partition_id AND au.type=2
	) obj ON bd.allocation_unit_id=obj.allocation_unit_id
WHERE database_id=DB_ID()
GROUP BY name, index_id WITH ROLLUP
ORDER BY cached_GB DESC


/****look up index name from index_id:
select object_name(object_id) object, * from sys.indexes where object_id = object_id ('DimMember')

ALTER INDEX [PK__Transact__3214EC26F0AE01A6] ON [hh].[dbo].[transactions] REBUILD WITH (FILLFACTOR = 95) ;


*/ 


/****Check for waits associated with large memory grants for queries: RESOURCE_SEMAPHORE waits
************************************************************************
check for the most expensive queries run on the server to see which ones get the biggest memory grants
don't need to worry about this if there aren't many RESOURCE_SEMAPHORE waits

SELECT group_id, name, statistics_start_time, total_request_count, active_request_count
	,queued_request_count --# of queries that got a reduced memory grant from what they asked for
	,total_reduced_memgrant_count
	,max_request_grant_memory_kb  --the biggest memory grant given to a query
	,max_request_grant_memory_kb/1024/1024. max_request_grant_memory_gb
FROM sys.dm_resource_governor_workload_groups;



*/
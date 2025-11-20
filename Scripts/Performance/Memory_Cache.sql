/*
How much memory is SQL server using?
SELECT physical_memory_in_use_kb/1024/1024. physical_memory_in_use_gb, 
locked_page_allocations_kb/1024/1024. locked_page_allocations_gb, * 
FROM sys.dm_os_process_memory


Can the system access enough memory?
--semaphore:  a variable used for controlling access, by multiple processes, to a common 
resource in a concurrent system
SELECT * FROM sys.dm_exec_query_resource_semaphores

waiter_count:  number of queries waiting for grants to be satisfied
timeout_error_count:  total number of time-out errors since server startup
forced_grant_count:  total number of forced minimum-memory grants since server startup
	if value>0: the cause could be execution plans that are asking for unreasonably large memory grants due to bad statistics, or a very large concurrent workload and not enought memory to service it
	will probably also see RESOURCE_SEMAPHORE waits

--cache memory is not buffer pool memory, it is query execution memory
select cache_memory_kb/1024/1024. cache_memory_gb, max_memory_kb/1024/1024. max_memory_gb, used_memory_kb/1024/1024. used_memory_gb, * from sys.dm_resource_governor_resource_pools
 

--**********Database Cached***********************
--check how much of current database is cached in memory
SELECT TOP 10 isnull(name,'TOTAL') 'object_name',isnull(convert(varchar(15),index_id),'SUBTOTAL') index_id
	--count all pages in the buffer pool (8K in size) and convert to MB
	,CAST(COUNT(*)/1024.*8/1024 AS NUMERIC(38,1)) 'cached_GB'
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

--clear the plan cache for a specific database:
select * from sys.databases;
DBCC FLUSHPROCINDB(7);
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
DBCC FREESYSTEMCACHE ('Staging')  --does not clear the buffer pool, just the query pool


DBCC FREESYSTEMCACHE ('Temporary Tables & Table Variables')
DBCC FREESYSTEMCACHE ('all')
DBCC FREESESSIONCACHE
DBCC FREEPROCCACHE

--clear wait stats:
DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR)


--************PLAN CACHE**************************
--how much of the cache is allocated to single use plans:
SELECT objtype AS [CacheType]
        , count_big(*) AS [Total Plans]
        , sum(cast(size_in_bytes as decimal(18,2)))/1024/1024 AS [Total MBs]
        , avg(usecounts) AS [Avg Use Count]
        , sum(cast((CASE WHEN usecounts = 1 THEN size_in_bytes ELSE 0 END) as decimal(18,2)))/1024/1024 AS [Total MBs – USE Count 1]
        , sum(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) AS [Total Plans – USE Count 1]
FROM sys.dm_exec_cached_plans
GROUP BY objtype WITH ROLLUP
ORDER BY [Total MBs – USE Count 1] DESC

--clear adhoc and prepared cache:
DBCC FREESYSTEMCACHE('SQL Plans')
DBCC FREEPROCCACHE();


--look at the contents of the cache:
SELECT text, cp.objtype, cp.size_in_bytes/1024./1024 size_in_MBs
FROM sys.dm_exec_cached_plans AS cp 
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
WHERE cp.cacheobjtype = N'Compiled Plan'
AND cp.objtype IN (N'Adhoc', N'Prepared')
AND cp.usecounts = 1
ORDER BY cp.size_in_bytes DESC 
OPTION (RECOMPILE);

--look at the contents of the cache for a certain database:
Select *
From sys.dm_exec_cached_plans CP
CROSS APPLY sys.dm_exec_query_plan(CP.plan_handle) QP
Where QP.dbid = DB_ID('Staging')


--which queries use parallelism?
SELECT TOP 10
p.*,
q.*,
qs.*,
cp.plan_handle
FROM
sys.dm_exec_cached_plans cp
CROSS apply sys.dm_exec_query_plan(cp.plan_handle) p
CROSS apply sys.dm_exec_sql_text(cp.plan_handle) AS q
JOIN sys.dm_exec_query_stats qs
ON qs.plan_handle = cp.plan_handle
WHERE
cp.cacheobjtype = 'Compiled Plan' AND
p.query_plan.value('declare namespace p="http://schemas.microsoft.com/sqlserver/2004/07/showplan";
max(//p:RelOp/@Parallel)', 'float') > 0
OPTION (MAXDOP 1)



/****how much memory is used by ad-hoc queries:
--CACHESTORE_SQLCP are our ad-hoc cached SQL statements or batches that aren’t in stored procedures, functions or triggers.  
--These consist of dynamic ad-hoc SQL  sent to the server by an application. 
--CACHESTORE_PHDR are algebrizer trees for views, constraints and defaults.  An algebrizer tree is the parsed SQL text that resolves the table and column names.
--CACHESTORE_OBJCP  are compiled plans for stored procedures, functions and triggers.


SELECT  
   LEFT([name], 20) AS [name],
   LEFT([type], 20) AS [type],
   SUM([single_pages_kb] + [multi_pages_kb])/1024. AS cache_mb,
   SUM([entries_count]) AS No_Entries
FROM sys.dm_os_memory_cache_counters 
WHERE TYPE IN ('CACHESTORE_SQLCP','CACHESTORE_PHDR','CACHESTORE_OBJCP')
GROUP BY [type], [name]
ORDER BY cache_mb DESC

SELECT *
FROM sys.dm_os_performance_counters
--WHERE [object_name] LIKE '%Manager%'AND [counter_name] = 'Page life expectancy'
WHERE counter_name ='Batch Requests/sec' or counter_name like '%wait%%sec%'

/**look at wait types:*****************
--wait_time_ms is the total wait time (cumulative for all queries)
--signal_wait_time is the amount of time query spent in the runnable queue:  waiting for a thread after being signaled that its resource is available
--resource wait time can be calculated by subracting signal wait time from the total wait time (wait_time_ms)
select datediff(minute,create_date,getdate()) 'minutes the server has been up' from sys.databases where database_id=2;
--select getdate();
select datediff(minute,'2015-06-29 15:53:14.267',getdate()) 'minutes since the stats were cleared'
SELECT *, (wait_time_ms-signal_wait_time_ms) resource_wait_time_ms, 100.*signal_wait_time_ms/wait_time_ms [% signal wait time]
FROM sys.dm_os_wait_stats WHERE wait_time_ms>0 AND [wait_type] NOT IN (
        N'BROKER_EVENTHANDLER',             N'BROKER_RECEIVE_WAITFOR',
        N'BROKER_TASK_STOP',                N'BROKER_TO_FLUSH',
        N'BROKER_TRANSMITTER',              N'CHECKPOINT_QUEUE',
        N'CHKPT',                           N'CLR_AUTO_EVENT',
        N'CLR_MANUAL_EVENT',                N'CLR_SEMAPHORE',
        N'DBMIRROR_DBM_EVENT',              N'DBMIRROR_EVENTS_QUEUE',
        N'DBMIRROR_WORKER_QUEUE',           N'DBMIRRORING_CMD',
        N'DIRTY_PAGE_POLL',                 N'DISPATCHER_QUEUE_SEMAPHORE',
        N'EXECSYNC',                        N'FSAGENT',
        N'FT_IFTS_SCHEDULER_IDLE_WAIT',     N'FT_IFTSHC_MUTEX',
        N'HADR_CLUSAPI_CALL',               N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
        N'HADR_LOGCAPTURE_WAIT',            N'HADR_NOTIFICATION_DEQUEUE',
        N'HADR_TIMER_TASK',                 N'HADR_WORK_QUEUE',
        N'KSOURCE_WAKEUP',                  N'LAZYWRITER_SLEEP',
        N'LOGMGR_QUEUE',                    N'ONDEMAND_TASK_QUEUE',
        N'PWAIT_ALL_COMPONENTS_INITIALIZED',
        N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
        N'REQUEST_FOR_DEADLOCK_SEARCH',     N'RESOURCE_QUEUE',
        N'SERVER_IDLE_CHECK',               N'SLEEP_BPOOL_FLUSH',
        N'SLEEP_DBSTARTUP',                 N'SLEEP_DCOMSTARTUP',
        N'SLEEP_MASTERDBREADY',             N'SLEEP_MASTERMDREADY',
        N'SLEEP_MASTERUPGRADED',            N'SLEEP_MSDBSTARTUP',
        N'SLEEP_SYSTEMTASK',                N'SLEEP_TASK',
        N'SLEEP_TEMPDBSTARTUP',             N'SNI_HTTP_ACCEPT',
        N'SP_SERVER_DIAGNOSTICS_SLEEP',     N'SQLTRACE_BUFFER_FLUSH',
        N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
        N'SQLTRACE_WAIT_ENTRIES',           N'WAIT_FOR_RESULTS',
        N'WAITFOR',                         N'WAITFOR_TASKSHUTDOWN',
        N'WAIT_XTP_HOST_WAIT',              N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
        N'WAIT_XTP_CKPT_CLOSE',             N'XE_DISPATCHER_JOIN',
        N'XE_DISPATCHER_WAIT',              N'XE_TIMER_EVENT',
		N'TRACEWRITE')
ORDER BY wait_time_ms DESC
--clear the stats:
DBCC SQLPERF('sys.dm_os_wait_stats',clear);


--******get a delta*************************************************************************
SELECT wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms
INTO #OriginalWaitStatSnapshot
FROM sys.dm_os_wait_stats
WHERE [wait_type] NOT IN (
        N'BROKER_EVENTHANDLER',             N'BROKER_RECEIVE_WAITFOR',
        N'BROKER_TASK_STOP',                N'BROKER_TO_FLUSH',
        N'BROKER_TRANSMITTER',              N'CHECKPOINT_QUEUE',
        N'CHKPT',                           N'CLR_AUTO_EVENT',
        N'CLR_MANUAL_EVENT',                N'CLR_SEMAPHORE',
        N'DBMIRROR_DBM_EVENT',              N'DBMIRROR_EVENTS_QUEUE',
        N'DBMIRROR_WORKER_QUEUE',           N'DBMIRRORING_CMD',
        N'DIRTY_PAGE_POLL',                 N'DISPATCHER_QUEUE_SEMAPHORE',
        N'EXECSYNC',                        N'FSAGENT',
        N'FT_IFTS_SCHEDULER_IDLE_WAIT',     N'FT_IFTSHC_MUTEX',
        N'HADR_CLUSAPI_CALL',               N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
        N'HADR_LOGCAPTURE_WAIT',            N'HADR_NOTIFICATION_DEQUEUE',
        N'HADR_TIMER_TASK',                 N'HADR_WORK_QUEUE',
        N'KSOURCE_WAKEUP',                  N'LAZYWRITER_SLEEP',
        N'LOGMGR_QUEUE',                    N'ONDEMAND_TASK_QUEUE',
        N'PWAIT_ALL_COMPONENTS_INITIALIZED',
        N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
        N'REQUEST_FOR_DEADLOCK_SEARCH',     N'RESOURCE_QUEUE',
        N'SERVER_IDLE_CHECK',               N'SLEEP_BPOOL_FLUSH',
        N'SLEEP_DBSTARTUP',                 N'SLEEP_DCOMSTARTUP',
        N'SLEEP_MASTERDBREADY',             N'SLEEP_MASTERMDREADY',
        N'SLEEP_MASTERUPGRADED',            N'SLEEP_MSDBSTARTUP',
        N'SLEEP_SYSTEMTASK',                N'SLEEP_TASK',
        N'SLEEP_TEMPDBSTARTUP',             N'SNI_HTTP_ACCEPT',
        N'SP_SERVER_DIAGNOSTICS_SLEEP',     N'SQLTRACE_BUFFER_FLUSH',
        N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
        N'SQLTRACE_WAIT_ENTRIES',           N'WAIT_FOR_RESULTS',
        N'WAITFOR',                         N'WAITFOR_TASKSHUTDOWN',
        N'WAIT_XTP_HOST_WAIT',              N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
        N'WAIT_XTP_CKPT_CLOSE',             N'XE_DISPATCHER_JOIN',
        N'XE_DISPATCHER_WAIT',              N'XE_TIMER_EVENT',
		N'TRACEWRITE');

WAITFOR DELAY '00:20:00';

SELECT wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms
INTO #NewestWaitStatSnapshot
FROM sys.dm_os_wait_stats;

--compare the results
SELECT n.wait_type, (n.wait_time_ms-o.wait_time_ms)/1000. accum_wait_s
FROM #OriginalWaitStatSnapshot o
INNER JOIN #NewestWaitStatSnapshot n ON o.wait_type=n.wait_type WHERE n.wait_time_ms>o.wait_time_ms
ORDER BY n.wait_time_ms DESC

DROP TABLE #OriginalWaitStatSnapshot, #NewestWaitStatSnapshot

select * from sys.sysprocesses;


--***********************************************************************************************
--show the waiter list at the current moment:
SELECT w.session_id, w.wait_duration_ms, w.wait_type, w.blocking_session_id,
	w.resource_description, s.program_name, --t.text. t.dbid,
	s.cpu_time, s.memory_usage
FROM sys.dm_os_waiting_tasks w
INNER JOIN sys.dm_exec_sessions s ON s.session_id=w.session_id
INNER JOIN sys.dm_exec_requests r ON s.session_id=r.session_id
--OUTER APPLY sys.dm_exec_sql_test (r.sql_handle) t
WHERE s.is_user_process=1

sp_who
*/
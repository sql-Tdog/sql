--*****SEMAPHORE*************************************************************************
--RESOURCE_SEMAPHORE:  queries waiting on memory grant
 
--grantee_count:  # of queries which have their memory; waiter_count: # of queries waiting to get memory
SELECT * FROM sys.dm_exec_query_resource_semaphores
 
--get the details of all queries which are waiting in queue to get their requested memory:
SELECT * FROM sys.dm_exec_query_memory_grants;
 
select top 10 plan_handle from sys.dm_exec_query_memory_grants order by granted_memory_kb desc;
 
--get SQL Plan:
SELECT * FROM sys.dm_exec_query_plan(0x05000A001374FC02404126EC000000000000000000000000)



--*****THREADPOOL WAITS*************************************************************************
SELECT count(*) 
FROM sys.dm_os_waiting_tasks 
WHERE wait_type = 'threadpool'

--Checking Thread Availability
SELECT 
    (SELECT max_workers_count FROM sys.dm_os_sys_info) as 'TotalThreads',
    SUM(active_Workers_count) as 'CurrentThreads',
    (SELECT max_workers_count FROM sys.dm_os_sys_info)
        - SUM(active_Workers_count) as 'AvailableThreads',
    SUM(runnable_tasks_count) as 'WorkersWaitingForCPU',
    SUM(work_queue_count) as 'RequestWaitingForThreads',
    SUM(current_workers_count) as 'CurrentWorkers'
FROM sys.dm_os_Schedulers
WHERE status = 'VISIBLE ONLINE'


/*********WRITELOG***********************************************************************
When a SQL Server session waits on the WRITELOG wait type, it is waiting to write the contents of the log cache to disk where the transaction log is stored.
Log access is purely sequential, even 1 log file can be bad due to VLFs
Divide database logs between drives to leverage multiple paths to SAN
 
USE Datamart
DBCC LOGINFO
 
select * from sys.dm_io_pending_io_requests;
 */
 -- Wait Statistics
SELECT * FROM sys.dm_os_wait_stats;					-- wait stats across the server
SELECT * FROM sys.dm_exec_session_wait_stats;		-- waits for a given session, but not across sessions 
 https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-wait-stats-transact-sql?view=sql-server-ver15
 
 
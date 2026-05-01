--view max threads configured on the server:
SELECT max_workers_count FROM sys.dm_os_sys_info;

SELECT
    GETDATE() AS 'CurrentDate',
    SUM(current_workers_count) AS 'AssociatedWorkers', -- Total workers associated with schedulers
    SUM(active_workers_count) AS 'CurrentActiveThreads',
    SUM(runnable_tasks_count) AS 'WorkersWaitingForCpu', -- Tasks waiting for CPU time
    SUM(work_queue_count) AS 'RequestsWaitingForThreads' -- Requests waiting for an available worker thread
FROM sys.dm_os_schedulers
WHERE status = 'VISIBLE ONLINE';


SELECT COUNT(*) AS TotalConnections FROM sys.dm_exec_sessions WHERE is_user_process = 1;

SELECT * FROM sys.dm_os_waiting_tasks order by wait_type

--If there's a high number of active temp tables:
SELECT 
    s.session_id,
    s.login_name,          -- The SQL or AD login
    s.host_name,           -- The client machine name
    s.program_name,        -- The app/service name (e.g., .Net SqlClient)
    s.status,
    (usage.user_objects_alloc_page_count * 8) / 1024 AS TempTable_MB
FROM sys.dm_exec_sessions AS s
JOIN sys.dm_db_session_space_usage AS usage 
    ON s.session_id = usage.session_id
WHERE usage.user_objects_alloc_page_count > 0
ORDER BY TempTable_MB DESC;

SELECT 
    s.session_id,
    s.login_name,
    s.host_name,
    COUNT(t.object_id) AS TempTableCount
FROM tempdb.sys.tables AS t
JOIN sys.dm_exec_sessions AS s ON t.principal_id = s.security_id 
    OR t.name LIKE '%[_][_][_]%' -- Matches the internal naming convention
WHERE t.name LIKE '#%'
GROUP BY s.session_id, s.login_name, s.host_name
ORDER BY TempTableCount DESC;


--check tempdb to make sure it has 8 files of equal size
sp_helpdb tempdb
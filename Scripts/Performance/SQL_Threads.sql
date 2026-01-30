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

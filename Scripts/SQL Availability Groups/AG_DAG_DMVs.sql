https://learn.microsoft.com/en-us/sql/database-engine/availability-groups/windows/distributed-availability-groups?view=sql-server-ver15#scale-out-readable-replicas
/*
Stuart Miller
Mar 28, 2025, 7:49 PM
to me

There are a bunch of potentially nuanced details in defining exactly what "latency" means in an AG 
scenario, and the engine does not monitor latency in real time for most of the ones that would 
indicate a customer-side problem — most of them are intended to debug SQL internal problems.
IMO, log_send_queue_size and redo_queue_size are the best approximations for "latency" as they 
directly indicate how much data a given replica does not have [visible for queries], but they 
do not have universally intuitive values like "one second". Values like last_sent_time will 
intentionally drift for an idle DB that has no data to be sent; they can be extremely useful for 
troubleshooting via time series comparisons of successive values but that's a bit too complicated 
to stuff into an automated alert. For similar reasons, merely filtering out values where 
log_send_queue_size is 0 can lead to false alerts for leading edges when workloads start up again 
after an idle period, if you just happen to check during the polling period where the worker is 
still asleep and thus hasn't consumed the available work yet.
In the context of a DAG, I would expect to monitor *at least* every Forwarder in addition to the 
global primary. Even the global primary does not have total visibility over all the leaf replicas. 

*/
-- shows replicas associated with availability groups
SELECT
   ag.[name] AS [AG Name],
   ag.Is_Distributed,
   ar.replica_server_name AS [Replica Name]
FROM sys.availability_groups AS ag
INNER JOIN sys.availability_replicas AS ar
   ON ag.group_id = ar.group_id;
GO

--show DAGs and AGs:
SELECT  ag.[name] AS [DAG Name],  ar.replica_server_name AS [Underlying AG],
ars.role_desc AS [Role],   ars.synchronization_health_desc AS [Sync Status]
FROM  sys.availability_groups AS ag
INNER JOIN sys.availability_replicas AS ar ON  ag.group_id = ar.group_id
INNER JOIN sys.dm_hadr_availability_replica_states AS ars ON  ar.replica_id = ars.replica_id
WHERE ag.is_distributed = 1


--show AGs and nodes:
SELECT  ag.[name] AS [AG Name],  ar.replica_server_name AS [Underlying Node],
	ars.role_desc AS [Role],   ars.synchronization_health_desc AS [Sync Status]
FROM  sys.availability_groups AS ag
INNER JOIN sys.availability_replicas AS ar ON  ag.group_id = ar.group_id
INNER JOIN sys.dm_hadr_availability_replica_states AS ars ON  ar.replica_id = ars.replica_id
WHERE ag.is_distributed = 0;


-- shows sync status of distributed AG
SELECT
   ag.[name] AS [AG Name],
   ag.is_distributed,
   ar.replica_server_name AS [Underlying AG],
   ars.role_desc AS [Role],
   ars.synchronization_health_desc AS [Sync Status]
FROM  sys.availability_groups AS ag
INNER JOIN sys.availability_replicas AS ar
   ON  ag.group_id = ar.group_id
INNER JOIN sys.dm_hadr_availability_replica_states AS ars
   ON  ar.replica_id = ars.replica_id
WHERE ag.is_distributed = 1;
GO


-- shows underlying performance of distributed AG
SELECT
   ag.[name] AS [Distributed AG Name],
   ar.replica_server_name AS [Underlying AG],
   dbs.[name] AS [Database],
   ars.role_desc AS [Role],
   drs.synchronization_health_desc AS [Sync Status],
   drs.log_send_queue_size,
   drs.log_send_rate,
   drs.redo_queue_size,
   drs.redo_rate
FROM sys.databases AS dbs
INNER JOIN sys.dm_hadr_database_replica_states AS drs
   ON dbs.database_id = drs.database_id
INNER JOIN sys.availability_groups AS ag
   ON drs.group_id = ag.group_id
INNER JOIN sys.dm_hadr_availability_replica_states AS ars
   ON ars.replica_id = drs.replica_id
INNER JOIN sys.availability_replicas AS ar
   ON ar.replica_id = ars.replica_id
WHERE ag.is_distributed = 1;
GO

-- displays OS performance counters related to the distributed ag named 'distributedag'
SELECT * FROM sys.dm_os_performance_counters WHERE instance_name LIKE '%distributed%'


-- displays sync status, send rate, and redo rate of availability groups,
-- including distributed AG
SELECT ag.name AS [AG Name],
    ag.is_distributed,
    ar.replica_server_name AS [AG],
    dbs.name AS [Database],
    ars.role_desc,
    drs.synchronization_health_desc,
    drs.log_send_queue_size,
    drs.log_send_rate,
    drs.redo_queue_size,
    drs.redo_rate,
    drs.suspend_reason_desc,
    drs.last_sent_time,
    drs.last_received_time,
    drs.last_hardened_time,
    drs.last_redone_time,
    drs.last_commit_time,
    drs.secondary_lag_seconds
FROM sys.databases dbs
INNER JOIN sys.dm_hadr_database_replica_states drs
    ON dbs.database_id = drs.database_id
INNER JOIN sys.availability_groups ag
    ON drs.group_id = ag.group_id
INNER JOIN sys.dm_hadr_availability_replica_states ars
    ON ars.replica_id = drs.replica_id
INNER JOIN sys.availability_replicas ar
    ON ar.replica_id = ars.replica_id
--WHERE ag.is_distributed = 1
GO


-- shows endpoint url and sync state for ag, and dag
SELECT
   ag.name AS group_name,
   ag.is_distributed,
   ar.replica_server_name AS replica_name,
   ar.endpoint_url,
   ar.availability_mode_desc,
   ar.failover_mode_desc,
   ar.primary_role_allow_connections_desc AS allow_connections_primary,
   ar.secondary_role_allow_connections_desc AS allow_connections_secondary,
   ar.seeding_mode_desc AS seeding_mode
FROM sys.availability_replicas AS ar
JOIN sys.availability_groups AS ag
   ON ar.group_id = ag.group_id;
GO

-- shows current_state of seeding
SELECT ag.name AS aag_name,
    ar.replica_server_name,
    d.name AS database_name,
    has.current_state,
    has.failure_state_desc AS failure_state,
    has.error_code,
    has.performed_seeding,
    has.start_time,
    has.completion_time,
    has.number_of_attempts
FROM sys.dm_hadr_automatic_seeding AS has
INNER JOIN sys.availability_groups AS ag
    ON ag.group_id = has.ag_id
INNER JOIN sys.availability_replicas AS ar
    ON ar.replica_id = has.ag_remote_replica_id
INNER JOIN sys.databases AS d
    ON d.group_database_id = has.ag_db_id;
GO
--view Azure SQL database resource use:
SELECT * FROM sys.dm_db_resource_stats;


--view SQL Managed Instance stats:
SELECT * FROM sys.server_resource_stats;


--Monitor connections:
SELECT * FROM sys.dm_exec_connections;  --only lists out current connections, # reads/writes performed, encrypted connection info




-- Index management
SELECT * FROM sys.dm_db_index_usage_stats;			-- counts of existing index operations

--track the lenght of time users must wait for table locks & latches before they can read/write to a table:
SELECT * FROM sys.dm_db_index_operational_stats 
						(NULL, NULL, NULL, NULL);	-- utilization of existing indexes
SELECT * FROM sys.dm_db_stats_properties 
						(1893581784, 1);			-- last time statistics were updated for a specific index
SELECT * FROM sys.dm_db_index_physical_stats
					(NULL, NULL, NULL, NULL, NULL);	-- index fragmentation
SELECT * FROM sys.dm_db_missing_index_details;		-- details for new and potentially useful indexes 


-- Query Plans
SELECT * FROM sys.dm_exec_cached_plans;				-- explore the plan cache
SELECT * FROM sys.dm_exec_query_plan
	(0x0500FF7F99F756F020E70773B501000001000000000000000000000000000000000000000000000000000000);
													-- view estimated execution plans from the plan cache
SELECT * FROM sys.dm_exec_query_plan_stats
	(0x0500FF7F99F756F020E70773B501000001000000000000000000000000000000000000000000000000000000);
													-- get the last actual execution plan for a query
													

-- Wait Statistics
SELECT * FROM sys.dm_os_wait_stats;					-- wait stats across the server
SELECT * FROM sys.dm_exec_session_wait_stats;		-- waits for a given session, but not across sessions


-- Get additional usage details and tips at
-- https://docs.microsoft.com/en-us/azure/azure-sql/database/monitoring-with-dmvs

--locks and blocks:
SELECT * FROM sys.dm_tran_locks;
SELECT * FROM sys.dm_exec_requests;
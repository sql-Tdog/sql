/*
live query statistics can provide real-time insights into the query execution process as the data flows from one query plan operator to another

The query execution statistics profile infrastructure, or standard profiling, must be enabled to collect information about execution plans, 
namely row count, CPU and I/O usage

SQL Server 2019 (15.x) and Azure SQL Database include a newly revised version of lightweight profiling collecting row count information for all executions. 
Lightweight profiling is enabled by default on SQL Server 2019 (15.x) and Azure SQL Database. 

Lightweight profiling can be disabled at the database level using the LIGHTWEIGHT_QUERY_PROFILING database scoped configuration: 
ALTER DATABASE SCOPED CONFIGURATION SET LIGHTWEIGHT_QUERY_PROFILING = OFF;.

A new DMF sys.dm_exec_query_plan_stats is introduced to return the equivalent of the last known actual execution plan for most queries, 
and is called last query plan statistics. 
The last query plan statistics can be enabled at the database level using the LAST_QUERY_PLAN_STATS database scoped configuration: 
ALTER DATABASE SCOPED CONFIGURATION SET LAST_QUERY_PLAN_STATS = ON;.

A new query_post_execution_plan_profile extended event collects the equivalent of an actual execution plan based on lightweight profiling, 
unlike query_post_execution_showplan which uses standard profiling. 
SQL Server 2017 (14.x) also offers this event starting with CU14. 


*/
ALTER DATABASE SCOPED CONFIGURATION SET LIGHTWEIGHT_QUERY_PROFILING = OFF;


--enable last query plan statistics
ALTER DATABASE SCOPED CONFIGURATION SET LAST_QUERY_PLAN_STATS = ON;

SELECT * FROM sys.dm_exec_cached_plans;  

--return the equivalent of the last known actual execution plan for most queries (input plan handle)
SELECT * FROM sys.dm_exec_query_plan_stats(0x0500FF7F9FD939CAA0FD35777B02000001000000000000000000000000000000000000000000000000000000);
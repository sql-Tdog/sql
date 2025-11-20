/***goal:  compare estimated rows and actual rows for a query:

select * from sys.dm_exec_query_stats 
select * from sys.dm_exec_cached_plans
select * from sys.dm_exec_query_plan 
SELECT * FROM sys.dm_exec_requests WHERE session_id = 54;

--snapshot of all query plans residing in the plan cache:
USE master;
GO
SELECT * FROM sys.dm_exec_cached_plans cp CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle)
where plan_handle=0x06000700B465F02340E15BA0020000000000000000000000
GO

--sys.dm_exec_query_stats DMV limitation: 
--if a query is not explicitly or implicitly parameterized and if the query text contains inline literal values, the query plan will not be reused
--every execution of the query with a different set of parameter values will generate a new compiled plan object
--therefore, sql_handle and plan_handle values will be different for each execution
--query_hash and query_plan_hash are new additions to SQL Server 2008 and will have the same value for queries that have the same shape (same sql after stripping out any inline parameters)

SELECT sql_handle, plan_handle, query_hash, query_plan_hash, execution_count, total_worker_time/1000. CPU_time_ms, total_logical_reads, text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text (qs.plan_handle) AS sql --where sql_handle=0x02000000EDFC7502DDBDB1707650FE898DD9DA3B679E6161
order by total_logical_reads desc

*/
--run in the context of the user database

-- Top 50 queries by CPU across all replicas in the last 8 hours
DECLARE @hours AS INT = 8;

SELECT TOP 50 qsq.query_id,
              qsp.plan_id,
              CASE qrs.replica_group_id WHEN 1 THEN 'PRIMARY' WHEN 2 THEN 'SECONDARY' WHEN 3 THEN 'GEO SECONDARY' WHEN 4 THEN 'GEO HA SECONDARY' ELSE CONCAT('NAMED REPLICA_', qrs.replica_group_id) END AS replica_type,
              qsq.query_hash,
              qsp.query_plan_hash,
              SUM(qrs.count_executions) AS sum_executions,
              SUM(qrs.count_executions * qrs.avg_logical_io_reads) AS total_logical_reads,
              SUM(qrs.count_executions * qrs.avg_cpu_time / 1000.0) AS total_cpu_ms,
              AVG(qrs.avg_logical_io_reads) AS avg_logical_io_reads,
              AVG(qrs.avg_cpu_time / 1000.0) AS avg_cpu_ms,
              ROUND(TRY_CAST (SUM(qrs.avg_duration * qrs.count_executions) AS FLOAT) / NULLIF (SUM(qrs.count_executions), 0) * 0.001, 2) AS avg_duration_ms,
              COUNT(DISTINCT qsp.plan_id) AS number_of_distinct_plans,
              qsqt.query_sql_text
FROM sys.query_store_runtime_stats_interval AS qsrsi
     INNER JOIN sys.query_store_runtime_stats AS qrs
         ON qrs.runtime_stats_interval_id = qsrsi.runtime_stats_interval_id
     INNER JOIN sys.query_store_plan AS qsp
         ON qsp.plan_id = qrs.plan_id
     INNER JOIN sys.query_store_query AS qsq
         ON qsq.query_id = qsp.query_id
     INNER JOIN sys.query_store_query_text AS qsqt
         ON qsq.query_text_id = qsqt.query_text_id
WHERE qsrsi.start_time >= DATEADD(HOUR, -@hours, GETUTCDATE())
GROUP BY qsq.query_id, qsq.query_hash, qsp.query_plan_hash, qsp.plan_id, qrs.replica_group_id, qsqt.query_sql_text
ORDER BY SUM(qrs.count_executions * qrs.avg_cpu_time / 1000.0) DESC, AVG(qrs.avg_cpu_time / 1000.0) DESC;
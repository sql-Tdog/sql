select top 50 getdate() as logtime, rank() over (order by total_logical_reads+total_logical_writes desc,sql_handle,statement_start_offset ) as row_no
,       (rank() over (order by total_logical_reads+total_logical_writes desc,sql_handle,statement_start_offset ))%2 as l1
,       creation_time
,       last_execution_time
,       (total_worker_time+0.0)/1000 as total_worker_time
,       (total_worker_time+0.0)/(execution_count*1000) as [AvgCPUTime]
,       total_logical_reads as [LogicalReads]
,       total_logical_writes as [LogicalWrites]
,       execution_count
,       total_logical_reads+total_logical_writes as [AggIO]
,       (total_logical_reads+total_logical_writes)/(execution_count+0.0) as [AvgIO]
,       case when sql_handle IS NULL
                then ' '
                else ( substring(st.text,(qs.statement_start_offset+2)/2,(case when qs.statement_end_offset = -1        then len(convert(nvarchar(MAX),st.text))*2      else qs.statement_end_offset    end - qs.statement_start_offset) /2  ) )
        end as query_text 
,       db_name(st.dbid) as database_name
,       st.objectid as object_id
,       query_plan
from sys.dm_exec_query_stats  qs
cross apply sys.dm_exec_sql_text(sql_handle) st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle)
where total_logical_reads+total_logical_writes > 0 
order by [AvgIO]  desc
with top20 
as
(
select top 20
	query_hash
	,min([sql_handle]) [sql_handle]
	,min([plan_handle]) [plan_handle]
	,min(qs.creation_time) [First_Exec]
	,max(qs.last_execution_time) [Last_exec]
	,sum(execution_count) execution_count 
	,sum(total_worker_time) total_worker_time
	,sum(total_worker_time) / sum(execution_count) avg_worker_time
	,sum(total_elapsed_time) total_elapsed_time
	,sum(total_logical_reads) total_logical_reads
	,sum(total_physical_reads) total_physical_reads
	,sum(total_logical_writes) total_logical_writes
from sys.dm_exec_query_stats qs
group by query_hash
order by total_worker_time desc
)
select 
	query_hash
	,qp.query_plan
	,st.[text]
	,tp.First_Exec
	,tp.Last_exec
	,tp.execution_count
	,tp.total_worker_time
	,tp.avg_worker_time
	,tp.total_elapsed_time
	,tp.total_logical_reads
	,tp.total_physical_reads
	,tp.total_logical_writes
From top20 tp
	cross apply sys.dm_exec_sql_text([sql_handle]) st
	outer apply sys.dm_exec_query_plan(plan_handle) qp
	
	
	
;with top20 
as
(
select top 20
	query_hash
	,est.[dbid]
	,statement_start_offset
	,statement_end_offset
	,max([sql_handle]) [sql_handle]
	,max([plan_handle]) [plan_handle]
	,min(qs.creation_time) [First_Exec]
	,max(qs.last_execution_time) [Last_exec]
	,sum(execution_count) sum_execution_count 
	,sum(total_worker_time) sum_total_worker_time
	,sum(total_elapsed_time) sum_total_elapsed_time
	,sum(total_logical_reads) sum_total_logical_reads
	,sum(total_physical_reads) sum_total_physical_reads
	,sum(total_logical_writes) sum_total_logical_writes
	,sum(total_used_grant_kb) sum_total_used_grant_kb
	,sum(total_grant_kb) sum_total_grant_kb
from sys.dm_exec_query_stats qs
	cross apply sys.dm_exec_sql_text (sql_handle) est
group by query_hash,statement_start_offset
	,statement_end_offset
	,est.[dbid]
order by sum_total_worker_time desc
)
select 
	query_hash
	,db_name(tp.[dbid])
	,qp.query_plan
	,st.[text]
	,substring(st.text, (tp.statement_start_offset/2)+1,((case tp.statement_end_offset when -1 then datalength(st.text) else tp.statement_end_offset end - tp.statement_start_offset)/2)+1) [Statement]
	,tp.First_Exec
	,tp.Last_exec
	,tp.sum_execution_count [Execution_count]
	,tp.sum_total_worker_time [total_worker_time]
	,tp.sum_total_worker_time / tp.sum_execution_count avg_worker_time
	,tp.sum_total_elapsed_time [total_elapsed_time]
	,tp.sum_total_elapsed_time / tp.sum_execution_count avg_elapsed_time
	,tp.sum_total_logical_reads [total_logical_reads]
	,tp.sum_total_logical_reads / tp.sum_execution_count avg_logical_reads
	,tp.sum_total_physical_reads [total_physical_reads]
	,tp.sum_total_logical_writes [total_logical_writes]
	,tp.sum_total_grant_kb [total_grant_kb]
	,tp.sum_total_grant_kb / tp.sum_execution_count [avg_grant_kb]
	,tp.sum_total_used_grant_kb [total_used_grant_kb]
	,tp.sum_total_used_grant_kb / tp.sum_execution_count [avg_used_grant_kb]
From top20 tp
	cross apply sys.dm_exec_sql_text([sql_handle]) st
	outer apply sys.dm_exec_query_plan(plan_handle) qp

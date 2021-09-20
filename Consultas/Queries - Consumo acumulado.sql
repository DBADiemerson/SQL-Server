set statistics io on
set statistics time on
go
select
	min(qt.[text]) 
	,sum(execution_count) execution_count 
	,sum(total_worker_time) total_worker_time
	,sum(total_worker_time) / sum(execution_count) avg_worker_time
	,sum(total_elapsed_time) total_elapsed_time
	,sum(total_logical_reads) total_logical_reads
	,sum(total_physical_reads) total_physical_reads
	,sum(total_logical_writes) total_logical_writes
from sys.dm_exec_query_stats qs
	cross apply sys.dm_exec_sql_text(sql_handle) qt
group by query_hash
order by total_worker_time desc

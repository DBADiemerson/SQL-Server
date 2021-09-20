declare @spid int = 64

select 
	req.session_id
	,ses.host_name
	,ses.program_name
	,ses.login_name
	,req.start_time
	,req.[status] 
	,req.command
	,req.wait_type
	,req.wait_time
	,req.last_wait_type
	,req.percent_complete
	,req.cpu_time
	,req.reads
	,req.writes
	,req.logical_reads
	,txt.[text]
	,case 
		when statement_end_offset > 0 
		then substring(txt.[text],(req.statement_start_offset/2)+1,((statement_end_offset - req.statement_start_offset)/2) +1) else 'ver coluna Text' end [Statement]
	,pln.query_plan
	,bff.event_type
	,bff.event_info
from sys.dm_exec_requests req
	inner join sys.dm_exec_sessions ses
		on req.session_id = ses.session_id
	outer apply sys.dm_exec_sql_text(req.sql_handle) txt
	outer apply sys.dm_exec_query_plan(plan_handle) pln
	cross apply sys.dm_exec_input_buffer(req.session_id,null) bff
where req.session_id = @spid

dbcc inputbuffer(@spid)

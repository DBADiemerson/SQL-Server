set statistics io on
set statistics time on
go
select 
	ses.[original_login_name],
	ses.[program_name],
	isnull(jbs.name,'') [Job],
	con.[client_net_address],
	req.[session_id],
	db_name(ses.database_id) [Database],
	ses.[host_name],
	req.[status],
	req.[start_time],
	req.[command],
	isnull(db_name(txt.[dbid]),'AdHoc') [Database],
	isnull(object_name(txt.[objectid],txt.[dbid]),'AdHoc') [Object],
	req.[blocking_session_id],
	req.[wait_type],
	req.[wait_time],
	req.[last_wait_type],
	req.[cpu_time],
	req.[logical_reads],
	req.[total_elapsed_time],
	txt.[text],
	case when statement_end_offset > 0 then substring(txt.[text],(req.statement_start_offset/2)+1,((statement_end_offset - req.statement_start_offset)/2)+1) else 'ver coluna Text' end [Statement],
	pln.query_plan,
	bff.event_type,
	bff.event_info
from sys.dm_exec_requests req
	join sys.dm_exec_sessions ses
		on req.session_id = ses.session_id
	join sys.dm_exec_connections con
		on req.session_id = con.session_id
	left join msdb.dbo.sysjobs jbs
		on master.dbo.fn_varbintohexstr(convert(varbinary(16), job_id)) = substring(ses.[program_name],30,34)
	outer apply sys.dm_exec_sql_text(sql_handle) txt
	outer apply sys.dm_exec_query_plan(plan_handle) pln
	cross apply sys.dm_exec_input_buffer(req.session_id,null) bff
where req.session_id <> @@spid--= 142
	and req.session_id > 50
	--and object_name(txt.[objectid],txt.[dbid]) = 'sp_relatorio_vendas'
order by req.cpu_time desc


--SELECT p.spid, j.name,substring(replace(program_name, 'SQLAgent - TSQL JobStep (Job ', ''), 1, 34),program_name
--FROM   master.dbo.sysprocesses p
--JOIN   msdb.dbo.sysjobs j ON 
--   master.dbo.fn_varbintohexstr(convert(varbinary(16), job_id)) COLLATE Latin1_General_CI_AI = 
--   substring(replace(program_name, 'SQLAgent - TSQL JobStep (Job ', ''), 1, 34)

--select * from sys.sysprocesses
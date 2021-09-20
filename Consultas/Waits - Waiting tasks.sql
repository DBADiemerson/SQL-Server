select r.session_id, 
	status, 
	command,
	r.blocking_session_id,
	r.wait_type as [request_wait_type], 
	r.wait_time as [request_wait_time],
	t.wait_type as [task_wait_type],
	t.wait_duration_ms as [task_wait_time],
	t.blocking_session_id,
	t.resource_description
from sys.dm_exec_requests r
left join sys.dm_os_waiting_tasks t
	on r.session_id = t.session_id
where r.session_id >= 50
and r.session_id <> @@spid;
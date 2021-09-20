select top 1 SQLProcessUtilization
	from (
	select 
		record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') as SQLProcessUtilization,
		timestamp
	from (
		select timestamp, convert(xml, record) as record 
		from sys.dm_os_ring_buffers 
		where ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
		and record like '%SystemHealth%') as x
		) as y
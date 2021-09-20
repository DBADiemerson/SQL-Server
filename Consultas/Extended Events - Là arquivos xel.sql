drop table if exists #extendedevents;
select 
	[object_name]
	,cast(event_data as xml) Event_data 
into #extendedevents  
from sys.fn_xe_file_target_read_file( 'D:\SQLServer\XE\OPENTECH\*.xel','D:\SQLServer\XE\OPENTECH\*.xem',null,null)


select
		dateadd(hour,(-3),event_data.value(N'(event/@timestamp)[1]',N'datetime')) [TimeStamp]
		,[object_name]
		,event_data.value(N'(event/action[@name="server_instance_name"]/value)[1]',N'varchar(100)') [Server]
		,event_data.value(N'(event/action[@name="username"]/value)[1]',N'varchar(100)') [Username]
		,event_data.value(N'(event/action[@name="client_hostname"]/value)[1]',N'varchar(100)') [Host]
		,event_data.value(N'(event/action[@name="client_app_name"]/value)[1]',N'varchar(200)') [App_name]
		,event_data.value(N'(event/action[@name="database_name"]/value)[1]',N'varchar(100)') [Database]
		,event_data.value(N'(event/action[@name="query_hash"]/value)[1]',N'varchar(50)') [query_hash]
		,event_data.value(N'(event/data[@name="logical_reads"]/value)[1]',N'bigint') [Logical_reads]
		,event_data.value(N'(event/data[@name="physical_reads"]/value)[1]',N'bigint') [Physical_reads]
		,event_data.value(N'(event/data[@name="writes"]/value)[1]',N'bigint') [Writes]
		,event_data.value(N'(event/data[@name="cpu_time"]/value)[1]',N'bigint') [Cpu_time]
		,event_data.value(N'(event/data[@name="duration"]/value)[1]',N'bigint') [Duration]
		,event_data.value(N'(event/action[@name="sql_text"]/value)[1]',N'varchar(max)') [Query]
		,event_data.value(N'(event/data[@name="statement"]/value)[1]',N'varchar(max)') [Statement]
		,event_data.value(N'(event/data[@name="error_number"]/value)[1]',N'int') [Error_number]
		,event_data.value(N'(event/data[@name="category"]/text)[1]',N'varchar(100)') [Error_category]
		,event_data.value(N'(event/data[@name="message"]/value)[1]',N'Varchar(2000)') [Error_Message]
		,event_data.value(N'(event/data[@name="wait_type"]/text)[1]',N'Varchar(200)') [wait_type]
from #extendedevents
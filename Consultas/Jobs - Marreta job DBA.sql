USE [msdb]
GO

declare 
	@job_name sysname = 'DBA - All DBs Daily Backup.Backup_Log_NODEATIVO'
	,@new_step int

select
	@new_step = max(js.step_id)+1
from dbo.sysjobs jb
	join dbo.sysjobsteps js
		on jb.job_id = js.job_id
where jb.[name] = @job_name


EXEC msdb.dbo.sp_add_jobstep 
		@job_name=@job_name, 
		@step_name=N'select1', 
		@step_id = @new_step,
		@subsystem=N'TSQL', 
		@command=N'select 1'

EXEC sp_start_job @job_name = @job_name, @step_name = 'select1'

waitfor delay '00:00:03'

EXEC msdb.dbo.sp_delete_jobstep @job_name = @job_name , @step_id = @new_step
GO

select @@servername
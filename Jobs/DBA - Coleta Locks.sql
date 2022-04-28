USE [DBA_HIST]
GO

/****** Object:  Table [dbo].[dba_baseline_locks]    Script Date: 28/04/2022 15:28:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

drop table if exists dba_baseline_locks;
go
CREATE TABLE [dbo].[dba_baseline_locks](
	[Timestamp] [datetime] NOT NULL,
	[dbid] [smallint] NOT NULL,
	[spid] [smallint] NOT NULL,
	[blocking] [smallint] NOT NULL,
	[cmd] [nchar](16) NOT NULL,
	[status] [nchar](30) NOT NULL,
	[open_tran] [smallint] NOT NULL,
	[login_time] [datetime] NOT NULL,
	[last_batch] [datetime] NOT NULL,
	[waittime] [bigint] NOT NULL,
	[lastwaittype] [nchar](32) NOT NULL,
	[waitresource] [nchar](256) NOT NULL,
	[loginame] [nchar](128) NOT NULL,
	[program_name] [nchar](128) NOT NULL,
	[hostname] [nchar](128) NOT NULL,
	[Query] [text] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

create clustered index idx_dba_base_locks_last_batch_spid on dba_baseline_locks(login_time, spid)

GO
USE [msdb]
GO

/****** Object:  Job [DBA - Locks Baseline]    Script Date: 28/04/2022 15:52:19 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 28/04/2022 15:52:19 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Locks Baseline', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Coleta locks]    Script Date: 28/04/2022 15:52:20 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Coleta locks', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
if exists (select 1 from sys.dm_exec_requests where blocking_session_id > 0 and wait_time > 30000)
begin
	with blkd as
	(
		select distinct
			blocked
		from sys.sysprocesses sp
		where blocked > 0 
			and spid <> blocked
	)
	insert into dba_hist.dbo.dba_baseline_locks
	select 
			getdate() [Timestamp],
			sp.[dbid],
			sp.spid,
			sp.blocked,
			sp.cmd,
			sp.[status],
			sp.open_tran,
			sp.login_time,
			sp.last_batch,
			sp.waittime,
			sp.lastwaittype,
			sp.waitresource,
			sp.loginame,
			sp.[program_name],
			sp.hostname,
			(select [text] from sys.fn_get_sql(sp.[sql_handle])) Query
	from sys.sysprocesses sp
		left join blkd 
			on sp.spid = blkd.blocked
		left join dba_hist.dbo.dba_baseline_locks dbl
			on sp.spid = dbl.spid
				and sp.last_batch = dbl.last_batch
	where (blkd.blocked is not null
		or sp.blocked <> 0)
		and dbl.spid is null
	order by spid
end', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Diario', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=2, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20220428, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'6cc8c42d-2bcb-481f-9dca-ea664f6c518a'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



USE [DBA_HIST]
GO


drop table if exists [dba_baseline_tamanho_tabelas];
go
CREATE TABLE [dbo].[dba_baseline_tamanho_tabelas](
	[Timestamp] [date] NULL,
	[Database] [nvarchar](128) NULL,
	[Schema] [nvarchar](128) NULL,
	[Object] [sysname] NOT NULL,
	[TotalMB] [bigint] NULL,
	[UsedMB] [bigint] NULL,
	[Rows] [bigint] NULL
) ON [PRIMARY]
GO


create clustered index idx_dba_base_tabelas_timestamp on [dba_baseline_tamanho_tabelas]([timestamp]) with (data_compression=page)

go

drop table if exists [dba_baseline_tamanho_databases];
go
CREATE TABLE [dbo].[dba_baseline_tamanho_databases](
	[timestamp] date
	,[database] varchar(100)
	,[DataFilesGB] decimal(10,2)
	,[PercentUsedDF] decimal(6,2)
	,[LogFilesGB] decimal(10,2)
	,[PercentUsedLF] decimal(6,2)
	,[FilestreamGB] decimal(10,2)
	,[PercentUsedFF] decimal(6,2)
)

create clustered index idx_dba_base_databases_timestamp on [dba_baseline_tamanho_databases]([timestamp]) with (data_compression=page)

go
USE [msdb]
GO

/****** Object:  Job [DBA - Crescimento Baseline]    Script Date: 29/04/2022 15:26:12 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 29/04/2022 15:26:12 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Crescimento Baseline', 
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
/****** Object:  Step [Crescimento tabelas]    Script Date: 29/04/2022 15:26:12 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Crescimento tabelas', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'insert into dba_hist.dbo.dba_baseline_tamanho_tabelas
exec sp_msforeachdb ''
use [?];

with volumetria as
(
	select 
		[object_id]
		,index_id
		,[rows]
		,total_pages
		,data_pages
		,used_pages
	from sys.allocation_units au
		join sys.partitions pt
			on au.container_id = pt.[partition_id]
	where au.[type] in (1,3) --1 - IN_ROW_DATA e 3 - ROW_OVERFLOW_DATA
	union all
	select 
		[object_id]
		,index_id
		,[rows]
		,total_pages
		,data_pages
		,used_pages
	from sys.allocation_units au
		join sys.partitions pt
			on au.container_id = pt.[partition_id]
	where au.[type] = 2 --2 - LOB
)
select 
	cast(getdate() as date) [Timestamp]
	,db_name() [Database]
	,schema_name(schema_id) [Schema]
	,tb.name [Object]
	,(sum(total_pages) / 128) [TotalMB]
	,(sum(used_pages) / 128) [UsedMB]
	,sum(case when vl.index_id in (0,1) then [rows] end) [Rows]
from sys.tables tb
	join volumetria vl
		on tb.[object_id] = vl.[object_id]
group by tb.[schema_id],tb.[name]
order by TotalMB desc''', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Crescimento databases]    Script Date: 29/04/2022 15:26:12 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Crescimento databases', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'insert into dba_hist.dbo.[dba_baseline_tamanho_databases]
exec sp_msforeachdb''
use [?]

select 
	getdate()
	,upper(db_name()) [Database]
	,sum(case [type] when 0 then size / 128.0 /1024 end)	[DataFilesGB]
	,sum( case [type] when 0 then  fileproperty(name,''''spaceused'''') end ) * 100.0 / sum(case [type] when 0 then size end) [PercentUsedDF]
	,sum(case [type] when 1 then size / 128.0 /1024 end)  [LogFilesGB]
	,sum( case [type] when 1 then  fileproperty(name,''''spaceused'''') end ) * 100.0 / sum(case [type] when 1 then size end) [PercentUsedLF]
	,sum(case [type] when 2 then size / 128.0 /1024 end)  [FilestreamGB]
	,sum(case [type] when 2 then  fileproperty(name,''''spaceused'''') end ) * 100.0 / sum(case [type] when 2 then size end) [PercentUsedFF]
from sys.database_files df;
''
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Diario 20h', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20220429, 
		@active_end_date=99991231, 
		@active_start_time=200000, 
		@active_end_time=235959, 
		@schedule_uid=N'35ce3421-9fb9-4b73-9ada-e16c044f1d77'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



USE [DBA_HIST]
GO

/****** Object:  Table [dbo].[dba_baseline_perfcounters]    Script Date: 28/04/2022 17:19:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

drop table if exists [dba_baseline_perfcounters];
go

CREATE TABLE [dbo].[dba_baseline_perfcounters](
	[Timestamp] [datetime] NOT NULL,
	[object_name] [nchar](128) NOT NULL,
	[counter_name] [nchar](128) NOT NULL,
	[instance_name] [nchar](128) NULL,
	[cntr_value] [bigint] NOT NULL,
	[cntr_type] [int] NOT NULL
) ON [PRIMARY]
GO

create clustered index idx_dba_base_perf_timestamp on dba_baseline_perfcounters([timestamp]) with (data_compression=page)

go

USE [msdb]
GO

/****** Object:  Job [DBA - Perfcounters Baseline]    Script Date: 28/04/2022 19:02:46 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 28/04/2022 19:02:46 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Perfcounters Baseline', 
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
/****** Object:  Step [Powershell Baseline]    Script Date: 28/04/2022 19:02:46 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Powershell Baseline', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'PowerShell', 
		@command=N'$counters = "\Processor Information(_total)\% Processor Time",
            "\LogicalDisk(*)\Avg. Disk sec/Read",
            "\LogicalDisk(*)\Avg. Disk sec/Write",
            "\LogicalDisk(*)\Disk Read Bytes/sec",
            "\LogicalDisk(*)\Disk Write Bytes/sec",
            "\LogicalDisk(*)\Current Disk Queue Length",
            "\LogicalDisk(*)\Avg. Disk Read Queue Length",
            "\LogicalDisk(*)\Avg. Disk Write Queue Length",
            "\Memory\Available MBytes",
            "\Paging File(_total)\% Usage"

$counter_values = (get-counter -Counter $counters).countersamples | select timestamp, path, cookedvalue

$sqlcmd = "begin tran
    begin try

"

foreach( $sample in $counter_values)
{
    $timestamp = $sample.timestamp.ToString(''yyyy-MM-dd hh:mm:ss'')
    $instancename = ($sample.Path.Split(''\''))[3]
    $countername = ($sample.Path.Split(''\''))[4]
    $countervalue = $sample.CookedValue 

    if(($countername -eq "avg. disk sec/read")-or($countername -eq "avg. disk sec/write"))
    {
        $countervalue = $countervalue * 1000
    }


    $sqlcmd += "        insert into dba_baseline_perfcounters values (getdate(),''Powershell:Perfmon'',''$countername'',''$instancename'',$countervalue,65792 ); `r`n"
    
}
$sqlcmd += "
    commit
    end try
    begin catch
        print error_message()
        rollback
    end catch
"
invoke-sqlcmd -ServerInstance localhost -Database dba_hist -Query $sqlcmd -QueryTimeout 0
 
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [SQL Baseline]    Script Date: 28/04/2022 19:02:46 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'SQL Baseline', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'insert into dba_hist.dbo.dba_baseline_perfcounters
select 
	getdate()[Timestamp]
	,*
from sys.dm_os_performance_counters
where
	object_name = ''SQLServer:Batch Resp Statistics''
	and instance_name = ''Elapsed Time:Requests''

union all

select 
	getdate()[Timestamp]
	,*
from sys.dm_os_performance_counters
where 
	object_name in (
						''SQLServer:SQL Statistics'',
						''SQLServer:Buffer Manager'',
						''SQLServer:General Statistics'',
						''SQLServer:Databases'',
						''SQLServer:Access Methods'',
						''SQLServer:Memory Manager''

					)
	and counter_name in (
							''Batch Requests/sec'',
							''SQL Compilations/sec'',
							''SQL Re-Compilations/sec'',
							''Buffer cache hit ratio'',
							''Lazy writes/sec'',
							''Page life expectancy'',
							''Processes blocked'',
							''Data File(s) Size (KB)'',
							''Log File(s) Size (KB)'',
							''Transactions/sec'',
							''Full Scans/sec'',
							''Index Searches/sec'',
							''Memory Grants Pending'',
							''Database Cache Memory (KB)'',
							''Granted Workspace Memory (KB)'',
							''Reserved Server Memory (KB)'',
							''Connection Memory (KB)''

						)

', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'A cada 10 minutos', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20220428, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'7bc817e6-a5cf-4ffc-ba4b-4605a800927b'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



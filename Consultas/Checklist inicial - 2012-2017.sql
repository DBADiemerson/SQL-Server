----------------------------------------
--Retorna informações do servidor
----------------------------------------
SELECT 
    serverproperty('computernamephysicalnetbios') [ServidorFisico]
    ,serverproperty('resourceversion') [ResourceDBVer]
    ,serverproperty('resourcelastupdatedatetime') [ResourceDBLastUpdt]
    ,SERVERPROPERTY('IsClustered') AS [IsClustered]
    ,SERVERPROPERTY('Collation') AS [Collation]
    ,sqlserver_start_time [StartTime]
    ,@@version [Versao]
    ,@@servername [Instancia]
    ,@@servicename [Servico]
    ,physical_memory_kb / 1024 /1024 [MemoriaGB]
    ,cpu_Count / hyperthread_ratio [CPUs_fisicos]
    ,hyperthread_ratio [Cores]
    ,cpu_count [CPUs_Logicos]
FROM sys.dm_os_sys_info

----------------------------------------
--Retorna informações da instäncia
----------------------------------------
Select 
	[Name]
	,[Value]
	,[Description]
from sys.configurations
where [name] in
(
'optimize for ad hoc workloads'
,'show advanced options'
,'priority boost'
,'cost threshold for parallelism'
,'max degree of parallelism'
,'max server memory (MB)'
,'optimize for ad hoc workloads'
,'Agent XPs'
,'Database Mail XPs'
,'xp_cmdshell'
)

----------------------------------------
--Retorna informações dos bancos
----------------------------------------
select 
	 db.name [Database]
	 ,sp.name [Owner]
	 ,db.[compatibility_level] [Compatibility]
	 ,db.collation_name [Collation]
	 ,db.is_read_only [ReadOnly]
	 ,db.is_auto_shrink_on [AutoShrink]
	 ,db.is_auto_close_on [AutoClose]
	 ,db.state_desc [State]
	 ,db.user_access_desc [UserAccess]
	 ,db.is_in_standby [Standby]
	 ,db.is_read_committed_snapshot_on [ReadCommittedSnapshot]
	 ,db.snapshot_isolation_state_desc [SnapshotIsolation]
	 ,db.recovery_model_desc [RecoveryModel]
	 ,db.page_verify_option_desc [PageVerify]
	 ,db.is_auto_create_stats_on [AutoCreateStats]
	 ,db.is_auto_update_stats_on [AutoUpdateStats]
	 ,db.is_fulltext_enabled [FullTextEnabled]
	 ,db.is_trustworthy_on [Trustworthy]
	 ,db.is_published [Published]
	 ,db.is_subscribed [Subscribed]
	 ,db.is_merge_published [MergePublished]
from sys.databases db
	join sys.server_principals sp
		on db.owner_sid = sp.[sid]

----------------------------------------
--Informações Backups
----------------------------------------

select 
	Database_name
	,case [type] 
		when 'D' then 'Full'
		when 'I' then 'Dif'
		when 'L' then 'Log'
	end [Tipo]
	,case [type]
		when 'D' then cast(datediff(day,min(backup_start_date),max(backup_start_date)) as varchar)+' Dia(s)' 
		when 'I' then cast(datediff(HH,min(backup_start_date),max(backup_start_date)) as varchar)+' Hora(s)' 
		when 'L' then cast(datediff(MI,min(backup_start_date),max(backup_start_date)) as varchar)+' Minuto(s)' 
	end [Frequencia]
	,max(backup_start_date) [UltimoBackup]
	,max(backup_size) backup_size
	,max(compressed_backup_size) compressed_backup_size
	,case 
		when [type] = 'D' and  datediff(day,max(backup_start_date),getdate()) <= datediff(day,min(backup_start_date),max(backup_start_date)) then ' Full: Ok' 
		when [type] = 'I' and  datediff(HH,max(backup_start_date),getdate()) <= datediff(HH,min(backup_start_date),max(backup_start_date)) then ' Dif: Ok' 
		when [type] = 'L' and  datediff(MI,max(backup_start_date),getdate()) <= datediff(MI,min(backup_start_date),max(backup_start_date)) then ' Log: Ok' 
		else 'Verificar'
	end [Status]
from (
		select 
			row_number() over (partition by database_name, [type] order by backup_set_id desc) Rowid
			,database_name
			,[type]
			,backup_start_date
			,cast((backup_size / 1024 / 1024 / 1024.0) as decimal(10,3)) backup_size
			,cast((compressed_backup_size / 1024 / 1024 / 1024.0) as decimal(10,3)) compressed_backup_size
		from msdb.dbo.backupset
	)bkps
where rowid <=2
group by database_name,[type]
order by 1,2



-------------------------------------------
--Informações Arquivos dos bancos de dados
-------------------------------------------

if object_id('tempdb..#vfs') is not null
	drop table #vfs

select 
	database_id
	,[file_id]
	,num_of_reads
	,num_of_bytes_read
	,io_stall_read_ms
	,num_of_writes
	,num_of_bytes_written
	,io_stall_write_ms 
	,io_stall
into #vfs 
from sys.dm_io_virtual_file_stats(NULL, NULL)

waitfor delay '00:00:10'

select 
	db_name(mf.database_id) [Database]
	,mf.physical_name
	,mf.is_read_only
	,cast(mf.size / 128.0 as decimal(10,2)) [TamanhoMB]
	,case mf.growth
		when 0 then 'Na'
		else case mf.is_percent_growth
				when 0 then cast(cast(mf.growth / 128.0 as decimal(10,2)) as varchar)+' MB'
				when 1 then cast(mf.growth as varchar)+' %'
			end
	end [Crescimento]
	,case mf.max_size
		when 0 then 'NA'
		when -1 then 'Ilimitado'
		else cast(cast(mf.max_size / 128.0 as decimal(10,2)) as varchar)+' MB'
	end [TamanhoMax]
	,(dvfs.num_of_reads - tvfs.num_of_reads) / 10 [LeiturasSeg]
	,case 
		when (dvfs.num_of_reads - tvfs.num_of_reads) = 0 then 0
		else (dvfs.io_stall_read_ms - tvfs.io_stall_read_ms) / (dvfs.num_of_reads - tvfs.num_of_reads)
	end [TempoLeituraMS]
	,(dvfs.num_of_writes - tvfs.num_of_writes) / 10 [EscritasSeg]
	,case 
		when (dvfs.num_of_writes - tvfs.num_of_writes) = 0 then 0
		else (dvfs.io_stall_write_ms - tvfs.io_stall_write_ms) / (dvfs.num_of_writes - tvfs.num_of_writes)
	end [TempoEscritaMS]
	,case 
		when (dvfs.num_of_writes - tvfs.num_of_writes) + (dvfs.num_of_reads - tvfs.num_of_reads) = 0 then 0
		else (dvfs.io_stall - tvfs.io_stall) / ((dvfs.num_of_writes - tvfs.num_of_writes)+(dvfs.num_of_reads - tvfs.num_of_reads)) 
	end [LatenciaMS]
	,volume_mount_point
	,(total_bytes / 1024 / 1024 /1024) [DiscoTotalGB]
	,(available_bytes / 1024 / 1024 /1024) [DisponivelGB]
	,is_compressed

from sys.master_files mf
	cross apply sys.dm_os_volume_stats(database_id, [file_id]) ovs
	cross apply sys.dm_io_virtual_file_stats(mf.database_id,mf.[file_id]) dvfs
	inner join #vfs tvfs
		on mf.database_id = tvfs.database_id
			and mf.[file_id] = tvfs.[file_id]		
order by mf.database_id


select 
	db.[Name] [Database]
	,max(case [type] when 'D' then backup_start_date end) [BackupFull]
	,max(case [type] when 'D' then 'A cada '+cast([FreqBackupsMI] / 1440 as varchar)+' dia(s)' end) [FreqBF]
	,isnull(max(case [type] when 'D' then [Status] end),'Verificar') [StatusBF]
	,max(case [type] when 'I' then backup_start_date end) [BackupDif]
	,max(case [type] when 'I' then 'A cada '+cast([FreqBackupsMI] / 60 as varchar)+' Hora(s)' end) [FreqBF]
	,case 
		when database_id > 4 
			then isnull(max(case when [type] = 'I' then [Status] end),'Verificar')
		else ' - '
	end [StatusBD]
	,max(case [type] when 'L' then backup_start_date end) [BackupLog]
	,max(case [type] when 'L' then 'A cada '+cast([FreqBackupsMI]as varchar)+' Minuto(s)' end) [FreqBF]
	,case 
		when database_id > 4 
			then isnull(max(case when [type] = 'L' then [Status] end),'Verificar')
		else ' - '
	end [StatusBL]
from sys.databases db
	left join (
				select
					row_number() over (partition by [database_name], [type] order by backup_start_date desc) [rowid]
					,[database_name]
					,[type]
					,[backup_start_date]
					,datediff(mi,lag([backup_start_date],1,[backup_start_date]) over(partition by [database_name], [type] order by backup_start_date),[backup_start_date]) [FreqBackupsMI]
					,case when datediff(mi,[backup_start_date],getdate()) <= datediff(mi,lag([backup_start_date],1,[backup_start_date]) over(partition by [database_name], [type] order by backup_start_date),[backup_start_date])
							then 'Ok'
							else 'Verificar'
						end [Status]
				from msdb.dbo.backupset
				)bkp
		on db.[name] = bkp.[database_name]
			and rowid = 1
where name <> 'tempdb'
group by db.database_id,db.[name]
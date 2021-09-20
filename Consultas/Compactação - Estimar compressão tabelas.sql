
drop table if exists #estimate_compression

create table #estimate_compression
(
	[object_name] sysname
	,[schema_name] sysname
	,[index_id] int
	,[partition_number] int
	,[size_with_current_compression_setting_KB] bigint
	,[size_with_requested_compression_setting_KB] bigint
	,[sample_size_with_current_compression_setting_KB] bigint
	,[sample_size_with_requested_compression_setting_KB] bigint
)

declare @cmd varchar(max) = ''
drop table if exists #comandos
create table #comandos( rowid int identity, comando varchar(5000))

declare @min int = 1, @max int

insert into #comandos
select 
	'exec sp_estimate_data_compression_savings @schema_name = '''+schema_name([schema_id])+''', @object_name = '''+[name]+''', @index_id = '+cast(index_id as varchar)+', @partition_number = '+cast(partition_number as varchar)+', @data_compression = ''page'';'+char(10)
from sys.tables tb
	join sys.partitions pt
		on tb.object_id = pt.object_id 
where pt.data_compression = 0

set @max = @@rowcount

while @min <= @max
begin

	select @cmd = comando
	from #comandos
	where rowid = @min
	
	
	begin try
		insert into #estimate_compression
		exec(@cmd)
	end try
	begin catch
		print 'Erro ao executar o comando :'+@cmd+'  -  '+error_message()
	end catch

	set @min+=1

end



select 
	*, 
	size_with_current_compression_setting_KB/1024 [TamanhoAtual], 
	size_with_requested_compression_setting_KB / 1024 [TamanhoCompactado], 
	(size_with_current_compression_setting_KB - size_with_requested_compression_setting_KB) / 1024 [GanhoCompactacao],
	'alter index ['+i.[name]+'] on ['+schema_name(t.schema_id)+'].['+t.[name]+'] rebuild with (online = on, data_compression = page)' [Comando_Compress]
 from #estimate_compression ec
	inner join sys.tables t
		on ec.[object_name] = t.[name] collate Latin1_General_CI_AS
			and schema_id(ec.[schema_name]) = t.[schema_id] 
	inner join sys.indexes i
		on t.[object_id] = i.[object_id]
			and ec.index_id = i.index_id
where (size_with_current_compression_setting_KB - size_with_requested_compression_setting_KB) > 500000
order by [TamanhoAtual]
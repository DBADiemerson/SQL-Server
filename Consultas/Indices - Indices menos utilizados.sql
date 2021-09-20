declare @obj table	(
						databaseid int
						,objectid int
						,indexid  int
						,is_primary_key bit
						,is_unique_constraint bit
						,TamanhoMB int
						,Linhas bigint
						,schemaname varchar(50)
						,objectname varchar(250)
						,indexname	varchar(250)
					)


declare @cmd varchar(max)
set @cmd = ''
select @cmd = @cmd +
'
select
	'''+convert(varchar,database_id)+'''
	,obj.[object_id]
	,idx.[index_id]
	,is_primary_key
	,is_unique_constraint
	,ixs.reserved /128
	,ixs.[rows]
	,sch.name [Schema]
	,obj.name [Objeto]
	,idx.name [Indice]
from ['+name+'].sys.indexes idx (nolock)
		join ['+name+'].sys.objects obj (nolock)
			on idx.[object_id] = obj.[object_id]
		join ['+name+'].sys.schemas sch (nolock)
			on obj.[schema_id] = sch.[schema_id]
		join ['+name+'].sys.sysindexes ixs
			on idx.object_id = ixs.id
				and idx.index_id = ixs.indid
where 
	obj.[type] in (''U'',''V'')
	and is_unique_constraint = 0
	and is_primary_key = 0
	and idx.[index_id] > 0;
'
from sys.databases (nolock)
where [state] = 0
and database_id > 4

print @cmd
insert into @obj exec(@cmd)


select 
	db_name(obj.databaseid)[DatabaseName]
	,obj.schemaname
	,obj.ObjectName
	,obj.IndexName
	,is_primary_key
	,is_unique_constraint
	,obj.TamanhoMB
	,obj.Linhas
	,ius.User_seeks
	,ius.User_scans
	,ius.User_lookups
	,ius.User_updates
	,ius.last_user_seek
	,ius.last_user_scan
	,ius.last_user_lookup
	,ius.last_user_update
	,'drop index ['+obj.IndexName+'] on ['+db_name(obj.databaseid)+'].['+obj.schemaname+'].['+obj.ObjectName+']' [DropIndex]
from @obj obj
	join sys.dm_db_index_usage_stats ius
		on obj.databaseid = ius.database_id
			and obj.[objectid] = ius.[object_id]
				and obj.indexid = ius.[index_id]
order by
	(ius.User_seeks+
	ius.User_scans+
	ius.User_lookups),ius.User_updates desc
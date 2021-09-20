select 
	fgs.[name] [Filegroup]
	,schema_name(tbl.schema_id) [Schema]
	,tbl.[name] [Tabela]
	,idx.[name] [Indice]
	,ius.user_seeks
	,ius.user_scans
	,ius.user_lookups
	,ius.user_updates
	,idx2.[reserved] / 128 TamanhoMB
from sys.indexes idx
	inner join sys.tables tbl
		on idx.[object_id] = tbl.[object_id]
	inner join sys.sysindexes idx2
		on idx.object_id = idx2.id
			and idx.index_id = idx2.indid
	inner join sys.filegroups fgs
		on idx.data_space_id = fgs.data_space_id
	left join sys.dm_db_index_usage_stats ius
		on ius.database_id = db_id()
			and idx.[object_id] = ius.[object_id]
				and idx.index_id = ius.index_id
--where idx.data_space_id = 2
order by 	(
				ius.user_seeks
				+ius.user_scans
				+ius.user_lookups
			) desc


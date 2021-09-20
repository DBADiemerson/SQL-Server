select 
	(db_name(id.database_id)) [Database]
	,(object_name(id.[object_id],id.database_id)) [Object]
	,isnull((id.equality_columns),'') Equality
	,isnull((id.inequality_columns),'') Inequality
	,isnull((id.included_columns),'') Included
	,igs.user_seeks
	,igs.user_scans
	,igs.avg_user_impact
	,igs.avg_total_user_cost
	,ius.user_updates
    ,'create index [idx_'+lower(object_name(id.[object_id],id.database_id))
    +isnull('_'+replace(replace(replace(replace(id.equality_columns,']',''),'[',''),',',''),' ',''),'')
    +isnull('_'+replace(replace(replace(replace(id.inequality_columns,']',''),'[',''),',',''),' ',''),'')
    +case when included_columns is not null then '_includes' else '' end+'_missidx]'
    +' on '+id.statement+'('+isnull(id.equality_columns,'')
    +case when id.equality_columns is not null and id.inequality_columns is not null then ', ' else '' END
    +isnull(id.inequality_columns,'')+')'
    +isnull(' include ('+id.included_columns+')','')
    +' with (online = ?, data_compression = ?, sort_in_tempdb = ?, drop_existing = ?)'
from sys.dm_db_missing_index_details id
	join sys.dm_db_missing_index_groups ig
		on id.index_handle = ig.index_handle
	join sys.dm_db_missing_index_group_stats igs
		on ig.index_group_handle = igs.group_handle
	left join sys.dm_db_index_usage_stats ius
		on id.database_id = ius.database_id
			and id.[object_id] = ius.[object_id]
				and ius.index_id in (0,1)
order by igs.avg_total_user_cost * igs.avg_user_impact * (igs.user_seeks + igs.user_scans) DESC

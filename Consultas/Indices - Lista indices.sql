with idxcol as
(
	select
		idx.[object_id]
		,idx.[index_id]
		,idx.key_ordinal
		,case is_included_column when 0 then '['+col.[name]+']' + case idx.is_descending_key when 1 then ' desc' else ' asc' end end [IndexColumn]
		,case is_included_column when 1 then '['+col.[name]+']' end [IncludeColumn]
	from sys.index_columns idx
		left join sys.columns col
			on idx.[object_id] = col.[object_id]
				and idx.column_id = col.column_id
)

select 
	schema_name(obj.[schema_id])[schema]
	,obj.[Name] [Tabela]
	,ix.[name] [Indice]
	,ix.[type_desc]
	,ix.fill_factor
	,ius.user_seeks
	,ius.user_scans
	,ius.user_lookups
	,ius.user_updates
	,stuff(ixcol,1,2,'') [IndexColumns]
	,stuff(iccol,1,2,'') [IncludeColumns]
	,'create'	+case ix.index_id when 1 then ' clustered' else ' nonclustered' end 
				+case ix.is_unique when 1 then ' unique' else '' end
	+' index ['+ix.[name]+'] on ['+schema_name([schema_id])+'].['+obj.[Name]+'] ('+stuff(ixcol,1,2,'')+isnull(') include ('+stuff(iccol,1,2,'')+')',')')
	+ case ix.has_filter when 0 then '' else ' where '+ix.filter_definition end 
	+ ' with (online = on, data_compression = page, sort_in_tempdb = on)' 
	+ isnull(' On ['+fg.name+']','') [CreateIndex]
	,'drop index ['+ix.[name]+'] on ['+schema_name([schema_id])+'].['+obj.[Name]+']' [DropIndex]
from sys.objects obj
	inner join sys.indexes ix
		on obj.[object_id] = ix.[object_id]
	left join sys.filegroups fg
		on ix.data_space_id = fg.data_space_id
	left join sys.dm_db_index_usage_stats ius
		on ius.database_id = db_id()
			and ix.[object_id] = ius.[object_id]
				and ix.index_id = ius.index_id
	cross apply (
					select 
						', ' +[indexcolumn]
					from idxcol
					where idxcol.[object_id] = ix.[object_id]
						and idxcol.[index_id] = ix.[index_id]
					order by key_ordinal
					for xml path('')
				)[indexcolumn] (IxCOl)
	cross apply (
					select 
						', ' +[IncludeColumn]
					from idxcol
					where idxcol.[object_id] = ix.[object_id]
						and idxcol.[index_id] = ix.[index_id]
					order by key_ordinal
					for xml path('')
				)[IncludeColumn] (IcCOl)
where obj.[type] in ('U','V')
		and ix.index_id > 0
order by obj.[schema_id],obj.[name], ix.index_id



use master
go

select 
	object_name(st.[object_id]) Objeto
	,st.[name] [Estatistica]
	,st.auto_created
	,st.has_filter
	,st.filter_definition
	,stp.last_updated
	,stp.[Rows]
	,stp.[Rows_Sampled]
	,cast(stp.[Rows_Sampled] * 100.00 / stp.[Rows] as decimal(5,2)) [Percent_Sampled]
	,stp.unfiltered_rows
	,id.rowmodctr
from sys.stats st
	join sys.tables tb
		on tb.[object_id] = st.[object_id]
	join sys.sysindexes id
		on id.id = st.object_id
			and st.stats_id = id.indid
	cross apply sys.dm_db_stats_properties(st.[object_id],st.[stats_id]) stp
order by last_updated
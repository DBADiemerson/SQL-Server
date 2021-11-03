select 
	db_name(database_id)
	,object_name(object_id, database_id)
	,index_id
	,partition_number
	,page_count
	,avg_fragmentation_in_percent
from sys.dm_db_index_physical_stats(null, null, null, null,'limited')
where database_id > 4

with volumetria as
(
	select 
		[object_id]
		,index_id
		,[rows]
		,total_pages
		,data_pages
		,used_pages
	from sys.allocation_units au
		join sys.partitions pt
			on au.container_id = pt.[partition_id]
	where au.[type] in (1,3) --1 - IN_ROW_DATA e 3 - ROW_OVERFLOW_DATA
	union all
	select 
		[object_id]
		,index_id
		,[rows]
		,total_pages
		,data_pages
		,used_pages
	from sys.allocation_units au
		join sys.partitions pt
			on au.container_id = pt.[partition_id]
	where au.[type] = 2 --2 - LOB
)
select 
	cast(getdate() as date) [Timestamp]
	,db_name() [Database]
	,schema_name(schema_id) [Schema]
	,tb.name [Object]
	,(sum(total_pages) / 128) [TotalMB]
	,(sum(used_pages) / 128) [UsedMB]
	,sum(case when vl.index_id in (0,1) then [rows] end) [Rows]
from sys.tables tb
	join volumetria vl
		on tb.[object_id] = vl.[object_id]
group by tb.[schema_id],tb.[name]
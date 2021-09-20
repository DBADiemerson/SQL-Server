select
	'EXEC sys.sp_cdc_enable_table
		@source_schema = N'''+schema_name(tb.schema_id)+''',
		@source_name = N'''+tb.name+''',
		@role_name = null,
		@filegroup_name = '+ct.filegroup_name+',
		@captured_column_list = '''+stuff(cdccol,1,2,'')+''';'

from sys.tables tb
	join cdc.change_tables ct
		on tb.object_id = ct.source_object_id
	cross apply (
					select 
						', ' +column_name
					from cdc.captured_columns cc
						where cc.object_id = ct.object_id
					for xml path('')
				)[indexcolumn] (cdccol) 


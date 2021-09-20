use credbell
go
select
	'['+db_name()+'].['+schema_name(tbl.schema_id)+'].['+tbl.name+']' Objeto
	,col.name Coluna
	,case 	when col.is_computed = 1
			then 'as '+cpd.[definition]
	else
		case 
			when tps.is_user_defined = 1
				then '['+schema_name(tps.schema_id)+'].['+tps.name+']'
			else '['+tps.name+']' 
		end	
		+case 
			when tps.name in ('datetime2', 'datetimeoffset','time') then '('+cast(col.scale as varchar)+')'
			when tps.name in ('decimal','float','numeric') then '('+cast(col.max_length as varchar)+case col.scale
																										when 0 then ''
																										else ','+cast(col.scale as varchar)
																									end+')'
			when tps.name in ('char','nchar','binary','nvarchar','varbinary','varchar') then '('+	case col.max_length 
																										when -1 then 'Max' 
																										else cast(col.max_length as varchar) 
																									end+')'
			else ''
		end
		+ case col.is_rowguidcol when 1 then ' rowguidcol unique' else '' end
		+ case col.is_filestream when 1 then ' Filestream' else '' end
		+ case col.is_identity when 1 then ' identity('+cast(seed_value as varchar)+','+cast(increment_value as varchar)+')' else '' end
		+ case col.is_nullable when 1 then ' null' when 0 then ' not null' end
	 end [Precisao]
from sys.tables tbl
	join sys.columns col
		on tbl.[object_id] = col.[object_id]
	join sys.types tps
		on col.user_type_id = tps.user_type_id	
	left join sys.identity_columns idt
		on col.[object_id] = idt.[object_id]
			and col.column_id = idt.column_id
	left join sys.computed_columns cpd
		on col.[object_id] = cpd.[object_id]
			and col.column_id = cpd.column_id
order by 
		tbl.[object_id]
		,col.column_id

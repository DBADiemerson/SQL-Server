select 
	tr.traceid,
	case tr.[property]
		when 1 then 'Opções de rastreamento'
		when 2 then 'Nome do arquivo'
		when 3 then 'Tamanho Maximo'
		when 4 then 'Hora da parada'
		when 5 then 'Status' -- 0 parado, 1 execução
	end [Property],
	tr.value PropertyValue,
	tc.name ColumnFilter,
	case tf.comparison_operator
		when 0 then '='
		when 1 then '<>'
		when 2 then '>'
		when 3 then '<'
		when 4 then '>='
		when 5 then '<='
		when 6 then 'Like'
		when 7 then 'Not like'
	end [Operador],
	tf.[value] [FilterValue]
from sys.fn_trace_getinfo(null) tr
	outer apply fn_trace_getfilterinfo(tr.traceid) tf
	left join sys.trace_columns tc
		on tf.columnid = tc.trace_column_id


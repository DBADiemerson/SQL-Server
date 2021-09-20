use credbell
go
declare @objeto varchar(250)
set @objeto = 'online_vendas'


;with Rel(Objetopai, Objetofilho, idfk, nomefk,idpk , nivel)
as(
	select 
		referenced_object_id, parent_object_id, [object_id], name,key_index_id, 1 [nivel]
	from sys.foreign_keys fks
	where referenced_object_id = object_id(@objeto)
	
	union all

	select 
		fks.referenced_object_id, fks.parent_object_id, [object_id], name, key_index_id, rel.nivel + 1 [nivel]
	from sys.foreign_keys fks
		join rel on rel.Objetofilho = fks.referenced_object_id


)
select 
	'['+schema_name(tbp.[schema_id])+'].['+tbp.name+']' [TabelaPai]
	,'['+schema_name(tbf.[schema_id])+'].['+tbf.name+']' [TabelaFilha]
	,rel.nomefk [ForeignKey]
	,idx.name [PrimayKey]
	,nivel
from rel
	inner join sys.tables tbp
		on rel.objetopai = tbp.[object_id]
	inner join sys.tables tbf
		on rel.objetofilho = tbf.[object_id]
	inner join sys.indexes idx
		on rel.objetopai = idx.[object_id]
			and rel.idpk = idx.index_id


--select top 10 * from sys.foreign_keys
--select top 10 * from sys.columns


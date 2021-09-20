declare 
	@table varchar(100) = 'posicao'
	,@key_column_list varchar(500) = 'pos_codigo,[pos_data]'
	,@Include_column_list varchar(500) = 'pos_latitude, [pos_longitude]'
	,@is_clustered bit = 0
	,@is_unique bit = 0
	,@fill_factor int = 80


declare 
	@num_rows bigint
	,@heap_clustered bit
	,@num_key_cols int
	,@fixed_key_size int
	,@num_variable_key_cols int
	,@max_var_key_size int
	,@index_null_bitmap int = 0
	,@variable_key_size int = 0
	,@index_row_size int
	,@index_rows_per_page int
	,@num_leaf_cols int
	,@fixed_leaf_size int
	,@num_variable_leaf_cols int
	,@max_var_leaf_size int
	,@leaf_null_bitmap int = 0
	,@variable_leaf_size int = 0
	,@leaf_row_size int
	,@leaf_rows_per_page int
	,@free_rows_per_page int
	,@num_leaf_pages bigint
	,@leaf_space_used bigint
	,@non_leaf_levels int
	,@num_index_pages bigint = 0
	,@index_space_used bigint
	,@index_level int = 1


declare @type_sizes table ([name] varchar(50),[size] decimal(10,3),[isvariable] bit, [isstring] bit, [isprecise] bit)
insert into @type_sizes
values  ('bigint',8,0,0,0), --8 bytes
		--binary -- Tamanho do binário armazenado até 8000 bytes
		('bit',0.001,0,0,0), --1 bit
		('char',1,0,1,0), --1 byte por caracter até 8000 bytes
		('date',3,0,0,0), --3 bytes
		('datetime',8,0,0,0), --8 bytes
		('datetime2',8,0,0,0), --6 a 8 bytes
		('datetimeoffset',10,0,0,0), --8 a 10 bytes
		('decimal',5,0,0,1), --Precisão de 1 a 9 (5 bytes), 10 a 19 (9 bytes), 20 a 28 (13 bytes), 29 a 38 (17 bytes)
		('float',8,0,0,0), --4 ou 8 bytes
		--geography ?
		--geometry ?
		--hierchyid ?
		--image -- tamanho da imágem armazenada até 2GB
		('int',4,0,0,0), --4 bytes
		('money',4,0,0,0),--4 bytes
		('nchar',2,0,1,0),--2 bytes por caracter até 4000 bytes
		('ntext',2,0,1,0),--2 bytes por caracter até 2GB
		('numeric',5,0,0,1), --Precisão de 1 a 9 (5 bytes), 10 a 19 (9 bytes), 20 a 28 (13 bytes), 29 a 38 (17 bytes)
		('nvarchar',2,1,1,0),--2 bytes por caracter até 2GB
		('real',4,0,0,0),--4 bytes
		('smalldatetime',4,0,0,0),--4 bytes
		('smallint',2,0,0,0),--2 bytes
		('smallmoney',4,0,0,0),--4 bytes
		--sql_variant --tamanhos de dados variáveis pois pode receber qualquer tipo de dados, até 8000 bytes
		('sysname',2,0,1,0),--2 bytes por caracter até 128 caractéres
		('text',1,0,1,0), --1 byte por caracter até 2GB
		('time',5,0,0,0), --3 a 5 bytes
		('timestamp',8,0,0,0), --8 bytes
		('tinyint',1,0,0,0), --1 byte
		('uniqueidentifier',16,0,0,0), --8 byte
		--varbinary -- binários de tamanhos variáveis até 8000 bytes
		('varchar',1,1,1,0)--1 bytes por caracter até 2GB
		--xml até 2GB

declare @string varchar(100)	
declare @key_table table (colname varchar(100))
declare @include_table table (colname varchar(100))

set @key_column_list = replace(replace(@key_column_list,'[',''),']','')
set @Include_column_list = replace(replace(@Include_column_list,'[',''),']','')

while charindex(',',@key_column_list,0) <> 0
	begin
	select
		  
		@string=rtrim(ltrim(substring(@key_column_list,1,charindex(',',@key_column_list)-1))),
		@key_column_list=rtrim(ltrim(substring(@key_column_list,charindex(',',@key_column_list)+ len(','), len(@key_column_list))))
		  
	if len(@string) > 0
		insert into @key_table select @string
end 
	
if len(@key_column_list) > 0
	insert into @key_table select @key_column_list

while charindex(',',@Include_column_list,0) <> 0
	begin
	select
		  
		@string=rtrim(ltrim(substring(@Include_column_list,1,charindex(',',@Include_column_list)-1))),
		@Include_column_list=rtrim(ltrim(substring(@Include_column_list,charindex(',',@Include_column_list)+ len(','), len(@Include_column_list))))
		  
	if len(@string) > 0
		insert into @include_table select @string
end 
	
if len(@Include_column_list) > 0
	insert into @include_table select @Include_column_list


select 
	@num_rows = [rows]
	,@heap_clustered = indid
from sys.sysindexes 
where id = object_id(@table)
	and indid <= 1

select 
	@num_key_cols = count(1), 
	@fixed_key_size = sum(case  
								when ts.isvariable = 0 and ts.isstring = 1 then ts.size * cl.max_length
								when ts.isvariable = 0 and ts.isprecise = 1 then ts.size + ((cl.[precision] / 10)*4)
								when ts.isvariable = 0 and ts.isstring = 0 then ts.size 
							end), 
	@num_variable_key_cols = count(case ts.isvariable when 1 then 1 end), 
	@max_var_key_size = sum(case ts.isvariable when 1 then ts.size * cl.max_length else 0 end),
	@index_null_bitmap += 2 + ((count( case cl.is_nullable when 1 then 1 end)+7)/8),
	@leaf_null_bitmap += count( case cl.is_nullable when 1 then 1 end)
from sys.columns cl
	join sys.types tp 
		on cl.system_type_id = tp.system_type_id
	join @type_sizes ts
		on tp.[name] = ts.[name]
	join @key_table kt
		on cl.[name] = kt.colname
	
where 
	cl.[object_id] = object_id(@table)
option(recompile)

if (@heap_clustered = 1)
	begin
		select 
			@num_key_cols += count(1) + case id.is_unique when 0 then 1 else 0 end,
			@fixed_key_size += sum(case  
										when ts.isvariable = 0 and ts.isstring = 1 then ts.size * cl.max_length
										when ts.isvariable = 0 and ts.isprecise = 1 then ts.size + ((cl.[precision] / 10)*4)
										when ts.isvariable = 0 and ts.isstring = 0 then ts.size 
									end), 
			@num_variable_key_cols += count(case ts.isvariable when 1 then 1 end) + case id.is_unique when 0 then 1 else 0 end, 
			@max_var_key_size += sum(case ts.isvariable when 1 then ts.size * cl.max_length else 0 end) + case id.is_unique when 0 then 4 else 0 end 
		from sys.columns cl
			join sys.types tp 
				on cl.system_type_id = tp.system_type_id
			join @type_sizes ts
				on tp.[name] = ts.[name]
			join sys.index_columns ic
				on cl.[object_id] = ic.[object_id]
					and cl.column_id = ic.column_id
						and ic.index_id = 1
			join sys.indexes id
				on ic.[object_id] = id.[object_id]
					and ic.index_id = id.index_id
		where 
			cl.[object_id] = object_id(@table)
		group by id.is_unique
		option(recompile)

	end
else
	begin
		select 
			@num_key_cols += 1,
			@num_variable_key_cols += 1,
			@max_var_key_size += 8
	end

set @variable_key_size = 2 + (@num_variable_key_cols * 2) + @max_var_key_size
set @index_row_size = @fixed_key_size + @variable_key_size + @index_null_bitmap + 1
set @index_rows_per_page = floor(8096.0 / (@index_row_size + 2))

select 
	@num_leaf_cols = @num_key_cols + count(1), 
	@fixed_leaf_size = @fixed_key_size + isnull(sum(case  
								when ts.isvariable = 0 and ts.isstring = 1 then ts.size * cl.max_length
								when ts.isvariable = 0 and ts.isprecise = 1 then ts.size + ((cl.[precision] / 10)*4)
								when ts.isvariable = 0 and ts.isstring = 0 then ts.size 
							end),0), 
	@num_variable_leaf_cols = @num_variable_key_cols + count(case ts.isvariable when 1 then 1 end), 
	@max_var_leaf_size = @max_var_key_size + isnull(sum(case ts.isvariable when 1 then ts.size * cl.max_length else 0 end),0),
	@leaf_null_bitmap = 2 + (((count( case cl.is_nullable when 1 then 1 end)+@leaf_null_bitmap)+7)/8)
from sys.columns cl
	join sys.types tp 
		on cl.system_type_id = tp.system_type_id
	join @type_sizes ts
		on tp.[name] = ts.[name]
	join @include_table it
		on cl.[name] = it.colname
	
where 
	cl.[object_id] = object_id(@table)
option(recompile)

set @variable_leaf_size = 2 + (@num_variable_leaf_cols * 2) + @max_var_leaf_size
set @leaf_row_size = @fixed_leaf_size + @variable_leaf_size + @leaf_null_bitmap + 1
set @leaf_rows_per_page = floor(8092.0 / (@leaf_row_size + 2))
set @free_rows_per_page = floor(8096.0 * ((100 - @fill_factor)/100)/(@leaf_row_size + 2))
set @num_leaf_pages = ceiling(cast(@num_rows as float) / (@leaf_rows_per_page - @free_rows_per_page))
set @leaf_space_used = 8192 * @num_leaf_pages


select @non_leaf_levels = ceiling(1 + log((cast(@num_leaf_pages as float) / @index_rows_per_page),@index_rows_per_page))

--16 Calcular o número de páginas não folha no índice
while (@index_level <= @non_leaf_levels)
begin
	select @num_index_pages += ceiling(cast(@num_leaf_pages as float) / power(@index_rows_per_page,cast(@index_level as float)))
	set @index_level += 1
end

set @index_space_used = 8192 * @num_index_pages

select ceiling((@leaf_space_used + @index_space_used) / 1024 / 1024.0) [Tamanho_indice_mb]
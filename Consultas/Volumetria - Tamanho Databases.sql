declare @cmd varchar(max)

declare @datasize table
(
	[database] varchar(100)
	,[DataFilesGB] decimal(10,2)
	,[PercentUsedDF] decimal(6,2)
	,[LogFilesGB] decimal(10,2)
	,[PercentUsedLF] decimal(6,2)
	,[FilestreamGB] decimal(10,2)
	,[PercentUsedFF] decimal(6,2)
)

insert into @datasize
exec sp_msforeachdb'
use [?]

select 
	upper(db_name()) [Database]
	,sum(case [type] when 0 then size / 128.0 /1024 end)	[DataFilesGB]
	,sum( case [type] when 0 then  fileproperty(name,''spaceused'') end ) * 100.0 / sum(case [type] when 0 then size end) [PercentUsedDF]
	,sum(case [type] when 1 then size / 128.0 /1024 end)  [LogFilesGB]
	,sum( case [type] when 1 then  fileproperty(name,''spaceused'') end ) * 100.0 / sum(case [type] when 1 then size end) [PercentUsedLF]
	,sum(case [type] when 2 then size / 128.0 /1024 end)  [FilestreamGB]
	,sum(case [type] when 2 then  fileproperty(name,''spaceused'') end ) * 100.0 / sum(case [type] when 2 then size end) [PercentUsedFF]
from sys.database_files df;
'

select * From @datasize
--Linked Servers

select 
	[name] [LinkedServer],
	[product],
	[data_source]
from sys.servers 
where is_linked = 1
	and [data_source] not like '%.intermedium%'

--Pacotes

;with packages as
(
	select 
		[name] [Package],
		[description],
		case packagetype
			when 0 then 'Default Value'
			when 1 then 'SQL Server Import and Export Wizard'
			when 3 then 'SQL Server Replication'
			when 5 then 'SSIS Designer'
			when 6 then 'Maintenance Plan Designer or Wizard'
		end [packagetype],
		cast(cast(packagedata as varbinary(max)) as xml) PackageData
	from msdb.dbo.sysssispackages
)
select 
	* 
from packages
where (cast(packagedata as nvarchar(max)) like '%INTERSERV%' or cast(packagedata as nvarchar(max)) like '%INTERSERV%'
	
--Procedures
CREATE TABLE [dbo].[#temp](
	[database] [nvarchar](128) NULL,
	[name] [sysname] NOT NULL,
	[type_desc] [nvarchar](60) NULL,
	[Object_definition] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
insert into #temp
exec sp_msforeachdb '
use [?];

select 
	db_name()[Database],
	[name],
	type_desc,
	OBJECT_DEFINITION(object_id) [Object_definition]
from sys.objects 
where type in (''TR'',''V'',''P'',''FN'',''TF'')
	and OBJECT_DEFINITION(object_id) like ''%interserv%''
'
select * from #temp

--Jobs 

select 
	jb.[name]
	,js.step_id
	,js.step_name
	,js.command
from msdb.dbo.sysjobs jb
	join msdb.dbo.sysjobsteps js
		on jb.job_id = js.job_id
where js.command like '%interserv%'
drop table if exists #server_permissions;

select
	[Name]
	,[Permission]
	,[Value]
into #server_permissions
from sys.syslogins
unpivot ([value] for [permission] in ([sysadmin],[securityadmin],[serveradmin],[setupadmin],[diskadmin],[dbcreator],[bulkadmin]))upvt
where [value] > 0 

drop table if exists #database_permissions

create table #database_permissions	(	
										[Level] varchar(100),
										[User] sysname,
										[Permission_type] varchar(250),
										[Permission] varchar(100),
										[Schema] varchar(100),
										[Object] varchar(250),
										[Column] varchar(250)
									)
insert into #database_permissions
exec sp_msforeachdb '
use [?]


select 
	db_name() 
	,usr.name
	,''ROLE'' 
	,user_name(role_principal_id) 
	,null 
	,null 
	,null 
from sys.database_role_members rle
	inner join sys.database_principals usr
		on rle.member_principal_id = usr.principal_id
	inner join sys.server_principals lgn
		on usr.[sid] = lgn.[sid]
where (usr.principal_id between 5 and 100 and db_id() <> 4) or (usr.principal_id between 25 and 100 and db_id() = 4)

union all

select 
	db_name() 
	,usr.name 
	,prm.state_desc 
	,permission_name
	,schema_name(obj.schema_id) 
	,obj.name 
	,col.name 
from sys.database_permissions prm
	inner join sys.database_principals usr
		on prm.grantee_principal_id = usr.principal_id
	left join sys.server_principals lgn
		on usr.[sid] = lgn.[sid]
	left join sys.objects obj
		on prm.major_id = obj.[object_id]
	left join sys.columns col
		on prm.major_id = col.[object_id]
			and prm.minor_id = col.column_id
where (usr.principal_id between 5 and 100 and db_id() <> 4) or (usr.principal_id between 25 and 100 and db_id() = 4)
'
select 
	prms.[Level]
	,prms.[User]
	,sp.is_disabled
	,sp.[Type_Desc]
	,sp.[Create_date]
	,sp.[Modify_date]
	,prms.[Permission_type]
	,prms.[Permission]
	,prms.[schema]
	,prms.[Object]
	,prms.[Column]
from (
		select * from #database_permissions 
		union all
		select
			'ALL SERVER'
			,[Name]
			,'SERVER ROLE'
			,[Permission]
			,null
			,null
			,null
		from #server_permissions 
	)prms
left join sys.server_principals sp
	on prms.[user] = sp.[name]
order by case [level] when 'ALL SERVER' then '1' else [level]end  

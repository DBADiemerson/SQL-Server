declare @database_permissions table 
(
    [SID] varbinary(100)
    ,[User_name] varchar(100)
    ,[Database] varchar(100)
)

insert into @database_permissions exec sp_msforeachdb'
use [?];

select 
    dp.sid
    ,user_name(rm.member_principal_id) [User]
    ,db_name() [Database]
from sys.database_role_members rm
    join sys.database_principals dp
        on rm.member_principal_id = dp.principal_id
where user_name(rm.role_principal_id) = ''db_owner''
'

select
    sp.[name]
	,sp.[type_desc]
    ,sp.[create_date]
	,sp.modify_date
    ,sp.is_disabled
    ,isnull(stuff(admins,1,2,''),'') [Server_roles]
    ,isnull(stuff(databases,1,2,''),'') [Db_owner_databases]
from sys.server_principals sp
    outer apply (
                    select ', '+[Database]
                    from @database_permissions dp
                    where dp.sid = sp.sid
                    order by [Database]
                    for xml path('')
                )dbroles (databases)
    outer apply (
                    select
                        ', '+[serverrole]
                    from(
                        select 
                            [sid]
                            ,[serverrole]
                        from sys.syslogins sl
                            unpivot ([Value] for [ServerRole] in([sysadmin] 
                            ,[securityadmin] 
                            ,[serveradmin] 
                            ,[setupadmin] 
                            ,[processadmin]
                            ,[diskadmin] 
                            ,[dbcreator]
                            ,[bulkadmin]))upvt
                        where value = 1
                    )unpivotroles
                    where unpivotroles.sid = sp.sid
                    for xml path('')
                )srvroles (admins)
where [type] in ('U','G')
and admins is not null or databases is not null
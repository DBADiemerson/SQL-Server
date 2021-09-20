--Extended Events SQL Server 2008R2
------------------------------------

declare 
	@package nvarchar(100) = 'sqlserver'
	,@event nvarchar(100) = 'sql_statement_completed'


-- Packages and events
select 
	pkg.[name] [Packages]
	,evt.[name] [Event]
	,evt.[description] [Event_desc]
	,evt.capabilities_desc [Event_cap_desc]
	,evc.[name] [Event_columns]
	,evc.[description] [Evt_col_desc]
from sys.dm_xe_packages pkg
	left join sys.dm_xe_objects evt
		on pkg.[guid] = evt.package_guid
			and evt.[object_type] = 'event'
	left join sys.dm_xe_object_columns evc
		on evt.[name] = evc.[object_name]
			and evt.package_guid = evc.object_package_guid
where (pkg.name like '%'+@package+'%' or (@package is null))
	and (evt.name like '%'+@event+'%' or (@event is null))
order by 1,2,5

------------------------------------------
-- Packages and actions
select 
	pkg.[name] [Packages]
	,act.[name] [Action]
	,act.[description] [Action_desc]
	,act.capabilities_desc [Action_cap_desc]
from sys.dm_xe_packages pkg
	inner join sys.dm_xe_objects act
		on pkg.[guid] = act.package_guid
			and act.[object_type] = 'action'
where (pkg.name like '%'+@package+'%' or (@package is null))
order by 1,2

------------------------------------------
-- Packages and predicates
select 
	pkg.[name] [Packages]
	,prd.[name] [Predicate]
	,prd.[description] [Predicate_desc]
from sys.dm_xe_packages pkg
	inner join sys.dm_xe_objects prd
		on pkg.[guid] = prd.package_guid
			and prd.[object_type] = 'pred_source'
where (pkg.name like '%'+@package+'%' or (@package is null))
order by 1,2


------------------------------------------
-- Packages and targets
select 
	pkg.[name] [Packages]
	,tgt.[name] [Target]
	,tgt.[description] [Target_desc]
	,tgt.capabilities_desc [Event_cap_desc]
	,tgc.[name] [Parameter]
	,tgc.[description] [Parameter_dec]
	,tgc.[column_value] [Par_default_val]
from sys.dm_xe_packages pkg
	inner join sys.dm_xe_objects tgt
		on pkg.[guid] = tgt.package_guid
			and tgt.[object_type] = 'target'
	left join sys.dm_xe_object_columns tgc
		on tgt.[name] = tgc.[object_name]
			and tgt.package_guid = tgc.object_package_guid
order by 1,2,5



------------------------------------------
-- Criação de sessão no extended events
/*
IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE Name='DBA - Coletas')
    DROP EVENT SESSION [DBA - Coletas] ON SERVER
GO
CREATE EVENT SESSION [DBA - Coletas] ON SERVER 
ADD EVENT sqlos.wait_info(
							WHERE ([duration]>=(2000000))
						 ),
ADD EVENT sqlos.wait_info_external(
										WHERE ([duration]>=(2000000))
									),
ADD EVENT sqlserver.error_reported(
										ACTION(
													sqlserver.client_app_name,
													sqlserver.client_hostname,
													sqlserver.database_id,
													sqlserver.sql_text,
													sqlserver.username
												)
										WHERE ([severity]>=(17))
									),
ADD EVENT sqlserver.sp_statement_completed(
												ACTION(
															sqlserver.client_app_name,
															sqlserver.client_hostname,
															sqlserver.database_id,
															sqlserver.sql_text,
															sqlserver.username
														)
												 WHERE ([duration]>=(3000000))
										),
ADD EVENT sqlserver.sql_statement_completed(
												ACTION(
															sqlserver.client_app_name,
															sqlserver.client_hostname,
															sqlserver.database_id,
															sqlserver.sql_text,
															sqlserver.username
														)
												 WHERE ([duration]>=(3000000))
										)
ADD TARGET package0.asynchronous_file_target(SET filename=N'W:\DBA\Extended_events\DBA - Coletas.xel',max_file_size=(100),max_rollover_files=(100))
WITH (STARTUP_STATE=ON)
GO
*/
------------------------------------------
-- Criação de sessão no extended events
/*

-- Start the event session  
ALTER EVENT SESSION [DBA - Coletas] ON SERVER  
STATE = start;  
GO  

-- Obtain live session statistics   
SELECT * FROM sys.dm_xe_sessions;  
SELECT * FROM sys.dm_xe_session_events;  
GO  
  
-- Add new events to the session  
ALTER EVENT SESSION test_session ON SERVER  
ADD EVENT sqlserver.database_transaction_begin,  
ADD EVENT sqlserver.database_transaction_end;  
GO  



*/




/*
select pkg.name as PackageName, obj.name as ActionName , obj.*
from sys.dm_xe_packages pkg 
inner join sys.dm_xe_objects obj on pkg.guid = obj.package_guid 
where obj.object_type = 'action' 
order by 1, 2

select 
	pkg.name, 
	pkg.description, 
	mod.* 
from sys.dm_xe_packages pkg 
	inner join sys.dm_os_loaded_modules mod 
		on mod.base_address = pkg.module_address
*/
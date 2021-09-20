with blkd as
(
	select distinct
		blocked
	from sys.sysprocesses sp
	where blocked > 0 
		and spid <> blocked
)
select 
		'kill '+cast(spid as varchar) [Kill],
		sp.[dbid],
		sp.spid,
		sp.blocked,
		sp.cmd,
		sp.[status],
		sp.open_tran,
		sp.login_time,
		sp.last_batch,
		sp.waittime,
		sp.lastwaittype,
		sp.waitresource,
		sp.loginame,
		sp.[program_name],
		sp.hostname,
		(select [text] from sys.fn_get_sql(sp.[sql_handle])) Query		
from sys.sysprocesses sp
	left join blkd 
		on sp.spid = blkd.blocked
where (blkd.blocked is not null
	or sp.blocked <> 0)
order by spid

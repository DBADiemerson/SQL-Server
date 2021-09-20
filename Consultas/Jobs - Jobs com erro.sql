with ultimaexec
as
(
	select
		row_number() over(partition by job_id order by instance_id desc) id
		,job_id
		,step_id
		,run_status
		,[message]
		,run_date
		,run_time
	from msdb..sysjobhistory
	where step_id > 0
)
select 
	jb.name [job]
	,ue.step_id [id]
	,js.step_name [step]
	,cast(run_date as varchar)+' '+stuff(stuff(right('000000'+cast(run_time as varchar),6),5,0,':'),3,0,':') [dataexec]
	,ue.[message] [erro]
from ultimaexec ue
	join msdb.dbo.sysjobs jb
		on ue.job_id = jb.job_id
	join msdb.dbo.sysjobsteps js
		on ue.job_id = js.job_id
			and ue.step_id = js.step_id
where id = 1
and run_status = 0
go



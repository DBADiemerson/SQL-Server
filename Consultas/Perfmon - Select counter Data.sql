use dba
go

select 
	cast(left(counterdatetime,16) as datetime) [Timestamp],
	[Page life expectancy] [PLE],
	[User Connections] [Conexoes],
	[% Usage] [PercentPaginacao],
	[% Processor Time] [PercentProcessador],
	[Processor Queue Length] [FilaCPU],
	[Memory Grants Pending] [FilaMemoria]
from (
select counterdatetime, countername, countervalue
from dbo.counterdetails cde
	join dbo.counterdata cda
		on cde.counterid = cda.counterid
where cast(left(cda.counterdatetime,16) as datetime) >= dateadd(hh,-1,getdate())
	and cast(replace(cde.machinename,'\\','') as nvarchar) = serverproperty('computernamephysicalnetbios')
		and countername in (
							'Page life expectancy',
							'User Connections',
							'Memory Grants Pending',
							'% Usage',
							'% Processor Time',
							'Processor Queue Length'
							)
)tbl
pivot(avg(countervalue) for countername in (
											[Page life expectancy],
											[User Connections],
											[% Usage],
											[% Processor Time],
											[Processor Queue Length],
											[Memory Grants Pending]
											))pvt
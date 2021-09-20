if object_id('tempdb..#temp') is not null
	drop table #temp

select
	 cast(left(cda.counterdatetime,16) as datetime) [Timestamp]
	 ,replace(right(countername,5),'/','') [Counter]
	 ,instancename
	 ,cast((countervalue * 1000) as decimal(17,3)) ms
into #temp
from dba.dbo.counterdetails cde
	join dba.dbo.counterdata cda
		on cde.counterid = cda.counterid 
where cde.objectname = 'PhysicalDisk'
	and cast(left(cda.counterdatetime,16) as datetime) >= cast('20170724' as datetime)


declare @pivot varchar(2000) = ''
select @pivot = @pivot+'['+convert(varchar,instancename)+'],'from (select distinct instancename from #temp )cols order by instancename
select @pivot = 'select [timestamp],'+left(@pivot,len(@pivot)-1)+' from #temp pivot(avg(ms) for instancename in('+@pivot+'[0]))pvt where [counter] = ''read'' '
exec(@pivot)

select @pivot = ''
select @pivot = @pivot+'['+convert(varchar,instancename)+'],'from (select distinct instancename from #temp )cols order by instancename
select @pivot = 'select [timestamp],'+left(@pivot,len(@pivot)-1)+' from #temp pivot(avg(ms) for instancename in('+@pivot+'[0]))pvt where [counter] = ''write'' '
exec(@pivot)

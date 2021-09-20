dbcc sqlperf('logspace')

select 
	counter_name
	,cntr_value / 1024 [TamanhoMB]
from sys.dm_os_performance_counters
where counter_name like '%log file%'

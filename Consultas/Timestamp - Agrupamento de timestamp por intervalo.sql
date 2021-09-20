declare @intervalo int = 10 --minutos

select 
	top 10 
	dateadd(minute, (datediff(minute, 0,[timestamp]) / @intervalo) * @intervalo, 0)
	,* 

from monitor_queries
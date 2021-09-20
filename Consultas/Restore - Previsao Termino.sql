select 
	percent_complete, 
	DATEADD(SECOND,floor((total_elapsed_time /1000 / percent_complete)*100),start_time) [Previsao_restore]
from sys.dm_exec_requests 
where command like '%restore%'


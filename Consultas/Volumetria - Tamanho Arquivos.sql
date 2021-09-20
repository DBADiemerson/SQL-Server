select 
	[Name]
	,[Physical_name]
	,[state_desc]
	,size / 128 [TamanhoMB]
	,fileproperty([name],'spaceused')/128 [UtilizadoMB]
	,max_size [Limite_TamanhoMB]
from sys.database_files
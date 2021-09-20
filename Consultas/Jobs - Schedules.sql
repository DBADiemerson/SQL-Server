USE [DBA]
GO

select 
	jb.Name [Job]
	,jb.[Enabled] [HabilitadoJ] 
	,jb.[Description] [Descricao]
	,sc.name [Schedule]
	,sc.[Enabled][HabilitadoS]
	,case sc.freq_type
		when 1 then 'Apenas uma vez'
		when 4 then 'Diário'
		when 8 then 'Semanal'
		when 16 then 'Mensal'
		when 32 then 'Mensal'
		when 64 then 'Inicialização do Agent'
		when 128 then 'Servidor Ocioso'
	end teste
	,case sc.freq_type 
		when 1 then 'Apenas uma vez: '+stuff(stuff(cast(sc.active_start_date as varchar),7,0,'-'),5,0,'-')+' '+stuff(stuff(right('000000'+cast(sc.active_start_time as varchar),6),5,0,':'),3,0,':')
		when 4 then 'A cada '+cast(sc.freq_interval as varchar)+' dia(s)'
		when 8 then 'A cada '+cast(sc.freq_recurrence_factor as varchar)+' Semana(s)'+	case when sc.freq_interval & 1 = 1 then ', Dom' else '' end+
																						case when sc.freq_interval & 2 = 2 then ', Seg' else '' end+
																						case when sc.freq_interval & 4 = 4 then ', Ter' else '' end+
																						case when sc.freq_interval & 8 = 8 then ', Qua' else '' end+
																						case when sc.freq_interval & 16 = 16 then ', Qui' else '' end+
																						case when sc.freq_interval & 32 = 32 then ', Sex' else '' end+
																						case when sc.freq_interval & 64 = 64 then ', Sab' else '' end
		when 16 then 'A cada'+cast(sc.freq_recurrence_factor as varchar)+' Mês(es), dia: '+cast(sc.freq_interval as varchar)
		when 32 then 'A cada'+cast(sc.freq_recurrence_factor as varchar)+' Mês(es), no(a) '+case sc.freq_relative_interval
																								when 1 then 'primeiro(a)'
																								when 2 then 'segundo(a)'
																								when 4 then 'terceiro(a)'
																								when 8 then 'quarto(a)'
																								when 16 then 'último(a)'
																							end+
																							case sc.freq_interval
																								when 1 then ' domingo'
																								when 2 then ' segunda'
																								when 3 then ' terça'
																								when 4 then ' quarta'
																								when 5 then ' quinta'
																								when 6 then ' sexta'
																								when 7 then ' sábado'
																								when 8 then ' dia'
																								when 9 then ' dia de semana'
																								when 10 then ' dia do fim de semana'
																							end
																								


		when 64 then 'Inicialização do Agent'
		when 128 then 'Servidor ocioso'
	end 
	+case freq_subday_type
		 when 0 then ''
		 when 1 then ' às '+stuff(stuff(right('000000'+cast(sc.active_start_time as varchar),6),5,0,':'),3,0,':')
		 else ', a cada '+cast(freq_subday_interval as varchar)+ case freq_subday_type 
																	when 2 then ' segundos'
																	when 4 then ' minutos'
																	when 8 then ' horas'
																end
			+' entre '+stuff(stuff(right('000000'+cast(sc.active_start_time as varchar),6),5,0,':'),3,0,':')+' e '+stuff(stuff(right('000000'+cast(sc.active_end_time as varchar),6),5,0,':'),3,0,':')
	end [Frequencia]
from msdb.dbo.sysjobs jb
	join msdb.dbo.sysjobschedules js
		on jb.job_id = js.job_id
	join msdb.dbo.sysschedules sc
		on js.schedule_id = sc.schedule_id 

GO



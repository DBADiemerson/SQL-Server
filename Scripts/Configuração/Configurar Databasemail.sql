--Configuração do database_mail via script
--Habilitando o Database Mail XPs
sp_configure 'show advanced options',1
GO
RECONFIGURE
GO
sp_configure 'Database Mail XPs',1
GO
reconfigure

--Criação do database mail profile
exec msdb.dbo.sysmail_add_profile_sp @profile_name = 'DBA', @description = 'Email para o envio de notificações'
go

--Atribuição das permissões para o Profile
exec msdb.dbo.sysmail_add_principalprofile_sp  @profile_name = 'DBA', @principal_name = 'public', @is_default = 0
go

declare @displayname nvarchar(100) = 'Database Mail: Cliente - '+@@servername
--Criação da conta para envio de email
exec msdb.dbo.sysmail_add_account_sp @account_name = 'Suporte_acc',
    @email_address = 'suporte@dominio.com',
    @display_name = @displayname,
    @replyto_address = 'suporte@rdornel.com',
    @description = 'Conta para envio de emails de notificações de jobs e alertas',
    @mailserver_name = 'smtp.office365.com',
    @mailserver_type = 'SMTP',
    @port = 587,
    @username = 'suporte@dominio.com',
    @password = 'Senha forte',
    @use_default_credentials = 0,
    @enable_ssl = 1

--Vincluar conta ao profile
exec msdb.dbo.sysmail_add_profileaccount_sp @profile_name = 'DBA', @account_name = 'Suporte_acc', @sequence_number = 1

--Configurar agent para envio de emails
EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1, 
		@databasemail_profile=N'DBA', 
		@use_databasemail=1
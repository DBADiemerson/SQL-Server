SELECT 
	'kill ' + cast(es.session_id AS VARCHAR) [Kill]
	,DB_NAME(tdt.[database_id]) [DatabaseName]
	,d.[recovery_model_desc] [RecoveryModel]
	,d.[log_reuse_wait_desc] [LogReuseWait]
	,es.[original_login_name] [OriginalLoginName]
	,es.[program_name] [ProgramName]
	,es.[session_id] [SessionID]
	,er.[blocking_session_id] [BlockingSessionId]
	,er.[wait_type] [WaitType]
	,er.[last_wait_type] [LastWaitType]
	,er.[status] [Status]
	,tat.[transaction_id] [TransactionID]
	,tat.[transaction_begin_time] [TransactionBeginTime]
	,tdt.[database_transaction_begin_time] [DatabaseTransactionBeginTime]
	,CASE tdt.[database_transaction_state]
		WHEN 1
			THEN 'The transaction has not been initialized.'
		WHEN 3
			THEN 'The transaction has been initialized but has not generated any log records.'
		WHEN 4
			THEN 'The transaction has generated log records.'
		WHEN 5
			THEN 'The transaction has been prepared.'
		WHEN 10
			THEN 'The transaction has been committed.'
		WHEN 11
			THEN 'The transaction has been rolled back.'
		WHEN 12
			THEN 'The transaction is being committed. In this state the log record is being generated, but it has not been materialized or persisted.'
		ELSE NULL 
		END [DatabaseTransactionStateDesc]
	,est.[text] [StatementText]
	,tdt.[database_transaction_log_record_count] [DatabaseTransactionLogRecordCount]
	,tdt.[database_transaction_log_bytes_used] [DatabaseTransactionLogBytesUsed]
	,tdt.[database_transaction_log_bytes_reserved] [DatabaseTransactionLogBytesReserved]
	,tdt.[database_transaction_log_bytes_used_system] [DatabaseTransactionLogBytesUsedSystem]
	,tdt.[database_transaction_log_bytes_reserved_system] [DatabaseTransactionLogBytesReservedSystem]
	,tdt.[database_transaction_begin_lsn] [DatabaseTransactionBeginLsn]
	,tdt.[database_transaction_last_lsn] [DatabaseTransactionLastLsn]
FROM sys.dm_exec_sessions es
	INNER JOIN sys.dm_tran_session_transactions tst 
		ON es.[session_id] = tst.[session_id]
	INNER JOIN sys.dm_tran_database_transactions tdt 
		ON tst.[transaction_id] = tdt.[transaction_id]
	INNER JOIN sys.dm_tran_active_transactions tat
		ON tat.[transaction_id] = tdt.[transaction_id]
	INNER JOIN sys.databases d 
		ON d.[database_id] = tdt.[database_id]
	LEFT JOIN sys.dm_exec_requests er 
		ON es.[session_id] = er.[session_id]
	LEFT JOIN sys.dm_exec_connections ec 
		ON ec.[session_id] = es.[session_id]
	OUTER APPLY sys.dm_exec_sql_text(ec.[most_recent_sql_handle]) est
WHERE DB_NAME(tdt.[database_id]) = 'tempdb' --tdt.[database_transaction_state] >= 4
ORDER BY [database_transaction_log_bytes_reserved] DESC
select 
	db_name(database_id),
	replica_id,
	is_primary_replica,
	synchronization_state_desc,
	synchronization_health_desc,
	last_redone_lsn,
	last_redone_time,
	last_received_lsn,
	last_received_time,
	last_commit_lsn,
	last_commit_time,
	log_send_rate log_send_rate_KB,
	redo_rate redo_rate_KB,
	log_send_queue_size log_send_queue_size_KB,
	redo_queue_size,
	secondary_lag_seconds
from sys.dm_hadr_database_replica_states  
where database_id = 5
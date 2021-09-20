select 
    db_name(hdr.database_id)
	,ar.replica_server_name
    ,hdr.synchronization_state_desc
    ,hdr.synchronization_health_desc
	,hdr.redo_queue_size
	,hdr.redo_rate
    ,hdr.redo_queue_size / hdr.redo_rate [DelaySeg]
from sys.availability_replicas ar
    join sys.dm_hadr_database_replica_states hdr
        on ar.replica_id = hdr.replica_id
where  hdr.is_primary_replica = 0
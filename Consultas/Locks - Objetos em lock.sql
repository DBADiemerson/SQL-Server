SELECT 
     TL.resource_type,
     TL.resource_database_id,
     TL.resource_associated_entity_id,
     TL.request_mode,
     TL.request_session_id,
     WT.blocking_session_id,
     O.name AS [object name],
     O.type_desc AS [object descr],
     P.partition_id AS [partition id],
     P.rows AS [partition/page rows],
     AU.type_desc AS [index descr],
     AU.container_id AS [index/page container_id]
FROM sys.dm_tran_locks AS TL
INNER JOIN sys.dm_os_waiting_tasks AS WT 
 ON TL.lock_owner_address = WT.resource_address
LEFT OUTER JOIN sys.objects AS O 
 ON O.object_id = TL.resource_associated_entity_id
LEFT OUTER JOIN sys.partitions AS P 
 ON P.hobt_id = TL.resource_associated_entity_id
LEFT OUTER JOIN sys.allocation_units AS AU 
 ON AU.allocation_unit_id = TL.resource_associated_entity_id;
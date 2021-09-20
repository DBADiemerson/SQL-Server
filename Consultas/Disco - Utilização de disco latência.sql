use master
go
SELECT  DB_NAME(vfs.database_id) AS database_name ,
        vfs.database_id ,
        vfs.FILE_ID ,
        io_stall_read_ms / NULLIF(num_of_reads, 0) AS avg_read_latency ,
        io_stall_write_ms / NULLIF(num_of_writes, 0)
                                               AS avg_write_latency ,
        io_stall / NULLIF(num_of_reads + num_of_writes, 0)
                                               AS avg_total_latency ,
        num_of_bytes_read / NULLIF(num_of_reads, 0)
                                               AS avg_bytes_per_read ,
        num_of_bytes_written / NULLIF(num_of_writes, 0)
                                               AS avg_bytes_per_write ,
        vfs.io_stall ,
        vfs.num_of_reads ,
        vfs.num_of_bytes_read ,
        vfs.io_stall_read_ms ,
        vfs.num_of_writes ,
        vfs.num_of_bytes_written ,
        vfs.io_stall_write_ms ,
        size_on_disk_bytes / 1024 / 1024. AS size_on_disk_mbytes ,
        physical_name
FROM    sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs
        JOIN sys.master_files AS mf ON vfs.database_id = mf.database_id
                                       AND vfs.FILE_ID = mf.FILE_ID
ORDER BY avg_total_latency DESC

--

use master
go
drop table if exists #dm_io_virtual_file_stats;

select
	*
into #dm_io_virtual_file_stats
from sys.dm_io_virtual_file_stats(null,null);

waitfor delay '00:15:00'

select
	db_name(mf.database_id) [Database_name],
	mf.[name] [File_name],
	mf.physical_name,
	mf.size / 128 [File_size_mb],
	(vfs.num_of_reads - vfs1.num_of_reads) [Num_of_reads],
	case when (vfs.num_of_reads - vfs1.num_of_reads) > 0 then (vfs.io_stall_read_ms - vfs1.io_stall_read_ms) / (vfs.num_of_reads - vfs1.num_of_reads) end [Avg_ms_read],
	case when (vfs.num_of_reads - vfs1.num_of_reads) > 0 then (vfs.num_of_bytes_read - vfs1.num_of_bytes_read) / (vfs.num_of_reads - vfs1.num_of_reads) end [Avg_bytes_read],
	(vfs.num_of_writes - vfs1.num_of_writes) [Num_of_writes],
	case when (vfs.num_of_writes - vfs1.num_of_writes) > 0 then (vfs.io_stall_write_ms - vfs1.io_stall_write_ms) / (vfs.num_of_writes - vfs1.num_of_writes) end [Avg_ms_write],
	case when (vfs.num_of_writes - vfs1.num_of_writes) > 0 then (vfs.num_of_bytes_written - vfs1.num_of_bytes_written) / (vfs.num_of_writes - vfs1.num_of_writes) end [Avg_bytes_write]
from sys.master_files mf
	inner join sys.dm_io_virtual_file_stats (null,null) vfs
		on mf.[database_id] = vfs.[database_id]
			and mf.[file_id] = vfs.[file_id]
	inner join #dm_io_virtual_file_stats vfs1
		on mf.[database_id] = vfs1.[database_id]
			and mf.[file_id] = vfs1.[file_id]
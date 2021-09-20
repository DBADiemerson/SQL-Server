-- Nesta query, que avalia os tempos de leitura, todo calor acima de 100 é ruim

SELECT UPPER(LEFT(mf.physical_name, 1)) as disco, physical_name, ( io_stall_read_ms / ( 1.0 + num_of_reads ) ) as [Tempo (ms)]
FROM    sys.dm_io_virtual_file_stats(NULL, NULL) AS fs
        INNER JOIN sys.master_files AS mf ON fs.database_id = mf.database_id
                                             AND fs.[file_id] = mf.[file_id]
--WHERE   ( io_stall_read_ms / ( 1.0 + num_of_reads ) ) > 100
order by 3 desc

-- Nesta query, que avalia os tempos de escrita, todo valor acima de 20 é ruim

SELECT UPPER(LEFT(mf.physical_name, 1)) as Disco, physical_name, ( io_stall_write_ms / ( 1.0 + num_of_writes ) ) as [Tempo (ms)]
FROM    sys.dm_io_virtual_file_stats(NULL, NULL) AS fs
        INNER JOIN sys.master_files AS mf ON fs.database_id = mf.database_id
                                             AND fs.[file_id] = mf.[file_id]
--WHERE   ( io_stall_write_ms / ( 1.0 + num_of_writes ) ) > 20
order by 3 desc

/*

Para efetuar monitoração de velocidade de discos

USE [DBA_ADMIN]
GO

DROP TABLE [dbo].[TB_PERFORMANCE_DISCO]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TB_PERFORMANCE_DISCO](
    [Performance_Type] [char](1) NOT NULL,
    [Collect_Date] [datetime] NOT NULL,
	[Disk_Name] [char](1) NOT NULL,
	[Physical_Name] [varchar](512) NOT NULL,
	[Average] [numeric](38, 18) NOT NULL,
    [IO_Stall_ms] bigint NOT NULL,
    [Num_Operations] bigint NOT NULL,
	[Bytes_Read] [bigint] NOT NULL,
	[Bytes_Written] [bigint] NOT NULL
) ON [PRIMARY]

GO


create index IX_PERFORMANCE_DISCO_001 on DBA_ADMIN.dbo.TB_PERFORMANCE_DISCO (Collect_Date, Performance_Type, Physical_Name)

go


-- Nesta query, que avalia os tempos de leitura, todo calor acima de 100 é ruim
use master
go

insert into DBA_ADMIN.dbo.TB_PERFORMANCE_DISCO (Performance_Type, Collect_Date, Disk_Name, Physical_Name, Average, IO_Stall_ms, Num_Operations, Bytes_Read, Bytes_Written)
SELECT 'R', getdate(), UPPER(LEFT(mf.physical_name, 1)) as disco, physical_name, ( io_stall_read_ms / ( 1.0 + num_of_reads ) ) as [Tempo (ms)], io_stall_read_ms, num_of_reads, num_of_bytes_read, num_of_bytes_written
FROM    sys.dm_io_virtual_file_stats(NULL, NULL) AS fs
        INNER JOIN sys.master_files AS mf ON fs.database_id = mf.database_id
                                             AND fs.[file_id] = mf.[file_id]
--WHERE   ( io_stall_read_ms / ( 1.0 + num_of_reads ) ) > 100
order by 5 desc

-- Nesta query, que avalia os tempos de escrita, todo valor acima de 20 é ruim

insert into DBA_ADMIN.dbo.TB_PERFORMANCE_DISCO (Performance_Type, Collect_Date, Disk_Name, Physical_Name, Average, IO_Stall_ms, Num_Operations, Bytes_Read, Bytes_Written)
SELECT 'W', getdate(), UPPER(LEFT(mf.physical_name, 1)) as Disco, physical_name, ( io_stall_write_ms / ( 1.0 + num_of_writes ) ) as [Tempo (ms)], io_stall_write_ms, num_of_writes, num_of_bytes_read, num_of_bytes_written
FROM    sys.dm_io_virtual_file_stats(NULL, NULL) AS fs
        INNER JOIN sys.master_files AS mf ON fs.database_id = mf.database_id
                                             AND fs.[file_id] = mf.[file_id]
--WHERE   ( io_stall_write_ms / ( 1.0 + num_of_writes ) ) > 20
order by 5 desc


delete from DBA_ADMIN.dbo.TB_PERFORMANCE_DISCO
where Collect_Date < dateadd(mm, -6, getdate())

select * from DBA_ADMIN.dbo.TB_PERFORMANCE_DISCO



*/
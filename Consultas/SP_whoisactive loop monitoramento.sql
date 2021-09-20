if object_id('tempdb..##tblxWhoIsActive') is not null
	drop table ##tblxWhoIsActive

CREATE TABLE ##tblxWhoIsActive (
	[dd hh:mm:ss.mss] VARCHAR(8000) NULL
	,[session_id] SMALLINT NOT NULL
	,[sql_text] XML NULL
	,[login_name] NVARCHAR(128) NOT NULL
	,[wait_info] NVARCHAR(4000) NULL
	,[tempdb_allocations] VARCHAR(30) NULL
	,[tempdb_current] VARCHAR(30) NULL
	,[blocking_session_id] SMALLINT NULL
	,[reads] VARCHAR(30) NULL
	,[writes] VARCHAR(30) NULL
	,[physical_reads] VARCHAR(30) NULL
	,[query_plan] XML NULL
	,[CPU] VARCHAR(30) NULL
	,[used_memory] VARCHAR(30) NULL
	,[status] VARCHAR(30) NOT NULL
	,[open_tran_count] VARCHAR(30) NULL
	,[percent_complete] VARCHAR(30) NULL
	,[host_name] NVARCHAR(128) NULL
	,[database_name] NVARCHAR(128) NULL
	,[program_name] NVARCHAR(128) NULL
	,[start_time] DATETIME NOT NULL
	,[login_time] DATETIME NULL
	,[request_id] INT NULL
	,[collection_time] DATETIME NOT NULL
	)



declare  @delay varchar(20) = '00:01:00',  @msg varchar(1000), @destination_table varchar(4000) = '##tblxWhoIsActive';

while 1=1
begin
	begin try

		exec dbo.sp_WhoIsActive	@output_column_list  = '
				[dd hh:mm:ss.mss][session_id][sql_text][login_name][wait_info][tempdb_allocations][tempdb_current][blocking_session_id][reads][writes][physical_reads][query_plan][CPU][used_memory][status][open_tran_count][percent_complete][host_name][database_name][program_name][start_time][login_time][request_id][collection_time]
		',
					@get_plans = 1,
					@destination_table = @destination_table;
	end try
	begin catch
		print error_message()
		break;
	end catch
	
	waitfor delay @delay
end



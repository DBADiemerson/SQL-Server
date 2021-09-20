select 
    db_name(database_id) [Database]
    ,count(case [type] when 0 then 1 end) [DataFiles]
    ,count(case [type] when 1 then 1 end) [LogFiles]
    ,count(case [type] when 2 then 1 end) [Filestream]
    ,count(case when [type] > 2 then 1 end) [Others]
    ,sum(case [type] when 0 then size end )/128 [DataSizeMB]
    ,sum(case [type] when 1 then size end )/128 [LogSizeMB]
    ,count(case when [max_size] not in (-1,268435456) then 1 end) [ArqsCrescLimitado]
    ,count(case [is_percent_growth] when 1 then 1 end) [ArqsCrescPercent]
from sys.master_files
group by database_id
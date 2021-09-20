if object_id('fn_split') is not null
	drop function fn_split
go

create function [dbo].[fn_split]
(
    @string varchar(5000),
    @delimiter char(1)
)
returns table
as
return
(
    with split(stpos,endpos)
    as(
        select 0 as stpos, charindex(@delimiter,@string) as endpos
        union all
        select endpos+1, charindex(@delimiter,@string,endpos+1)
            from split
            where endpos > 0
    )
    select 'data' = rtrim(ltrim(substring(@string,stpos,coalesce(nullif(endpos,0),len(@string)+1)-stpos)))
    from split
)


DECLARE @SIZE INT
SET @SIZE = 16750

WHILE (@SIZE >= 14750)
BEGIN

dbcc shrinkfile ('filename',@size)

SET @SIZE = @SIZE - 250 

END
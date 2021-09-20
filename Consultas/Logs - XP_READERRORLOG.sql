xp_readerrorlog

/*
xp_readerrrorlog

Even though sp_readerrolog accepts only 4 parameters, the extended stored procedure accepts at least 7 parameters.

If this extended stored procedure is called directly the parameters are as follows:

    1 - Value of error log file you want to read: 0 = current, 1 = Archive #1, 2 = Archive #2, etc...
    2 - Log file type: 1 or NULL = error log, 2 = SQL Agent log
    3 - Search string 1: String one you want to search for
    4 - Search string 2: String two you want to search for to further refine the results
    5 - Search from start time
    6 - Search to end time
    7 - Sort order for results: N'asc' = ascending, N'desc' = descending
*/
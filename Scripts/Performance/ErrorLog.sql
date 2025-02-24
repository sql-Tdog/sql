use master
go
 
 --get location of error log:
 SELECT SERVERPROPERTY('ErrorLogFileName') AS 'Error log file location';
 
/*
--read error log: @p1-# of the log, starts with 0, most recent
--@p2-1=SQL Server error log, 2=SQL Server Agent error log
--@p3 and @p4 are search strings
EXEC sys.sp_readerrorlog 0, 1, 'error'--,'recovery'
EXEC sys.sp_readerrorlog 1, 1
 
--extended read error log stored procedure: xp_readerrorlog:
--@p1 through @p4 are the same
--@p5: start time
--@p6: end time
--@p7: search order
EXEC xp_readerrorlog 0,1,"seconds",NULL,NULL,NULL,'desc'
EXEC xp_readerrorlog 0,1,"source",NULL,NULL,NULL,'desc'

EXEC xp_readerrorlog 0,1,NULL,NULL,NULL,NULL,'desc'
 
select * from sys.databases;
 
--powershell
 
 
--refresh error log: by default, log restarts when server restarts
sp_cycle_errorlog
 
 
--configure the # of error log files: default is 6
 
 
 
*/
USE Datamart;
GO
--get information about locks:
EXEC sp_lock;
GO
 
 
select * from sys.sysprocesses where loginame<>'sa' order by waittime desc
 
/*
--Severity 19 "The instance of the SQL Server Database Engine cannot obtain a LOCK resource at this time."
--Occurs when the number of locks exceeds 60% of Max Server Memory
--check how much memory is being taken by the lock manager:
select sum(pages_kb)/1024./1024. locked_pages_gb from sys.dm_os_memory_clerks where type like '%lock%'
select * from sys.dm_os_memory_clerks where type like '%lock%'
 
--When a single transact-sql statement acquires at least 5,000 locks on a table, lock escalation should occur
--Check queries with highest # of locks.  If it exceeds 5K, lock escalation is not happening as it should be (either because trace flags 1211/1224 were enabled,
--Lock_Manager is using more than 60% SQL Max Memory, or query hints are preventing lock escalation)
SELECT P.loginame, P.lastwaittype, P.cmd,P.spid, COUNT (*) num_locks FROM sys.dm_tran_locks L LEFT JOIN sys.sysprocesses P ON P.spid=L.request_session_id
GROUP BY spid, P.loginame, P.lastwaittype, P.cmd
HAVING COUNT (L.request_session_id)>1
ORDER BY num_locks desc
 
EXEC sp_whoisactive
select * from sys.sysprocesses where spid=54

 
--also check for open transactions:
DBCC OPENTRAN
 
--check memorystatus for analysis:
DBCC MEMORYSTATUS
 
--to clear lock manager contents:
DBCC FREESYSTEMCACHE ( 'ALL' )
 
*/
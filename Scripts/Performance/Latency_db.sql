/** script to check read and write latency of databases ****
 
select db_name(4), file_name(18)
GO
sp_helpdb tempdb
select * from sys.databases;
select file_name(23), file_name(24), file_name(25), file_name(26)
select file_name(3), file_name(4), file_name(5), file_name(6)
 
 --get  I/O statistics for data and log files:

SELECT db_name(mf.database_id) 'database', mf.physical_name
	, num_of_reads --number of reads issued on the file
	, num_of_bytes_read --number of bytes read on this file
	, io_stall_read_ms --total time (ms) users waited for reads issued on the file'
	, num_of_bytes_read/io_stall_read_ms 'ave_stall_read' --the bigger the better
	, num_of_writes --number of writes made on this file
	, num_of_bytes_written --total number of bytes written to the file
	, io_stall_write_ms --total time (ms) users waited for writes to be completed on the file
	, num_of_bytes_written/io_stall_write_ms 'ave_stall_write' --the bigger the better
	, io_stall  --total time (ms) that users waited for I/O to be completed on the file
	--, size_on_disk_bytes --Number of bytes used on the disk for this file. For sparse files, this number is the actual number of bytes on the disk that are used for database snapshots.
	,getdate()
	FROM sys.dm_io_virtual_file_stats(null, null) divfs
	JOIN sys.master_files mf ON mf.database_id=divfs.database_id AND mf.file_id=divfs.file_id
	WHERE mf.database_id IN (2,3,4,5)
	ORDER BY ave_stall_read 


--write/read stall over 40ms is bad....
SELECT files.physical_name, files.name,   stats.num_of_writes, (1.0 * stats.io_stall_write_ms / stats.num_of_writes) AS avg_write_stall_ms,
  stats.num_of_reads, (1.0 * stats.io_stall_read_ms / stats.num_of_reads) AS avg_read_stall_ms
FROM sys.dm_io_virtual_file_stats(2, NULL) as stats INNER JOIN master.sys.master_files AS files
  ON stats.database_id = files.database_id  AND stats.file_id = files.file_id


**/
 
SELECT
           [database_id],
           [file_id],
           [ReadLatency] =
               CASE WHEN [num_of_reads] = 0
                   THEN 0 ELSE ([io_stall_read_ms] / [num_of_reads]) END,
           [WriteLatency] =
       CASE WHEN [num_of_writes] = 0
                   THEN 0 ELSE ([io_stall_write_ms] / [num_of_writes]) END,
              getdate() AS date_checked
       --INTO DBAWork.dbo.db_latency
       FROM
           sys.dm_io_virtual_file_stats (NULL, NULL)
      -- WHERE database_id IN (2,5) OR [file_id] in (1,2) OR [database_id] =2;
 
/**
use tempdb
go
--write/read stall over 40ms is bad....
SELECT files.physical_name, files.name, stats.num_of_writes, (1.0 * stats.io_stall_write_ms / stats.num_of_writes) AS avg_write_stall_ms,
  stats.num_of_reads, (1.0 * stats.io_stall_read_ms / stats.num_of_reads) AS avg_read_stall_ms
FROM sys.dm_io_virtual_file_stats(2, NULL) as stats INNER JOIN master.sys.master_files AS files
  ON stats.database_id = files.database_id AND stats.file_id = files.file_id
 
select * from sys.sysprocesses where spid>50;
 
SELECT  CAST(SUM(io_stall_read_ms + io_stall_write_ms) /
             SUM(1.0 + num_of_reads + num_of_writes) AS NUMERIC(10, 1)
        ) AS [avg_io_stall_ms]
FROM    sys.dm_io_virtual_file_stats(DB_ID(), NULL)
WHERE   FILE_ID <> 2;

 
select file_name(3)
 
SELECT *
FROM sys.fn_trace_getinfo(0)
 
sp_trace_setstatus 1,0
**/
 
 
 
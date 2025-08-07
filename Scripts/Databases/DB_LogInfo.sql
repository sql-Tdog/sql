/** Frist, check if there are ny open transactions in the transaction log or any un-replicated
 ** transactions if the database is published */
DBCC OPENTRAN

/*
--if log does not truncate because of replication or cdc, update the record that identifies the 
--last distrubted transaction at the Publisher on the publication database
--the following will mark all replicated transactions in the log as distributed:
EXEC sp_repldone @xactid=NULL, @xact_seqno=NULL, @numtrans=0, @time=0, @reset=1;

*/
 
--******  Check the sizes of the transaction logs and % used
DBCC SQLPERF(logspace)
 
--******  waits on the transaction log files ***************************
select name, log_reuse_wait, log_reuse_wait_desc
from sys.databases
 
 /*
 OLDEST_PAGE wait:  occurs when indirect checkpoints are being used, indicates that the oldest page is older than the 
 checkpoint LSN; SQL cannot re-use the log file:  there are modified data pages in memory that have not been persisted
 to disk
 AVAILABILITY_REPLICA:  occurs when the logged changes at the primary replica are not yet hardened on the secondary replica
	--for a 1 replica AG, change the availiability mode to async commit to clear this wait


 --indirect checkpoints are ON by default in SQL 2016, with target recovery time set to 60 seconds
 --I see this wait intermittently on KC prod databases, however the tran log is not growing so I let it be

 --verify that indirect checkpoint is set on a database:
 select name, log_reuse_wait_desc, target_recovery_time_in_seconds from sys.databases;

  --turn off indirect checkpoints for databases that do not have very many dirty pages but a lot of transactions to log:
 ALTER DATABASE DBName SET TARGET_RECOVERY_TIME = 0 SECONDS 

 --or issue a checkpoint (temporary solution)
 CHECKPOINT

 */

 --******check size:
SELECT db_name() AS DbName, name AS FileName, size/128.0 CurrentSizeMB, size/128./1024 AS CurrentSizeGB, size/128.0/1024
	-CAST(FILEPROPERTY(name,'SpaceUsed') AS INT)/128.0/1024 AS FreeSpaceGB
FROM sys.database_files;

 
/*************************************************************************
**  shrink log files:
 
USE Datamart
GO
SELECT name, physical_name, size/128 FROM        sys.database_files
 
DBCC SHRINKFILE ('DW_PBM_log', 200000)

--if log file does not shrink because of CDC, then reset it:
EXEC sp_repldone @xactid=NULL, @xact_seqno=NULL, @numtrans=0, @time=0, @reset=1;

--**script to grow log files:
 
sp_helpfile
 
ALTER DATABASE gpas_audit MODIFY FILE (Name=gpas_audit_log, SIZE=5 MB)
 
*****************/
 
 
 

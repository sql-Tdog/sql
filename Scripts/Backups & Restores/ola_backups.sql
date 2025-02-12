/***********************************************************************************
issue:  backup files are not getting deleted
examine the xp_delete_file command in the CommandLog table  */
SELECT StartTime, Command FROM dbo.CommandLog where CommandType='xp_delete_file'


--if t-log backups are still not getting deleted:
SELECT StartTime, Command FROM dbo.CommandLog 
where CommandType='xp_delete_file' and Command LIKE '%databasename%'

/*
the xp_delete_file command will ask to delete files based on the last backupdate 
in the msdb.dbo.backupset table

if t-log backups are still not getting deleted after the backupset table is cleaned up,
run the full backup job, then run the t-log backup job 

****bug in the Ola scripts:  
if the database was in full recovery mode and then set to simple mode,
the last log backup date is going to be either NULL or will not be getting updated,
therefore the logs will not be getting deleted for other databases although they are not related

to solve, turn on the sp_delete_backuphistory job that gets installed with Ola scripts
*/

/***********************************************************************************
issue:  log backups are not being taken even though the log backup job is running
the execution time of this job is 00:00:00
the CommandLog table shows no commands logged for log backups
check the log of the job to see if "Log since last log backup (MB)" is coming back with N/A

*/
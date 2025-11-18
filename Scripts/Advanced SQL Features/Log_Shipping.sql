/***
--available on all versions of SQL Server except Express
--requires a Network Path to backup folder (shared storage)

--after setting up log shipping, do not take any log backups outside the log shipping backup job without using the COPY_ONLY option
or the link between the databases will be disrupted

--log shipping cannot be used with keep_cdc for CDC enabled databases
*/

--monitor log shippping

SELECT * FROM msdb.dbo.log_shipping_monitor_history_detail;
SELECT * FROM msdb.dbo.log_shipping_monitor_primary;

/*
--set recovery to full (if not already):
alter database DBAwork set recovery full

--restore latest backup from primary server:
restore FILELISTONLY FROM DISK='G:/DBAwork_backup_2014_07_07_104312_9841865.bak'

restore database dba_prod FROM DISK='G:/DBAwork_backup_2014_07_07_104312_9841865.bak'
WITH MOVE 'dbaWork' TO 'G:\db_files\dba_prod.mdf', MOVE 'dbaWork_log' TO 'G:\db_files\dba_prod.ldf'


--on the primary server, execute sp to add a primary database, the sp returns the backup job id and primary id:
EXEC master.dbo.sp_add_log_shipping_primary_database 
	 @database='DBAwork'
	,@backup_directory='K:/DBAwork'
	,@backup_share='



--On the primary server, execute sp_add_jobschedule to add a schedule for the backup job.

--On the monitor server, execute sp_add_log_shipping_alert_job to add the alert job.

--On the primary server, enable the backup job.

--On the secondary server, execute sp_add_log_shipping_secondary_primary supplying the details of the primary server and database. This stored procedure returns the secondary ID and the copy and restore job IDs.

--On the secondary server, execute sp_add_jobschedule to set the schedule for the copy and restore jobs.

--On the secondary server, execute sp_add_log_shipping_secondary_database to add a secondary database.

--On the primary server, execute sp_add_log_shipping_primary_secondary to add the required information about the new secondary database to the primary server.

--On the secondary server, enable the copy and restore jobs. For more information, see Disable or Enable a Job.


--Easy to set up using the Wizard:  database>Tasks>Ship Transaction Logs...
*/
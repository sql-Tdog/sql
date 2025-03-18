USE [msdb]
GO
sp_delete_job @job_name='Alert - DAG Health'
GO
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'DBA' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'DBA'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Alert - DAG Health', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'DBA', 
		@owner_login_name=N'essay', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DAG ALert]    Script Date: 5/16/2024 10:33:50 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DAG ALert', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @stmt nvarchar(max);
DECLARE @mail_profile varchar(300)=(SELECT TOP 1 name FROM msdb.dbo.sysmail_profile);
DECLARE @recipient_emails varchar(600)=''6504921209@txt.att.net; 7044020005@tmomail.net; 5594174301@vtext.com;'';
DECLARE @subject varchar(1000);
DECLARE @log_queue nchar(15)
DECLARE @log_send_rate nchar(15)
DECLARE @search nvarchar(max)=''SELECT @log_queue= MAX(drs.log_send_queue_size)
FROM sys.databases dbs
INNER JOIN sys.dm_hadr_database_replica_states drs
    ON dbs.database_id = drs.database_id
INNER JOIN sys.availability_groups ag
    ON drs.group_id = ag.group_id
INNER JOIN sys.dm_hadr_availability_replica_states ars
    ON ars.replica_id = drs.replica_id
INNER JOIN sys.availability_replicas ar
    ON ar.replica_id = ars.replica_id'';
EXECUTE sp_executesql @search, N''@log_queue nchar(15) OUTPUT'', @log_queue=@log_queue OUTPUT

SET @search=''SELECT @log_send_rate= MAX(drs.log_send_rate)
FROM sys.databases dbs
INNER JOIN sys.dm_hadr_database_replica_states drs
    ON dbs.database_id = drs.database_id
INNER JOIN sys.availability_groups ag
    ON drs.group_id = ag.group_id
INNER JOIN sys.dm_hadr_availability_replica_states ars
    ON ars.replica_id = drs.replica_id
INNER JOIN sys.availability_replicas ar
    ON ar.replica_id = ars.replica_id'';
EXECUTE sp_executesql @search, N''@log_send_rate nchar(15) OUTPUT'', @log_send_rate=@log_send_rate OUTPUT

IF (@log_queue)>10000 AND @log_send_rate<25000 BEGIN
	SET @subject=''DAG queue and log send rate ON ''+@@SERVERNAME;
	SET @stmt = ''Current log send queue is ''+@log_queue +'' and Current log send rate is ''+@log_send_rate +'' (in bytes).''
			EXEC msdb.dbo.sp_send_dbmail 
				@profile_name=@mail_profile, 
				@recipients=@recipient_emails,
				@subject=@subject,
				@body=@stmt;
END 

', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every Hour', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20240510, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'6f9e480b-7866-4963-b58d-c1d0d18fd3b3'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



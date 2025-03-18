USE [msdb]
GO

/****** Object:  Job [Audit Alert]    Script Date: 5/1/2018 2:47:41 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Internal Reports]    Script Date: 5/1/2018 2:47:41 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Internal Reports' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Internal Reports'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Audit Alert', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Alert DBA when a certain action gets logged in the server audit.', 
		@category_name=N'Internal Reports', 
		@owner_login_name=N'CENTENE\TNIKOLAYCHUK', 
		@notify_email_operator_name=N'tnikolaychuk', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Scan the audit file, send alert]    Script Date: 5/1/2018 2:47:41 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Scan the audit file, send alert', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @body varchar(max);
IF  EXISTS (SELECT event_time,action_id,session_server_principal_name AS UserName,server_instance_name,database_name,schema_name,object_name,statement, *
FROM sys.fn_get_audit_file(''E:\Audit\*.sqlaudit'', DEFAULT, DEFAULT) 
WHERE statement LIKE''%impersonate%'' and session_server_principal_name<>''CENTENE\reports'') 
BEGIN
	EXEC msdb.dbo.Sp_send_dbmail
		@profile_name = ''SQL_MAIL_Profile'',
		@body_format =''html'',
		@recipients = ''tnikolaychuk@centene.com'',
		@subject = ''ALERT: Impersonation occured on ERXDWBISB1500'',
		@body= ''Impersonation has occured by an account other than the services account.  Check the audit log.'';
END

', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Hourly', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180501, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'335f370d-4bb5-48c9-893f-b2c202e025d1'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


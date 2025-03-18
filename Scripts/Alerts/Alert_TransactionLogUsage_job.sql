USE [msdb]
GO

/****** Object:  Job [DBA_Alert_TransactionLog]    Script Date: 2/18/2020 1:18:59 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 2/18/2020 1:18:59 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA_TransactionLog_Alert', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'tnikolaychuk', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Send out transaction log alert]    Script Date: 2/18/2020 1:18:59 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Send out transaction log alert', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
SET NOCOUNT ON
 
DECLARE @threshold int=60;
-- step 1: Create temp table and record sqlperf data
CREATE TABLE #tloglist 
( 
databaseName sysname, 
logSize decimal(18,5), 
logUsed decimal(18,5), 
status INT
) 
 
INSERT INTO #tloglist 
       EXECUTE(''DBCC SQLPERF(LOGSPACE)'') 
 
-- step 2: get T-logs exceeding threshold size in html table format
DECLARE  @xml nvarchar(max); 
SELECT @xml = Cast((SELECT databasename AS ''td'','''',logsize AS ''td'','''',logused AS ''td''
FROM #tloglist
WHERE logused >= (@threshold) 
FOR xml path(''tr''), elements) AS NVARCHAR(max))
 
-- step 3: Specify table header and complete html formatting
Declare @body nvarchar(max);
SET @body =
''<html><body><H2>High T-Log Utilization </H2><table border = 1 BORDERCOLOR="Black"> <tr><th> Database </th> <th> LogSize </th> <th> LogUsed </th> </tr>''
SET @body = @body + @xml + ''</table></body></html>''
 
-- step 4: send email if a T-log exceeds threshold
DECLARE @mail_profile varchar(300)=(SELECT TOP 1 name FROM msdb.dbo.sysmail_profile);
DECLARE @recipient_emails varchar(600)=''tnikolaychuk@centene.com; dba@Envolvehealth.com'';
DECLARE @subject nvarchar(600)=''ALERT: High T-Log Utilization on ''+@@SERVERNAME;

if(@xml is not null)
	BEGIN
		EXEC msdb.dbo.Sp_send_dbmail
		@profile_name = @mail_profile,
		@body = @body,
		@body_format =''html'',
		@recipients = @recipient_emails,
		@subject = @subject;
	END
 

--send out a special alert for critical databases:

SET @xml = (SELECT databasename + '' Log Size is '' + convert(varchar(25),logsize) 
	+ '' MB.  Log % used is: '' + convert(varchar(8),logused) +''.''
FROM #tloglist
WHERE logused >= (@threshold) AND databasename IN(''Datamart'',''Staging''));


IF (@xml is not null)
	BEGIN
		SET @recipient_emails=''5594174301@vtext.com'';
		EXEC msdb.dbo.Sp_send_dbmail
		@profile_name = @mail_profile,
		@body = @xml,
		@body_format =''text'',
		@recipients = @recipient_emails,
		@subject = @subject;
	END

DROP TABLE #tloglist 
SET NOCOUNT OFF', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 15 minutes', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=15, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20171121, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'96548c3a-ab93-4679-9f62-b2bea4d6824f'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


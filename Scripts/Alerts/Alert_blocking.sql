
--*****************************set up blocking alert:******************************************************************************************************
--1.  configure blocked process threshold values
select @@version

EXEC sp_configure 'show advanced options',1
GO
RECONFIGURE WITH OVERRIDE
GO
EXEC sp_configure 'blocked process threshold (s)',20
GO
RECONFIGURE WITH OVERRIDE 
--2.  Replace tokens for all job responses to alert
USE [msdb]
GO
sysmail_help_profile_sp

EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1,
	@alert_replace_runtime_tokens=1,
	@databasemail_profile=N'DBMail'

--	restart SQL server agent service
--3.  Create a table to store blocking information
USE [DBAToolbox]
GO

--Create this table to store the history of the blocked events
CREATE TABLE [dbo].[BlockedEvents](
	[Event_id] [int] IDENTITY(1,1) NOT NULL,
	[AlertTime] [datetime] NULL,
	[BlockedReport] [xml] NULL,
	[SPID] [int] NULL
)
GO


--4.  Create a new job, in the step add the following script:
USE [msdb]
GO

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 2/4/2020 2:52:46 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Blocking', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Alert DBA]    Script Date: 2/4/2020 2:52:46 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Alert DBA', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET QUOTED_IDENTIFIER ON;
DECLARE @blockingxml XML;
DECLARE @mail_profile varchar(300)=(SELECT TOP 1 name FROM msdb.dbo.sysmail_profile);
DECLARE @recipient_emails varchar(600)=''tanya.nikolaychuk@kindercare.com'';
SELECT  @blockingxml = N''$(ESCAPE_SQUOTE(WMI(TextData)))'';

CREATE TABLE #BlockingDetails
	(
	Nature				VARCHAR(100),
	waittime			bigint,
	transactionname		VARCHAR(100),
	lockMode			VARCHAR(100),
	status				VARCHAR(100),
	clientapp			VARCHAR(100),
	hostname			VARCHAR(100),
	loginname			VARCHAR(100),
	currentdb			VARCHAR(100),
	inputbuf			VARCHAR(1000)
	)

--Blocked process details
INSERT INTO #BlockingDetails
	SELECT 
		Nature			= ''Blocked'',
		waittime		= isnull(d.c.value(''@waittime'',''varchar(100)''),''''),
		transactionname = isnull(d.c.value(''@transactionname'',''varchar(100)''),''''),
		lockMode		= isnull(d.c.value(''@lockMode'',''varchar(100)''),''''),
		status			= isnull(d.c.value(''@status'',''varchar(100)''),''''),
		clientapp		= isnull(d.c.value(''@clientapp'',''varchar(100)''),''''),
		hostname		= isnull(d.c.value(''@hostname'',''varchar(100)''),''''),
		loginname		= isnull(d.c.value(''@loginname'',''varchar(100)''),''''),
		currentdb		= isnull(db_name(d.c.value(''@currentdb'',''varchar(100)'')),''''),
		inputbuf		= isnull(d.c.value(''inputbuf[1]'',''varchar(1000)''),'''')
	FROM @blockingxml.nodes(''TextData/blocked-process-report/blocked-process/process'') d(c)

--Blocking process details
INSERT INTO #BlockingDetails
SELECT 
Nature			= ''BlockedBy'',
waittime		= '''',
transactionname = '''',
lockMode		= '''',
status			= isnull(d.c.value(''@status'',''varchar(100)''),''''),
clientapp		= isnull(d.c.value(''@clientapp'',''varchar(100)''),''''),
hostname		= isnull(d.c.value(''@hostname'',''varchar(100)''),''''),
loginname		= isnull(d.c.value(''@loginname'',''varchar(100)''),''''),
currentdb		= isnull(db_name(d.c.value(''@currentdb'',''varchar(100)'')),''''),
inputbuf		= isnull(d.c.value(''inputbuf[1]'',''varchar(1000)''),'''')
FROM @blockingxml.nodes(''TextData/blocked-process-report/blocking-process/process'') d(c)

DECLARE @body VARCHAR(max)
SELECT @body =
(
	SELECT td = 
	currentdb + ''</td><td>''  +  Nature + ''</td><td>'' + convert(varchar(max),waittime/1000./60) + ''</td><td>'' + transactionname + ''</td><td>'' + 
	lockMode + ''</td><td>'' + status + ''</td><td>'' + clientapp +  ''</td><td>'' + 
	hostname + ''</td><td>'' + loginname + ''</td><td>'' +  inputbuf
	FROM #BlockingDetails
	FOR XML PATH( ''tr'' )     
)  

SELECT @body = ''<table cellpadding="2" cellspacing="2" border="1">''    
              + ''<tr><th>currentdb</th><th>Nature</th><th>waittime_min</th><th>transactionname</th></th></th><th>lockMode</th></th>
              </th><th>status</th></th></th><th>clientapp</th></th></th><th>hostname</th></th>
              </th><th>loginname</th><th>inputbuf</th></tr>''    
              + replace( replace( @body, ''&lt;'', ''<'' ), ''&gt;'', ''>'' )     
              + ''</table>''  +  ''<table cellpadding="2" cellspacing="2" border="1"><tr><th>XMLData</th></tr><tr><td>'' + replace( replace( convert(varchar(max),@blockingxml),  ''<'',''&lt;'' ),  ''>'',''&gt;'' )  
              + ''</td></tr></table>''

DROP TABLE #BlockingDetails

--Insert into a table for further reference
INSERT INTO DBAWork.dbo.BlockedEvents
                (AlertTime, BlockedReport)
                VALUES (getdate(), N''$(ESCAPE_SQUOTE(WMI(TextData)))'')


--send alert only if blocking spid is not equal to blocked spid:
IF (SELECT d.c.value(''@spid'',''int'') FROM @blockingxml.nodes(''TextData/blocked-process-report/blocked-process/process'') d(c)) <>
	(SELECT d.c.value(''@spid'',''int'') FROM @blockingxml.nodes(''TextData/blocked-process-report/blocking-process/process'') d(c))
	BEGIN
		DECLARE @recipientsList varchar(8000)=''tanya.nikolaychuk@kindercare.com'';
		DECLARE @subject varchar(300)=''Alert! Blocking on ''+@@SERVERNAME;
		EXEC msdb.dbo.sp_send_dbmail
			@profile_name		= @mail_profile, 
			@recipients			= @recipient_emails,
			@body				= @body,
			@body_format		= ''HTML'',
			@subject			= @subject,
			@importance			= ''High'' ;
	END

', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO



  --5.  Creat an alert, select alert type as WMI event
USE [msdb]
GO
DECLARE @jobid uniqueidentifier
SET @jobid=(SELECT job_id from msdb.dbo.sysjobs where name='Blocking')

EXEC msdb.dbo.sp_add_alert @name=N'Blocking', 
		@message_id=0, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=0, 
		@category_name=N'[Uncategorized]', 
		@wmi_namespace=N'\\.\root\Microsoft\SqlServer\ServerEvents\MSSQLSERVER', 
		@wmi_query=N'SELECT * FROM BLOCKED_PROCESS_REPORT', 
		@job_id=@jobid
GO


  



/**
--to include other options such as killing connections:

--3.  Create a table to store blocking information
USE [DBAToolbox]
GO

--Create this table to store the history of the blocked events
CREATE TABLE [dbo].[BlockedEvents](
	[Event_id] [int] IDENTITY(1,1) NOT NULL,
	[AlertTime] [datetime] NULL,
	[BlockedReport] [xml] NULL,
	[SPID] [int] NULL
)
GO

--4.  Create a new job, in the step add the following script:
USE [msdb]
GO


BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Blocking', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'tnikolaychuk', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Alert DBA', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET QUOTED_IDENTIFIER ON
DECLARE @blockingxml XML
SELECT  @blockingxml = N''$(ESCAPE_SQUOTE(WMI(TextData)))''

CREATE TABLE #BlockingDetails
(
Nature				VARCHAR(100),
waittime			VARCHAR(100),
transactionname		VARCHAR(100),
lockMode			VARCHAR(100),
status				VARCHAR(100),
clientapp			VARCHAR(100),
hostname			VARCHAR(100),
loginname			VARCHAR(100),
currentdb			VARCHAR(100),
inputbuf			VARCHAR(1000)
)

--Blocked process details
INSERT INTO #BlockingDetails
SELECT 
Nature			= ''Blocked'',
waittime		= isnull(d.c.value(''@waittime'',''varchar(100)''),''''),
transactionname = isnull(d.c.value(''@transactionname'',''varchar(100)''),''''),
lockMode		= isnull(d.c.value(''@lockMode'',''varchar(100)''),''''),
status			= isnull(d.c.value(''@status'',''varchar(100)''),''''),
clientapp		= isnull(d.c.value(''@clientapp'',''varchar(100)''),''''),
hostname		= isnull(d.c.value(''@hostname'',''varchar(100)''),''''),
loginname		= isnull(d.c.value(''@loginname'',''varchar(100)''),''''),
currentdb		= isnull(db_name(d.c.value(''@currentdb'',''varchar(100)'')),''''),
inputbuf		= isnull(d.c.value(''inputbuf[1]'',''varchar(1000)''),'''')
FROM @blockingxml.nodes(''TextData/blocked-process-report/blocked-process/process'') d(c)

--Blocking process details
INSERT INTO #BlockingDetails
SELECT 
Nature			= ''BlockedBy'',
waittime		= '''',
transactionname = '''',
lockMode		= '''',
status			= isnull(d.c.value(''@status'',''varchar(100)''),''''),
clientapp		= isnull(d.c.value(''@clientapp'',''varchar(100)''),''''),
hostname		= isnull(d.c.value(''@hostname'',''varchar(100)''),''''),
loginname		= isnull(d.c.value(''@loginname'',''varchar(100)''),''''),
currentdb		= isnull(db_name(d.c.value(''@currentdb'',''varchar(100)'')),''''),
inputbuf		= isnull(d.c.value(''inputbuf[1]'',''varchar(1000)''),'''')
FROM @blockingxml.nodes(''TextData/blocked-process-report/blocking-process/process'') d(c)

DECLARE @body VARCHAR(max)
SELECT @body =
(
	SELECT td = 
	currentdb + ''</td><td>''  +  Nature + ''</td><td>'' + waittime + ''</td><td>'' + transactionname + ''</td><td>'' + 
	lockMode + ''</td><td>'' + status + ''</td><td>'' + clientapp +  ''</td><td>'' + 
	hostname + ''</td><td>'' + loginname + ''</td><td>'' +  inputbuf
	FROM #BlockingDetails
	FOR XML PATH( ''tr'' )     
)  

SELECT @body = ''<table cellpadding="2" cellspacing="2" border="1">''    
              + ''<tr><th>currentdb</th><th>Nature</th><th>waittime</th><th>transactionname</th></th></th><th>lockMode</th></th>
              </th><th>status</th></th></th><th>clientapp</th></th></th><th>hostname</th></th>
              </th><th>loginname</th><th>inputbuf</th></tr>''    
              + replace( replace( @body, ''&lt;'', ''<'' ), ''&gt;'', ''>'' )     
              + ''</table>''  +  ''<table cellpadding="2" cellspacing="2" border="1"><tr><th>XMLData</th></tr><tr><td>'' + replace( replace( convert(varchar(max),@blockingxml),  ''<'',''&lt;'' ),  ''>'',''&gt;'' )  
              + ''</td></tr></table>''

DROP TABLE #BlockingDetails

--Sending Mail
DECLARE @recipientsList varchar(8000)
SELECT @recipientsList =''tnikolaychuk@rhainc.com''
EXEC msdb.dbo.sp_send_dbmail
    @profile_name		= ''DBA Mail Account'', 
    @recipients			= @recipientsList,
    @body				= @body,
    @body_format		= ''HTML'',
    @subject			= ''Alert! Blocking On HBEX SQL PROD  Server'',
    @importance			= ''High'' ;


--Insert into a table for further reference
INSERT INTO DBAWork.dbo.BlockedEvents
                (AlertTime, BlockedReport)
                VALUES (getdate(), N'$(ESCAPE_SQUOTE(WMI(TextData)))')

--Execute sp to kill connection if it is a dbForge with sleeping status
EXEC sp_KillBlocking_dbForge

--Update the SPID column
UPDATE B
	SET B.SPID = B.BlockedReport.value(''(/TextData/blocked-process-report/blocking-process/process/@spid)[1]'',''int'')
	FROM DBAWork.dbo.BlockedEvents B 
	where  B.Event_id = SCOPE_IDENTITY()  

', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

  --5.  Creat an alert, select alert type as WMI event
USE [msdb]
GO
DECLARE @jobid uniqueidentifier
SET @jobid=(SELECT job_id from msdb.dbo.sysjobs where name='Blocking')

EXEC msdb.dbo.sp_add_alert @name=N'Blocking', 
		@message_id=0, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=0, 
		@category_name=N'[Uncategorized]', 
		@wmi_namespace=N'\\.\root\Microsoft\SqlServer\ServerEvents\MSSQLSERVER', 
		@wmi_query=N'SELECT * FROM BLOCKED_PROCESS_REPORT', 
		@job_id=@jobid
GO


*/
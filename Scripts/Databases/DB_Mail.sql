use msdb 
GO


/**
sysmail_help_account_sp
go
sysmail_help_profile_sp

SELECT name FROM sysmail_profile;

GRANT EXECUTE ON sysmail_help_profile_sp TO [CENTENE\ERX_Specialty_Analytics];
GRANT EXECUTE ON sysmail_help_profile_sp TO [CENTENE\ERX_Specialty_Analytics];

--enable database mail:
USE master
GO
sp_configure 'show advanced options',1
GO
RECONFIGURE WITH OVERRIDE
GO
sp_configure 'Database Mail XPs',1
GO
RECONFIGURE 
GO

--create a new mail account with anonymous authentication:
EXECUTE msdb.dbo.sysmail_add_account_sp
    @account_name = 'SQL_MAIL',
    @description = 'SQL Server Mail Account',
    @email_address = 'tnikolaychuk@EnvolveHealth.com',
    @display_name = 'SQL Server DBA',
	@replyto_address = 'tnikolaychuk@EnvolveHealth.com',
    @mailserver_name = 'mail.centene.com' ;

--create a new profile:
EXECUTE msdb.dbo.sysmail_add_profile_sp @profile_name = 'SQL_MAIL_Profile', @description = 'SQL Server Mail Profile';

--update profile:
EXECUTE msdb.dbo.sysmail_update_profile_sp @profile_id = 750, @profile_name = 'Operator'  


--add account to a profile:
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
	@profile_name = 'SQL_MAIL_Profile',
	@account_name = 'SQL_MAIL',
	@sequence_number = 1
GO

 --Grant access to the profile to all users in the msdb database
Execute msdb.dbo.sysmail_add_principalprofile_sp
    @profile_name = 'SQL_MAIL_Profile'
    , @principal_name = 'public'
    , @is_default = 1;
	  
--set MaxFileSize
EXEC msdb..sysmail_configure_sp MaxFileSize, 2000000;

--enable SQL Server Agent to use Database Mail profile:
USE [msdb]
GO
EXEC master.dbo.sp_MSsetalertinfo @failsafeoperator=N'SQL_DBA_Information',
	@notificationmethod=1
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1,
	@alert_replace_runtime_tokens=1,
	@databasemail_profile=N'SQL_MAIL_Profile'
GO

EXEC master.dbo.xp_instance_regwrite
N'HKEY_LOCAL_MACHINE',
N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
N'UseDatabaseMail',
N'REG_DWORD', 1
EXEC master.dbo.xp_instance_regwrite
N'HKEY_LOCAL_MACHINE',
N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
N'DatabaseMailProfile',
N'REG_SZ',
N'SQL_MAIL_Profile'


--set default profile and security


--update account:
EXECUTE msdb.dbo.sysmail_update_account_sp 
	@account_id=3
	,@enable_ssl=1
	,@username='ocortes@rhamail.com'
	,@password=''

EXECUTE msdb.dbo.sysmail_update_account_sp 
	@account_id=1
	,@mailserver_name ='DA2MailBE'

GRANT EXECUTE ON sysmail_update_account_sp TO ocortes


EXECUTE AS USER='CENTENE\RNICHOLS';
sysmail_update_account_sp 
	@account_id=4
	,@username='ocortes@rhamail.com'
	,@password=''

REVERT;


DENY EXECUTE ON sysmail_update_account_sp TO ocortes

--send test email
EXEC msdb.dbo.sp_send_dbmail
    @profile_name		= 'SQL_MAIL_Profile',
    @recipients			= 'tnikolaychuk@centene.com;',
    @subject				= 'test email.',
    @body			= 'test email';


--check db mail log for failed items only:
use msdb
go
SELECT TOP 100 items.subject,  items.last_mod_date ,l.description 
FROM dbo.sysmail_faileditems as items
INNER JOIN dbo.sysmail_event_log AS l ON items.mailitem_id = l.mailitem_id
ORDER BY l.mailitem_id desc


--check db mail event log:
select top 100 * from dbo.sysmail_event_log order by log_id desc

--check for all mail items sent:
select top 100 sent_status, * from msdb.dbo.sysmail_allitems order by mailitem_id desc
*/


select top 100 sent_status, sent_date, *
from dbo.sysmail_allitems 
order by mailitem_id desc


/*****************TROUBLESHOOTING****************
Issue:  emails are sitting in the queue, sent_status:  unsent
Fix:	Go to Program Files/Microsoft SQL Server/MSSQL13.MSSQLSERVER/MSSQL/Binn and try to launch the DatabaseMail executable manually
		It may be missing .NET Framework 3.5
Database Mail requires .NET Framework 3.5 and a DatabaseMail.exe.config file
Also check if any of the following are missing:  DatabaseMailengine.dll DatabaseMailprotocols.dll  or  DataCollectorController.dll

One time when I installed a 2nd instance of SQL on a server, this config file was not in the Binn folder and all mail remained unsent until I copied
and pasted the file from the first instance's Binn folder

Another time, 2 of the dll files were missing and once I copied them from another server, all unsent mail went out

*/


/***********************script to configure mail specific to server name*************************************************

declare @account varchar(55)
set @account = replace(@@servername, '\' , '-')+'@kindercare.com'
EXEC msdb.dbo.sysmail_add_account_sp
@account_name = @account,
@description = ' Mail account for database mail',
@email_address = @account,
@display_name = @@servername ,
@replyto_address = 'ITOpsAlert_SQLServerInfo_KCE@kindercare.com',
@mailserver_name = 'smarty.corp.edu-resources.com';


EXEC msdb.dbo.sysmail_add_profile_sp
@profile_name = 'DBMail',
@description = 'Mail account for DBAs';

EXEC msdb.dbo.sysmail_add_profileaccount_sp
@profile_name = 'DBMail',
@account_name = @account,
@sequence_number = 1;

EXEC msdb.dbo.sysmail_add_principalprofile_sp
@profile_name = 'DBMail',
@principal_name = 'public',
@is_default = 1;

WAITFOR DELAY '00:00:02';

EXEC msdb..sysmail_configure_sp 
MaxFileSize, 2000000;

Waitfor DELAY '00:00:04';

EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'DBMail',
    @recipients = 'fred.woolverton@Kindercare.com',
	@body = 'Testing new email profile.',
    @subject = 'Database Mail';

	--Use msdb; Select * from sysmail_allitems Order by MailItem_ID DESC

--Use msdb; Select * from sysmail_log

--  USE msdb; select * FROM [dbo].[sysmail_event_log]

--EXECUTE msdb.dbo.sysmail_help_configure_sp ;

/*
--To resend failed database mail enter the mailitem_id and profile_name below
DECLARE @to        varchar(max) 
DECLARE @copy    varchar(max) 
DECLARE @title    nvarchar(255)  
DECLARE @msg    nvarchar(max) 
SELECT @to = recipients, @copy = copy_recipients, @title = [subject], @msg = body 
FROM msdb.dbo.sysmail_faileditems 
WHERE mailitem_id =  <Mailitem_ID number>
EXEC msdb.dbo.sp_send_dbmail  
@profile_name = <'ProfileName'>,
@recipients = @to, 
@copy_recipients = @copy,  
@body = @msg,  
@subject = @title,  
@body_format = 'HTML'; 

*/

/****************
REMOVE DATABASE ACCOUNTS AND PROFILE
EXEC msdb.dbo.sysmail_delete_profileaccount_sp
    @profile_name = 'DBMail',  
    @account_name = 'PDX1ITSQL1P@kindercare.com';

	EXECUTE msdb.dbo.sysmail_delete_account_sp
    @account_name = 'PDX1ITSQL1P@kindercare.com';

	EXECUTE msdb.dbo.sysmail_delete_profile_sp
    @profile_name = 'DBMail';


*/
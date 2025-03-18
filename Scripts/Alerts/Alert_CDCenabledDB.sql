SET NOCOUNT ON;
 
DECLARE @cdc_enabled bit;
DECLARE @mail_profile varchar(256);
declare @account varchar(55);
Declare @body nvarchar(max);
DECLARE @recipient_emails varchar(600)='ITOpsAlert_SQLServerInfo_KCE@kindercare.com';
DECLARE @subject nvarchar(600)='ALERT: High T-Log Utilization on '+@@SERVERNAME;


set @account = replace(@@servername, '\' , '-')+'@kindercare.com'
SET @cdc_enabled=(SELECT TOP 1 is_cdc_enabled FROM sys.databases ORDER BY is_cdc_enabled DESC);
SET @mail_profile=(SELECT TOP 1 name FROM msdb.dbo.sysmail_profile)
SET @body = 'CDC enabled database found on '+ @@SERVERNAME;


IF @cdc_enabled=1 BEGIN
	EXEC msdb.dbo.Sp_send_dbmail
		@profile_name = @mail_profile,
		@body = @body,
		@recipients = @recipient_emails,
		@subject = @subject;
END
 

SET NOCOUNT OFF
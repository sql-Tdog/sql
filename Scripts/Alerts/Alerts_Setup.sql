/**steps to set up server alerts
 **
 **/
USE msdb
GO

/**create an operator

EXEC msdb.dbo.sp_add_operator @name=N'tnikolaychuk', 
		@enabled=1, 
		@email_address=N'Tatyanna.Nikolaychuk@EnvolveHealth.com'
GO

SELECT * FROM msdb.dbo.sysoperators;

sysmail_help_profile_sp

EXEC msdb.dbo.sp_set_sqlagent_properties @alert_replace_runtime_tokens = 1
GO



**/
/** error 825**/
EXEC msdb.dbo.sp_add_alert @name = N'823 – Hardware/System problem',
    @message_id = 823,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 0,
    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification
	 @alert_name = N'823 – Hardware/System problem',
	 @operator_name = N'tnikolaychuk',
	 @notification_method = 1 ;
GO
EXEC msdb.dbo.sp_add_alert @name = N'824 – IO error',
    @message_id = 824,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 0,
    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification
	 @alert_name = N'824 – IO error',
	 @operator_name = N'tnikolaychuk',
	 @notification_method = 1 ;
GO
EXEC msdb.dbo.sp_add_alert @name = N'825 – Read-Retry Required',
    @message_id = 825,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 0,
    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification
	 @alert_name = N'825 – Read-Retry Required',
	 @operator_name = N'tnikolaychuk',
	 @notification_method = 1 ;
GO
/** severity 17-25**/
EXEC msdb.dbo.sp_add_alert @name = N'Severity 17',
    @message_id = 0,
    @severity = 17,
    @enabled = 1,
    @delay_between_responses = 30,
    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification
	 @alert_name = N'Severity 17',
	 @operator_name = N'tnikolaychuk',
	 @notification_method = 1 ;
GO

EXEC msdb.dbo.sp_add_alert @name = N'Severity 18',
    @message_id = 0,
    @severity = 18,
    @enabled = 1,
    @delay_between_responses = 30,
    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification
	 @alert_name = N'Severity 18',
	 @operator_name = N'tnikolaychuk',
	 @notification_method = 1 ;
GO
EXEC msdb.dbo.sp_add_alert @name = N'Severity 19',
    @message_id = 0,
    @severity = 19,
    @enabled = 1,
    @delay_between_responses = 30,
    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification
	 @alert_name = N'Severity 19',
	 @operator_name = N'tnikolaychuk',
	 @notification_method = 1 ;
GO
EXEC msdb.dbo.sp_add_alert @name = N'Severity 20',
    @message_id = 0,
    @severity = 20,
    @enabled = 1,
    @delay_between_responses = 30,
    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification
	 @alert_name = N'Severity 20',
	 @operator_name = N'tnikolaychuk',
	 @notification_method = 1 ;
GO
EXEC msdb.dbo.sp_add_alert @name = N'Severity 21',
    @message_id = 0,
    @severity = 21,
    @enabled = 1,
    @delay_between_responses = 30,
    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification
	 @alert_name = N'Severity 21',
	 @operator_name = N'tnikolaychuk',
	 @notification_method = 1 ;
GO
EXEC msdb.dbo.sp_add_alert @name = N'Severity 22',
    @message_id = 0,
    @severity = 22,
    @enabled = 1,
    @delay_between_responses = 30,
    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification
	 @alert_name = N'Severity 22',
	 @operator_name = N'tnikolaychuk',
	 @notification_method = 1 ;
GO
EXEC msdb.dbo.sp_add_alert @name = N'Severity 23',
    @message_id = 0,
    @severity = 23,
    @enabled = 1,
    @delay_between_responses = 30,
    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification
	 @alert_name = N'Severity 23',
	 @operator_name = N'tnikolaychuk',
	 @notification_method = 1 ;
GO
EXEC msdb.dbo.sp_add_alert @name = N'Severity 24',
    @message_id = 0,
    @severity = 24,
    @enabled = 1,
    @delay_between_responses = 30,
    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification
	 @alert_name = N'Severity 24',
	 @operator_name = N'tnikolaychuk',
	 @notification_method = 1 ;
GO
EXEC msdb.dbo.sp_add_alert @name = N'Severity 25',
    @message_id = 0,
    @severity = 25,
    @enabled = 1,
    @delay_between_responses = 30,
    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification
	 @alert_name = N'Severity 25',
	 @operator_name = N'tnikolaychuk',
	 @notification_method = 1 ;
GO
/*
EXEC msdb.dbo.sp_add_alert @name=N'Mirroring Connection Error', 
		@message_id=1474, 
		@severity=16, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification
	 @alert_name = N'Mirroring Connection Error',
	 @operator_name = N'tnikolaychuk',
	 @notification_method = 1 ;
GO
*/
EXEC msdb.dbo.sp_add_alert @name=N'Operating system error', 
		@message_id=17054, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Operating system error', @operator_name=N'tnikolaychuk', @notification_method = 1
GO

EXEC msdb.dbo.sp_add_alert @name=N'User Cannot Login', 
		@message_id=18456, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=30, 
		@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'User Cannot Login', @operator_name=N'tnikolaychuk', @notification_method = 1
GO

/* SCRIPT to send a TEST alert
USE msdb
GO
RaisError (N'An error occurred Severity 17: insufficient resources ! ', 17, 1) With Log;
 
Go
*/
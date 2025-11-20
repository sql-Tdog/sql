/**To See or Modify SQL Server Login Audit settings:
0 – None
1 – Successful logins only
2 – Failed logins only
3 – All logins only
*/

--check the current setting:
USE [master]
GO
DECLARE @result INT
EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'AuditLevel', @result OUTPUT
SELECT @result AS 'AuditLevel'
GO

--change the setting:

EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'AuditLevel', REG_DWORD, 1
GO






/****all editions of SQL Server support server level audits*****
There can be multiple audits per SQL Server instance. The target must be specified and it could be a file.
By default, the audit is created in a disabled state and must be enabled.

The WHERE clause in the server audit statement can be used to filter auditing by database_name, server_principal_name, statement, etc.

CREATE AUDIT SPECIFICATION is not supported in Azure SQL and there is no Audits Folder under the Security folder in object explorer
Auditing works differently for Azure SQL databases:  needs to be configured using Azure dashboard
Go to Azure SQL database and turn on Auditing, then choose a storage account & set retention (days); Auditing Type is Blob storage

*/

USE master
GO
--to write to the application log, 1 second queue delay:
CREATE SERVER AUDIT DBA_Audit TO APPLICATION_LOG WITH (
		QUEUE_DELAY=1000,  --logging delay, in milliseconds
		ON_FAILURE=CONTINUE --other options:  SHUTDOWN, FAIL_OPERATION
	);
GO

--to write to a file:
CREATE SERVER AUDIT DBA_Audit TO FILE (FILEPATH='E:\Audit\', MAXSIZE = 10MB) WITH (QUEUE_DELAY=1000, ON_FAILURE=CONTINUE) 
	WHERE server_principal_name<>'CENTENE\USSFOGLIGHT';

ALTER SERVER AUDIT DBA_Audit WITH (STATE=ON);

/*
Create a Server Audit Specification object, which belongs to an audit and there can be only one, both are created at the SQL Server instance scope.
Add Audit Action Groups to the Audit Specification depending on what needs to be audited. Server-level action groups cover actions across a SQL Server instance.

*/

ALTER SERVER AUDIT SPECIFICATION DBA_Audit_ServerMods FOR SERVER AUDIT DBA_Audit ADD(FAILED_LOGIN_GROUP), ADD(LOGIN_CHANGE_PASSWORD_GROUP), 
	ADD(AUDIT_CHANGE_GROUP), ADD(SERVER_OPERATION_GROUP), ADD(SERVER_OBJECT_PERMISSION_CHANGE_GROUP), ADD(SERVER_PERMISSION_CHANGE_GROUP), 
	ADD(SERVER_PRINCIPAL_CHANGE_GROUP), ADD(SERVER_PRINCIPAL_IMPERSONATION_GROUP), ADD(SERVER_ROLE_MEMBER_CHANGE_GROUP), ADD(SERVER_STATE_CHANGE_GROUP),
	ADD(DATABASE_ROLE_MEMBER_CHANGE_GROUP), ADD(DATABASE_PRINCIPAL_IMPERSONATION_GROUP), ADD(DATABASE_CHANGE_GROUP), ADD(DATABASE_OBJECT_CHANGE_GROUP),
	ADD(DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP), ADD(DATABASE_PERMISSION_CHANGE_GROUP), ADD(DATABASE_PRINCIPAL_CHANGE_GROUP)
	WITH (STATE=ON);

ALTER SERVER AUDIT DBA_Audit WITH (STATE=OFF);
ALTER SERVER AUDIT SPECIFICATION DBA_Audit_ServerMods WITH (STATE=OFF);


DROP SERVER AUDIT SPECIFICATION DBA_Audit_ServerMods;
DROP SERVER AUDIT DBA_Audit;


--to make changes to the specs, both the audit and the spec must be disabled first:
ALTER SERVER AUDIT DBA_Audit WITH (STATE=OFF);
ALTER SERVER AUDIT SPECIFICATION DBA_Audit_ServerMods WITH (STATE=OFF);

SELECT * FROM sys.server_audits;

--find out where the files are located:
SELECT * FROM sys.server_file_audits;

--to read from the audit file:
SELECT event_time,action_id,session_server_principal_name, server_principal_name,server_instance_name,database_name,schema_name,object_name,statement, *
FROM sys.fn_get_audit_file('E:\Audit\*.sqlaudit', DEFAULT, DEFAULT) 
WHERE action_id<>'VSST' and session_server_principal_name like '%tnikol%';


--view the audit file:
SELECT event_time,action_id,session_server_principal_name AS UserName,server_instance_name,database_name,schema_name,object_name,statement, *
FROM sys.fn_get_audit_file('E:\Audit\*.sqlaudit', DEFAULT, DEFAULT) 
WHERE statement<>'DBCC SQLPERF(LOGSPACE)' AND action_id<>'VSST';

/*
--**action id list:
VSST: View Server State
*/

/*
--inspecting the audit file, I found many of these sort of errors:
Network error code 0x2746 occurred while establishing a connection; the connection has been closed. This may have been caused by client or server login timeout expiration. 
Time spent during login: total 501 ms, enqueued 0 ms, network writes 0 ms, network reads 501 ms, establishing SSL 0 ms, network reads during SSL 0 ms, network writes during 
SSL 0 ms, secure calls during SSL 0 ms, enqueued during SSL 0 ms, negotiating SSPI 0 ms, network reads during SSPI 0 ms, network writes during SSPI 0 ms, secure calls during 
SSPI 0 ms, enqueued during SSPI 0 ms, validating login 0 ms, including user-defined login processing 0 ms. [CLIENT: 10.4.129.224]

--this error is NOT due to a flaky VPN connection from an outside database source to SQL server;
*/



--SQL Server Audit action_id list: https://cprovolt.wordpress.com/2013/08/02/sql-server-audit-action_id-list/
--for a complete list of audit action groups:
https://docs.microsoft.com/en-us/sql/relational-databases/security/auditing/sql-server-audit-action-groups-and-actions?view=sql-server-2017

--to troubleshoot connection errors: go to server_LogonErrors
--turn on trace flags to see any errors in the log:
DBCC TRACEON (3689,4029,-1)
GO

--turn off the trace flags:
DBCC TRACEOFF (3689,4029)


--SQL Server Audit action_id list: https://cprovolt.wordpress.com/2013/08/02/sql-server-audit-action_id-list/

--connection errors:
SELECT dateadd (ms, (a.[Record Time] - sys.ms_ticks), GETDATE()) as [Notification_Time], a.* FROM 
(SELECT 
x.value('(//Record/@id)[1]', 'bigint') AS [Record_ID], 
x.value('(//Record/Error/ErrorCode)[1]', 'varchar(30)') AS [ErrorCode], 
x.value('(//Record/Error/APIName)[1]', 'varchar(255)') AS [APIName], 
x.value('(//Record/Error/CallingAPIName)[1]', 'varchar(255)') AS [CallingAPIName], 
x.value('(//Record/Error/SPID)[1]', 'int') AS [SPID], 
x.value('(//Record/@time)[1]', 'bigint') AS [Record Time] 
FROM (SELECT CAST (record as xml) FROM sys.dm_os_ring_buffers 
WHERE ring_buffer_type = 'RING_BUFFER_SECURITY_ERROR') AS R(x)) a 
CROSS JOIN sys.dm_os_sys_info sys 
ORDER BY a.[Record_ID] DESC


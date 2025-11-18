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
WHERE --action_id<>'VSST' and session_server_principal_name like '%tnikol%';

/*
statement LIKE'%impersonate%' and session_server_principal_name<>'CENTENE\reports'


statement<>'DBCC SQLPERF(LOGSPACE)' --action_id<>'VSST';

--**action id list:
VSST: View Server State

--SQL Server Audit action_id list: https://cprovolt.wordpress.com/2013/08/02/sql-server-audit-action_id-list/
--for a complete list of audit action groups:
https://docs.microsoft.com/en-us/sql/relational-databases/security/auditing/sql-server-audit-action-groups-and-actions?view=sql-server-2017

--to troubleshoot connection errors: go to server_LogonErrors

*/
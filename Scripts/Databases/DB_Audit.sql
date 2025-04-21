/****
--the Database Audit Specification belong to a SQL Server audit and only one can be created per database per audit
--prerequisite is to create a Server Level Audit
use master
GO
CREATE SERVER AUDIT Finance_Audit TO FILE (FILEPATH='E:\Audit\') WITH (QUEUE_DELAY=1000, ON_FAILURE=CONTINUE)  
	WHERE server_principal_name<>'CENTENE\USSFOGLIGHT';


To audit at the database level, create a Database Audit Specification in the scope of the database that needs to be audited and add appropriate Audit
Action Groups.  Some Audit Action Groups can be created both in the server-level audit and in the database-level audit.  If an action group is already
added to a server-level audit specification that is enabled, it will be recorded in both audit files if it is also added to the database audit specification.
https://docs.microsoft.com/en-us/sql/relational-databases/security/auditing/sql-server-audit-action-groups-and-actions?view=sql-server-2017
*/

USE FinanceNew
GO
CREATE DATABASE AUDIT SPECIFICATION FinanceAuditSpecs FOR SERVER AUDIT Finance_Audit 
	ADD (DATABASE_OBJECT_CHANGE_GROUP)
	,ADD (DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP)
	,ADD (DATABASE_PERMISSION_CHANGE_GROUP) 
	,ADD (DATABASE_PRINCIPAL_CHANGE_GROUP)
	,ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP) 
	,ADD (SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP) 
	,ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP)
	,ADD (DATABASE_PRINCIPAL_IMPERSONATION_GROUP)  --log every time a user impersonates another user
	,ADD (SELECT ON OBJECT::[dbo].[Account] BY [user_name]  --audit select queries on a specific object by a specific user
WITH (STATE=ON);

--altering the audit:
ALTER DATABASE AUDIT SPECIFICATION FinanceAuditSpecs ADD
ALTER DATABASE AUDIT SPECIFICATION FinanceAuditSpecs DROP



ALTER DATABASE AUDIT SPECIFICATION FinanceAuditSpecs WITH (STATE=OFF);
DROP DATABASE AUDIT SPECIFICATION ; 

USE Master
GO
ALTER SERVER AUDIT Finance_Audit WITH (STATE=ON);


SELECT * FROM sys.database_audit_specifications;
SELECT * FROM sys.database_audit_specification_details;

DROP SERVER AUDIT SPECIFICATION DBA_Audit_ServerMods;
DROP SERVER AUDIT DBA_Audit;


SELECT event_time,action_id,session_server_principal_name AS UserName,server_instance_name,database_name,schema_name,object_name,statement, *
FROM sys.fn_get_audit_file('E:\Audit\Fina*.sqlaudit', DEFAULT, DEFAULT) 


*/
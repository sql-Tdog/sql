/******Accounts****************************
Built-In Accounts
There are two administrative accounts (Server admin and Active Directory admin) that act as administrators. To identify these administrator accounts for your SQL server, 
open the Azure portal, and navigate to the properties of your SQL server.
• Server admin
When you create an Azure SQL server, you must designate a Server admin login. SQL server creates that account as a login in the master database. This account connects using SQL Server 
authentication (user name and password). Only one of these accounts can exist.
• Azure Active Directory admin
One Azure Active Directory account, either an individual or security group account, can also be configured as an administrator. It is optional to configure an Azure AD administrator, 
but an Azure AD administrator must be configured if you want to use Azure AD accounts to connect to SQL Database.
The Server admin and Azure AD admin accounts has the following characteristics:
	• These are the only accounts that can automatically connect to any SQL Database on the server. (To connect to a user database, other accounts must either be the owner of the database, 
	or have a user account in the user database.)
	• These accounts enter user databases as the dbo user and they have all the permissions in the user databases. (The owner of a user database also enters the database as the dbo user.)
	• These accounts do not enter the master database as the dbo user and they have limited permissions in master.
	• These accounts are not members of the standard SQL Server sysadmin fixed server role, which is not available in SQL database.
	• These accounts can create, alter, and drop databases, logins, users in master, and server-level firewall rules.
	• These accounts can add and remove members to the dbmanager and loginmanager roles.
	• These accounts can view the sys.sql_logins system table.

Additional server-level administrative roles
In addition to the server-level administrative roles, SQL Database provides two restricted administrative roles in the master database to which user accounts can be added 
that grant permissions to either create databases or manage logins.
• dbmanager: can create new databases (create the login, then create the user in the master database and add it to the role)
• loginmanager: can create new logins in the master database

Database level roles are the same in Azure SQL database as in the traditional SQL database
 
Contained Users
• Contained user is mapped directly to a contained database and does not have a login in the master database.  The authentication process occurs at the user database.  
• A contained database is a database that is isolated from other databases and from the instance of SQL Server/ SQL Database (and the master database) that hosts the database.
• The SQL Database server admin account can never be a contained database user. The server admin has sufficient permissions to create and manage contained database users. The server admin can grant permissions to contained database users on user databases.
• The name of contained database user cannot be the same as the name of the server admin account.
• When a contained database user connects to the database, the connection string must include the database name
• Contained database users offer better performance than logins because they authenticate directly to the database instead of making an extra network hop to the master database
*/
--create a user from the Azure Active Directory
USE azuredb
GO
CREATE USER [courtney@cartogia.com] FROM EXTERNAL PROVIDER;


--view all logins:
select * from sys.sql_logins;


--create a new sql login:
CREATE LOGIN sentryone WITH PASSWORD='m2[0N!VzAGSU#uPYAeYz7yDAy[M[ya'

ALTER SERVER ROLE ##MS_DatabaseConnector## ADD MEMBER sentryone
ALTER SERVER ROLE ##MS_SecurityDefinitionReader## ADD MEMBER sentryone
ALTER SERVER ROLE ##MS_ServerStateManager## ADD MEMBER sentryone
ALTER SERVER ROLE ##MS_DefinitionReader## ADD MEMBER sentryone

--while still in the context of the master database:
CREATE USER sentryone FOR LOGIN sentryone
ALTER ROLE dbmanager ADD MEMBER sentryone
ALTER ROLE loginmanager ADD MEMBER sentryone

--change context to user database:
CREATE USER sentryone FOR LOGIN sentryone
GRANT VIEW DATABASE PERFORMANCE STATE TO sentryone


SELECT    roles.principal_id                            AS RolePrincipalID
    ,    roles.name                                    AS RolePrincipalName
    ,    database_role_members.member_principal_id    AS MemberPrincipalID
    ,    members.name                                AS MemberPrincipalName
FROM sys.database_role_members AS database_role_members  
JOIN sys.database_principals AS roles  
    ON database_role_members.role_principal_id = roles.principal_id  
JOIN sys.database_principals AS members  
    ON database_role_members.member_principal_id = members.principal_id
    WHERE members.name='sentryone'
GO

SELECT * FROM fn_my_permissions('sentryone', 'USER');  


--server level permissions
SELECT sql_logins.principal_id AS MemberPrincipalID,
    sql_logins.name AS MemberPrincipalName,
    roles.principal_id AS RolePrincipalID,
    roles.name AS RolePrincipalName
FROM sys.server_role_members AS server_role_members
LEFT JOIN sys.server_principals AS roles
    ON server_role_members.role_principal_id = roles.principal_id
LEFT JOIN sys.sql_logins AS sql_logins
    ON server_role_members.member_principal_id = sql_logins.principal_id
    WHERE sql_logins.name='sentryone'
GO

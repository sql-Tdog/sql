/***
 SELECT USER_NAME();

--create a new login with windows authentication:
CREATE LOGIN [Domain\User] FROM WINDOWS;
 
--create a new sql authentication login:
CREATE LOGIN ignite WITH PASSWORD='xxxx', DEFAULT_DATABASE=master;
ALTER LOGIN fn_extraction WITH PASSWORD ='xxxxx'

--drop a SQL login:
ALTER LOGIN UserName DISABLE;
--check for active sessions and kill:
SELECT login_name, session_id FROM sys.dm_exec_sessions WHERE login_name = 'UserName'


DROP LOGIN UserName;
CREATE LOGIN UserName WITH PASSWORD=xxxxxxxxxxxxxxxxxxxx HASHED, SID=xxxxxxxxxx, DEFAULT_DATABASE=master;
 
  
--****check current sql authentication logins:
select name, sid,password_hash from master.sys.sql_logins
 
--check all server logins:
select principal_id,name, type_desc, is_disabled FROM sys.server_principals
where name like '%kuk%'
 
--view all windows groups:
select principal_id,name, type_desc, is_disabled FROM sys.server_principals where type_desc='WINDOWS_GROUP'
 
--view all windows logins:
select principal_id,name, type_desc, is_disabled FROM sys.server_principals where type_desc='WINDOWS_LOGIN' and is_disabled=0
 

 --view members of an AD group:
 EXEC xp_logininfo @acctname = 'DomainName\GroupName', @option = 'members';


--view members of a sys role:
SELECT sys.server_role_members.role_principal_id, role.name AS RoleName,
    sys.server_role_members.member_principal_id, member.name AS MemberName
FROM sys.server_role_members
JOIN sys.server_principals AS role
    ON sys.server_role_members.role_principal_id = role.principal_id
JOIN sys.server_principals AS member
    ON sys.server_role_members.member_principal_id = member.principal_id;

--grant system role to user:
ALTER SERVER ROLE sysadmin ADD MEMBER [Domain\UserName];
 
 
--get permissions of user to mimic:
select [Login Type]= case sp.type when 'u' then 'WIN' when 's' then 'SQL' when 'g' then 'GRP' end,
convert(char(45),sp.name) as srvLogin, convert(char(45),sp2.name) as srvRole, convert(char(25),dbp.name) as dbUser,
convert(char(25),dbp2.name) as dbRole, dpe.class_desc, dpe.state_desc, dpe.permission_name, o.name object_name
from
sys.server_principals as sp join
sys.database_principals as dbp on sp.sid=dbp.sid left join
sys.database_permissions dpe on dpe.grantee_principal_id=dbp.principal_id left join
sys.objects o on o.object_id=dpe.major_id join
sys.database_role_members as dbrm on dbp.principal_Id=dbrm.member_principal_Id join
sys.database_principals as dbp2 on dbrm.role_principal_id=dbp2.principal_id left join
sys.server_role_members as srm on sp.principal_id=srm.member_principal_id left join
sys.server_principals as sp2 on srm.role_principal_id=sp2.principal_id
where sp.name like '%monreal%' or sp.name like '%slaug%'
 
 

--**************database roles*************************************
CREATE ROLE [db_executor] AUTHORIZATION [dbo]
GO
GRANT EXECUTE TO [db_executor]
GO
ALTER ROLE db_executor ADD MEMBER AWSuser

--**************database users*************************************
CREATE USER [Domain\User] WITH DEFAULT_SCHEMA=[dbo];
DROP USER [Domain\User];
CREATE USER Mary WITH PASSWORD='xxxx' WITH DEFAULT_SCHEMA=[dbo];


--Contained Database Users: contained database authentication must be enabled on the server first before contained databases can be created or attached
--in Azure, contained databases are always enabled and cannot be disabled
--if the user doesn't have a SQL LOGIN, the connection string must specify the database
sp_configure 'contained database authentication'

sp_configure 'contained database authentication', 1;  
GO  
RECONFIGURE;  
GO


--find orphaned accounts:
SELECT dp.type_desc, dp.SID, dp.name AS user_name  
FROM sys.database_principals AS dp  
LEFT JOIN sys.server_principals AS sp  
    ON dp.SID = sp.SID  
WHERE sp.SID IS NULL  
    AND authentication_type_desc = 'INSTANCE';

EXEC sp_change_users_login 'Report';


--to link an SID by mapping an existing database user to a SQL Server login:
sp_change_users_login 'Update_One', 'OTCLink', 'OTCLink';

*/

--get users with server roles:
select [Login Type]= case sp.type when 'u' then 'WIN' when 's' then 'SQL' when 'g' then 'GRP' end,
convert(char(45),sp.name) as srvLogin, convert(char(45),sp2.name) as srvRole
from
sys.server_principals as sp join
sys.server_role_members as srm on sp.principal_id=srm.member_principal_id left join
sys.server_principals as sp2 on srm.role_principal_id=sp2.principal_id
--where sp.name like '%monreal%' or sp.name like '%parkar%'
 
 
--get sql authentication logins:
SELECT name, sid,default_database_name,create_date,modify_date,password_hash FROM sys.sql_logins where is_disabled=0;
 
 /*****login errors*******************************************
 1      'Account is locked out'
2      'User id is not valid'
3-4    'Undocumented'
5      'User id is not valid'
6      'Undocumented'
7      'The login being used is disabled'
8      'Incorrect password'
9      'Invalid password'
10     'Related to a SQL login being bound to Windows domain password policy enforcement.
        See KB925744.'
11-12  'Login valid but server access failed'
16     'Login valid, but not permissioned to use the target database'
18     'Password expired'
27     'Initial database could not be found'
38     'Login valid but database unavailable (or login not permissioned)'


*/
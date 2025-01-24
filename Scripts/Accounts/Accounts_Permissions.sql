/** 
--see server logins and their types
select principal_id,name, type_desc, is_disabled
FROM sys.server_principals where type_desc IN('WINDOWS_LOGIN','SQL_LOGIN','SERVER_ROLE')

select name, sid, password_hash from sys.sql_logins order by name

sp_helprotect null, 'Reporting'

sp_helprotect null, 'sysadmin'

sp_helplogins 'loginame'

--do we use Kerberos? SPN (Service Principal Name) must be registered with AD and mapped to the Windows account
--that SQL Server instance service runs under
SELECT auth_scheme FROM sys.dm_exec_connections where auth_scheme='KERBEROS';


--view definition of a view:
sp_helptext 'dbo.FctClaims'


--********SERVER ROLES*********************************************
--server roles cannot be used to control permissions on per database level
--they are mainly used to give certain access to junior dba (instead of giving sa rights)
--***sysadmin:  members of this role cannot be restricted from anything via DENY***

CREATE SERVER ROLE ServerRole_JrDBA AUTHORIZATION sa;

--Server Level DMVs, for non-admin users:
GRANT VIEW SERVER STATE TO [ServerRole_JrDBA]; 

sp_helpsrvrolemember 'sysadmin';

--view server level permissions:
SELECT  [srvprin].[name] [server_principal], [srvprin].[type_desc] [principal_type], [srvperm].[permission_name], [srvperm].[state_desc]  
	FROM [sys].[server_permissions] srvperm INNER JOIN [sys].[server_principals] srvprin ON [srvperm].[grantee_principal_id] = [srvprin].[principal_id] 
	WHERE [srvprin].[type] IN ('S', 'U', 'G') AND [srvprin].[name]='CENTENE\MPARKAR'
	ORDER BY [server_principal], [permission_name]; 

--*******SERVER LEVEL PERMISSIONS****************************************
CONTROL SERVER: most extensive permission after sysadmin
				cannot execute system stored procedures but there is a workaround by calling exec sys.sysprocedure instead of just exec sysprocedure
				implicitly allows impersonation of any account, including sa;  allows creating/altering logins and altering server role which can also lead to privilege escalation; 
				gives full access to all databases but unlike sysadmins, are not mapped to dbo (so any new objects created will be in the user's own schema by default)
				
ALTER ANY DATABASE; --gives user rights to make schema changes in any database (create/drop tables, etc.), this is not to just run ALTER DATABASE statements
					--denying will prevent users from being able to alter procedures, etc. in any database!
ALTER SERVER STATE:  allows user to run DBCC FREEPROCCACHE & DBCC SQLPERF 
CONNECT ANY DATABASE:  does not grant any permission in any database beyond connect
VIEW ANY DATABASE:  view metadata that describes all databases, regardless of whether the user can actually see the database

--if granting CONTROL SERVER permission, also deny the following:
GRANT CONTROL SERVER TO [CENTENE\MPARKAR];
DENY IMPERSONATE ANY LOGIN TO [CENTENE\MPARKAR];
DENY ALTER ANY LOGIN TO [CENTENE\MPARKAR];
DENY ALTER ANY SERVER ROLE TO [CENTENE\MPARKAR];
DENY ALTER ANY SERVER AUDIT TO [CENTENE\MPARKAR];
DENY ALTER ANY DATABASE AUDIT TO [CENTENE\MPARKAR];

--view "my" permissions:
EXECUTE AS LOGIN='CENTENE\MNILES';
SELECT entity_name, permission_name FROM sys.fn_my_permissions(NULL, NULL)
EXECUTE AS LOGIN='CENTENE\TNIKOLAYCHUK';

SELECT USER_NAME();
--view current login's database level permissions:
SELECT * FROM fn_my_permissions(NULL,'DATABASE');
--view current login's object level permissions:
SELECT * FROM fn_my_permissions(dbo.tablename,'OBJECT');

REVERT;

--compare to all server permissions: 
SELECT class_desc COLLATE Latin1_General_CI_AI, permission_name COLLATE Latin1_General_CI_AI
FROM sys.fn_builtin_permissions('SERVER')
EXCEPT
SELECT entity_name, permission_name
FROM sys.fn_my_permissions(NULL, NULL) 


--********DATABASE LEVEL PERMISSIONS*******************************************
--Before giving a user any rights to a database, create the database user from their login with a default schema specified
--Adding users to database role without creating their user account will not let them connect to database unless they have a server login
--Make sure to specify default schema to prevent any permission issues
CREATE USER [CENTENE\CN121433] FROM LOGIN [CENTENE\CN121433] WITH DEFAULT_SCHEMA=[dbo];

--to give user access to database DMVs:
USE Datamart
GO
GRANT VIEW DATABASE STATE TO [CENTENE\ERX_Specialty_Analytics];
GRANT SHOWPLAN TO [CENTENE\ERX_Specialty_Analytics];


--------------remove database level permissions------------------------------------------

--first, check current access:
SELECT pe.class_desc, dp.name AS UserName, dp.type_desc as UserType, dp.type, pe.state_desc, pe.permission_name, 
	CASE
		WHEN pe.class_desc='SCHEMA' THEN s.name 
		WHEN pe.class_desc='OBJECT_OR_COLUMN' THEN COALESCE(o.name,t.name)
		ELSE O.name 
	END ObjectName
FROM sys.database_permissions pe
JOIN sys.database_principals dp ON pe.grantee_principal_id=dp.principal_id
LEFT JOIN sys.objects O ON O.object_id=pe.major_id 
LEFT JOIN sys.schemas S ON s.schema_id=pe.major_id
LEFT JOIN sys.tables t ON t.object_id=pe.major_id
LEFT JOIN sys.columns c on c.object_id=pe.major_id
WHERE (dp.name LIKE '%CMSAWS_Reader%' ) order by permission_name


REVOKE CONNECT FROM CMSAWS_Reader;

DENY CONNECT TO CMSAWS_Reader;

DROP Login test;

--For SQL Server Agent roles:
--SQLAgentUserRole: Ability to manage Jobs that they own
--SQLAgentReaderRole:  All of the SQLAgentUserRole rights plus the ability to review multiserver jobs, their configurations and history
--SQLAgentOperatorRole:  All of the SQLAgentReaderRole rights plus the ability to review operators, proxies and alerts; Execute, stop or start all local jobs; 
--		delete the job history for any local job; Enable or disable all local jobs and schedules
USE msdb
GO
CREATE USER [CENTENE\ERX_Specialty_Analytics] FROM LOGIN [CENTENE\ERX_Specialty_Analytics] WITH DEFAULT_SCHEMA=[dbo];  
--for 2008R2: sp_addrolemember 'SQLAgentReaderRole',[CENTENE\MPARKAR]
ALTER ROLE SQLAgentUserRole ADD MEMBER [CENTENE\ERX_Specialty_Analytics]
DROP USER test;

--give user access to read the error log:
GRANT EXECUTE ON master.sys.xp_readerrorlog TO [CENTENE\MPARKAR]

--SSIS permissions:
USE SSISDB 
GO
CREATE USER [CENTENE\ERX_Specialty_Analytics] FROM LOGIN [CENTENE\ERX_Specialty_Analytics] WITH DEFAULT_SCHEMA=[dbo];  
ALTER ROLE ssis_admin ADD MEMBER [];


--to view database properties:
GRANT VIEW DATABASE STATE TO [centene\cmonreal];
GRANT VIEW DEFINITION TO [centene\mparkar];

--if a user is in a windows group with read only access to the db  and has no personal database account, 
--I can still give them rights to view stored procs in the database:
GRANT VIEW DEFINITION on SCHEMA::dbo to [centene\cn158464]  

--read only access to all stored procedures:
CREATE USER [CENTENE\elslaughter] FROM LOGIN [CENTENE\elslaughter] WITH DEFAULT_SCHEMA=[dbo];
GRANT VIEW DEFINITION TO [CENTENE\MPEREIRA];

--***********Database Roles*******************
--don't use db_datareader or db_datawriter in SQL 2014+, instead, use GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO user;
--the reason is these roles can cause metadata visibility problems i.e. user can query tables but cannot view them in object explorer
CREATE ROLE db_executor AUTHORIZATION dbo;
GRANT SHOWPLAN TO USRGRP_ENCOUNTERS_ADMIN;
GRANT ALTER  TO USRGRP_UNDERWRITING_READER;
GRANT EXECUTE TO db_executor;
GRANT SELECT TO USRGRP_UNDERWRITING_READER;
GRANT DELETE TO USRGRP_UNDERWRITING_READER;
GRANT INSERT TO USRGRP_UNDERWRITING_READER;
GRANT UPDATE TO USRGRP_UNDERWRITING_READER;

GRANT SELECT ON FctMembership TO Datamart_Reader ;
GRANT SELECT ON SCHEMA::PBMADM TO [CENTENE\MKUKAL];



--for 2008R2 and older:  sp_addrolemember 'db_owner','USRGRP_UNDERWRITING_ADMIN'
CREATE ROLE USRGRP_UNDERWRITING_READER AUTHORIZATION dbo;

ALTER USER [CENTENE\RMHANGO] WITH DEFAULT_SCHEMA=[dbo]

ALTER ROLE USRGRP_UNDERWRITING_ADMIN ADD MEMBER  [CENTENE\CHADJONES];


sp_helprole 
sp_helprolemember 
sp_helpuser 'CENTENE\DW_USS_PHARM'
GO
sp_helpuser 'CENTENE\DW_USS_ACCTG'

--view permissions given to custom database roles:
SELECT DISTINCT rp.name, ObjectType = rp.type_desc, 
                PermissionType = pm.class_desc, 
                pm.permission_name, 
                pm.state_desc, 
                ObjectType = CASE 
                               WHEN obj.type_desc IS NULL 
                                     OR obj.type_desc = 'SYSTEM_TABLE' THEN 
                               pm.class_desc 
                               ELSE obj.type_desc 
                             END, 
                [ObjectName] = Isnull(ss.name, Object_name(pm.major_id)) 
FROM   sys.database_principals rp 
       INNER JOIN sys.database_permissions pm 
               ON pm.grantee_principal_id = rp.principal_id 
       LEFT JOIN sys.schemas ss 
              ON pm.major_id = ss.schema_id 
       LEFT JOIN sys.objects obj 
              ON pm.[major_id] = obj.[object_id] 
WHERE  rp.type_desc = 'DATABASE_ROLE' 
        AND rp.name<>'public'
ORDER  BY rp.name, 
          rp.type_desc, 
          pm.class_desc 


--to easily give users execute permissions on all procedures and functions, create a special role for it:
CREATE ROLE [USRGRP_ENCOUNTERS_ADMIN] AUTHORIZATION dbo;
GRANT EXECUTE TO db_executor;
ALTER ROLE db_executor ADD MEMBER [test];  --OR EXEC sp_addrolemember 'db_executor','testuser';

--to give users access to import/export wizard:
GRANT ALTER ON SCHEMA::dbo TO [USRGRP_ENCOUNTERS_ADMIN];
GRANT CREATE TABLE TO [USRGRP_ENCOUNTERS_ADMIN];
GRANT INSERT ON SCHEMA::dbo TO [USRGRP_ENCOUNTERS_ADMIN];

--**if user has db_datareader role membership, he can still update/insert data if permission is granted
  on object level

CREATE FUNCTION: user will also need ALTER SCHEMA permission to create functions 

--**********************SCHEMAS:*********************************************************************************************
--schema owner should be dbo to give all users access to it and to be able to control permissions on a finer level
--User will need ALTER permission on schema in order to be able to CREATE objects in that schema

CREATE SCHEMA [analyst] AUTHORIZATION dbo;  --new schema with ownership belonging to dbo

--SQL Server will assume the owner of newly created objects such as tables is the owner of the schema it is created in

GRANT CREATE SCHEMA TO [USRGRP_UNDERWRITING_ADMIN]  --give user permission to create schemas

GO
GRANT ALTER ON SCHEMA :: dbo TO [CENTENE\REPORTS];
GRANT select  TO [CENTENE\REPORTS];
GRANT INSERT  TO [CENTENE\REPORTS];
GRANT UPDATE  TO [CENTENE\REPORTS];
GRANT CREATE VIEW  TO analyst;
GRANT CREATE FUNCTION TO [CENTENE\REPORTS];
GRANT CREATE PROCEDURE TO [CENTENE\REPORTS];
GRANT DROP OBJECT TO [CENTENE\REPORTS]; 

GRANT INSERT ON SCHEMA :: analyst to analyst;
GRANT DELETE ON SCHEMA :: analyst to analyst;
GRANT select ON SCHEMA :: analyst to analyst;
GRANT CREATE FUNCTION TO analyst;
GRANT EXECUTE TO [CENTENE\MPARKAR];


ALTER AUTHORIZATION ON SCHEMA:: mherring TO dbo;
DENY ALTER ON SCHEMA :: dbo TO ocortes;
DROP SCHEMA [test_user];
DROP USER test_user;

--*****move objects from one schema to another:
ALTER SCHEMA analyst TRANSFER dbo.EnrollmentInstallations

--*****test user rights:
EXECUTE AS USER='SSRS_User';
SELECT * FROM INFORMATION_SCHEMA.TABLES
REVERT;

EXECUTE AS USER='CENTENE\elslaughter';
SELECT * FROM ReportServer.dbo.Catalog;
SELECT TOP 1 * FROM Datamart.dbo.FctMonthlyMembership;
SELECT TOP 1 * FROM Datamart.dbo.DimDate;
--UPDATE Kansas SET PlanGroupHierarchy1=1600 where segalrecordid=18
EXEC GROUP_CONCAT_DS;

BEGIN TRANSACTION
ROLLBACK TRANSACTION

USE USRGRP_UNDERWRITING
select top 1 * from datamart.dbo.fcttransactions; 
sp_helpdb usrgrp_finance;
dbcc showfilestats;
sp_spaceused;
CREATE TABLE test (id int)
select  * from test;
INSERT INTO test values ('1'),('2')
DELETE FROM TEST
drop table test
CREATE VIEW testcort AS SELECT Id from test
drop VIEW testcort

REVERT;
select * from sys.sysprocesses where loginame='CENTENE\rmhango'

--Display current execution context.
SELECT SUSER_NAME(), USER_NAME();


CREATE FUNCTION vtest  (@value varchar(max))
RETURNS varchar(max)
AS
BEGIN
	DECLARE @Result varchar(max)
	
	SET @Result = RTRIM(LTRIM(@value))

    RETURN CASE CHARINDEX(' ', @Result, 1)
        WHEN 0 THEN @Result
        ELSE SUBSTRING(@Result, 1, CHARINDEX(' ', @Result, 1) - 1) END
END

DROP FUNCTION vtest

EXECUTE usp_Updatesite_getsites


--view orphaned user accounts:
exec sp_change_users_login 'report'
exec sp_helplogins 'mkukal'
*/
/** see user permissions for objects in a database */
--ObjectName will not be relevant if class_desc is SCHEMA
SELECT pe.class_desc, dp.name AS UserName, dp.type_desc as UserType, dp.type, pe.state_desc, pe.permission_name, 
	CASE
		WHEN pe.class_desc='SCHEMA' THEN s.name 
		WHEN pe.class_desc='OBJECT_OR_COLUMN' THEN COALESCE(o.name,t.name)
		ELSE O.name 
	END ObjectName
FROM sys.database_permissions pe
JOIN sys.database_principals dp ON pe.grantee_principal_id=dp.principal_id
LEFT JOIN sys.objects O ON O.object_id=pe.major_id 
LEFT JOIN sys.schemas S ON s.schema_id=pe.major_id
LEFT JOIN sys.tables t ON t.object_id=pe.major_id
LEFT JOIN sys.columns c on c.object_id=pe.major_id
WHERE-- pe.class_desc='schema' 
(dp.name LIKE '%slaugh%' )-- ('analyst') --and o.name is not null state_desc='grant' and pe.permission_name IN ('alter','create table')
AND o.name like '%syrtis%'
order by permission_name

--rewrite the query above,  too many repeating rows since it is selecting from permissions first
SELECT DISTINCT pe.class_desc, dp.name AS UserName, dp.type_desc as UserType, dp.type, pe.state_desc, pe.permission_name, 
	CASE
		WHEN pe.class_desc='SCHEMA' THEN s.name 
		WHEN pe.class_desc='OBJECT_OR_COLUMN' THEN COALESCE(o.name, t.name)
		ELSE O.name 
	END ObjectName
FROM sys.objects O
INNER JOIN sys.database_permissions pe ON O.object_id=pe.major_id
LEFT JOIN sys.database_principals dp ON pe.grantee_principal_id=dp.principal_id
LEFT JOIN sys.schemas S ON s.schema_id=pe.major_id
LEFT JOIN sys.tables t ON t.object_id=pe.major_id
LEFT JOIN sys.columns c on c.object_id=pe.major_id

--get member of a role:
SELECT DP1.name AS DatabaseRoleName,   
   isnull (DP2.name, 'No members') AS DatabaseUserName   
 FROM sys.database_role_members AS DRM  
 RIGHT OUTER JOIN sys.database_principals AS DP1  
   ON DRM.role_principal_id = DP1.principal_id  
 LEFT OUTER JOIN sys.database_principals AS DP2  
   ON DRM.member_principal_id = DP2.principal_id  
WHERE DP1.type = 'R'
ORDER BY DP1.name;  

/*
select * from sys.schemas 
select * from sys.database_permissions pe LEFT JOIN sys.objects O ON O.object_id=pe.major_id where class_desc='OBJECT_OR_COLUMN'
*/
--see user database role memberships:
--some users are part of windows group so their accounts will not be shown
--if a user both has a SQL login and is a member of a windows group, some of the memberships that are inherited through the membership will not be shown 
select [Login Type]= case sp.type when 'u' then 'WIN' when 's' then 'SQL' when 'g' then 'GRP' end,
convert(char(45),sp.name) as srvLogin, convert(char(45),sp2.name) as srvRole, convert(char(25),dbp.name) as dbUser,
convert(char(25),dbp2.name) as dbRole from 
sys.database_principals as dbp inner join
sys.server_principals as sp  on sp.sid=dbp.sid left join
sys.database_role_members as dbrm on dbp.principal_Id=dbrm.member_principal_Id LEFT join
sys.database_principals as dbp2 on dbrm.role_principal_id=dbp2.principal_id left join 
sys.server_role_members as srm on sp.principal_id=srm.member_principal_id left join
sys.server_principals as sp2 on srm.role_principal_id=sp2.principal_id
where convert(char(25),dbp2.name) NOT IN ('Datamart_Reader          ','db_exec_datefunctions    ','db_datareader            ','db_datawriter            ')
 AND dbp.name like '%ribb%' or dbp.name like '%ribb%'


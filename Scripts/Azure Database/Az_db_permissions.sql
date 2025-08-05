--my permissions at the server level:
SELECT * FROM fn_my_permissions(NULL, 'SERVER');  
--my permissions on the database:
SELECT * FROM fn_my_permissions (NULL, 'DATABASE');  
GO
--my permissions on a view
SELECT * FROM fn_my_permissions('Sales.vIndividualCustomer', 'OBJECT')   
    ORDER BY subentity_name, permission_name ;   
GO  
--effective permissions of another user:
EXECUTE AS USER = 'Wanida';  
SELECT * FROM fn_my_permissions('HumanResources.Employee', 'OBJECT')   
    ORDER BY subentity_name, permission_name ;    
--on the database:
SELECT * FROM fn_my_permissions('MalikAr', 'USER');  
GO
REVERT;  
GO  
--effective permissions on a certificate:
SELECT * FROM fn_my_permissions('Shipping47', 'CERTIFICATE');  
GO


--server level permissions
SELECT sql_logins.principal_id AS MemberPrincipalID,
    sql_logins.name AS MemberPrincipalName,
    roles.principal_id AS RolePrincipalID,
    roles.name AS RolePrincipalName
FROM sys.server_role_members AS server_role_members
LEFT JOIN sys.server_principals AS roles
    ON server_role_members.role_principal_id = roles.principal_id
LEFT JOIN sys.sql_logins AS sql_logins
    ON server_role_members.member_principal_id = sql_logins.principal_id;
GO
--run this under master
SELECT member.principal_id AS MemberPrincipalID,
    member.name AS MemberPrincipalName,
    roles.principal_id AS RolePrincipalID,
    roles.name AS RolePrincipalName
FROM sys.server_role_members AS server_role_members
INNER JOIN sys.server_principals AS roles
    ON server_role_members.role_principal_id = roles.principal_id
INNER JOIN sys.server_principals AS member
    ON server_role_members.member_principal_id = member.principal_id
LEFT JOIN sys.sql_logins AS sql_logins
    ON server_role_members.member_principal_id = sql_logins.principal_id
WHERE member.principal_id NOT IN (
    -- prevent SQL Logins from interfering with resultset
    SELECT principal_id
    FROM sys.sql_logins AS sql_logins
    WHERE member.principal_id = sql_logins.principal_id
);
--Check the virtual master database roles for specific logins
SELECT DR1.name AS DbRoleName,
    ISNULL(DR2.name, 'No members') AS DbUserName
FROM sys.database_role_members AS DbRMem
RIGHT JOIN sys.database_principals AS DR1
    ON DbRMem.role_principal_id = DR1.principal_id
LEFT JOIN sys.database_principals AS DR2
    ON DbRMem.member_principal_id = DR2.principal_id
WHERE DR1.type = 'R'
    AND DR2.name LIKE 'bob%';

-- Run this under Application Database

SELECT    roles.principal_id                            AS RolePrincipalID
    ,    roles.name                                    AS RolePrincipalName
    ,    database_role_members.member_principal_id    AS MemberPrincipalID
    ,    members.name                                AS MemberPrincipalName
FROM sys.database_role_members AS database_role_members  
JOIN sys.database_principals AS roles  
    ON database_role_members.role_principal_id = roles.principal_id  
JOIN sys.database_principals AS members  
    ON database_role_members.member_principal_id = members.principal_id;  
GO

SELECT * FROM fn_builtin_permissions(default);
GO

--Return the permissions applicable to a specified object

SELECT * FROM sys.database_permissions
    WHERE major_id = OBJECT_ID('Repl.Handlelock');
GO

--Can I create procedures and tables in schema S?
SELECT HAS_PERMS_BY_NAME(db_name(), 'DATABASE', 'CREATE PROCEDURE')  
    & HAS_PERMS_BY_NAME('S', 'SCHEMA', 'ALTER') AS _can_create_procs,  
    HAS_PERMS_BY_NAME(db_name(), 'DATABASE', 'CREATE TABLE') &  
    HAS_PERMS_BY_NAME('S', 'SCHEMA', 'ALTER') AS _can_create_tables;  

--Which tables do I have SELECT permission on?
SELECT HAS_PERMS_BY_NAME  
(QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name),   
    'OBJECT', 'SELECT') AS have_select, * FROM sys.tables  

--Which columns of table T do I have SELECT permission on?
SELECT name AS column_name,   
    HAS_PERMS_BY_NAME('T', 'OBJECT', 'SELECT', name, 'COLUMN')   
    AS can_select   
    FROM sys.columns AS c   
    WHERE c.object_id=object_id('T');  

--Do I have INSERT permission on the SalesPerson table in AdventureWorks2022?

SELECT HAS_PERMS_BY_NAME('Sales.SalesPerson', 'OBJECT', 'INSERT'); 
SELECT HAS_PERMS_BY_NAME('AdventureWorks2022.Sales.SalesPerson',   
    'OBJECT', 'INSERT');  
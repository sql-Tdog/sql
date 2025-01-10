--view owners of schemas in the database:
SELECT [name] AS [schema], [schema_id], USER_NAME(principal_id) [Owner] FROM sys.schemas;

--SQL Server will assume the owner of newly created objects such as tables is the owner of the schema it is created in


--view all objects and the schemas they belong to and the effective owner:
SELECT so.[name] AS [Object], sch.[name] AS [Schema], USER_NAME(COALESCE(so.[principal_id], sch.[principal_id])) AS [Owner], type_desc AS [ObjectType] 
	FROM sys.objects so JOIN sys.schemas sch ON so.[schema_id] = sch.[schema_id] WHERE [type] IN ('U', 'P');


--ownership chaining occurs when the following are true:  one object refers to another object (like a stored proc referring to a table) and both objects have the same owner
--the user only needs permission on the first object because an onwership chain is formed
--this is useful if we want to control access to a table so that a user must access it through the stored procedure
--the stored proc can make sure the user does not accidentally delete all rows if he forgets the WHERE clause by including a parameter as an input

--****cross database ownership chaining*************************************************************
--cross database ownership can be turned on at either the server or the database level; by default, it is off at the server level
--and on for master, msdb, and tempdb only

--an unbroken ownership chain requires that all the object owners are mapped to the same login account
--If the source object in the source database and the target objects in the target databases are owned by the same login account, 
--SQL Server does not check permissions on the target objects


--check if it is on at the server level:
SELECT [name], value  FROM [sys].configurations WHERE [name] = 'cross db ownership chaining';

--to turn it on at the server level:
EXECUTE sp_configure 'show advanced', 1;  
RECONFIGURE;  
EXECUTE sp_configure 'cross db ownership chaining', 1;  
RECONFIGURE;  


--check what databases have database cross ownership chaining turned on:
SELECT [name] AS [Database], [is_db_chaining_on] FROM [sys].databases ORDER BY [name];

--in case there are database user that don't map to a login, find the ultimate owner of each object:
SELECT  so.[name] AS [Object], sch.[name] AS [Schema], USER_NAME(COALESCE(so.[principal_id], sch.[principal_id])) AS [OwnerUserName] 
  , sp.NAME AS [OwnerLoginName] , so.type_desc AS [ObjectType]  
FROM sys.objects so  JOIN sys.schemas sch  ON so.[schema_id] = sch.[schema_id]  
  JOIN [sys].database_principals dp ON dp.[principal_id] = COALESCE(so.[principal_id], sch.[principal_id]) 
  LEFT JOIN [master].[sys].[server_principals] sp  ON dp.sid = sp.sid 
WHERE so.[type] IN ('U', 'P');  


-- Turn on Cross-Database Ownership Chaining
ALTER DATABASE Database1 SET DB_CHAINING ON; 
GO


/*
Fashion Fair:  return AE sweaters, redeem $20 express reward
Return ps4 @Target, VS cologne
Mail back Amazon return & Nike sweater return


*/

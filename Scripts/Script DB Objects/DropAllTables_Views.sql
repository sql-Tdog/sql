/**T-SQL to drop all views in a database

USE ipas_audit 
GO

select * from sys.views

DECLARE @sql VARCHAR(MAX)='';
SELECT @sql=@sql+'DROP VIEW ['+name +'];' FROM sys.views;
EXEC(@sql);



--****1.  truncate all tables that are not referenced by any other tables
USE ipas_audit_2
GO

BEGIN TRANSACTION

EXEC sp_msforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"

DECLARE @sql VARCHAR(MAX)='';

WITH counts AS (
select  t.name, count(referenced_object_id) as NoOfReferences
from sys.foreign_key_columns f
right join sys.tables t on t.object_id=f.referenced_object_id
group by name
)

SELECT @sql=@sql+'TRUNCATE TABLE ['+name +'];' FROM counts  WHERE NoOfReferences=1 ;
SELECT @sql
EXEC(@sql);


-- Reseed
DBCC CHECKIDENT ('TestTable', RESEED, 1)
GO


EXEC sp_msforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"

*/

/**-- t-sql scriptlet to drop all constraints on all tables in a database
SELECT CONSTRAINT_CATALOG,TABLE_NAME, CONSTRAINT_NAME FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS

SELECT CONSTRAINT_CATALOG,TABLE_NAME, CONSTRAINT_NAME
INTO #constraints
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
ORDER BY TABLE_NAME DESc
ALTER TABLE #constraints add row_id int IDENTITY

DECLARE @database nvarchar(50), @rowid int
SET @rowid=1
DECLARE @sql nvarchar(500)
WHILE @Rowid=1
BEGIN
    select    @sql = 'ALTER TABLE ' + TABLE_NAME + ' DROP CONSTRAINT ' + CONSTRAINT_NAME 
    from    #constraints 
    where    row_id=@rowid
    exec    sp_executesql @sql
	set @rowid=@rowid+1
	select @sql
END

DROP TABLE #constraints

*/
/*T-SQL to drop all tables in a database
USE ipas_audit 
GO

select * from sys.tables

DECLARE @sql VARCHAR(MAX)='';
SELECT @sql=@sql+'DROP TABLE ['+name +'];' FROM sys.tables WHERE name not like '%audit%';
EXEC(@sql);

*/



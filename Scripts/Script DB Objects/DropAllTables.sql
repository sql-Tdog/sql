--drop all indexes:
select 'DROP INDEX ' + i.name + ' ON ' +quotename(OBJECT_SCHEMA_NAME(i.object_id))+'.['+ Object_name(t.object_id)+']' AS QUERYLIST
from sys.indexes i inner join sys.tables t on t.object_id=i.object_id
where i.name like 'ix%'


--drop all tables:
select 'DROP TABLE '+ schema_name(schema_id)+'.'+ name  from sys.tables

--drop all sps:
SELECT 'DROP PROCEDURE '+SPECIFIC_SCHEMA+'.'+SPECIFIC_NAME
  FROM INFORMATION_SCHEMA.ROUTINES
 WHERE ROUTINE_TYPE = 'PROCEDURE'
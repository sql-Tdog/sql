/******stored procedure DMVs*******************************
select * from sys.dm_exec_procedure_stats;
 
--view text for all stored procedures:
SELECT DISTINCT o.name AS Object_Name, o.type_desc, m.definition
FROM sys.sql_modules m
       INNER JOIN
       sys.objects o
         ON m.object_id = o.object_id
WHERE m.definition Like '%N''4415%';
 
 
select * from sys.sysprocesses where spid=69;
*/
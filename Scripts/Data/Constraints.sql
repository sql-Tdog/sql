SELECT chk.definition
FROM sys.check_constraints chk
INNER JOIN sys.columns c ON chk.parent_object_id=c.object_id
INNER JOIN sys.tables t ON t.object_id=chk.parent_object_id
WHERE t.name IN('RxA_PA_Transaction_File_To_Process','RxA_PA_Transaction_File')


SELECT chk.definition
FROM sys.default_constraints chk
INNER JOIN sys.columns c ON chk.parent_object_id=c.object_id
INNER JOIN sys.tables t ON t.object_id=chk.parent_object_id
WHERE t.name IN('RxA_PA_Transaction_File_To_Process','RxA_PA_Transaction_File')


SELECT OBJECT_NAME(object_id) AS ConstraintName, SCHEMA_NAME(schema_id) AS SchemaName,
	type_desc
FROM sys.objects
WHERE (OBJECT_NAME(parent_object_id)='RxA_PA_Transaction_File_To_Process' OR OBJECT_NAME(parent_object_id)='RxA_PA_Transaction_File')


--check which columns cannot have NULLS
SELECT Table_Name, Column_Name, Data_Type, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA='RXA' AND TABLE_NAME IN ('RxA_PA_Transaction_File_To_Process','RxA_PA_Transaction_File')
AND IS_NULLABLE='NO'

--look for CASCADE delete tables
select * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
where DELETE_RULE ='CASCADE'
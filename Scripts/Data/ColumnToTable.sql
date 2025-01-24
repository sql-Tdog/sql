/****** find what table a column belongs to  *****/
SELECT  C.name as columnName, T.name as tableName
FROM sys.columns C
INNER JOIN sys.tables T ON T.object_id=C.object_id
WHERE C.name like '%trg%'
 
 

select  t.name TableName, c.name ColumnName
from sys.tables t
inner join sys.columns c on c.object_id=t.object_id
inner join sys.types ty on ty.system_type_id=c.system_type_id
where ty.name NOT IN ('datetime','bit','sysname') and c.max_length=16
AND t.name NOT LIKE 'sys%' AND t.name like '%cred%'
 
 
 
--find certain types of columns:
DECLARE @sqlstatement VARCHAR(MAX);
DECLARE @stmt varchar(max);
 
SET @sqlstatement =
    REPLACE (
        STUFF ( (
            SELECT  'UNION ALL SELECT TOP 1 ''' + t.name + ''' as TableName, '''
                + c.name + ''' AS ColumnName'--, '
               -- + c.name
                       -- + ' AS Value
                       +' FROM '                + t.name
                        + ' WHERE LEN (' + c.name + ') ' + CHAR(62) + ' 16 '
            FROM sys.columns c
            INNER JOIN sys.tables t ON c.object_id = t.object_id -- AND c.name LIKE '%gl%acc%'
                     INNER JOIN sys.types ty ON c.system_type_id = ty.system_type_id
    AND (
        ty.name IN ('text', 'ntext')
        OR (
            ty.name IN ('varchar', 'char', 'nvarchar', 'nchar')
            AND (c.max_length > 25 OR c.max_length = -1)
    ))
            FOR XML PATH('')
            ), 1, 10, '')
        , '&gt;', '=')
 
SET @stmt=(SELECT @sqlstatement)
SELECT @STMT;
EXEC (@sqlstatement)
 
 
 
 
--script to run select statement to select all fields that have a length of 16 characters:
DECLARE @sqlstatement VARCHAR(MAX);
DECLARE @stmt varchar(max);
 
SET @sqlstatement =
    REPLACE (
        STUFF ( (
            SELECT  'UNION ALL SELECT TOP 1 ''' + t.name + ''' as TableName, '''
                + c.name + ''' AS ColumnName'--, '
               -- + c.name
                       -- + ' AS Value
                       +' FROM '                + t.name
                        + ' WHERE LEN (' + c.name + ') ' + CHAR(62) + ' 16 '
            FROM sys.columns c
            INNER JOIN sys.tables t ON c.object_id = t.object_id -- AND c.name LIKE '%gl%acc%'
                     INNER JOIN sys.types ty ON c.system_type_id = ty.system_type_id
    AND (
        ty.name IN ('text', 'ntext')
        OR (
            ty.name IN ('varchar', 'char', 'nvarchar', 'nchar')
            AND (c.max_length > 25 OR c.max_length = -1)
    ))
            FOR XML PATH('')
            ), 1, 10, '')
        , '&gt;', '=')
 
SET @stmt=(SELECT @sqlstatement)
SELECT @STMT;
EXEC (@sqlstatement)
 

/**script to get information about user defined TABLE TYPEs:
 **get column information**/

SELECT TableTypeName=CASE rn WHEN 1 THEN TableTypeName ELSE '' END
    ,ColumnName, ColumnType, max_length
    ,[precision], scale, collation_name
    ,[Nulls Allowed]=CASE is_nullable WHEN 1 THEN 'YES' ELSE 'NO' END
    ,[Is Identity]=CASE is_identity WHEN 1 THEN 'YES' ELSE 'NO' END
    ,[Is In Primary Key]=CASE WHEN index_column_id IS NULL THEN 'NO' ELSE 'YES' END
    ,[Primary Key Constraint Name]=CASE rn WHEN 1 THEN ISNULL(PKName, '') ELSE '' END
FROM
(
    SELECT TableTypeName=a.name, ColumnName=b.name, ColumnType=UPPER(c.name)
        ,b.max_length, b.[precision], b.scale
        ,collation_name=COALESCE(b.collation_name, a.collation_name, '')
        ,rn=ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY b.column_id)
        ,b.column_id
        ,b.is_nullable
        ,b.is_identity
        ,e.index_column_id
        ,PKName = d.name
    FROM sys.table_types a
    JOIN sys.columns b ON b.[object_id] = a.type_table_object_id
    JOIN sys.types c
        ON c.system_type_id = b.system_type_id
    LEFT JOIN sys.key_constraints d ON b.[object_id] = d.parent_object_id
    LEFT JOIN sys.index_columns e
        ON b.[object_id] = e.[object_id] AND e.index_column_id = b.column_id
    WHERE c.system_type_id = c.user_type_id
) a
--WHERE a.TableTypeName = 'Process_Log'
ORDER BY a.TableTypeName, column_id;


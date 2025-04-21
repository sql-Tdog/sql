/***
--test compression savings:

USE DataMart;
GO
EXEC sp_estimate_data_compression_savings 'dbo', 'DimClaim', NULL, NULL, 'PAGE' ;
GO

--identify non-compressed indexes:
SELECT st.name, ix.name , st.object_id, sp.partition_id, sp.partition_number, sp.data_compression,sp.data_compression_desc
FROM sys.partitions SP 
INNER JOIN sys.tables ST ON st.object_id = sp.object_id 
LEFT OUTER JOIN sys.indexes IX ON sp.object_id = ix.object_id and sp.index_id = ix.index_id
WHERE sp.data_compression = 0
order by st.name, sp.index_id

--identify compressed indexes:
SELECT st.name, ix.name , st.object_id, sp.partition_id, sp.partition_number, sp.data_compression,sp.data_compression_desc
FROM sys.partitions SP 
INNER JOIN sys.tables ST ON st.object_id = sp.object_id 
LEFT OUTER JOIN sys.indexes IX ON sp.object_id = ix.object_id and sp.index_id = ix.index_id
WHERE sp.data_compression <> 0
order by st.name, sp.index_id

--Creates the ALTER TABLE Statements

SET NOCOUNT ON
SELECT 'ALTER TABLE ' + '[' + s.[name] + ']'+'.' + '[' + o.[name] + ']' + ' REBUILD WITH (DATA_COMPRESSION=PAGE);'
FROM sys.objects AS o WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON o.[object_id] = i.[object_id]
INNER JOIN sys.schemas AS s WITH (NOLOCK)
ON o.[schema_id] = s.[schema_id]
INNER JOIN sys.dm_db_partition_stats AS ps WITH (NOLOCK)
ON i.[object_id] = ps.[object_id]
AND ps.[index_id] = i.[index_id]
WHERE o.[type] = 'U'
ORDER BY ps.[reserved_page_count]




--Creates the ALTER INDEX Statements

SET NOCOUNT ON
SELECT 'ALTER INDEX '+ '[' + i.[name] + ']' + ' ON ' + '[' + s.[name] + ']' + '.' + '[' + o.[name] + ']' + ' REBUILD WITH (DATA_COMPRESSION=PAGE);'
FROM sys.objects AS o WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON o.[object_id] = i.[object_id]
INNER JOIN sys.schemas s WITH (NOLOCK)
ON o.[schema_id] = s.[schema_id]
INNER JOIN sys.dm_db_partition_stats AS ps WITH (NOLOCK)
ON i.[object_id] = ps.[object_id]
AND ps.[index_id] = i.[index_id]
WHERE o.type = 'U' AND i.[index_id] >0
ORDER BY ps.[reserved_page_count]


*/
/****tsql to defragment indexes based on % of fragmentation *****/
 
/*
 
--this script is to be run as a SQL Server Agent job
--it will go through all databases and rebuild/reorganize indexes
 
 
--get all fragmented indexes in all databases and dump them into a table:
CREATE TABLE  #FragmentedIndexs  (db varchar(25),sch VARCHAR(15),ObjectName VARCHAR(100), IndexName Varchar(500),
IndexType Varchar(25), AvgFragmentationInPercent DECIMAL(6,2),FragmentCount INT,AvgFragmentSizeInPage DECIMAL(6,2), Pages INT, [FillFactor] INT)
declare @SQL nvarchar(max);
set @SQL = ''
select @SQL = @SQL +
'INSERT INTO #FragmentedIndexs
Select ' + quotename(name,'''') + ' as db,
object_schema_name(PS.Object_ID,'+ convert(varchar(10),database_id) + '),
object_Name(PS.Object_ID,' + convert(varchar(10),database_id) + ') as [Object],
''[''+I.Name+'']'' as [Index Name], PS.Index_Type_Desc,
PS.avg_fragmentation_in_percent,    PS.fragment_count,  PS.avg_fragment_size_in_pages,
PS.page_count, fill_factor
from ' + quotename(name) + '.sys.dm_db_index_physical_stats(' +
convert(varchar(10),database_id) + ', NULL, NULL, NULL, NULL) PS
INNER JOIN ' + quotename(name) +
'.sys.Indexes I on PS.Object_ID = I.Object_ID and PS.Index_ID = I.Index_ID '
+ CHAR(13)
  from sys.databases
  where state_desc = 'ONLINE' and database_id IN (5,6,7,8,9,11,12)
 
 
execute(@SQL)
 
select * from #FragmentedIndexs order by AvgFragmentationInPercent desc;
 
 
DECLARE @tsql NVARCHAR(MAX), @fillfactor INT
SET @fillfactor = 99
 
--Prepare the Query to REORGANIZE the Indexes
 
SET @tsql = ''
SELECT @tsql =
       STUFF(( SELECT DISTINCT
                     ';' + 'ALTER INDEX ' + IndexName + ' ON ' + '['+db+'].['+sch+'].['+ObjectName + '] REORGANIZE '
              FROM
                     #FragmentedIndexs FI
                     WHERE
                     AvgFragmentationInPercent BETWEEN 5 AND 30 AND [FillFactor]=0
                     FOR XML PATH('')), 1,1,'')
SELECT @tsql
EXEC sp_executesql @tsql
 
--Prepare the Query to REBUILD the Indexes
SET @tsql = ''
SELECT @tsql =
       STUFF(( SELECT DISTINCT
                     ';' + 'ALTER INDEX ' + IndexName + ' ON ' + '['+db+'].['+sch+'].['+ObjectName + '] REBUILD WITH (FILLFACTOR = ' + CONVERT(VARCHAR(3),@fillfactor) + ') '
                     FROM
                     #FragmentedIndexs FI
                     WHERE
                     AvgFragmentationInPercent > 30 OR [FillFactor]<>0
                     FOR XML PATH('')), 1,1,'')
SELECT @tsql
EXEC sp_executesql @tsql
 
DROP TABLE #FragmentedIndexs
 
*/
 
DECLARE @tsql NVARCHAR(MAX), @fillfactor INT
SET @fillfactor = 70
DECLARE @FragmentedIndexs TABLE (IndexID INT,IndexName VARCHAR(1000),ObjectName VARCHAR(1000),
       AvgFragmentationInPercent DECIMAL(6,2),FragmentCount INT,AvgFragmentSizeInPage DECIMAL(6,2),IndexDepth INT)
 
--Insert the Details for Fragmented Indexes.
INSERT INTO @FragmentedIndexs
SELECT
  PS.index_id,
  QUOTENAME(I.name) Name,
  QUOTENAME(DB_NAME()) +'.'+ QUOTENAME(OBJECT_SCHEMA_NAME(I.[object_id])) + '.' + QUOTENAME(OBJECT_NAME(I.[object_id])) ObjectName,
  PS.avg_fragmentation_in_percent,
  PS.fragment_count,
  PS.avg_fragment_size_in_pages,
   PS.index_depth
FROM
  sys.dm_db_index_physical_stats (
  DB_ID(), NULL ,NULL, NULL, NULL
  ) AS PS
INNER JOIN sys.indexes AS I
  ON PS.[object_id]= I.[object_id]  AND PS.index_id = I.index_id
WHERE  PS.avg_fragmentation_in_percent > 5  AND PS.fragment_count>5
ORDER BY
  PS.avg_fragmentation_in_percent DESC
 
--Select the details.
SELECT * FROM @FragmentedIndexs ORDER BY
  AvgFragmentationInPercent DESC
 
 
/*
 
 
--Prepare the Query to REORGANIZE the Indexes
SET @tsql = ''
SELECT @tsql =
  STUFF(( SELECT DISTINCT
           ';' + 'ALTER INDEX ' + FI.IndexName + ' ON ' + FI.ObjectName + ' REORGANIZE '
              FROM
           @FragmentedIndexs FI
          WHERE
            FI.AvgFragmentationInPercent <= 30
          FOR XML PATH('')), 1,1,'')
SELECT @tsql
--EXEC sp_executesql @tsql
 
--Prepare the Query to REBUILD the Indexes
SET @tsql = ''
SELECT @tsql =
  STUFF(( SELECT DISTINCT
           ';' + 'ALTER INDEX ' + FI.IndexName + ' ON ' + FI.ObjectName + ' REBUILD WITH (FILLFACTOR = ' + CONVERT(VARCHAR(3),@fillfactor) + ') '
          FROM
           @FragmentedIndexs FI
          WHERE
            FI.AvgFragmentationInPercent > 30
          FOR XML PATH('')), 1,1,'')
SELECT @tsql
--EXEC sp_executesql @tsql
 
*/
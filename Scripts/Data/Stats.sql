/**STATS************************************************************
--when an index is created, the statistics are created as well with FULLSCAN (same name as the index)

is_auto_create_stats_on:  SQL will create stats for columns used as predicates in WHERE clauses
is_auto_update_stats_on:  stats will be checked every time a query is compiled, will be updated if considered out of date
			threshold is 500+20% of # records in a table for older versions, starting with SQL 2016 the threshold changes as table gets larger
is_auto_update_stats_async_on:  default is off, stats will be updated as soon as query is compiled and before executing
								when on, the Query Optimizer will not wait for the update of statistics, but will run the query first and update 
								the outdated statistics afterwards, a background process will start to update the statistics in a separate thread
								may choose a suboptimal plan for current query
is_auto_create_stats_incremental_on: disabled by default, recommend to enable if using partitioning; when ON, the statistics created are per partition statistics. 
								when OFF, stats are combined for all partitions			
											
*/

--check if auto stats is set to on:
SELECT name, is_auto_create_stats_on, is_auto_update_stats_on, is_auto_update_stats_async_on, is_auto_create_stats_incremental_on
FROM sys.databases;
--set auto update 
ALTER DATABASE DocusignCentral SET AUTO_UPDATE_STATISTICS_ASYNC ON


SELECT sp.stats_id, object_name(stat.object_id), name, filter_definition, last_updated, rows, rows_sampled, steps, unfiltered_rows, modification_counter
FROM sys.stats AS stat
CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp
--WHERE stat.object_id=object_id('SalesLT.Address')
order by modification_counter desc
 
SELECT s.stats_id StatsID,
  s.name StatsName,
  sc.stats_column_id StatsColID,
  c.name ColumnName 
FROM sys.stats s 
  INNER JOIN sys.stats_columns sc
    ON s.object_id = sc.object_id AND s.stats_id = sc.stats_id
  INNER JOIN sys.columns c
    ON sc.object_id = c.object_id AND sc.column_id = c.column_id
WHERE OBJECT_NAME(s.object_id) = 'awsales'
ORDER BY s.stats_id, sc.column_id;


/**
SET STATISTICS IO ON
 
ALTER DATABASE ipas SET AUTO_CREATE_STATISTICS ON;
ALTER DATABASE SDGEESA SET AUTO_UPDATE_STATISTICS ON;

 
DBCC SHOW_STATISTICS ('dbo.Posts', ix_Posts_LastActivityDate) WITH HISTOGRAM;
DBCC SHOW_STATISTICS ('dbo.Posts', ix_Posts_LastActivityDate);
 
--update stats on an entire table:
UPDATE STATISTICS FctClaims

--update stats on a specific index:
UPDATE STATISTICS FctClaims ix_Fctclaims_claimkey;  --uses a default calculation to determine the sample
UPDATE STATISTICS FctClaims ix_Fctclaims_claimkey WITH FULLSCAN;  --use full table's data instead of a sample to update stats
UPDATE STATISTICS FctClaims ix_Fctclaims_claimkey WITH SAMPLE 10 PERCENT;  

 
 --update stas on an entire database:
--what does exec sp_updatestats do?
--it will update stats for any table that has at least 1 row that has been changed
--sample size is selected by SQL server and will be too small for very large tables
 EXEC sp_updatestats;

 
SELECT [sch].[name] + '.' + [so].[name] AS [TableName] ,
[ss].[name] AS [Statistic],
[sp].[last_updated] AS [StatsLastUpdated] ,
[sp].[rows] AS [RowsInTable] ,
[sp].[rows_sampled] AS [RowsSampled] ,
[sp].[modification_counter] AS [RowModifications]
FROM [sys].[stats] [ss]
JOIN [sys].[objects] [so] ON [ss].[object_id] = [so].[object_id]
JOIN [sys].[schemas] [sch] ON [so].[schema_id] = [sch].[schema_id]
OUTER APPLY [sys].[dm_db_stats_properties]([so].[object_id],
[ss].[stats_id]) sp
WHERE [so].[type] = 'U'
--AND [sp].[modification_counter] > 0
ORDER BY [sp].[last_updated] ;
 
 
USE Datamart -- Change desired database name here
GO
SET NOCOUNT ON
GO
DECLARE updatestats CURSOR FOR
SELECT table_name FROM information_schema.tables
       where TABLE_TYPE = 'BASE TABLE'
OPEN updatestats
 
DECLARE @tablename NVARCHAR(128)
DECLARE @Statement NVARCHAR(300)
 
FETCH NEXT FROM updatestats INTO @tablename
WHILE (@@FETCH_STATUS = 0)
BEGIN
   SET @Statement = 'UPDATE STATISTICS '  + @tablename + '  WITH FULLSCAN'
   PRINT @Statement
       --EXEC sp_executesql @Statement
   FETCH NEXT FROM updatestats INTO @tablename
END
 
CLOSE updatestats
DEALLOCATE updatestats
GO
SET NOCOUNT OFF
GO
 
*/
 
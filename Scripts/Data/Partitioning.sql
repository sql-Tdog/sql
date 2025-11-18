/**Enterprise Edition feature************************************************************************
--look at partitioned tables:
SELECT DISTINCT t.name FROM sys.partitions P INNER JOIN sys.tables T ON P.object_id=T.object_id
WHERE P.partition_number<>1;

SELECT name, physical_name, size 
FROM  sys.database_files 

SELECT name, data_space_id, type, type_desc, is_default, filegroup_guid, log_filegroup_id, is_read_only
FROM sys.filegroups;


--create a new filegroup for each partition 
--it's easier to manage partitions if there is 1 file in each filegroup and 1 filegroup is used for each partition
--if clustered index will be columnstore, create an extra partition that will remain empty since we cannot split the last partition if it has data
ALTER DATABASE prtn ADD FILEGROUP prtn1;
ALTER DATABASE prtn ADD FILEGROUP prtn2;
ALTER DATABASE prtn ADD FILEGROUP prtn3;
ALTER DATABASE prtn ADD FILEGROUP prtn4;
ALTER DATABASE prtn ADD FILEGROUP prtn5;
ALTER DATABASE prtn ADD FILEGROUP prtn6;
GO

--add a new file to the new filegroup
ALTER DATABASE prtn ADD FILE (NAME = prtn1,FILENAME='D:\SQLDATA\prtn1.ndf',SIZE=1GB)	TO FILEGROUP prtn1;
ALTER DATABASE prtn ADD FILE (NAME = prtn2,FILENAME='D:\SQLDATA\prtn2.ndf',SIZE=1GB)	TO FILEGROUP prtn2;
ALTER DATABASE prtn ADD FILE (NAME = prtn3,FILENAME='D:\SQLDATA\prtn3.ndf',SIZE=1GB)	TO FILEGROUP prtn3;
ALTER DATABASE prtn ADD FILE (NAME = prtn4,FILENAME='D:\SQLDATA\prtn4.ndf',SIZE=1GB)	TO FILEGROUP prtn4;
ALTER DATABASE prtn ADD FILE (NAME = prtn5,FILENAME='D:\SQLDATA\prtn5.ndf',SIZE=1GB)	TO FILEGROUP prtn5;
ALTER DATABASE prtn ADD FILE (NAME = prtn6,FILENAME='D:\SQLDATA\prtn6.ndf',SIZE=1GB)	TO FILEGROUP prtn6;

--Create a partition function, choosing the appropriate column for partitioniong
--LEFT partition means the boundary will be in the left partition
CREATE PARTITION FUNCTION key_prtnfunction (int) AS RANGE LEFT FOR VALUES (161652979,211785809,261790158,311791056,361792577);

--Create a partition scheme that will apply the partition function to the new filegroup
CREATE PARTITION SCHEME prtn_scheme AS PARTITION key_prtnfunction TO (prtn2,prtn2,prtn3,prtn4,prtn5,prtn6);
--DROP PARTITION SCHEME prtn_scheme

--view partition scheme definition:
select distinct ps.Name AS PartitionScheme, pf.name AS PartitionFunction,fg.name AS FileGroupName, rv.value AS PartitionFunctionValue
    from sys.indexes i  
    join sys.partitions p ON i.object_id=p.object_id AND i.index_id=p.index_id  
    join sys.partition_schemes ps on ps.data_space_id = i.data_space_id  
    join sys.partition_functions pf on pf.function_id = ps.function_id  
    left join sys.partition_range_values rv on rv.function_id = pf.function_id AND rv.boundary_id = p.partition_number
    join sys.allocation_units au  ON au.container_id = p.hobt_id   
    join sys.filegroups fg  ON fg.data_space_id = au.data_space_id  
where i.object_id = object_id('TableName') 


--Create a new table that be used to switch out oldest data from MyTable:
CREATE TABLE MyTableHistory (claim_key int primary key, claim_amt numeric(11,2), tax_amt numeric(8,2)) ON prtn1 WITH (DATA_COMPRESSION=PAGE);

DROP TABLE MyTableHistory;

--to partition an existing table, drop and recreate the clustered index (remember to drop nonclustered indexes first):
ALTER TABLE [dbo].MyTable DROP  CONSTRAINT pk_primarykey;
GO
ALTER TABLE [dbo].MyTable ADD  CONSTRAINT pk_primarykey PRIMARY KEY CLUSTERED ([claim_key] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = ON, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100,
	DATA_COMPRESSION=PAGE) ON prtn_scheme (claim_key);
GO  --00:15:47

--to create a columnstore clustered index on a table, partition the table first in previous step, then drop the clustered index
ALTER TABLE [dbo].MyTable DROP  CONSTRAINT pk_primarykey  WITH ( ONLINE = OFF );
GO
CREATE CLUSTERED COLUMNSTORE INDEX ix_MyTable_ClusteredColumn ON MyTable ON prtn_scheme (claim_key); 
GO
ALTER TABLE [dbo].[MyTable] ADD  CONSTRAINT [pk_primarykey] PRIMARY KEY ([claim_key] ASC); 
*/


--view how many rows of table are in each partition:
SELECT f.name filegroup_name, i.data_space_id, i.name indexname, partition_id, partition_number, [rows], ps.name partition_scheme, 
pf.name partition_function, r.boundary_id, r.value
FROM sys.partitions p
INNER JOIN sys.objects o ON o.object_id=p.object_id
INNER JOIN sys.indexes i ON i.object_id=p.object_id and p.index_id=i.index_id
INNER JOIN sys.partition_Schemes ps on ps.data_space_id=i.data_space_id
INNER JOIN sys.partition_functions pf on pf.function_id=ps.function_id
LEFT JOIN sys.partition_range_values r on pf.function_id=r.function_id AND r.boundary_id=p.partition_number
INNER JOIN sys.allocation_units AU ON AU.container_id = p.partition_id 
INNER JOIN sys.filegroups f on f.data_space_id=au.data_space_id
WHERE o.name LIKE 'FctClaims%' OR o.name LIKE 'Work_FctClaims%'
ORDER BY indexname, partition_number

/*
--view boundaries:
SELECT  partition_id, partition_number, [rows], ps.name partition_scheme, pf.name partition_function, 
r.boundary_id, r.value
FROM sys.partitions p
INNER JOIN sys.indexes i ON i.object_id=p.object_id and p.index_id=i.index_id
INNER JOIN sys.partition_Schemes ps on ps.data_space_id=i.data_space_id
INNER JOIN sys.partition_functions pf on pf.function_id=ps.function_id
LEFT JOIN sys.partition_range_values r on pf.function_id=r.function_id AND r.boundary_id=p.partition_number
WHERE ps.name='Fcttransactions_prtnscheme' -- OR o.name LIKE 'PK_FctClaims%'


select * from sys.filegroups
--to specify the filegroup that will be used next:
ALTER PARTITION SCHEME MyRangePS1 NEXT USED test5fg;


/**************Switching*******************************************************************************************
--Switching can be used to assign a table as a partition to an already existing partitioned table,
--switching a partition from one partitioned table to another, or reassigning a partition to form a single table

--when a partition is transferred, the data is not physically moved; only the metadata about the location of the data changes

--Requirements:  both tables must exist, the receiving partion must be empty, partitions must be on the same column,
--the receiving nonpartitioned table must be empty, source and target tables must share the same filegroup
*/

--switch from a non-partitioned table to another non-partitioned table:
ALTER TABLE [Source] SWITCH TO [Target];

--if the table's right most partition was switched out, it does not know what partition to use next (specify)
ALTER PARTITION SCHEME FctTransactions_prtnscheme NEXT USED FctTransactionsPartition4;


--load data by switching in: assign a table as a partition to an already partitioned table
--in order to switch into a partition, we have to EXPLICITLY add a check constraint, this will ensure it only contains data with values 
--that are allowed in the target partition
--in order to be able to switch out like this, both tables must be created on the same filegroup

ALTER TABLE [Source] WITH CHECK ADD CONSTRAINT date_check CHECK (col IS NOT NULL AND col >='1/1/2012');
ALTER TABLE [Source] SWITCH TO [Target] PARTITION 1;

--archive data by switching out:  move a partition to a nonpartitioned empty table
--if I switch out the right most partition in the table, I will have only full partitions left in the table & SQL Server won't 
--know what partition to use next (I need to tell it)
ALTER TABLE MyTable SWITCH PARTITION 1 TO MyTableHistory;
ALTER PARTITION SCHEME FctTransactions_prtnscheme NEXT USED FctTransactionsPartition4;

--switch partition in one table to an empty partition in another table:
ALTER TABLE [Source] SWITCH PARTITION 1 TO [Target] PARTITION 1;

--to split a partition, add a new boundary split
--this will create a new partition on the same filegroup as the range that is being split is sitting on
--OR if I am adding a new range by splitting higher then the right most range, it will create the new range on the NEXT USED filegroup
/**Caveats:  
	1.  cannot split a range in a non-empty partition when the partitioned table has a clustered columnstore index, 
		the solution is to empty out the partition by switching it out to a work table, then split the range, then switch the data back in
	2.  splitting a range in a table that has data in it might take a long time, so the solution is the same as #1

*/
ALTER PARTITION FUNCTION claim_key_prtnfunction()  SPLIT RANGE ('20120303');


--to merge partitions, remove a boundary
--now the 2 partitions will merge to exist on 1 filegroup
ALTER PARTITION FUNCTION claim_key_prtnfunction() MERGE RANGE ('20130303');

--rebuild all partitions:
ALTER TABLE PartitionTable1 REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE ON PARTITIONS(1) ) ;


--view all possible error/warning messages related to switching partitions:
SELECT message_id, text FROM sys.messages WHERE language_id = 1033 AND text LIKE '%ALTER TABLE SWITCH%';


--check what filegroup a table is on:
SELECT o.[name], o.[type], i.[name], i.[index_id], f.[name]
FROM sys.indexes i INNER JOIN sys.filegroups f ON i.data_space_id = f.data_space_id
INNER JOIN sys.all_objects o ON i.[object_id] = o.[object_id]
WHERE i.data_space_id = f.data_space_id AND o.type = 'U' -- User Created Tables
AND f.name LIKE 'FctClaims%'


--get seed info of column:
SELECT IDENT_SEED(TABLE_NAME) AS Seed,
IDENT_INCR(TABLE_NAME) AS Increment,
IDENT_CURRENT(TABLE_NAME) AS Current_Identity,
TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE OBJECTPROPERTY(OBJECT_ID(TABLE_NAME), 'TableHasIdentity') = 1
AND TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME IN ('FctClaims','Work_FctClaims')


--check if  there are indexes are NOT partition aligned
SELECT ISNULL(db_name(s.database_id),db_name()) AS DBName,OBJECT_SCHEMA_NAME(i.object_id,DB_ID()) AS SchemaName
 ,o.name AS [Object_Name],i.name AS Index_name,i.Type_Desc AS Type_Desc,ds.name AS DataSpaceName,ds.type_desc AS DataSpaceTypeDesc
 ,s.user_seeks,s.user_scans,s.user_lookups,s.user_updates,s.last_user_seek,s.last_user_update
FROM sys.objects AS o
JOIN sys.indexes AS i ON o.object_id = i.object_id
JOIN sys.data_spaces ds ON ds.data_space_id = i.data_space_id
LEFT OUTER JOIN sys.dm_db_index_usage_stats AS s ON i.object_id = s.object_id AND i.index_id = s.index_id AND s.database_id = DB_ID()
WHERE o.type = 'u' AND i.type IN (1, 2) AND o.object_id in
	(
	 SELECT a.object_id from
	 (SELECT ob.object_id, ds.type_desc from sys.objects ob 
	 JOIN sys.indexes ind on ind.object_id = ob.object_id 
	 JOIN sys.data_spaces ds on ds.data_space_id = ind.data_space_id
	 GROUP BY ob.object_id, ds.type_desc ) a 
	 GROUP BY a.object_id 
	 HAVING COUNT (*) > 1
	 )
ORDER BY [Object_Name] DESC;
GO





**/

/**example of loading data into a work table and then switching it in to the main table:

When to do this:
if all partitions are full on a clustered columnstore indexed table: cannot split a range in a non-empty partition on a clustered columnstore index
if I need to add more partitions at the tail end but there is a lot of data to split, this may take a very long time & resources

Solution:
Empty out the partition that needs to be split by switching it out to a work table and then split it
***in order to be able to switch out like this, both tables must be created on the same filegroup***


Steps:
1.  create a work table by scripting the original table, keep the same primary key & default constraints & same filegroup, but remove partition scheme
	script out & add clustered index if it's not the primary key (make sure to remove partition scheme from the script)
	any indexes that are not partition aligned will either need to be dropped or disabled (disabling misaligned clustered index will not accomplish switching)


--in this case I created a work table on Partition4, this table is partitioned on transaction_key
ALTER TABLE FctTransactions SWITCH PARTITION 4 TO Work_FctTransactions;

--first, create the same clustered index on the work table so I can switch in to the partitioned table
--make sure the filegroup is the same as the partition for current year 
CREATE CLUSTERED COLUMNSTORE INDEX ix_Work_FctTransactions_Clustered ON Work_FctTransactions ON FctTransactionsPartition4;

--now, split the range based on the max value of partitioned column of work table
--since I currently have 4 full partitions & rightmost #5 is empty; this split will create a new partition on the same filegroup as #4
DECLARE @range_high INT = (SELECT max(transaction_key) FROM Work_FctTransactions);
ALTER PARTITION FUNCTION FctTransactions_prtfcn () SPLIT RANGE (@range_high);
	
--make sure the work table matches the partition keys in the main table
DECLARE @range_low INT = (SELECT max(transaction_key)+1 FROM FctTransactions);
DECLARE @stmt nvarchar(2000);
SET @stmt='ALTER TABLE Work_FctTransactions WITH CHECK ADD CONSTRAINT claim_key_check_Work_FctTransactions CHECK (transaction_key IS NOT NULL AND 
	transaction_key between '+ convert(nvarchar(25),@range_low )
	+' AND '+convert(varchar(25),@range_high) +' )'
	
EXECUTE sp_executesql @stmt;



--since I just switched ou the right most partition, I need to tell SQL what partition to use next:


--now split the far right partition in FctTransactions:
DECLARE @range_high INT = (SELECT max(transaction_key) FROM Work_FctTransactions);
SELECT @range_high;
ALTER PARTITION FUNCTION FctTransactions_prtfcn () SPLIT RANGE (@range_high);

--switch data from the work table back in to partition 4
--in order to switch into a partition, we have to add a check constraint:
DECLARE @range_high INT = (SELECT max(transaction_key) FROM Work_FctTransactions);
DECLARE @range_low INT = (SELECT max(transaction_key)+1 FROM FctTransactions);
DECLARE @stmt nvarchar(2000);
SET @stmt='ALTER TABLE Work_FctTransactions WITH CHECK ADD CONSTRAINT claim_key_check_Work_FctTransactions CHECK (transaction_key IS NOT NULL AND 
	transaction_key between '+ convert(nvarchar(25),@range_low )
	+' AND '+convert(varchar(25),@range_high) +' )'
EXECUTE sp_executesql @stmt;

ALTER TABLE Work_FctTransactions SWITCH  TO FctTransactions PARTITION 4;

DROP INDEX ix_Work_FctTransactions_Clustered ON Work_FctTransactions;
ALTER TABLE Work_FctTransactions DROP CONSTRAINT claim_key_check_Work_FctTransactions;


--now I have 4 full partitions in FctTransactions and #5 is empty
--switch to the empty right most partition
ALTER TABLE Work_FctTransactions SWITCH TO FctTransactions PARTITION 5;

--now the work table should be empty, drop clustered index & check constraint
DROP INDEX ix_Work_FctTransactions_Clustered ON Work_FctTransactions;
ALTER TABLE Work_FctTransactions DROP CONSTRAINT claim_key_check_Work_FctTransactions;


--cannot merge partitions in the main table when it has a columnstore clustered index
--work around:  switch out last 2 partitions to a staging table on the same filegroup, drop clustered index, 
--then merge ranges, recreate index, switch back to main table
--since I already have a work table on the same filegroup, I can partition it for switching
ALTER TABLE [dbo].[Work_FctClaims] DROP CONSTRAINT [PK_FctClaims_Stg] WITH ( ONLINE = OFF )
DROP INDEX ix_Work_FctClaims_Clustered ON Work_FctClaims;
ALTER TABLE Work_FctClaims drop CONSTRAINT claim_key_check;
ALTER TABLE [dbo].[Work_FctClaims] ADD  CONSTRAINT [PK_FctClaims_Stg] PRIMARY KEY CLUSTERED ([claim_key] ASC) ON FctClaims_prtnscheme (claim_key); 
ALTER TABLE [dbo].[Work_FctClaims] DROP CONSTRAINT [PK_FctClaims_Stg] WITH ( ONLINE = OFF )
ALTER TABLE [dbo].[Work_FctClaims] ADD  CONSTRAINT [PK_FctClaims_Stg] PRIMARY KEY NONCLUSTERED ([claim_key] ASC) ON FctClaims_prtnscheme (claim_key); 
CREATE CLUSTERED COLUMNSTORE INDEX ix_Work_FctClaims_Clustered ON Work_FctClaims ON FctClaims_prtnscheme (claim_key);


ALTER TABLE FctClaims SWITCH PARTITION 4 TO Work_FctClaims PARTITION 4;
ALTER TABLE Work_FctClaims SWITCH PARTITION 4 TO FctClaims PARTITION 4;


DROP INDEX ix_Work_FctClaims_Clustered ON Work_FctClaims ;

ALTER TABLE [dbo].[Work_FctClaims] ADD  CONSTRAINT [PK_FctClaims_Stg] PRIMARY KEY CLUSTERED ([claim_key] ASC) ON FctClaimsPartition4;

ALTER PARTITION FUNCTION FctClaims_prtfcn () MERGE RANGE (700123533);

select claim_key from Work_FctClaims
DROP PARTITION FUNCTION Work_FctClaims_prtfcn
DROP PARTITION SCHEME Work_FctClaims_prtnscheme

--the right most partition will become empty 
SET @range_high = (SELECT max(transaction_key) FROM FctTransactions);
ALTER PARTITION FUNCTION FctTransactions_prtfcn () MERGE RANGE (@range_high);

--let SQL know what partition to use next
ALTER PARTITION SCHEME FctTransactions_prtnscheme NEXT USED FctTransactionsPartition4;

*/

/**at the end of year, split the last partition, add a new one, and start using the next to last one
--first, split the range where the data ends
SELECT max(claim_key) FROM FctClaims;
ALTER PARTITION FUNCTION FctClaims_prtfcn () SPLINT RANGE (700123533);

--now, I should have 2 partitions on the right that are empty
ALTER PARTITION SCHEME FctClaims_prtnscheme NEXT USED FctClaimsPartition5;

--combine the 2 partitions
ALTER PARTITION FUNCTION FctClaims_prtfcn () MERGE RANGE (838232129);

--add a new partition, making sure the boundary value is high enough to accomodate all of this year's data
ALTER PARTITION FUNCTION FctClaims_prtfcn () SPLINT RANGE (11500123533);


***/
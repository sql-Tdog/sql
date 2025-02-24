/***
-- Force query to not using any indexes: 
SELECT ObjectId,ObjectName,ObjectType FROM TblForceIndexHint with (index (0)) 
 
-- Force query to use IX_ObjectId index created on ObjectId
SELECT ObjectId,ObjectName,ObjectType FROM TblForceIndexHint  with (index (IX_ObjectId))
 
--tell the query optimizer to use only an index seek operation
SELECT  drug_key, GPI_Code_2 FROM DimDrug WITH (FORCESEEK) WHERE GPI_Code_2=01
SELECT  GPI_Code_2 FROM DimDrug WITH (FORCESEEK, INDEX(ix_DimDrug_GPI_Code_2)) WHERE GPI_Code_2=01

--tell the query optimizer to use only an index scan operation
SELECT  drug_key, GPI_Code_2 FROM DimDrug WITH (FORCESCAN) WHERE GPI_Code_2=01
SELECT  drug_key, GPI_Code_2 FROM DimDrug WITH (FORCESCAN,INDEX(PK_DimDrug)) WHERE GPI_Code_2=01


--Review column list of an index:
SELECT Col.Column_Name from 
    INFORMATION_SCHEMA.TABLE_CONSTRAINTS Tab, 
    INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE Col 
WHERE 
    Col.Constraint_Name = Tab.Constraint_Name
    AND Col.Table_Name = Tab.Table_Name
    AND Constraint_Type = 'PRIMARY KEY'
    AND Col.Table_Name = 'FctClaims'


--find all heap tables*****************************************************
SELECT SCH.name + '.' + TBL.name AS TableName 
FROM sys.tables AS TBL 
     INNER JOIN sys.schemas AS SCH ON TBL.schema_id = SCH.schema_id 
     INNER JOIN sys.indexes AS IDX ON TBL.object_id = IDX.object_id AND IDX.type = 0 -- = Heap 
ORDER BY TableName

select * from sys.indexes

--**************columnstore indexes************************************************/
--find columnstore indexes:
SELECT is_disabled,f.name Filegroup_Name,i.name Index_Name, * 
	FROM sys.tables t INNER JOIN sys.indexes i on t.object_id=i.object_id
	INNER JOIN sys.filegroups f on f.data_space_id=i.data_space_id where i.type_desc='NONCLUSTERED COLUMNSTORE'

--check which partition an index is on: (will display a row for each index in the table and partition_number it belongs to
SELECT * FROM sys.partitions WHERE object_id=object_id('lkup_claim');

--view columnstore segments of a certain partition: (min & max data values, on_disk_size, row_count)
SELECT * FROM sys.column_store_segments  WHERE partition_id=(SELECT partition_id FROM sys.partitions WHERE object_id=object_id('lkup_claim')
	AND data_compression_desc='COLUMNSTORE');

--get state_desc on columnstore indexes (closed, compressed?), total_rows, deleted_rows, created_date
SELECT * FROM sys.dm_db_column_store_row_group_physical_stats;

--**************Review mising indexes*********************************************************

--get all indexes on a table and indexed columns:  (does not included "included" columns)
EXEC sp_helpindex 'JobCostSummary_EI_T';

SELECT
	id.statement,
	cast(gs.avg_total_user_cost * gs.avg_user_impact * (gs.user_seeks + gs.user_scans) as int) AS Impact,
	cast(gs.avg_total_user_cost as numeric(10,2)) as [Average Total Cost],
	cast(gs.avg_user_impact as int) as [% Reduction of Cost],
	gs.user_seeks + gs.user_scans as [Missed Opportunities],
	id.equality_columns as [Equality Columns],
	id.inequality_columns as [Inequality Columns],
	id.included_columns as [Included Columns]
FROM sys.dm_db_missing_index_group_stats as gs
JOIN sys.dm_db_missing_index_groups AS ig ON gs.group_handle=ig.index_group_handle
JOIN sys.dm_db_missing_index_details AS id ON ig.index_handle=id.index_handle
--WHERE id.database_id=8 and object_id IN (642817352,927342368,326292222,742293704)
ORDER BY Impact DESC
GO

	

--*************Review Indexes already on the table************************************************************
SELECT Object_name(ps.object_id) AS object_name, ps.index_id,
	ISNULL(si.name,'(heap)') AS index_name,
	CAST(ps.reserved_page_count *8/1024. AS NUMERIC(10,2)) AS reserved_MB,
	ps.row_count, ps.partition_number, ps.in_row_reserved_page_count, ps.lob_reserved_page_count
FROM sys.dm_db_partition_stats ps
	LEFT JOIN sys.indexes AS si
		ON ps.object_id=si.object_id AND ps.index_id=si.index_id
WHERE Object_Name(ps.object_id)='FctClaims'

exec sp_help 

--*********** Create Indexes ********************************************************************************************************
CREATE NONCLUSTERED INDEX ix_FACT_UTILIZATION_PRESCRIBED_DRUG_KEY 
	ON FACT_UTILIZATION ([PRESCRIBED_DRUG_KEY] ) INCLUDE ([PHARMACY_KEY], [PATIENT_REFERENCE_CATEGORY_KEY], [SHIP_MODE_KEY], [DELIVERY_ADDRESS_KEY], [PATIENT_KEY], [RX_KEY], [SHIP_DATE_KEY], [PRIMARY_INSURANCE_PLAN_KEY], [FILL_NUMBER], [QUANTITY_DISPENSED], [METRIC_QUANTITY_DISPENSED], [ORDER_NEED_DATE_KEY], [UNIQUE_REFERRAL_IDENTIFIER])
	WITH (DATA_COMPRESSION=PAGE)

CREATE NONCLUSTERED INDEX ix_DIM_PATIENT_KEY oN DIM_PATIENT ([PATIENT_KEY] ) INCLUDE ([PATIENT_ID])	WITH (DATA_COMPRESSION=PAGE)

DROP INDEX IX_FctTransactions_Columnstore ON FctTransactions;


--************* Review index usage *****************************************************************************

SELECT o.name as [Object Name], i.name as [Index Name], --i.type_desc as [Index Type],
	s.user_seeks + s.user_scans + s.user_lookups as [Total Reading Queries],
	s.user_updates [Total Writing Queries], ps.row_count as [Row Count], ps.used_page_count, ps.reserved_page_count,
	ps.reserved_page_count*8/1024./1024 [size (GB)],
	CASE WHEN s.user_updates<1 THEN 100
		ELSE (s.user_seeks + s.user_scans +s.user_lookups)/s.user_updates*1.0
	END AS [Reads Per Write]
FROM sys.dm_db_index_usage_stats s
JOIN sys.dm_db_partition_stats ps on s.object_id=ps.object_id and s.index_id=ps.index_id
JOIN sys.indexes i ON i.index_id=s.index_id AND s.object_id=i.object_id
JOIN sys.objects o ON s.object_id=o.object_id
JOIN sys.schemas c ON o.schema_id=c.schema_id 
--WHERE o.name IN('DimMember')--,'DimMember','FctTransactions','DimTransaction',FctClaims)
ORDER BY [reads per write],[Total Reading Queries]

--************* Review index usage on memory optimized tables *****************************************************************************
SELECT o.name as [Object Name], i.name as [Index Name], --i.type_desc as [Index Type],
	s.*,
	ps.row_count as [Row Count], ps.used_page_count, ps.reserved_page_count,
	ps.reserved_page_count*8/1024./1024 [size (GB)]
FROM sys.dm_db_xtp_index_stats s
JOIN sys.dm_db_partition_stats ps on s.object_id=ps.object_id and s.index_id=ps.index_id
JOIN sys.indexes i ON i.index_id=s.index_id AND s.object_id=i.object_id
JOIN sys.objects o ON s.object_id=o.object_id
JOIN sys.schemas c ON o.schema_id=c.schema_id 
--WHERE o.name IN('DimMember')--,'DimMember','FctTransactions','DimTransaction',FctClaims)


--*********indexes that have not been used at all**************:
SELECT ISNULL(si.name,'(heap)') AS index_name
FROM sys.dm_db_partition_stats ps	LEFT JOIN sys.indexes AS si	ON ps.object_id=si.object_id AND ps.index_id=si.index_id
WHERE Object_Name(ps.object_id)='FctClaims'
EXCEPT
SELECT  i.name as [Index Name]
FROM sys.dm_db_index_usage_stats s JOIN sys.dm_db_partition_stats ps on s.object_id=ps.object_id and s.index_id=ps.index_id
JOIN sys.indexes i ON i.index_id=s.index_id AND s.object_id=i.object_id
JOIN sys.objects o ON s.object_id=o.object_id
JOIN sys.schemas c ON o.schema_id=c.schema_id 
WHERE o.name IN('FctClaims')




--***check index fill factor

SELECT object_id, object_name(object_id) ,name, index_id, type_desc, fill_factor
FROM sys.indexes

/*
ALTER INDEX IX_member_expiration ON member_expiration REBUILD WITH (FILLFACTOR=80);

ALTER INDEX ix_DimDate_CalendarYear_CalendarMonthNo ON DimDate REBUILD WITH (FILLFACTOR=80);

--to force a query to use an index:
SELECT * FROM table WITH (index(0));

--view current lower level IO, locking, latching, and access method activity for each partition
--inputs: db_id, object_id, index_id,partition
select t.name, i.name, s.* from sys.dm_db_index_operational_stats(5,NULL,NULL,NULL) s inner join sys.tables t on t.object_id=s.object_id
	inner join sys.indexes i on i.object_id=t.object_id
	order by page_io_latch_wait_in_ms desc; --return data for all indexes in database

--view size and fragmentation information:
SELECT t.name, i.name, s.* FROM sys.dm_db_index_physical_stats(DB_ID('DBAWork'),NULL,NULL,NULL,'DETAILED') s inner join sys.tables t on t.object_id=s.object_id
	inner join sys.indexes i on i.object_id=t.object_id
	order by avg_fragmentation_in_percent desc; --return data for all indexes in database;

--reorganize indexes that are below 30% fragmentation and rebuild the ones above30%


--view hash index stats:
/*The empty_bucket_percent is an indicator of how much space is left in the index before buckets need to start being reused for key values.  
Having about 1/3 of the buckets empty allows for a safe level of growth.  dm_db_xtp_hash_index_stats can be used to monitor your hash indexes 
en masses to determine if any need to be recreated with a larger bucket count.
The avg_chain_length tells us, on average, how many keys are chained in each bucket.  Ideally, this value would be 1, or at least close to 1.  
A high value for this stat can indicate that there are many duplicate keys in your index.  If this is the case, it may be worth considering using 
a standard nonclustered index instead.  A high avg_chain_length can also indicate that the bucket count is too low, forcing buckets to be shared.  
Recreating the index with a higher bucket count will resolve this problem.
*/
SELECT
       object_name(dm_db_xtp_hash_index_stats.object_id) AS 'object name',
       indexes.name,
       floor((cast(empty_bucket_count as float)/total_bucket_count) * 100) AS 'empty_bucket_percent',
       dm_db_xtp_hash_index_stats.total_bucket_count,
       dm_db_xtp_hash_index_stats.empty_bucket_count,
       dm_db_xtp_hash_index_stats.avg_chain_length,
       dm_db_xtp_hash_index_stats.max_chain_length
FROM sys.dm_db_xtp_hash_index_stats
INNER JOIN sys.indexes
ON indexes.index_id = dm_db_xtp_hash_index_stats.index_id
AND indexes.object_id = dm_db_xtp_hash_index_stats.object_id
*/
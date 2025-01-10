--find the pages for a nonclustered index:
SELECT index_id, page_type_desc, allocated_page_page_id FROM sys.dm_db_database_page_allocations (
	DB_ID('DBAWork'), OBJECT_ID('dbo.BlockedEvents'),2 /*index id 2 =  nonclustered index */
	, NULL /*partition id here*/, 'detailed' /*mode*/ ) WHERE is_allocated=1
	ORDER BY allocated_page_page_id asc;



--to view contents of a page in a dataabase
DBCC PAGE( DB_ID('database'),filenumber, pagenumber,printoption)

--get database id:
SELECT * FROM sys.databases;

--get file id:
SELECT file_id,  name AS FileName, size/128.0/1024 AS CurrentSizeGB,  
size/128.0/1024 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0/1024 AS FreeSpaceGB 
FROM sys.database_files 

--get index id:  
SELECT i.index_id, i.name as [Index Name] FROM sys.indexes i 
	JOIN sys.objects o ON i.object_id=o.object_id
	WHERE o.name IN('FctClaims')

--get a list of table's data and index pages; 
--index_id=-1 would return all indexes and IAMs, -2 would return all IAMs
DBCC IND (database,table,index_id)  

DBCC IND ('Datamart',FctClaims,1)

--PageFID is the filenumber of the file the page is on
--now view contents of a page: DBCC PAGE( DB_ID('database'),filenumber, pagenumber,printoption)
DBCC PAGE( 14,10, 2051204,3) WITH TABLERESULTS;


/**
DBCC CHECKDB will run the following:
		DBCC CHECKALLOC  check the consistency of disk space allocation structures
		DBCC CHECKTABLE on every table
		DBCC CHECKCATALOG  validates contents of every indexed view
and has limited ability to repair identified problems with the following 3 options (to use only if no backup option is available)
	REPAIR_ALLOW_LOSS  --will deallocate damaged pages
	REPAIR_FAST			--doesn't do anything
	REPAIR_REBUILD	--will rebuild compromised indexes
When CHECKDB is executed, it actually creates a snapshot of the database and runs checks against that to prevent concurrency problems, unless the db is in single user mode

 
If corruption is found, restore last full backup & then all the transaction logs since
WIll not cause blocking
Requires balancing 2 big factors:  Early diagnosis of corruption & Performance Impact
		Storage Intensive, High CPU burn, Memory hog, Big tempdb user
CHECKSUM should be set on:  It's overhead is negligible, Will help detect corruption quicker
Schedule: System databases:  nightly, Resource database will be auto checked when the master database is checked
	Small user databases (10gb or less):  nightly
	Large user databases:  as often as resources permit 
**/

--to validate CHECKSUM settings:
SELECT name, page_verify_option_desc FROM sys.databases;

ALTER DATABASE Staging SET PAGE_VERIFY CHECKSUM ;

--to validate last CHECKDB:
DBCC DBINFO(CMS_S1_App) WITH TABLERESULTS, NO_INFOMSGS;

--**************DBCC CHECKDB OPTIONS********************************************
--column value check for invalid data, runs by default with CHECKDB:
DBCC CHECKDB(CMS_S1_App) WITH DATA_PURITY; 

--WITH PHYSICAL_ONLY: designed to have a smaller overhead & be faster for larger database
--only looks at every 8K page & verifies CHECKSUMs for all physical page structures
--skips logical checks such as pointers from nonclustered index to clustered index but will catch
--nonclustered index corruption (verifies page checksums even on nonclustered indexes)
DBCC CHECKDB(CMS_S1_App) WITH PHYSICAL_ONLY; 

--NOINDEX:  will not catch index corruption
--intensive checks of nonclustered indexes will not be performed to decrease the overall execution time
DBCC CHECKDB(CMS_S1_App,NOINDEX) ; 
DBCC CHECKDB(CMS_S1_App,NOINDEX) WITH PHYSICAL_ONLY;  

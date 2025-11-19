/*****this script worked on SQL Server 2016 Standard Edition on 5/7/20:
******recover a database that got its ndf file deleted, without using any backup files
**this method involves creating an empty replica database, then taking it offline, and replacing new files with originals
**the key is not to detach the database, thus tricking SQL Server into using old and new files)
**I'd like to try this method without setting the empty ndf file offline!

select @@version

--initial error:  database is in Recovery Pending mode after SQL Server restart, it cannot be detached
--set the database offline
ALTER DATABASE EPO_Source SET OFFLINE;

--droppping the database should not drop the files because it's set offline, but rename the files just in case, then drop it
DROP DATABASE EPO_Source


--1.  create a new database that has the same exact file layout including all filegroups and locations
CREATE DATABASE [EPO_Source]  CONTAINMENT = NONE
	 ON  PRIMARY 
	( NAME = N'EPO_Source', FILENAME = N'F:\EPO_Source.mdf' ,  MAXSIZE = UNLIMITED, FILEGROWTH = 256000KB )
	 LOG ON 
	( NAME = N'EPO_Source_log', FILENAME = N'I:\EPO_Source.ldf' , MAXSIZE = 2048GB , FILEGROWTH = 1024000KB )
	GO
--add the missing filegroup & file that is now missing:
 ALTER DATABASE EPO_Source ADD FILEGROUP EnrollmentWorkflowStep;
 GO
ALTER DATABASE EPO_Source ADD FILE (NAME='EnrollmentWorkflowStep1', FILENAME='D:\SQLData\EnrollmentWorkflowStep1.ndf', SIZE=10GB, FILEGROWTH=10%) TO FILEGROUP EnrollmentWorkflowStep;

--will have to make sure that the file id matches what was in database that had to be dropped:
SELECT file_id, name, physical_name AS CurrentLocation, state_desc, size*8./1024/1024 size_GB, growth
FROM sys.master_files
WHERE database_id = DB_ID('EPO_Source');

--I got this error because of file_id mismatch:
An unexpected file id was encountered. File id 4 was expected but 3 was read from "D:\SQLData\EnrollmentWorkflowStep1.ndf". 
Verify that files are mapped correctly in sys.master_files. ALTER DATABASE can be used to correct the mappings.

--To fix it,  I created the new empty database with 4 files and drop (made the 3rd file something arbitrary and then dropped it)


--2.  Take the missing file offline:
ALTER DATABASE EPO_Source MODIFY FILE (NAME='EnrollmentWorkflowStep1', OFFLINE);

--3.  Take the database offline:
ALTER DATABASE EPO_Source SET OFFLINE;

--4.  Delete the empty mdf and ldf files and rename the old ones to their old names (effectively replacing 2 files of the new empty database with the originals)

--5.  Set database back online (do not delete the missing ndf file, leave the new empty one in place)
ALTER DATABASE EPO_Source SET ONLINE;

--Will get this message and table will not be accessible:
Msg 8653, Level 16, State 1, Line 66
The query processor is unable to produce a plan for the table or view 'EnrollmentWorkflowStep' because the table resides in a filegroup that is not online.

--6.  Rename the table
EXEC sp_rename 'EnrollmentWorkflowStep','EnrollmentWorkflowStep_Old';

--7.  Since the file is offline, I will not be able to modify it, remove it, or move it.  And since I cannot remove the file, I won't be able to remofe the filegroup.
--this phantom file will always be attached to this database and physical location


--will not be able to set it online (Msg 155, Level 15, State 1, Line 58 'ONLINE' is not a recognized CREATE/ALTER DATABASE option.)
ALTER DATABASE EPO_Source MODIFY FILE (NAME='EnrollmentWorkflowStep1', ONLINE);


--Another issue-cannot take backup of the database while the file is offline, will get this error:
"An error occurred while processing 'BackupMetadata' metadata for database id 18 file id 4.
Inconsistent metadata has been encountered. The only possible backup operation is a tail-log backup using the WITH CONTINUE_AFTER_ERROR or NO_TRUNCATE option.
BACKUP DATABASE is terminating abnormally.". Possible failure reasons: Problems with the query, "ResultSet" property not set correctly, parameters not set correctly, 
or connection not established correctly.

SELECT * FROM sys.database_files;  

--Fix:  remove the file & the file group
USE master
GO
ALTER DATABASE EPO_Source REMOVE FILE EnrollmentWorkflowStep1;  --will get error, just ignore it
ALTER DATABASE EPO_Source REMOVE FILEGROUP EnrollmentWorkflowStep;  --will succeed and will mark the file as DEFUNCT (removes filegroup but retains metadata)

BACKUP DATABASE EPO_Source TO DISK = N'K:\EPO_SOURCE\EPO_Source_20200508.bak' WITH COMPRESSION;--still failed although others say it works for them

BACKUP DATABASE EPO_Source FILEGROUP ='PRIMARY', FILEGROUP='EnrollmentWorkflowStepHistory' TO DISK = N'K:\EPO_SOURCE\EPO_Source_20200508.bck' WITH COMPRESSION;--still failed

--what if I change the database to simple recovery mode?
ALTER DATABASE EPO_Source SET RECOVERY FULL;  --no go

USE master;  
GO  
ALTER DATABASE EPO_Source SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
ALTER DATABASE EPO_Source MODIFY NAME = EPO_Source_Old ;
GO  
ALTER DATABASE EPO_Source_Old SET MULTI_USER
GO

--is there a full text catalog that's causing this error?
SELECT t.name AS TableName, c.name AS FTCatalogName  
	FROM sys.tables t JOIN sys.fulltext_indexes i  
	  ON t.object_id = i.object_id  
	JOIN sys.fulltext_catalogs c  
	  ON i.fulltext_catalog_id = c.fulltext_catalog_id


DROP FULLTEXT INDEX ON User_T;
DROP FULLTEXT CATALOG search1;

--is it because this is not an Enterprise SQL Server Edition?
--I did not find any way to resolve this error so I generated a script to create a copy of this database, then moved the data 
--doing SELECT * from old table to new table was the faster way but the fastest way is to SELECT * INTO without creating the new tables first

BACKUP LOG EPO_SOURCE TO DISK = N'K:\EPO_SOURCE\EPO_Source_20200508.trn' WITH NO_TRUNCATE, CONTINUE_AFTER_ERROR; --does not work

DBCC SHRINKFILE(EnrollmentWorkflowStep1,EMPTYFILE);  --does not work

DBCC CHECKDB (EPO_Source);  (runs CHECKALLOC, CHECKTABLE, CHECKCATALOG in this order)
DBCC CHECKCATALOG (EPO_Source);  --no errors
DBCC CHECKALLOC  (EPO_Source, NOINDEX);  --no errors
DBCC CHECKFILEGROUP (EnrollmentWorkflowStep) 

--this is not a viable option for creating a database without attaching the missing ndf file:
EXECUTE sp_attach_single_file_db @dbname='EPO_Source', @physname=N'F:\EPO_Source.mdf'
GO
*/
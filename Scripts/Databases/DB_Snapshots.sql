/***Prerequisites*******************************************************************************
The server instance must be running an edition of SQL Server that supports database snapshot.  All versions of SQL Server 2016 support this.
The source database must be online, unless the database is a mirror database within a database mirroring session.
To create a database snapshot on a mirror database, the database must be in the synchronized mirroring state.
The source database cannot be configured as a scalable shared database.
The source database must not contain a MEMORY_OPTIMIZED_DATA filegroup.
Snapshots are strictly read only.
The user permissions are exactly the same as it was in the source database. You cannot grant a user access to a snapshot.


.ss extension is arbitrary, it can be anything
all database files of the source database must be specified
do not specify log files


In the event of a user error on a source database, you can revert the source database to the state it was in when a given database snapshot was created. 
Data loss is confined to updates to the database since the snapshot's creation. 
For example, before doing major updates, such as a bulk update or a schema change, create a database snapshot on the database protects data. 
If you make a mistake, you can use the snapshot to recover by reverting the database to the snapshot. Reverting is potentially much faster for this 
purpose than restoring from a backup; however, you cannot roll forward afterward.
 
*/
SELECT name, physical_name AS CurrentLocation, state_desc
FROM sys.master_files
WHERE database_id = DB_ID(N'CMS_Prod_App');


--executes in seconds
CREATE DATABASE CMS_Prod_App_SS ON ( NAME = DW_PBM, FILENAME ='I:\SQLData\Datamart_Snapshot\DW_PBM.ss' ),
	( NAME = DimClaimClustered1, FILENAME ='I:\SQLData\Datamart_Snapshot\DimClaimClustered1.ss' ),
	( NAME = DURMA4, FILENAME ='G:\SQLData\Datamart_Snapshot\DURMA4.ss' ),
	( NAME = DURMA5, FILENAME ='G:\SQLData\Datamart_Snapshot\DURMA5.ss' ) AS SNAPSHOT OF CMS_Prod_App;



--check if database snapshots exist (source_Database_id is not null for snapshots):
select * from sys.databases;


--revert back to a snapshot:  (in case of multiple snapshots, drop any other database snapshots first)
USE master;  
GO
--If there is more than one snapshot: Test to see if a snapshot exists and delete it.  
IF EXISTS (SELECT dbid FROM sys.databases WHERE NAME='sales_snapshot0600')  
    DROP DATABASE SalesSnapshot0600;  
GO  
RESTORE DATABASE CMS_Prod_App FROM DATABASE_SNAPSHOT = 'CMS_Prod_App_SS';  
GO  


--drop database snapshot:
DROP DATABASE  CMS_Prod_App_SS;  
GO
--can use IF EXISTS condition in SQL Server 2016 and newer
IF EXISTS (SELECT dbid FROM sys.databases WHERE NAME='CMS_Prod_App_SS')  
    DROP DATABASE CMS_Prod_App_SS;  

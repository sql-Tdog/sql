/*
sp_CONFIGURE
 
*/
 
 
/****Informational DBCC *************************************/
--check for open transactions
DBCC OPENTRAN
 
--display the last statement sent from a client to the server
DBCC INPUTBUFFER(53)
 
--display fragmentation information for the data and indexes of the specified table or view
DBCC SHOWCONTIG ('eh.dbo.transactions')
 
--get transaction log space usage statistics for all databases
DBCC SQLPERF(LOGSPACE)
--reset waiting statistics
DBCC SQLPERF("sys.dm_os_wait_stats",CLEAR)
 
--get the current output buffer in hexadecimal and ASCII format for the specified session_id
DBCC OUTPUTBUFFER(53)
 
--display the status of trace flags
DBCC TRACESTATUS(-1) --display the status of all trace flags that are currently enabled globally
 
--display information about the procedure cache, the plan cache
DBCC PROCCACHE
 
--return the SET options active (set) for the current connection
DBCC USEROPTIONS
 
--display current query optimization statistics for a table or indexed view (steps is # of bins)
DBCC SHOW_STATISTICS ('SalesLT.Address','IX_Address_StateProvince')
 
 --display all pages used by a table:
DBCC IND ('DatabaseName', 'TableName', -1);
 

 
/***************Validation DBCC: */
--check the consistency of disk space allocation structures for a specified database:
DBCC CHECKALLOC('cph')
 
--check for catalog consistency within the specified database (must be online)
DBCC CHECKCATALOG('eh')
 
--check the current identity value for the specified table
DBCC CHECKIDENT('transactions')  --corrects it if incorrect
DBCC CHECKIDENT('transactions',NORESEED) --does not correct it
DBCC CHECKIDENT('transactions',RESEED, 1274) --next row inserted will be 1275
 
--check the integrity of a specified constraint or all constraints on a specified table in the current db
DBCC CHECKCONSTRAINTS;
 
--check the integrity of all the pages and structures that make up the table or indexed view
DBCC CHECKTABLE('transactions');
 
--check the logical and physical integrity of all the objects in the specified database by running the following:
DBCC CHECKDB('tracking_cph')
/*
DBCC CHECKDB will run the following:
		DBCC CHECKALLOC
		DBCC CHECKTABLE on every table
		DBCC CHECKCATALOG  validates contents of every indexed view and has limited ability to repair identified problems with the following
			3 options (to use only if no backup option is available)
				REPAIR_ALLOW_LOSS  --will deallocate damaged pages
				REPAIR_FAST			--doesn't do anything
				REPAIR_REBUILD	--will rebuild compromised indexes
When CHECKDB is executed, it actually creates a snapshot of the database and runs checks against that to prevent concurrency problems, unless the 
db is in single user mode
 */
 
--to run DBCC CHECKDB only against a certain filegroup:
DBCC CHECKFILEGROUP(1)
 

 
/********Maintenance */
--reclaims space from dropped variable-length columns in tables or indexed views
DBCC CLEANTABLE('eh','transactions')
 
----defragments indexes of the specified table or view, will be removed, use ALTER INDEX instead
DBCC INDEXDEFRAG('eh','transactions','PK_transactions')
 
--rebuild one or more indexes for a table in the specified database:
DBCC DBREINDEX('transactions')
 
--shrink the size of the data and log files in the specified database:
       --A shrink operation is most effective after an operation that creates lots of unused space, such as a truncate table or a drop table operation.
       --Unless you have a specific requirement, do not set the AUTO_SHRINK database option to ON
DBCC SHRINKDATABASE('eh')
 
--remove all clean buffers from the buffer pool:
       --Use DBCC DROPCLEANBUFFERS to test queries with a cold buffer cache without shutting down and restarting the server.
DBCC DROPCLEANBUFFERS
 
--Shrink the size of the specified data or log file for the current database, or empties a file by moving the data from the specified file to other
--files in the same filegroup, allowing the file to be removed from the database. You can shrink a file to a size that is less than the size specified
--when it was created. This resets the minimum file size to the new value.
DBCC SHRINKFILE ('filename')
 
 
--remove all elements from the plan cache, remove a specific plan from the plan cache
DBCC FREEPROCCACHE
 
--report and correct page and row count inaccuracies in the catalog views
--These inaccuracies may cause incorrect space usage reports returned by the sp_spaceused system stored procedure.
--Best Practices:
    --Do not run DBCC UPDATEUSAGE routinely. Because DBCC UPDATEUSAGE can take some time to run on large tables or databases,
       --it should not be used only unless you suspect incorrect values are being returned by sp_spaceused.
    --Consider running DBCC UPDATEUSAGE routinely (for example, weekly) only if the database undergoes frequent Data Definition Language (DDL)
       --modifications, such as CREATE, ALTER, or DROP statements.
DBCC UPDATEUSAGE('eh')
 
 
/*******Miscellaneous: */

--unload the specified extended stored procedure DLL from memory:
DBCC dllname(FREE)
 
 
/**undocumented commands */

--get metadata information of the specified database
DBCC DBINFO(sttts) WITH TABLERESULTS;
 
--list all of a table's data and index pages
DBCC IND('hh',transactions,-1)
 
--look at contents of a certain page
DBCC PAGE('NavigatorsGrant',1,157311,3) WITH TABLERESULTS  --DBCC PAGE('databasename',filenumber, pagenumber,printoption)
 
--dump all checkpoint events into error log, 3502 turns on checkpoint information & 3605 lets the info go to the error log,
--the s on the end of the spid# shows that this is an automatic checkpoint:
DBCC TRACEON (3502, 3605, -1);
 
 

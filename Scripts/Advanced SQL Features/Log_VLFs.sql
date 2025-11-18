/**  Get information about your virtual logs inside the transaction log. 
 **  The primary thing to look at here is the Status column. 
 **  Since this file is written sequentially and then looped back to the beginning,
 **  take a look at where the value of "2" is in the output. 
 **  This will tell you what portions of the log are in use and which are not in use Status = 0. 
 **  Another thing to keep an eye on is the FSeqNo column. This is the virtual log sequence number
 **  and the latest is the last log.  If you keep running this command as you are issuing transactions 
 **  you will see these numbers keep changing. **/
DBCC LOGINFO


/**------------------------------get a count of VLFs:
 
DECLARE @query varchar(1000),  @dbname varchar(1000),  @count int
 
SET NOCOUNT ON
 
DECLARE csr CURSOR FAST_FORWARD READ_ONLY
FOR
SELECT name
FROM sys.databases
 
CREATE TABLE ##loginfo ( dbname varchar(100), num_of_rows int)
 
OPEN csr
 
FETCH NEXT FROM csr INTO @dbname
 
WHILE (@@fetch_status <> -1)
BEGIN
 
CREATE TABLE #log_info ( RecoveryUnitId tinyint, --RecoveryUnitId does not exist in 2008R2
fileid tinyint, file_size bigint,
start_offset bigint, FSeqNo int,[status] tinyint, parity tinyint, create_lsn numeric(25,0))
 
SET @query = 'DBCC loginfo (' + '''' + @dbname + ''') '
 
INSERT INTO #log_info
EXEC (@query)
 
SET @count = @@rowcount
 
DROP TABLE #log_info
--select * from #log_info
INSERT ##loginfo VALUES(@dbname, @count)
 
FETCH NEXT FROM csr INTO @dbname
 
END
 
CLOSE csr
DEALLOCATE csr
 
SELECT dbname,
num_of_rows
FROM ##loginfo
--WHERE num_of_rows >= 50 --My rule of thumb is 50 VLFs. Your mileage may vary.
ORDER BY num_of_rows desc
 
DROP TABLE ##loginfo
 
 */



/**
brentozar.com/go/vlf
First, how is the log divided?
Here’s the breakdown for chunksize:
chunks less than 64MB and up to 64MB = 4 VLFs
chunks larger than 64MB and up to 1GB = 8 VLFs
chunks larger than 1GB = 16 VLFs
 
Recommended size:  create the log in 8GB chunks so that the number and size of VLFs is manageable (in this case 512MB).  This way we won't have to wait until a very large chunk is full
and becomes completely inactive before we can clear it.
Good rule of thumb for # of VLFs:  50
 
How Do I Lower a Database’s VLF Count?
The next step is to shrink the logs to as small as possible then grow them back to the original size,
ideally in a single growth. This is best done during off-peak times. You may have to run it multiple times to get to a'
low enough VLF count.
 
 
USE USRGRP_FINANCE
--size from sys.database_files is the # of pages, page size is 8KB>>size*8/1024=size/128
SELECT name, size/128/1024. size_GB FROM sys.database_files WHERE type_desc = 'log'
 
USE EPOInvoice
DECLARE @file_name sysname,
@file_size int,
@file_growth int,
@shrink_command nvarchar(max),
@alter_command nvarchar(max)
 
SELECT @file_name = name, @file_size = (size / 128)
FROM sys.database_files WHERE type_desc = 'log'
 
SELECT @shrink_command = 'DBCC SHRINKFILE (N''' + @file_name + ''' , 0, TRUNCATEONLY)'
PRINT @shrink_command
EXEC sp_executesql @shrink_command
 
SELECT @shrink_command = 'DBCC SHRINKFILE (N''' + @file_name + ''' , 0)'
PRINT @shrink_command
EXEC sp_executesql @shrink_command
 
SELECT @alter_command = 'ALTER DATABASE [' + db_name() + '] MODIFY FILE (NAME = N''' + @file_name + ''', SIZE = ' + CAST(@file_size AS nvarchar) + 'MB)'
PRINT @alter_command
EXEC sp_executesql @alter_command
 
 
*/
 
 